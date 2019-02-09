package {
    import flash.display.Sprite;
    import flash.geom.Point;
    import flash.display.MovieClip;
    import flash.geom.Rectangle;
    import flash.events.MouseEvent;

    public class ListContainer extends Sprite {
        public static const ITEM_SELECTED: String = "List::ItemSelected";
        public var _type: String;
        public var _categoryName: String;

        private const ITEM_SIZE: uint = 30;

        private var _height: Number;

        private var _iconManager: IconManager;

        private var _scrollbar: Scrollbar;

        private var _closeOnUse: Boolean;

        private var _itemsCount: int;

        private var _listItems: Array = [];

        private var _currentListItem: ListItem = null;

        public function ListContainer(
            category: String,
            type: String,
            leftPos: Point,
            width: Number,
            height: Number,
            iconManager: IconManager,
            items: Array,
            closeOnUse: Boolean = true
        ) {
            this._closeOnUse = closeOnUse;
            this._type = type;
            this._categoryName = category;
            this._iconManager = iconManager;
            this._height = height;
            this._itemsCount = items.length;

            this.x = leftPos.x;
            this.y = leftPos.y;
            this.graphics.moveTo(0, 0);

            var listHitArea: Sprite = new Sprite();
            listHitArea.graphics.moveTo(0, 0);
            listHitArea.graphics.beginFill(0, 0);
            listHitArea.graphics.drawRect(0, 0, width, height);
            listHitArea.graphics.endFill();
            listHitArea.mouseEnabled = false;
            this.addChild(listHitArea);

            this.graphics.lineStyle(2, 0xffffff, 0.8, true);
            this.graphics.beginFill(0x202020, 0.75);
            this.graphics.drawRect(0, 0, width, height);
            this.hitArea = listHitArea;
            this.hitArea.addEventListener(MouseEvent.MOUSE_WHEEL, this.onMouseWheel);
            this.mouseChildren = true;

            this.hitArea.scrollRect = new Rectangle(0, 0, width, height + 1);

            this._scrollbar = new Scrollbar(height, (this.ITEM_SIZE) * items.length);
            this._scrollbar.x = width + 3;
            this._scrollbar.y = 0;
            this.addChild(this._scrollbar);

            var sortedItems: Array = items.sortOn("fullName");

            for (var i: uint = 0; i < sortedItems.length; i++) {
                var item: Item = sortedItems[i];
                var icon: MovieClip = item.iconName ? this._iconManager.getIconInstance(item.iconName) : null;
                // substract borders from item width. For some reason 4 (border width * 2) doesn't look good
                // var listItem: ListItem = new ListItem(i, new Point(leftPos.x + 2, leftPos.y + (i * this.ITEM_SIZE) + 2), width - 3, this.ITEM_SIZE, item, icon);
                var listItem: ListItem = new ListItem(i, new Point(2, (i * this.ITEM_SIZE) + 2), width - 3, this.ITEM_SIZE, item, icon);
                listItem.addEventListener(ListItem.MOUSE_CLICK, this.onItemClick);
                listItem.addEventListener(ListItem.MOUSE_ENTER, this.onItemEnter);
                listItem.addEventListener(ListItem.MOUSE_LEAVE, this.onItemLeave);
                this._listItems.push(listItem);
                this.hitArea.addChild(listItem);
            }
        }

        /**
         * Select next/previous item based on offset
         */
        public function highlightNextItem(offset: Number): void {
            var currentIndex: Number = this._currentListItem ? this._listItems.indexOf(this._currentListItem) || 0 : 0;
            var nextIndex: Number = currentIndex + offset;

            // special case to select first item if not selected any
            if (!this._currentListItem) {
                nextIndex = 0;
            }

            if (nextIndex < 0) {
                nextIndex = 0;
            }

            var nextItem: ListItem = this._listItems[nextIndex];
            if (!nextItem) {
                return;
            }

            if (this._currentListItem) {
                this._currentListItem.highlighted = false;
            }
            nextItem.highlighted = true;
            this._currentListItem = nextItem;
            this.updateScrollForCurrentItem();
        }

        public function selectCurrentItem(): void {
            if (!this._currentListItem) {
                return;
            }
            var item: Item = this._currentListItem.item;
            if (!item.equipped) {
                var selEv: CustomEvent = new CustomEvent(ListContainer.ITEM_SELECTED, { item: item, close: this._closeOnUse });
                this.dispatchEvent(selEv);
            }
        }

        private function get currentScrollOffset(): Number {
            return this.hitArea.scrollRect.y;
        }

        private function get maxScrollOffset(): Number {
            return (this._itemsCount * this.ITEM_SIZE) > this._height ? (this._itemsCount * this.ITEM_SIZE) - this._height : 0;
        }

        private function onItemClick(ev: CustomEvent): void {
            var item: Item = ev.customData.item;
            if (!item.equipped) {
                var selEv: CustomEvent = new CustomEvent(ListContainer.ITEM_SELECTED, { item: item, close: this._closeOnUse });
                this.dispatchEvent(selEv);
            }
        }

        private function onItemEnter(ev: CustomEvent): void {
            if (this._currentListItem) {
                this._currentListItem.highlighted = false;
            }
            var item: ListItem = ev.customData.listItem;
            this._currentListItem = item;
            this._currentListItem.highlighted = true;
        }

        private function onItemLeave(ev: CustomEvent): void {
            if (this._currentListItem) {
                this._currentListItem.highlighted = false;
            }
            this._currentListItem = null;
        }

        private function onMouseWheel(ev: MouseEvent): void {
            ev.stopImmediatePropagation();
            var delta: int = ev.delta;
            // delta === 0 -> one item down
            // delta === 1 -> one item up
            // delta < 0 -> delta items down
            // delta > 1 -> delta items up
            var rect: Rectangle = this.hitArea.scrollRect;
            if (delta <= 0 && this.currentScrollOffset < this.maxScrollOffset) {
                rect.y += delta > 0 ? (delta * 15) : 15;
                if (rect.y > this.maxScrollOffset) {
                    rect.y = maxScrollOffset;
                }
                this.hitArea.scrollRect = rect;
            } else if (delta > 0 && this.currentScrollOffset > 0) {
                rect.y -= (delta * 15);
                if (rect.y < 0) {
                    rect.y = 0;
                }
                this.hitArea.scrollRect = rect;
            }
            var scrolledPercents: Number = 100 * this.currentScrollOffset / this.maxScrollOffset;
            this._scrollbar.setScrollPercents(scrolledPercents);
        }

        private function updateScrollForCurrentItem(): void {
            if (!this._currentListItem) {
                return;
            }

            var rect: Rectangle = this.hitArea.scrollRect;
            if (this._currentListItem.y > (this._height - 2) + this.currentScrollOffset) {
                rect.y += this.ITEM_SIZE;
                this.hitArea.scrollRect = rect;
            } else if (this._currentListItem.y < this.currentScrollOffset) {
                rect.y -= this.ITEM_SIZE;
                this.hitArea.scrollRect = rect;
            }
            var scrolledPercents: Number = 100 * this.currentScrollOffset / this.maxScrollOffset;
            this._scrollbar.setScrollPercents(scrolledPercents);
        }
    }

}