package {
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.geom.Point;
    import flash.events.MouseEvent;
    import flash.events.Event;

    public class MenuContainer extends Sprite {
        public static const ITEM_SELECTED: String = "Menu::ItemSelected";
        private const rightDegStart: uint = 290;
        private const rightDegEnd: uint = 90;
        private const leftDegStart: uint = 250;
        private const leftDegEnd: uint = 90;
        private const totalDegsPerSection: uint = 160;

        /**
         * Menu inner circle radius
         */
        private var innerRadius: uint;
        /**
         * Menu outer circle radius
         */
        private var outerRadius: uint;
        /**
         * Center position
         */
        private var centerPos: Point;
        /**
         * Icon manager
         */
        private var iconManager: IconManager;
        /**
         * Processed menu items
         */
        private var items: Array = [];
        /**
         * Triangle pointer shape
         */
        private var pointer: Shape;
        /**
         * Current highlighted item
         */
        private var highlightedItem: MenuItem;
        /**
         * Pinned (i.e. active selected) item
         */
        private var pinnedItem: MenuItem;
        /**
         * Top menu item refernece (the one without submenu)
         */
        private var topMenuItem: MenuItem;

        public function MenuContainer(centerPos: Point, innerRad: uint, outerRad: uint, iconManager: IconManager, items: Array) {
            this.innerRadius = innerRad;
            this.outerRadius = outerRad;
            this.iconManager = iconManager;
            this.centerPos = centerPos;
            this.x = centerPos.x;
            this.y = centerPos.y;

            var menuHitArea: Sprite = new Sprite();
            menuHitArea.graphics.beginFill(0, 0);
            menuHitArea.graphics.drawCircle(0, 0, this.outerRadius);
            menuHitArea.mouseEnabled = false;
            this.addChild(menuHitArea);
            this.hitArea = menuHitArea;

            // create menu circle borders
            var circ: Shape = new Shape();
            circ.graphics.beginFill(0x202020, 0.75);
            circ.graphics.lineStyle(3, 0x0ffffff, 0.2, true);
            circ.graphics.drawCircle(0, 0, this.outerRadius);
            circ.graphics.drawCircle(0, 0, this.innerRadius);
            circ.graphics.endFill();
            this.addChild(circ);

            // add stub menu item at the top
            topMenuItem = new MenuItem(null, "left", this.innerRadius, this.outerRadius, this.leftDegStart, this.rightDegStart, 20, null, true);
            this.addChild(topMenuItem);
            this.highlightedItem = topMenuItem;

            var leftItems: Array = items.filter(function (item: Object, index: int, array: Array): Boolean {
                return item.type === "left";
            })
            var rightItems: Array = items.filter(function (item: Object, index: int, array: Array): Boolean {
                return item.type === "right";
            })

            var leftItemsDeg: Number = this.totalDegsPerSection / leftItems.length;
            var rightItemsDeg: Number = this.totalDegsPerSection / rightItems.length;

            for (var il: int = 0; il < leftItems.length; il++) {
                var itemL: Object = leftItems[il];
                var startL: Number = leftDegStart - (il * leftItemsDeg);
                var endL: Number = leftDegStart - leftItemsDeg - (il * leftItemsDeg);
                var menuDefItemL: Object = {
                    name: itemL.name,
                    startDeg: endL, //counterclockwise
                    endDeg: startL, //counterclockwise
                    type: "left",
                    menuObj: new MenuItem(itemL.name, "left", this.innerRadius, this.outerRadius, startL, endL, leftItemsDeg, iconManager.getIconInstance(itemL.icon))
                };
                this.items.push(menuDefItemL);
                this.addChild(menuDefItemL.menuObj);
            }
            for (var ir: int = 0; ir < rightItems.length; ir++) {
                var itemR: Object = rightItems[ir];
                var startR: Number = rightDegStart + (ir * rightItemsDeg);
                var endR: Number = rightDegStart + rightItemsDeg + (ir * rightItemsDeg);
                if (startR > 360) {
                    startR = startR - 360;
                }
                if (endR > 360) {
                    endR = endR - 360;
                }
                var menuDefItemR: Object = {
                    name: itemR.name,
                    startDeg: startR,
                    endDeg: endR,
                    type: "right",
                    menuObj: new MenuItem(itemR.name, "right", this.innerRadius, this.outerRadius, startR, endR, rightItemsDeg, iconManager.getIconInstance(itemR.icon))
                };
                this.items.push(menuDefItemR);
                this.addChild(menuDefItemR.menuObj);
            }
            this.mouseEnabled = true;
            this.mouseChildren = false;
            this.addEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMove);
            this.addEventListener(MouseEvent.CLICK, this.onMouseClick);
            this.addEventListener(MouseEvent.MOUSE_OUT, this.onMouseOut);

            this.pointer = new Shape();
            this.pointer.graphics.beginFill(0xffffff, 0.8);
            this.pointer.graphics.moveTo(-10, 5);
            this.pointer.graphics.lineTo(0, -20);
            this.pointer.graphics.lineTo(10, 5);
            this.pointer.graphics.lineTo(-10, 5);
            this.addChild(this.pointer);
        }

        private function getDegFromMouseEvent(ev: MouseEvent): Number {
            // the coords are x -> right, y -> bottom, but rotation is performed by x-> right, y -> top, so swap
            var x: int = -ev.localX;
            var y: int = -ev.localY;
            if (y === 0) {
                y = 1;
            }
            if (x === 0) {
                x = 1;
            }
            // const degCos = y / 100;
            var l: Number = Math.sqrt((x * x) + (y * y));
            if (l === 0) {
                l = 1;
            }
            var radiants: Number = Math.acos(
                ((y * y) + (l * l) - (x * x)) /
                (2 * y * l)
            );
            // y can be 0 and the math will be NaN
            if (isNaN(radiants)) {
                radiants = 90 * Math.PI / 180;
            }
            var degs: Number = radiants * 180 / Math.PI
            return degs;
        }

        private function onMouseClick(ev: MouseEvent): void {
            if (!this.highlightedItem || this.highlightedItem === this.topMenuItem) {
                return;
            }
            // unpin on second click
            if (this.highlightedItem === this.pinnedItem) {
                this.pinnedItem = null;
            } else {
                var prevPinnedItem: MenuItem = this.pinnedItem;
                // unhighlight previously pinned item if any
                if (prevPinnedItem) {
                    prevPinnedItem.active = false;
                }
                this.pinnedItem = this.highlightedItem;
                var e: Event = new CustomEvent(MenuContainer.ITEM_SELECTED, { name: this.pinnedItem.itemName, type: this.pinnedItem.type });
                this.dispatchEvent(e);

                var degs: Number = this.getDegFromMouseEvent(ev);
                if (ev.localX >= 0) {
                    this.pointer.rotationZ = degs;
                } else {
                    this.pointer.rotationZ = -degs;
                }
            }
        }

        private function onMouseOut(ev: MouseEvent): void {
            if (!this.pinnedItem && !this.highlightedItem) {
                return;
            }
            if (this.pinnedItem && this.pinnedItem !== this.highlightedItem) {
                this.highlightedItem.active = false;
                this.highlightedItem = this.pinnedItem;
                // this.highlightedItem = null;
            }
        }

        private function onMouseMove(ev: MouseEvent): void {
            var prevPinnedItem: MenuItem = this.pinnedItem;
            // var degs: Number = radiants * 180 / Math.PI
            var degs: Number = this.getDegFromMouseEvent(ev);
            this.updateActiveItemFromMouseDeg(ev.localX >= 0 ? degs : 360 - degs, ev.localX < 0);
            // rotate pointer only when not pinned something, otherise it's confusing
            if (!prevPinnedItem || !this.pinnedItem || (this.pinnedItem !== prevPinnedItem)) {
                if (ev.localX >= 0) {
                    this.pointer.rotationZ = degs;
                } else {
                    this.pointer.rotationZ = -degs;
                }
            }
        }

        private function updateActiveItemFromMouseDeg(degs: Number, left: Boolean = false): void {
            // menu items degs are shifted by 90 clockwise
            var menuDegs: Number = degs <  90 ? 270 + degs : degs - 90;
            var foundItem: Object;
            for (var i: int = 0; i < this.items.length; i++) {
                var item: Object = this.items[i];
                if (item.startDeg <= menuDegs && item.endDeg > menuDegs) {
                    foundItem = item;
                    break;
                }
            }
            // use degree-border item if in right pane, and not at the top
            if (!foundItem && !left && (menuDegs >= this.rightDegStart || menuDegs <= this.rightDegEnd)) {
                var filtered: Array = this.items.filter(function (item: Object, index: int, arr: Array): Boolean {
                    return item.type === "right" && item.startDeg > item.endDeg;
                });
                foundItem = filtered[0];
            }
            if (foundItem && this.highlightedItem !== foundItem.menuObj) {
                if (this.pinnedItem !== this.highlightedItem) {
                    this.highlightedItem.active = false;
                }
                this.highlightedItem = foundItem.menuObj;
                this.highlightedItem.active = true;
                // send event only if not pinned something
                if (!this.pinnedItem) {
                    var e1: Event = new CustomEvent(MenuContainer.ITEM_SELECTED, { name: this.highlightedItem.itemName, type: this.highlightedItem.type });
                    this.dispatchEvent(e1);
                }
            } else if (!foundItem && this.highlightedItem !== this.topMenuItem) {
                if (this.highlightedItem && this.highlightedItem !== this.pinnedItem) {
                    this.highlightedItem.active = false;
                }
                this.highlightedItem = this.topMenuItem;
                this.highlightedItem.active = true;
                if (!this.pinnedItem) {
                    var e2: Event = new CustomEvent(MenuContainer.ITEM_SELECTED, { name: null, type: null });
                    this.dispatchEvent(e2);
                }
            }
            // trace(menuDegs);
        }
    }
}