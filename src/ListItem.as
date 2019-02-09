package {
    import flash.display.Sprite;
    import flash.geom.Point;
    import flash.display.MovieClip;
    import flash.text.TextField;
    import flash.display.Shape;
    import flash.text.TextFieldAutoSize;
    import flash.events.MouseEvent;
    import flash.text.TextFormat;
    import flash.geom.ColorTransform;
    import flash.display.BlendMode;
    import flash.text.AntiAliasType;

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

        private var containerHitArea: Sprite;

        private var _highlightedBox: Sprite;

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
            this.x = pos.x;
            this.y = pos.y;
            // render separator line
            this.graphics.lineStyle(1, 0xffffff, 0.4, true);
            this.graphics.moveTo(0, 0 + this._height);
            this.graphics.lineTo(0 + this._width, 0 + this._height);

            this.drawContent();
            this.addEventListener(MouseEvent.MOUSE_OVER, this.onMouseEnter);
            this.addEventListener(MouseEvent.MOUSE_OUT, this.onMouseLeave);
            this.addEventListener(MouseEvent.CLICK, this.onClick);
        }

        private function drawContent(initial: Boolean = true): void {
            if (this.containerHitArea) {
                this.removeChild(this.containerHitArea);
            }
            if (this.icon && !initial) {
                this.removeChild(this.icon);
            }
            if (this.equippedMarker) {
                this.removeChild(this.equippedMarker);
            }
            if (this.text) {
                this.removeChild(this.text);
            }
            if (this.countText) {
                this.removeChild(this.countText);
            }

            if (this._highlightedBox) {
                this.removeChild(this._highlightedBox);
            }

            this.containerHitArea = new Sprite();
            this.containerHitArea.graphics.beginFill(0x000000, 0);
            this.containerHitArea.graphics.drawRect(0, 0, this._width, this._height);
            this.containerHitArea.graphics.endFill();
            this._highlightedBox = new Sprite();
            this._highlightedBox.graphics.beginFill(0xffffff, 1);
            this._highlightedBox.graphics.drawRect(0, 0, this._width, this._height);
            this._highlightedBox.graphics.endFill();
            this._highlightedBox.alpha = 0;

            this.addChild(this.containerHitArea);
            this.addChild(this._highlightedBox);
            this.hitArea = this.containerHitArea;
            // this.mouseChildren = false;
            this.mouseEnabled = true;

            // paddings are 10% of height
            this.paddings = this._height * 0.1;

            var elementsHeight: Number = this._height - this.paddings * 2;

            var nextElementX: Number = 0 + this.paddings;

            // left 10px at right side
            var availableWidth: Number = this._width - (this.paddings * 2) - 10;

            // render icon if given
            if (icon) {
                this.icon.height = elementsHeight;
                // square icon, so set width to height
                this.icon.width = elementsHeight;
                this.icon.x = nextElementX;
                this.icon.y = 0 + this.paddings;
                this.icon.mouseEnabled = false;
                this.icon.blendMode = BlendMode.NORMAL;
                this.addChild(this.icon);

                nextElementX += this.icon.width + 10;
                availableWidth -= (this.icon.width + 10);
            } else {
                // increase left padding in case if icon is not available
                nextElementX += 8;
                availableWidth -= 8;
            }
            // render equipped marker
            if (this._item.equipped) {
                this.equippedMarker = new Shape();
                this.equippedMarker.graphics.beginFill(0xffffff, 0.7);
                this.equippedMarker.graphics.moveTo(nextElementX - 5, 0 + elementsHeight / 2 - 5);
                this.equippedMarker.graphics.lineTo(nextElementX, 0 + elementsHeight / 2 + 5);
                this.equippedMarker.graphics.lineTo(nextElementX + 5, 0 + elementsHeight / 2 - 5);
                this.equippedMarker.graphics.lineTo(nextElementX, 0 + elementsHeight);
                this.equippedMarker.graphics.lineTo(nextElementX - 5, 0 + elementsHeight / 2 - 5);

                this.addChild(this.equippedMarker);

                nextElementX += 10;
                availableWidth -= 10;
            }
            // render text
            this.text = new TextField();
            this.text.defaultTextFormat = new TextFormat("$MAIN_Font", 14, null);
            this.text.antiAliasType = AntiAliasType.ADVANCED;
            // this.text.embedFonts = true;
            // this.text.autoSize = TextFieldAutoSize.LEFT;
            this.text.text = this._item.name;
            this.text.textColor = 0xffffff;
            this.text.x = nextElementX;
            this.text.y = 0 + this.paddings;
            this.text.height = elementsHeight;
            this.text.width = availableWidth - 30;
            this.text.mouseEnabled = false;
            this.alignVertical(this.text);
            this.addChild(this.text);
            nextElementX += (this.text.width + 10);
            availableWidth -= (this.text.width + 10);


            // render count
            this.countText = new TextField();
            this.countText.defaultTextFormat = new TextFormat("$MAIN_Font", 14, null);
            this.countText.antiAliasType = AntiAliasType.ADVANCED;
            // this.text.embedFonts = true;
            // this.countText.autoSize = TextFieldAutoSize.RIGHT;
            this.countText.text = String(this._item.count);
            this.countText.textColor = 0xffffff;
            this.countText.x = nextElementX;
            this.countText.y = 0 + this.paddings;
            this.countText.height = elementsHeight;
            this.countText.width = 30;
            this.alignVertical(this.countText);
            this.addChild(this.countText);

            this.useHandCursor = true;
            this.countText.mouseEnabled = false;

            if (this._item.equipped) {
                this.highlighted = true;
            }
        }

        public function get highlighted(): Boolean {
            return this._highlighted;
        }

        public function set highlighted(v: Boolean): void {
            if (v) {
                // this.transform.colorTransform = new ColorTransform(1, 1, 1, 1);
                this._highlightedBox.alpha = 1;
                this.text.textColor = 0x000000;
                this.countText.textColor = 0x000000;
                this._highlighted = true;
                if (this.icon) {
                    this.icon.transform.colorTransform = new ColorTransform(0, 0, 0, 1);
                }
                if (this.equippedMarker) {
                    this.equippedMarker.transform.colorTransform = new ColorTransform(0, 0, 0, 1);
                }
            } else if (!this._item.equipped) {
                this._highlightedBox.alpha = 0;
                this.text.textColor = 0xffffff;
                this.countText.textColor = 0xffffff;
                this._highlighted = false;
                if (this.icon) {
                    this.icon.transform.colorTransform = new ColorTransform();
                    // this.icon.transform.colorTransform = null;
                }
                if (this.equippedMarker) {
                    // this.equippedMarker.transform.colorTransform = null;
                    this.equippedMarker.transform.colorTransform = new ColorTransform();
                }
            }
        }

        public function get item(): Item {
            return this._item;
        }

        private function alignVertical(tf: TextField): void {
            tf.y += Math.round((tf.height - tf.textHeight) / 2);
        }

        private function onClick(e: MouseEvent): void {
            var ev: CustomEvent = new CustomEvent(ListItem.MOUSE_CLICK, { item: this.item, listItem: this });
            this.dispatchEvent(ev);
        }

        private function onMouseEnter(e: MouseEvent): void {
            // this.highlighted = true;
            var ev: CustomEvent = new CustomEvent(ListItem.MOUSE_ENTER, { item: this.item, listItem: this });
            this.dispatchEvent(ev);
        }

        private function onMouseLeave(e: MouseEvent): void {
            // this.highlighted = false;
            var ev: CustomEvent = new CustomEvent(ListItem.MOUSE_LEAVE, { item: this.item, listItem: this });
            this.dispatchEvent(ev);
        }

        private function onEquippedChanged(): void {
            this.drawContent(false);
        }
    }
}