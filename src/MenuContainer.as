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
         * Current active item
         */
        private var activeItem: MenuItem;
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
            circ.graphics.beginFill(0x000000, 0.7);
            circ.graphics.lineStyle(3, 0xffffff, 0.1, true);
            circ.graphics.drawCircle(0, 0, this.outerRadius);
            circ.graphics.drawCircle(0, 0, this.innerRadius);
            // circ.graphics.endFill();
            this.addChild(circ);

            // add stub menu item at the top
            topMenuItem = new MenuItem(null, "left", this.innerRadius, this.outerRadius, this.leftDegStart, this.rightDegStart, 20, null, true);
            this.addChild(topMenuItem);
            this.activeItem = topMenuItem;

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
            this.addEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMove);

            this.pointer = new Shape();
            this.pointer.graphics.beginFill(0xffffff, 0.35);
            this.pointer.graphics.moveTo(-10, 5);
            this.pointer.graphics.lineTo(0, -20);
            this.pointer.graphics.lineTo(10, 5);
            this.pointer.graphics.lineTo(-10, 5);
            this.addChild(this.pointer);
        }

        private function onMouseMove(ev: MouseEvent): void {
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
            // var deg: Number = (1 / (Math.sin(y / 100))) / (Math.PI / 180);
            var radiants: Number = Math.acos(
                ((y * y) + (l * l) - (x * x)) /
                (2 * y * l)
            );
            // y can be 0 and the math will be NaN
            if (isNaN(radiants)) {
                radiants = 90 * Math.PI / 180;
            }
            var degs: Number = radiants * 180 / Math.PI
            // trace(degs);
            // trace(ev.localX);
            if (ev.localX >= 0) {
                // trace(degs);
                this.pointer.rotationZ = degs;
            } else {
                this.pointer.rotationZ = -degs;
                // trace(360 - degs);
            }
            this.updateActiveItemFromMouseDeg(ev.localX >= 0 ? degs : 360 - degs, ev.localX < 0);
            // this.pointer.rotationZ = 350;
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
            if (foundItem && this.activeItem !== foundItem.menuObj) {
                this.activeItem.active = false;
                this.activeItem = foundItem.menuObj;
                this.activeItem.active = true;
                var e1: Event = new CustomEvent(MenuContainer.ITEM_SELECTED, { name: this.activeItem.itemName, type: this.activeItem.type });
                this.dispatchEvent(e1);
            } else if (!foundItem && this.activeItem !== this.topMenuItem) {
                if (this.activeItem) {
                    this.activeItem.active = false;
                }
                this.activeItem = this.topMenuItem;
                this.activeItem.active = true;
                var e2: Event = new CustomEvent(MenuContainer.ITEM_SELECTED, { name: null, type: null });
                this.dispatchEvent(e2);
            }
            // trace(menuDegs);
        }
    }
}