package {
    import flash.events.Event;

    public class CustomEvent extends Event {
        public var customData: Object;

        public function CustomEvent(type: String, data: Object = null) {
            super(type);
            this.customData = data;
        }
    }
}