package {
    import flash.display.Sprite;
    import flash.geom.Point;
    import flash.display.MovieClip;
    import flash.text.TextField;
    import flash.display.Shape;
    import flash.text.TextFieldAutoSize;
    import flash.events.MouseEvent;
    import flash.text.TextFormat;

    public class ListItem extends Sprite {
        public static const MOUSE_ENTER: String = "ListItem::MouseEnter";
        public static const MOUSE_LEAVE: String = "ListItem::MouseLeave";
        public static const MOUSE_CLICK: String = "ListItem::MouseClick";

        private var paddings: Number;

        private var _highlighted: Boolean;

        private var icon: MovieClip;

        private var text: TextField;

        private var countText: TextField;

        private var equippedMarker: Shape;

        private var containerSprite: Sprite;

        private var _item: Item;

        private var _pos: Point;
        private var _width: uint;
        private var _height: uint;

        public function ListItem(index: uint, pos: Point, width: uint, height: uint, item: Item, icon: MovieClip = null) {
            this._item = item;
            this._item.addEventListener(Item.EQUIPPED_CHANGED, this.onEquippedChanged);
            this._pos = pos;
            this._width = width;
            this._height = height;
            this.icon = icon;
            // render separator line
            this.graphics.lineStyle(1, 0xffffff, 0.2, true);
            this.graphics.moveTo(this._pos.x, this._pos.y + this._height);
            this.graphics.lineTo(this._pos.x + this._width, this._pos.y + this._height);

            this.drawContent();
            this.addEventListener(MouseEvent.MOUSE_OVER, this.onMouseEnter);
            this.addEventListener(MouseEvent.MOUSE_OUT, this.onMouseLeave);
            this.addEventListener(MouseEvent.CLICK, this.onClick);
        }

        private function drawContent(initial: Boolean = true): void {
            if (this.containerSprite) {
                this.removeChild(this.containerSprite);
            }
            if (this.icon) {
                this.removeChild(this.icon);
            }
            if (this.equippedMarker) {
                this.removeChild(this.equippedMarker);
            }
            if (this.text) {
                this.removeChild(this.text);
            }
            if (this.contextMenu) {
                this.removeChild(this.countText);
            }

            this.containerSprite = new Sprite();
            this.containerSprite.graphics.beginFill(0x000000, 1);
            this.containerSprite.graphics.drawRect(this._pos.x, this._pos.y, this._width, this._height);
            this.containerSprite.graphics.endFill();
            this.containerSprite.alpha = 0.1;
            this.addChild(containerSprite);
            this.hitArea = this.containerSprite;
            // this.mouseChildren = false;
            this.mouseEnabled = true;

            // paddings are 10% of height
            this.paddings = this._height * 0.1;

            var elementsHeight: Number = this._height - this.paddings * 2;

            var nextElementX: Number = this._pos.x + this.paddings;

            // left 10px at right side
            var availableWidth: Number = this._width - (this.paddings * 2) - 10;

            // render icon if given
            if (icon) {
                this.icon.height = elementsHeight;
                // square icon, so set width to height
                this.icon.width = elementsHeight;
                this.icon.x = nextElementX;
                this.icon.y = this._pos.y + this.paddings;
                this.icon.mouseEnabled = false;
                this.addChild(this.icon);

                nextElementX += this.icon.width + 10;
                availableWidth -= (this.icon.width + 10);
            }
            // render equipped marker
            if (this.item.equipped) {
                this.equippedMarker = new Shape();
                this.equippedMarker.graphics.beginFill(0xffffff, 0.5);
                this.equippedMarker.graphics.moveTo(nextElementX - 5, this._pos.y + elementsHeight / 2 - 5);
                this.equippedMarker.graphics.lineTo(nextElementX, this._pos.y + elementsHeight / 2 + 5);
                this.equippedMarker.graphics.lineTo(nextElementX + 5, this._pos.y + elementsHeight / 2 - 5);
                this.equippedMarker.graphics.lineTo(nextElementX, this._pos.y + elementsHeight);
                this.equippedMarker.graphics.lineTo(nextElementX - 5, this._pos.y + elementsHeight / 2 - 5);

                this.addChild(this.equippedMarker);

                nextElementX += 10;
                availableWidth -= 10;
            }
            // render text
            this.text = new TextField();
            this.text.defaultTextFormat = new TextFormat("$MAIN_Font", 14);
            // this.text.embedFonts = true;
            // this.text.autoSize = TextFieldAutoSize.LEFT;
            this.text.text = this.item.name;
            this.text.textColor = 0xffffff;
            this.text.x = nextElementX;
            this.text.y = _pos.y + this.paddings;
            this.text.height = elementsHeight;
            this.text.width = availableWidth - 30;
            this.text.mouseEnabled = false;
            this.alignVertical(this.text);
            this.addChild(this.text);
            nextElementX += (this.text.width + 10);
            availableWidth -= (this.text.width + 10);


            // render count
            this.countText = new TextField();
            this.countText.defaultTextFormat = new TextFormat("$MAIN_Font");
            // this.text.embedFonts = true;
            // this.countText.autoSize = TextFieldAutoSize.RIGHT;
            this.countText.text = String(this.item.count);
            this.countText.textColor = 0xffffff;
            this.countText.x = nextElementX;
            this.countText.y = _pos.y + this.paddings;
            this.countText.height = elementsHeight;
            this.countText.width = 30;
            this.alignVertical(this.countText);
            this.addChild(this.countText);

            this.useHandCursor = true;
            this.countText.mouseEnabled = false;

            if (this.item.equipped) {
                this.highlighted = true;
            }
        }

        public function get highlighted(): Boolean {
            return this._highlighted;
        }

        public function set highlighted(v: Boolean): void {
            if (v) {
                this.containerSprite.alpha = 0.5;
                this._highlighted = true;
            } else if (!this._item.equipped) {
                this.containerSprite.alpha = 0.1;
                this._highlighted = false;
            }
        }

        public function get item(): Item {
            return this._item;
        }

        private function alignVertical(tf: TextField): void {
            tf.y += Math.round((tf.height - tf.textHeight) / 2);
        }

        private function onClick(e: MouseEvent): void {
            var ev: CustomEvent = new CustomEvent(ListItem.MOUSE_CLICK, { item: this.item });
            this.dispatchEvent(ev);
        }

        private function onMouseEnter(e: MouseEvent): void {
            this.highlighted = true;
        }

        private function onMouseLeave(e: MouseEvent): void {
            this.highlighted = false;
        }

        private function onEquippedChanged(): void {
            this.drawContent(false);
        }
    }
}