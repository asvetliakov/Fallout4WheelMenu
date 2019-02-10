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
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;

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
		private var menuInnerRadius: uint = 60;
		/**
		 * Menu outer radius
		 */
		private var menuOuterRadius: uint = 100;
		/**
		 * Item list width
		 */
		private const listWidth: uint = 300;
		/**
		 * Item list height // 16 items max
		 */
		private const listHeight: uint = 483;
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
		 * Menu items. Need to be array to preserve order
		 */
		private var menuItems: Array = [];
		/**
		 * Collection of items mapped to approtiative category. Key is the menu item name
		 */
		private var inventoryItemsMap: Object = {};
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
		 * Offset position point from the center of the screen
		 */
		private var _offsetPoint: Point;

		private var _equippedItem: int;
		/**
		 * Stage scaling factor
		 */
		private var _scaling: Number = 1;

		public function Main() {
			trace("WheelMenu: Constructor");
			this._offsetPoint = new Point(0, 0);

			// Note: need to set them early
			this.scaleX = this._scaling;
			this.scaleY = this._scaling;
			try {
				Font.registerFont(this.font);
			} catch (e: Error) {
				trace("WheelMenu: Registering font failed, e: " + e.message);
			}
			// this.stage.addChild(this);
			this.inventoryItemsMap = {};
			this.list = null;
			var confLoader: URLLoader = new URLLoader();
			confLoader.addEventListener(Event.COMPLETE, this.onConfLoaded);
			confLoader.load(new URLRequest("./WHEEL_MENU/conf.xml"));
			this.stage.addEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDown);
			this.stage.addEventListener(MouseEvent.MOUSE_WHEEL, this.onWheel);
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
						var item: Item = new Item(
							this.getDataField(data, "id"),
							this.getDataField(data, "Name"),
							this.getDataField(data, "Description"),
							this.getDataField(data, "count"),
							this.getDataField(data, "Category"),
							this.getDataField(data, "Equipped")
						);
						trace("WheelMenu: Item, formId: " + item.id + ", Name: " + item.name + ", Category: " + item.defaultCategory);
						if (item.sortingName) {
							var iconName: String = this.getItemIcon(item.sortingName);
							if (iconName) {
								item.iconName = iconName;
							}
						}
						var inventoryNames: Array = this.getItemInventoryNames(item);
						trace("WheelMenu: Item inventories: " + inventoryNames.join(", "));
						for each (var name: String in inventoryNames) {
							this.inventoryItemsMap[name].push(item);
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

		public function get equippedItemId(): int {
			return 0;
		}

		public function set menuPos(val: Object): void {
			var data: Object = val["__struct__"]["__data__"];
			// Some magic here - it MAY become different casing
			this._offsetPoint = new Point(data["offsetx"] || data["Offsetx"] || data["OffsetX"] || 0, data["offsety"] || data["Offsety"] || data["OffsetY"] || 0);
			this._scaling = data["scaling"] || 1;
			this.scaleX = this._scaling;
			this.scaleY = this._scaling;
			this.drawMenu();
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

		/**
		 * Return center position of the screen including offset
		 */
		private function get centerPos(): Point {
			return new Point(
				(this.stage.stageWidth / this._scaling / 2) + this._offsetPoint.x,
				(this.stage.stageHeight / this._scaling / 2) + this._offsetPoint.y
			);
		}

		private function onConfLoaded(event: Event): void {
			trace("WheelMenu: Configuration loaded");
			this.conf = new XML(event.currentTarget.data);
			if (this.conf.@innerRadius && this.conf.@innerRadius[0] && parseInt(this.conf.@innerRadius[0].toString())) {
				this.menuInnerRadius = parseInt(this.conf.@innerRadius[0].toString(), 10);
			}
			if (this.conf.@outerRadius && this.conf.@outerRadius[0] && parseInt(this.conf.@outerRadius[0].toString())) {
				this.menuOuterRadius = parseInt(this.conf.@outerRadius[0].toString(), 10);
			}
			for each (var menu: XML in this.conf.children()) {
				var menuItem: Object = {
					name: menu.@name[0].toString(),
					type: menu.@type[0].toString(),
					icon: menu.@icon[0].toString(),
					close: menu.@closeOnUse[0] && menu.@closeOnUse[0].toString() === "false" ? false : true,
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
			this.iconManager = new IconManager(event.target.applicationDomain);
			// this.menuContainer = new MenuContainer(
			// 	this.centerPos,
			// 	this.menuInnerRadius,
			// 	this.menuOuterRadius,
			// 	this.iconManager,
			// 	this.menuItems
			// );
			// this.menuContainer.addEventListener(MenuContainer.ITEM_SELECTED, this.onMenuSelected);
			// this.addChild(this.menuContainer);
			// NOTE: DO NOT Set stage scale mode
			// this.stage.scaleMode = StageScaleMode.SHOW_ALL;
			trace("WheelMenu: Menu Loaded");

			try {
				this.f4seCodeObj.SendExternalEvent(Main.INIT_EVENT_NAME);
			} catch (err: Error) {
				trace("WheelMenu: Sending WheelMenuInit failed");
			}
			// testing code
			// this.inventoryItemsMap["Aid"] = [];
			// for (var i: int = 0; i < 40; i++) {
			// 	this.inventoryItemsMap["Aid"].push(new Item(i, "(Aid) test " + i, "", 1, "Aid", false, this.getItemIcon("Aid")));
			// }
			// this.drawMenu();
		}

		private function drawMenu(): void {
			trace("WheelMenu: Drawing menu");
			if (this.menuContainer) {
				this.removeChild(this.menuContainer);
			}
			this.menuContainer = new MenuContainer(
				this.centerPos,
				this.menuInnerRadius,
				this.menuOuterRadius,
				this.iconManager,
				this.menuItems
			)
			this.menuContainer.addEventListener(MenuContainer.ITEM_SELECTED, this.onMenuSelected);
			this.addChild(this.menuContainer);
		}

		private function redrawCurrentList(): void {
			if (this.list) {
				var name: String = this.list._categoryName;
				var type: String = this.list._type;
				this.removeChild(this.list);
				this.list = null;
				this.showList(type, name);
			}
		}

		private function onKeyDown(event: KeyboardEvent): void {
			if (!this.list) {
				return;
			}

			// w - 87
			// s - 83
			// e - 69
			switch (event.keyCode) {
				// case 87: {
				// 	this.list.highlightNextItem(-1);
				// 	break;
				// }
				// case 83: {
				// 	this.list.highlightNextItem(1);
				// 	break;
				// }
				case 69: {
					this.list.selectCurrentItem();
					break;
				}
			}
		}

		private function onWheel(event: MouseEvent): void {
			if (!this.list) {
				return;
			}
            var delta: int = event.delta;
            // delta === 0 -> one item down
            // delta === 1 -> one item up
            // delta < 0 -> delta items down
            // delta > 1 -> delta items up

            // scroll max 1 item
            if (delta <= 0) {
                delta = 1;
            } else if (delta > 0) {
                delta = -1;
            }
			this.list.highlightNextItem(delta);
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
			var menuItem: Object = this.findMenuItemByName(name) || {};
			if (type === "left") {
				var leftListPosX: Number = this.centerPos.x - this.menuOuterRadius - this.listMargin - this.listWidth;
				var leftListPosY: Number = this.centerPos.y - (this.listHeight / 2);
				this.list = new ListContainer(name, "left", new Point(leftListPosX, leftListPosY), this.listWidth, this.listHeight, this.iconManager, items, menuItem["close"]);
				this.list.addEventListener(ListContainer.ITEM_SELECTED, this.onItemSelect);
				this.addChild(this.list);
			} else {
				var rightListPosX: Number = this.centerPos.x + this.menuOuterRadius + this.listMargin;
				var rightListPosY: Number = this.centerPos.y - (this.listHeight / 2);
				this.list = new ListContainer(name, "right", new Point(rightListPosX, rightListPosY), this.listWidth, this.listHeight, this.iconManager, items, menuItem["close"]);
				this.list.addEventListener(ListContainer.ITEM_SELECTED, this.onItemSelect);
				this.addChild(this.list);
			}
		}

		private function onItemSelect(ev: CustomEvent): void {
			var item: Item = ev.customData.item;
			var close: Boolean = ev.customData.close;
			if (item) {
				trace("WheelMenu: Selected item: " + item.id + ", close: " + close);
				if (this.f4seCodeObj) {
					try {
						this.f4seCodeObj.SendExternalEvent(Main.SELECT_EVENT_NAME, item.id, close);
					} catch (error: Error) {
						trace("WheelMenu: Unable to send f4se external event: " + error.message);
					}
				}
				// if not closing need to decrement count of item/remove if last and redrawList
				if (!close) {
					item.count -= 1;
					if (item.count <= 0) {
						this.filterItemFromInventories(item);
					}
					this.redrawCurrentList();
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
							if (item.fullName.match(new RegExp(pattern.value, "i"))) {
								inventoryNames.push(menuItem.name);
							}
							break;
						}
						case "category": {
							if ((item.defaultCategory === pattern.value.toLowerCase()) && (!pattern.noTaggedOnly || (pattern.noTaggedOnly && !item.sortingName))) {
								inventoryNames.push(menuItem.name);
							}
							break;
						}
					}
				}
			}

			return inventoryNames;
		}

		private function filterItemFromInventories(item: Item): void {
			var inventoryNames: Array = this.getItemInventoryNames(item);
			for each (var name: String in inventoryNames) {
				this.inventoryItemsMap[name] = this.inventoryItemsMap[name].filter(function (i: Item, index: int, arr: Array): Boolean {
					return i !== item;
				})
			}
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

		private function findMenuItemByName(name: String): Object {
			for each (var item: Object in this.menuItems) {
				if (item.name === name) {
					return item;
				}
			}
			return null;
		}

		private function updateUIPositions(): void {
			if (this.menuContainer) {
				this.menuContainer.x += this._offsetPoint.x;
				this.menuContainer.y += this._offsetPoint.y;
			}
			if (this.list) {
				this.list.x += this._offsetPoint.x;
				this.list.y	+= this._offsetPoint.y;
			}
		}

		/**
		 * F4SE breaks name casing of object properties sent from papyrus.
		 * Helper will try various name casing combinations to get the prop.
		 */
		private function getDataField(obj: Object, name: String): * {
			if (!obj) {
				return null;
			}
			// try first original name
			if (obj[name] != null) {
				return obj[name];
			}
			// lowercased
			if (obj[name.toLowerCase()] != null) {
				return obj[name.toLowerCase()];
			}
			// lowercased first letter
			if (obj[name.charAt(0).toLowerCase() + name.slice(1)] != null) {
				return obj[name.charAt().toLowerCase() + name.slice(1)];
			}
			// uppercased first letter
			if (obj[name.charAt(0).toUpperCase() + name.slice(1)] != null) {
				return obj[name.charAt().toUpperCase() + name.slice(1)];
			}
			return null;
		}
	}
}