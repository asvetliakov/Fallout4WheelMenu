package {

    import flash.display.Sprite;
    import flash.display.MovieClip;

    public class MenuItem extends Sprite {
        private var lineObj: Sprite;
        private var icon: MovieClip;
        private var _active: Boolean;
        private var centerX: Number;
        private var centerY: Number;

        public var type: String;

        public var itemName: String;

        public function MenuItem(name: String, type: String, innerRadius: Number, outerRadius: Number, startDeg: Number, endDeg: Number, angle: Number, icon: MovieClip, active: Boolean = false) {
            this.itemName = name;
            this.type = type;
            this.lineObj = new Sprite();
            this.lineObj.graphics.clear();
            this.lineObj.graphics.lineStyle(3, 0xffffff, 1, true);

            var innerLeftX: Number = innerRadius * Math.cos(startDeg * Math.PI / 180);
            var innerLeftY: Number = innerRadius * Math.sin(startDeg * Math.PI / 180);
            var innerRightX: Number = innerRadius * Math.cos(endDeg * Math.PI / 180);
            var innerRightY: Number = innerRadius * Math.sin(endDeg * Math.PI / 180);

            var outerLeftX: Number = outerRadius * Math.cos(startDeg * Math.PI / 180);
            var outerLeftY: Number = outerRadius * Math.sin(startDeg * Math.PI / 180);
            var outerRightX: Number = outerRadius * Math.cos(endDeg * Math.PI / 180);
            var outerRightY: Number = outerRadius * Math.sin(endDeg * Math.PI / 180);

            // var centerDeg: Number = startDeg +  (angle / 2);
            var centerDeg: Number = type === "left" ? startDeg - (angle / 2) : startDeg + (angle / 2);
            if (centerDeg > 360) {
                centerDeg = centerDeg - 360;
            }
            centerX = (innerRadius + ((outerRadius - innerRadius) / 2)) * Math.cos(centerDeg * Math.PI / 180);
            centerY = (innerRadius + ((outerRadius - innerRadius) / 2)) * Math.sin(centerDeg * Math.PI / 180);

            this.lineObj.graphics.moveTo(innerLeftX, innerLeftY);
            this.lineObj.graphics.lineTo(outerLeftX, outerLeftY);
            this.lineObj.graphics.moveTo(innerRightX, innerRightY);
            this.lineObj.graphics.lineTo(outerRightX, outerRightY);
            this.addChild(lineObj);

            this.lineObj.alpha = 0.1;
            if (icon) {
                this.icon = icon;
                this.icon.scaleX = 0.5;
                this.icon.scaleY = 0.5;
                this.icon.alpha = 0.7;
                this.updateIconPos();
                this.addChild(icon);
            }

            this.active = active;
        }

        public function get active(): Boolean {
            return this._active;
        }

        public function set active(v: Boolean): void {
            this._active = active;
            if (v) {
                if (this.icon) {
                    this.icon.alpha = 1;
                    this.icon.scaleX = 0.85;
                    this.icon.scaleY = 0.85;
                    this.updateIconPos();
                }
                this.lineObj.alpha = 0.7;
            } else {
                if (this.icon) {
                    this.icon.alpha = 0.7;
                    this.icon.scaleX = 0.5;
                    this.icon.scaleY = 0.5;
                    this.updateIconPos();
                }
                this.lineObj.alpha = 0.1;
            }
        }

        private function updateIconPos(): void {
            if (this.icon) {
                this.icon.x = centerX - this.icon.width / 2;
                this.icon.y = centerY - this.icon.height / 2;
            }
        }
    }
}