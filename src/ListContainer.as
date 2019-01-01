package {
    import flash.display.Sprite;
    import flash.geom.Point;
    import flash.display.MovieClip;

    public class ListContainer extends Sprite {
        public static const ITEM_SELECTED: String = "List::ItemSelected";
        public var type: String;
        public var categoryName: String;

        private const ITEM_SIZE: uint = 30;

        private var iconManager: IconManager;

        private var closeOnUse: Boolean;

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
            this.closeOnUse = closeOnUse;
            this.type = type;
            this.categoryName = category;
            this.iconManager = iconManager;

            var listHitArea: Sprite = new Sprite();
            listHitArea.graphics.moveTo(leftPos.x, leftPos.y);
            listHitArea.graphics.beginFill(0, 0);
            listHitArea.graphics.drawRect(leftPos.x, leftPos.y, width, height);
            listHitArea.graphics.endFill();
            listHitArea.mouseEnabled = false;
            this.addChild(listHitArea);

            this.graphics.moveTo(leftPos.x, leftPos.y);
            this.graphics.lineStyle(2, 0xffffff, 0.4, true);
            this.graphics.beginFill(0x000000, 0.4);
            this.graphics.drawRect(leftPos.x, leftPos.y, width, height);
            this.hitArea = listHitArea;
            this.mouseChildren = true;

            for (var i: uint = 0; i < items.length; i++) {
                var item: Item = items[i];
                var icon: MovieClip = item.iconName ? this.iconManager.getIconInstance(item.iconName) : null;
                var listItem: ListItem = new ListItem(i, new Point(leftPos.x + 2, leftPos.y + (i * this.ITEM_SIZE) + 2), width - 2, this.ITEM_SIZE, item, icon);
                listItem.addEventListener(ListItem.MOUSE_CLICK, this.onItemClick);
                this.addChild(listItem);
            }
        }

        private function onItemClick(ev: CustomEvent): void {
            var item: Item = ev.customData.item;
            if (!item.equipped) {
                var selEv: CustomEvent = new CustomEvent(ListContainer.ITEM_SELECTED, { item: item, close: this.closeOnUse });
                this.dispatchEvent(selEv);
            }
        }
    }

}