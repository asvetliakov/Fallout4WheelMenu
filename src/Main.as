package {

	import flash.text.TextField;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.geom.Point;
	import flash.ui.Mouse;
	import flash.display.Sprite;
	import Shared.F4SE.ICodeObject;
	import flash.net.URLLoader;
	import flash.display.StageScaleMode;
	import flash.text.Font;

    [SWF(width="1920", height="1080", backgroundColor="#393939", frameRate="24")]
	public class Main extends MovieClip implements ICodeObject {
		public static const SELECT_EVENT_NAME: String = "WheelMenuSelect";
		public static const INIT_EVENT_NAME: String = "WheelMenuInit";
		public static const MAX_ITEMS: uint = 16;

		[Embed(source="./fonts_en.swf", symbol="$MAIN_Font")]
		public var font: Class;

		/**
		 * Menu inner radius
		 */
		private const menuInnerRadius: uint = 60;
		/**
		 * Menu outer radius
		 */
		private const menuOuterRadius: uint = 100;
		/**
		 * Item list width
		 */
		private const listWidth: uint = 300;
		/**
		 * Item list height // 16 items max
		 */
		private const listHeight: uint = 500;
		/**
		 * Item list margin from the radial menu
		 */
		private const listMargin: uint = 50;
		/**
		 * Icon manager
		 */
		private var iconManager: IconManager;
		/**
		 * Menu container
		 */
		private var menuContainer: MenuContainer;
		/**
		 * Menu items
		 */
		private var menuItems: Array = [];
		/**
		 * Collection of items mapped to approtiative category. Key is the menu item name
		 */
		private var inventoryItemsMap: Object;
		/**
		 * Current list handle. Null if not selected
		 */
		private var list: ListContainer;
		/**
		 * F4SE handle
		 */
		private var f4seCodeObj: *;
		/**
		 * XML Configuration
		 */
		private var conf: XML;
		/**
		 * DEF_INV_TAGS.xml
		 */
		private var defUIConf: XML;
		/**
		 * Center position of the stage
		 */
		private var centerPos: Point;
		/**
		 * X offset from the center
		 */
		private var _offsetX: int;
		/**
		 * Y offset from the center
		 */
		private var _offsetY: int;

		private var _equippedItem: int;

		public function Main() {
			trace("WheelMenu: Constructor");
			try {
				Font.registerFont(this.font);
			} catch (e: Error) {
				trace("WheelMenu: Registering font failed, e: " + e.message);
			}
			// note: stage.scaleMode doesn't do anything
			this.stage.addChild(this);
			// stage.scaleMode = StageScaleMode.SHOW_ALL;
			this.inventoryItemsMap = {};
			this.list = null;
			var confLoader: URLLoader = new URLLoader();
			confLoader.addEventListener(Event.COMPLETE, this.onConfLoaded);
			confLoader.load(new URLRequest("./WHEEL_MENU/conf.xml"));
		}

		public function get inventoryItems(): Array {
			return [];
		}

		/**
		 * Set from papyrus struct, array of inventory items
		 */
		public function set inventoryItems(items: Array): void {
			// Note: if passed only single structure data will be in var["__struct__"]["__data__"]
			// If passed array converted by VarArrayToVar the data will be in var["__var__"]["__struct__"]["__data__"]
			trace("WheelMenu: Settings inventory items, length: " + items.length);
			try {
				for (var i: uint = 0; i < items.length; i++) {
					var invItem: Object = items[i];
					try {
						var data: Object = invItem["__var__"]["__struct__"]["__data__"];
						// for some reason int fields are lowercased
						var item: Item = new Item(data["id"], data["Name"], data["Description"], data["count"], data["Category"], data["Equipped"]);
						trace("WheelMenu: Item, formId: " + item.id + ", Name: " + item.name);
						if (item.sortingName) {
							var iconName: String = this.getItemIcon(item.sortingName);
							if (iconName) {
								item.iconName = iconName;
							}
						}
						var inventoryNames: Array = this.getItemInventoryNames(item);
						trace("WheelMenu: Item inventories: " + inventoryNames.join(", "));
						for each (var name: String in inventoryNames) {
							if (this.inventoryItemsMap[name].length < Main.MAX_ITEMS) {
								this.inventoryItemsMap[name].push(item);
							}
						}
					} catch (err: Error) {
						trace("WheelMenu: Error when procesing item, e: " + err.message);
					}
				}
			} catch (e: Error) {
				trace("WheelMenu: Error when setting inventory items, e: " + e.message);
			}
			this.redrawCurrentList();
		}

		public function get offsetX(): int {
			return this._offsetX;
		}

		public function get offsetY(): int {
			return this._offsetY;
		}

		/**
		 * Called from papyrus
		 */
		public function set offsetX(v: int): void {
			this.offsetX = v;
			this.centerPos.x += v;
			this.redrawMenu();
			this.redrawCurrentList();
		}

		/**
		 * Called from papyrus
		 */
		public function set offsetY(v: int): void {
			this.offsetY = v;
			this.centerPos.y += v;
			this.redrawMenu();
			this.redrawCurrentList();
		}

		public function get equippedItemId(): int {
			return 0;
		}

		public function set equippedItemId(id: int): void {
			var item: Item = this.findItemById(id);
			if (item) {
				item.equipped = true;
			}
		}

		public function onF4SEObjCreated(codeObject:*): void {
			trace("WheelMenu: F4SE handler called");
			try {
				// this will block keyboard until UI open
				// Note: Won't unblock on menu close, so leave commented for now
				// codeObject.AllowTextInput(true);
				this.f4seCodeObj = codeObject;
			} catch (error: Error) {
				trace("WheelMenu: AllowTextInput call failed, e: " + error.message);
			}
		}

		private function onConfLoaded(event: Event): void {
			trace("WheelMenu: Configuration loaded");
			this.conf = new XML(event.currentTarget.data);
			for each (var menu: XML in this.conf.children()) {
				var menuItem: Object = {
					name: menu.@name[0].toString(),
					type: menu.@type[0].toString(),
					icon: menu.@icon[0].toString(),
					patterns: []
				};
				for each (var pattern: XML in menu.children()) {
					menuItem.patterns.push({
						kind: pattern.@kind[0].toString(),
						value: pattern.@value[0].toString(),
						noTaggedOnly: pattern.@noTaggedOnly[0] && pattern.@noTaggedOnly[0].toString() === "true" ? true : false
					})
				}
				this.menuItems.push(menuItem);
				this.inventoryItemsMap[menuItem.name] = [];
			}

			var defUiConfLoader: URLLoader = new URLLoader();
			defUiConfLoader.addEventListener(Event.COMPLETE, this.onDefUIConfLoaded);
			defUiConfLoader.load(new URLRequest("./DEF_CONF/DEF_INV_TAGS.xml"));
		}

		private function onDefUIConfLoaded(event: Event): void {
			trace("WheelMenu: DEF UI configuration loaded");
			this.defUIConf = new XML(event.currentTarget.data);
			var iconLoader: Loader = new Loader();
			iconLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.onIconsLoaded);
			iconLoader.load(new URLRequest("iconlibs2.swf"));
		}

		/**
		 * Initialize menu with items, doesn't display it now
		 */
		private function onIconsLoaded(event: Event): void {
			trace("WheelMenu: DEF UI Icons loaded");
			this.centerPos = new Point(stage.stageWidth / 2, stage.stageHeight / 2)
			// this.stage.scaleMode = StageScaleMode.SHOW_ALL;
			this.iconManager = new IconManager(event.target.applicationDomain);
			this.menuContainer = new MenuContainer(
				this.centerPos,
				this.menuInnerRadius,
				this.menuOuterRadius,
				this.iconManager,
				this.menuItems
			);
			this.menuContainer.addEventListener(MenuContainer.ITEM_SELECTED, this.onMenuSelected);
			this.addChild(this.menuContainer);
			trace("WheelMenu: Menu constructed");

			try {
				this.f4seCodeObj.SendExternalEvent(Main.INIT_EVENT_NAME);
			} catch (err: Error) {
				trace("WheelMenu: Sending WheelMenuInit failed");
			}
		}

		private function redrawMenu(): void {
			if (this.menuContainer) {
				this.removeChild(this.menuContainer);
				this.menuContainer = new MenuContainer(
					this.centerPos,
					this.menuInnerRadius,
					this.menuOuterRadius,
					this.iconManager,
					this.menuItems
				)
				this.addChild(this.menuContainer);
			}
		}

		private function redrawCurrentList(): void {
			if (this.list) {
				var name: String = this.list.categoryName;
				var type: String = this.list.type;
				this.removeChild(this.list);
				this.list = null;
				this.showList(type, name);
			}
		}

		private function onMenuSelected(event: CustomEvent): void {
			var name: String = event.customData.name;
			var type: String = event.customData.type;
			trace("WheelMenu: Selected menu: " + name + ", type: " + type);
			// remove previous list
			if (this.list) {
				this.removeChild(this.list);
				this.list = null;
			}
			if (name) {
				this.showList(type, name);
			}
		}

		private function showList(type: String, name: String): void {
			var items: Array = this.inventoryItemsMap[name] || [];
			if (type === "left") {
				var leftListPosX: Number = this.centerPos.x - this.menuOuterRadius - this.listMargin - this.listWidth;
				var leftListPosY: Number = this.centerPos.y - (this.listHeight / 2);
				this.list = new ListContainer(name, "left", new Point(leftListPosX, leftListPosY), this.listWidth, this.listHeight, this.iconManager, items);
				this.list.addEventListener(ListContainer.ITEM_SELECTED, this.onItemSelect);
				this.addChild(this.list);
			} else {
				var rightListPosX: Number = this.centerPos.x + this.menuOuterRadius + this.listMargin;
				var rightListPosY: Number = this.centerPos.y - (this.listHeight / 2);
				this.list = new ListContainer(name, "right", new Point(rightListPosX, rightListPosY), this.listWidth, this.listHeight, this.iconManager, items);
				this.list.addEventListener(ListContainer.ITEM_SELECTED, this.onItemSelect);
				this.addChild(this.list);
			}
		}

		private function onItemSelect(ev: CustomEvent): void {
			var item: Item = ev.customData.item;
			if (item) {
				trace("WheelMenu: Selected item: " + item.id);
				if (this.f4seCodeObj) {
					try {
						this.f4seCodeObj.SendExternalEvent(Main.SELECT_EVENT_NAME, item.id);
					} catch (error: Error) {
						trace("WheelMenu: Unable to send f4se external event: " + error.message);
					}
				}
			}
		}

		private function getItemIcon(name: String): String {
			if (!this.defUIConf || !name) {
				return null;
			}
			// without reassigning to local variable it seems unable to find. WTF??
			var findAttr: String = name;
			var tags: XMLList = this.defUIConf.tag.(@keyword == findAttr);
			if (!tags || tags.length() < 1) {
				return null;
			}
			return tags[0].@icon[0].toString();
		}

		private function getItemInventoryNames(item: Item): Array {
			var inventoryNames: Array = [];
			for each (var menuItem: Object in this.menuItems) {
				for each (var pattern: Object in menuItem.patterns) {
					switch (pattern.kind) {
						case "tag": {
							if (item.sortingName && item.sortingName === pattern.value) {
								inventoryNames.push(menuItem.name);
							}
							break;
						}
						case "regex": {
							if (item.fullName.match(new RegExp(pattern.value))) {
								inventoryNames.push(menuItem.name);
							}
							break;
						}
						case "category": {
							if ((item.defaultCategory === pattern.value) && (!pattern.noTaggedOnly || (pattern.noTaggedOnly && !item.sortingName))) {
								inventoryNames.push(menuItem.name);
							}
							break;
						}
					}
				}
			}

			return inventoryNames;
		}

		private function findItemById(id: int): Item {
			var item: Item;
			for each (var inventoryItems: Array in this.inventoryItemsMap) {
				for each (var invItem: Item in inventoryItems) {
					if (invItem.id === id) {
						item = invItem;
						break;
					}
				}
				// abort if found
				if (item) {
					break;
				}
			}
			return item;
		}
	}
}