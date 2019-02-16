package {
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    public class Scrollbar extends Sprite {
        private static const MIN_THUMB_SIZE: Number = 50;

        public var _thumbSize: Number = Scrollbar.MIN_THUMB_SIZE;

        private var _thumb: Sprite;

        private var _areaHeight: Number;

        public function Scrollbar(
            areaHeight: Number,
            scrollHeight: Number
        ) {
            this._areaHeight = areaHeight;
            // calculate thumb size
            if (scrollHeight > areaHeight) {
                this._thumbSize = areaHeight - (scrollHeight - areaHeight)
                if (this._thumbSize < Scrollbar.MIN_THUMB_SIZE) {
                    this._thumbSize = Scrollbar.MIN_THUMB_SIZE;
                }
            } else {
                this.visible = false;
            }

            this._thumb = new Sprite();
            this._thumb.graphics.moveTo(0, 0);
            this._thumb.graphics.lineStyle(1, 0xffffff, 0.5, true);
            this._thumb.graphics.beginFill(0x202020, 0.7);
            this._thumb.graphics.drawRect(0, 0, 10, this._thumbSize);
            this._thumb.graphics.endFill();
            this.addChild(this._thumb);
        }

        public function setScrollPercents(percents: Number): void {
            var trackAvailableHeight: Number = this._areaHeight - this._thumbSize;
            this._thumb.y = trackAvailableHeight / 100 * percents;
        }
    }

}