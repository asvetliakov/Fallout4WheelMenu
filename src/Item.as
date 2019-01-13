package {
    import flash.events.EventDispatcher;
    import flash.events.Event;

    public class Item extends EventDispatcher {
        public static const EQUIPPED_CHANGED: String = "Item::EquippedChanged";
        private static const SORT_REGEXP: RegExp = /^\s*[|{\[\(](.+?)[|}\]\)]\s*/
        /**
         * Item form id
         */
        public var id: uint;
        /**
         * Item name
         */
        public var name: String;
        /**
         * Item full name (including non removed sorting name)
         */
        public var fullName: String;
        /**
         * Item description
         */
        public var description: String;
        /**
         * Item count
         */
        public var count: uint;
        /**
         * Sorting name if exists
         */
        public var sortingName: String;
        /**
         * Item icon name if exist and resolved correctly
         */
        public var iconName: String;
        /**
         * Default category for item
         */
        public var defaultCategory: String;
        /**
         * True if item is equipped
         */
        private var _equipped: Boolean;


        public function Item(id: uint, name: String, description: String, count: uint, defaultCategory: String, equipped: Boolean = false, iconName: String = null) {
            super();
            this.id = id;
            this.name = name;
            this.fullName = name;
            this.description = description;
            this.count = count;
            this._equipped = equipped;
            this.iconName = iconName;
            this.defaultCategory = defaultCategory.toLowerCase();
            this.sortingName = null;

            var regexpRes: * = Item.SORT_REGEXP.exec(name);
            if (regexpRes) {
                this.sortingName = regexpRes[1] as String;
                this.name = this.name.replace(Item.SORT_REGEXP, "");
            }
        }

        public function get equipped(): Boolean {
            return this._equipped;
        }

        public function set equipped(v: Boolean): void {
            this._equipped = v;
            this.dispatchEvent(new Event(Item.EQUIPPED_CHANGED));
        }
    }
}