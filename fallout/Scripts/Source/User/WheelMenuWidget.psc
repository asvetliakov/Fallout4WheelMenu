Scriptname WheelMenuWidget extends Quest

Keyword Property AlcoholKeyword Auto
Keyword Property ChemKeyword Auto
Keyword Property DrinkKeyword Auto
Keyword Property FoodKeyword Auto
Keyword Property GrenadeExplosiveKeyword Auto
Keyword Property GrenadeGrenadeKeyword Auto
Keyword Property GrenadeMineKeyword Auto
Keyword Property GrenadeThrownKeyword Auto
Keyword Property Melee1HKeyword Auto
Keyword Property Melee2HKeyword Auto
Keyword Property NukaKeyword Auto
Spell Property SlowTimeSpell Auto
Spell Property SlowTimeSpellLight Auto
Spell Property SlowTimeSpellMedium Auto
Keyword Property StimpackKeyword Auto
Keyword Property WaterKeyword Auto

int Property SlowTimeMode = 0 Auto
int Property SlowTimeMagnitude = 0 Auto
int Property MenuOffsetX = 0 Auto
int Property MenuOffsetY = 0 Auto
float Property MenuScaling = 1.0 Auto
bool Property GamepadControlEnabled = true Auto

String WheelMenuName = "F4WheelMenu" const

Struct Item
    int Id
    string Name
    string Description
    int Count
    bool Equipped
    string Category
EndStruct

Struct MenuConf
    int offsetX
    int offsetY
    float scaling
EndStruct

Struct ItemFind
    int index
    int usedArray
EndStruct

; Easier and faster to track them separately
; max arr length in papyrus is 128 so use secondary arr in case when has more items
Item[] weaponInventoryItems
Item[] weaponInventoryItems2
Item[] ingestibleInventoryItems
Item[] ingestibleInventoryItems2
InputEnableLayer mLayer

; Return default sorting category for the form
string Function GetItemCategory(Form item)
    if (item is Weapon)
        Weapon itemW = item as Weapon
        If (itemW.HasKeyword(Melee1HKeyword) || itemW.HasKeyword(Melee2HKeyword))
            return MELEE
        ElseIf (itemW.HasKeyword(GrenadeExplosiveKeyword) || itemW.HasKeyword(GrenadeGrenadeKeyword) || itemW.HasKeyword(GrenadeMineKeyword) || itemW.HasKeyword(GrenadeThrownKeyword))
            return EXPLOSIVE
        Else
            return RANGED
        Endif
    Else
        if (item.HasKeyword(ChemKeyword) || item.HasKeyword(StimpackKeyword))
            return CHEMS
        ElseIf ((item.HasKeyword(WaterKeyword) || item.HasKeyword(DrinkKeyword) || item.HasKeyword(NukaKeyword)) && !item.HasKeyword(AlcoholKeyword))
            return DRINK
        ElseIf (item.HasKeyword(AlcoholKeyword))
            return ALCOHOL
        ElseIf (item.HasKeyword(FoodKeyword))
            return FOOD
        Else
            return INGESTIBLE
        EndIf
    Endif
EndFunction

Item[] Function GetAvailableArrayForItem(Form item)
    If (item is Weapon)
        If (weaponInventoryItems.Length < 128)
            return weaponInventoryItems
        Else
            return weaponInventoryItems2
        Endif
    Else
        If (ingestibleInventoryItems.Length < 128)
            return ingestibleInventoryItems
        Else
            return ingestibleInventoryItems2
        EndIf
    Endif
EndFunction

Item[] Function GetArrayForFindItem(ItemFind item, Form formItem)
    if (formItem is Weapon)
        if (item.usedArray == 1)
            return weaponInventoryItems
        else
            return weaponInventoryItems2
        endif
    else
        if (item.usedArray == 1)
            return ingestibleInventoryItems
        else
            return ingestibleInventoryItems2
        endif
    endif
EndFunction

ItemFind Function FindItemInArray(Form item)
    int id = item.GetFormID()
    int usedArray = 0
    If (item is Weapon)
        int itemIndex = weaponInventoryItems.FindStruct("Id", id)
        usedArray = 1
        If (itemIndex < 0)
            itemIndex = weaponInventoryItems2.FindStruct("Id", id)
            usedArray = 2
        Endif
        if (itemIndex >= 0)
            ItemFind found = new ItemFind
            found.index = itemIndex
            found.usedArray = usedArray
            return found
        Endif
    ElseIf (item is Potion)
        int itemIndex = ingestibleInventoryItems.FindStruct("Id", id)
        usedArray = 1
        If (itemIndex < 0)
            itemIndex = ingestibleInventoryItems2.FindStruct("Id", id)
            usedArray = 2
        Endif
        if (itemIndex >= 0)
            ItemFind found = new ItemFind
            found.index = itemIndex
            found.usedArray = usedArray
            return found
        Endif
    Endif
    return None
EndFunction


; Init inventory items. Run on game/quest initialization
Function InitInventoryItems(Actor player)
    Debug.Trace("WheelMenu: Initializing player inventory")
    weaponInventoryItems = new Item[0]
    weaponInventoryItems2 = new Item[0]
    ingestibleInventoryItems = new Item[0]
    ingestibleInventoryItems2 = new Item[0]
    ; Getting inventory items is fast
    ; Iterating through items is fast
    ; Calculating count of items in inventory is SLOW
    ; Checking isEquipped() for each weapon item is SLOW
    Form[] items = player.GetInventoryItems()
    int currentItem = 0
    While (currentItem < items.Length)
        Form item = items[currentItem]
        If ((item is Weapon) || (item is Potion))
            Item invItem = new Item
            invItem.Id = item.GetFormID()
            invItem.Name = item.GetName()
            invItem.Description = ""
            ; Only once on initialization, later we'll track them though onItemAdded/Removed/Equipped
            invItem.Count = player.GetItemCount(item)
            invItem.Equipped = false
            invItem.Category = GetItemCategory(item)

            Item[] arr = GetAvailableArrayForItem(item)
            arr.Add(invItem)
        Endif
        currentItem += 1
    EndWhile
    int totalWeapons = weaponInventoryItems.Length + weaponInventoryItems2.Length
    int totalIngestibles = ingestibleInventoryItems.Length + ingestibleInventoryItems2.Length
    Debug.Trace("WheelMenu: Initial items were initialized, weapon count: " + totalWeapons + ", ingestible count: " + totalIngestibles)

EndFunction

Function RemoveItem(Form item, int count = 1)
    ItemFind foundItem = FindItemInArray(item)
    If (!foundItem)
        Return
    Endif
    Item[] arr = GetArrayForFindItem(foundItem, item)
    Item invItem = arr[foundItem.index]
    If (!invItem)
        return
    Endif
    invItem.Count -= count;
    ; last consumed/removed , remove
    If (invItem.Count <= 0)
        arr.Remove(foundItem.index)
    Endif
EndFunction

Function AddItem(Form item, int count = 1)
    ItemFind foundItem = FindItemInArray(item)
    If (foundItem)
        Item[] arr = GetArrayForFindItem(foundItem, item)
        Item invItem = arr[foundItem.index]
        invItem.Count += count
    Else
        ; new item added
        Item[] arr = GetAvailableArrayForItem(item)
        int id = item.GetFormID()
        Item invItem = new Item
        invItem.Id = id
        invItem.Name = item.GetName()
        invItem.Description = ""
        invItem.Equipped = false
        invItem.Count = count
        invItem.Category = GetItemCategory(item)
        arr.Add(invItem)
    Endif
EndFunction

Function ApplySlowTimeMode(int magn, Actor player)
    If (magn == 0)
        player.DoCombatSpellApply(SlowTimeSpell, player)
    Elseif (magn == 1)
        player.DoCombatSpellApply(SlowTimeSpellMedium, player)
    Elseif (magn == 2)
        player.DoCombatSpellApply(SlowTimeSpellLight, player)
    Endif
EndFunction

Function DispellSlowTime(Actor player)
    player.DispelSpell(SlowTimeSpell)
    player.DispelSpell(SlowTimeSpellMedium)
    player.DispelSpell(SlowTimeSpellLight)
EndFunction

Function OpenMenu()
    If (UI.IsMenuOpen(WheelMenuName) || Utility.IsInMenuMode())
    ; If (UI.IsMenuOpen(WheelMenuName))
        Return
    Endif
    Actor player = Game.GetPlayer()
    ; Bail while in dialogue
    Actor dTarget = player.GetDialogueTarget()
    ; Simple GetDialogueTarget() is not enough, since it's not cleaned up
    ; after the dialogue
    ; IsInDialogueWithPlayer checks only for full-featured (with answers) dialogues, skips for simple
    ; conversations
    If (dTarget && dTarget.IsInDialogueWithPlayer())
        Return
    Endif
    ; bail if health is 0 or less
    If (player.GetValue(Game.GetHealthAV()) <= 0)
        Return
    Endif
    Debug.Trace("WheelMenu: SlowTimeMode: " + SlowTimeMode)
    Debug.Trace("WheelMenu: SlowTimeMagnitude: " + SlowTimeMagnitude)
    if (SlowTimeMode == 0 || (SlowTimeMode == 1 && player.IsInCombat()))
        ApplySlowTimeMode(SlowTimeMagnitude, player)
    EndIf
    mLayer.DisablePlayerControls(false, false, true, true, false, true, true, true, true, true, false)
    UI.OpenMenu(WheelMenuName)
EndFunction

Function CloseMenu()
    If (!UI.IsMenuOpen(WheelMenuName))
        Return
    EndIf
    mLayer.EnablePlayerControls(true, true, true, true, true, true, true, true, true, true, true)
    UI.CloseMenu(WheelMenuName)
EndFunction

Function ToggleMenu()
    Actor player = Game.GetPlayer()
    ; try to always dispell slow time mode, regardless of status
    DispellSlowTime(player)
    If (!UI.IsMenuRegistered(WheelMenuName))
        Return
    EndIf
    If (UI.IsMenuOpen(WheelMenuName))
        CloseMenu()
        ; UI.CloseMenu(WheelMenuName)
    Else
        ; int MenuSlowTimeMode = MCM.GetModSettingInt("WheelMenu", "iSlowTimeMode:WheelMenu")
        ; int MenuSlowTimeMagn = MCM.GetModSettingInt("WheelMenu", "iSlowTimeMagnitude:WheelMenu")
        OpenMenu()
        ; Debug.Trace("WheelMenu: SlowTimeMode: " + SlowTimeMode)
        ; Debug.Trace("WheelMenu: SlowTimeMagnitude: " + SlowTimeMagnitude)
        ; if (SlowTimeMode == 0 || (SlowTimeMode == 1 && player.IsInCombat()))
        ;     ApplySlowTimeMode(SlowTimeMagnitude, player)
        ; EndIf
        ; UI.OpenMenu(WheelMenuName)
    EndIf
EndFunction

Function RegisterMenu()
    mLayer = InputEnableLayer.Create()
    If (!UI.IsMenuRegistered(WheelMenuName))
        UI:MenuData data = new UI:MenuData
        ; data.MenuFlags = ShowCursor|EnableMenuControl = 12
        ; data.MenuFlags = ShowCursor|DoNotPreventGameSave|EnableMenuControl = 2060
        data.MenuFlags = 12
        ; data.ExtendedFlags = 0x01
        UI.RegisterCustomMenu(WheelMenuName, "WheelMenu", "root1", data)
    EndIf
EndFunction

Function RegisterForCustomEvents(Actor player)
    ; RegisterForRemoteEvent(player, "onItemEquipped")
    RegisterForRemoteEvent(player, "onItemAdded")
    RegisterForRemoteEvent(player, "onItemRemoved")
    RegisterForRemoteEvent(player, "onDeath")
    ; Todo: investigate possibility of applying only to specific keywords only
    AddInventoryEventFilter(none)
    ; RegisterForKey(71); g
    RegisterForExternalEvent("WheelMenuInit", "onMenuInit")
    RegisterForExternalEvent("WheelMenuSelect", "onMenuSelect")
    RegisterForExternalEvent("WheelMenuClose", "OnMenuClose")
    if (GamepadControlEnabled)
        RegisterForControl("QuickkeyDown")
    Else
        UnregisterForControl("QuickkeyDown")
    EndIf
EndFunction

Event OnQuestInit()
    Actor player = Game.GetPlayer()
    RegisterForRemoteEvent(player, "OnPlayerLoadGame")
    RegisterMenu()
    RegisterForCustomEvents(player)
    InitInventoryItems(player)
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    Actor player = Game.GetPlayer()
    RegisterMenu()
    RegisterForCustomEvents(player)
    InitInventoryItems(player)
EndEvent

Event ObjectReference.OnItemAdded(ObjectReference akSender, Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    If (!(akBaseItem is Weapon) && !(akBaseItem is Potion))
        Return
    EndIf
    AddItem(akBaseItem, aiItemCount)
EndEvent

Event ObjectReference.OnItemRemoved(ObjectReference akSender, Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
    If (!(akBaseItem is Weapon) && !(akBaseItem is Potion))
        Return
    EndIf
    RemoveItem(akBaseItem, aiItemCount)
EndEvent

; Note: doesn't work with alternative death mods
Event Actor.OnDeath(Actor akSender, Actor akKiller)
    OnMenuClose()
EndEvent

; Event OnKeyDown(int aiKeyCode)
;     If (aiKeyCode == 71)
;         ToggleMenu()
;     Endif
; EndEvent

Event OnControlDown(string asControlName)
    If (asControlName == "QuickkeyDown")
        ToggleMenu()
    Endif
EndEvent


;; Wheel menu is ready
Function onMenuInit()
    Debug.Trace("WheelMenu: Menu initialized")
    If (UI.IsMenuOpen(WheelMenuName))
        ; int menuOffsetX = MCM.GetModSettingInt("WheelMenu", "iMenuOffsetX:WheelMenu")
        ; int menuOffsetY = MCM.GetModSettingInt("WheelMenu", "iMenuOffsetY:WheelMenu")
        ; float menuScaling = MCM.GetModSettingFloat("WheelMenu", "fMenuScaling:WheelMenu")
        Debug.Trace("WheelMenu: Offset x: " + MenuOffsetX + ", Offset Y: " + MenuOffsetY + ", Scaling: " + MenuScaling)
        MenuConf conf = new MenuConf
        conf.offsetX = MenuOffsetX
        conf.offsetY = MenuOffsetY
        conf.scaling = MenuScaling
        ; This will display menu
        UI.Set(WheelMenuName, "root1.menuPos", conf)

        UI.Set(WheelMenuName, "root1.inventoryItems", Utility.VarArrayToVar(ingestibleInventoryItems as Var[]))
        UI.Set(WheelMenuName, "root1.inventoryItems", Utility.VarArrayToVar(ingestibleInventoryItems2 as Var[]))
        UI.Set(WheelMenuName, "root1.inventoryItems", Utility.VarArrayToVar(weaponInventoryItems as Var[]))
        UI.Set(WheelMenuName, "root1.inventoryItems", Utility.VarArrayToVar(weaponInventoryItems2 as Var[]))

        ; Set equipped status
        Actor player = Game.GetPlayer()
        ; slot 0 - guns, melee (1h/2h)
        ; slot 2 - grenades/mines
        Weapon equippedWeap = player.GetEquippedWeapon(0)
        Weapon equippedGrenade = player.GetEquippedWeapon(2)

        If (equippedGrenade)
            int id = equippedGrenade.GetFormID()
            Debug.Trace("WheelMenu: Detected equipped grenade/mine id: " + id)
            UI.Set(WheelMenuName, "root1.equippedItemId", id)
        Endif
        If (equippedWeap)
            int id = equippedWeap.GetFormID()
            Debug.Trace("WheelMenu: Detected equipped weapon id: " + id)
            UI.Set(WheelMenuName, "root1.equippedItemId", id)
        Endif
    Endif
EndFunction

;; Selected item
Function onMenuSelect(int id, bool close)
    Debug.Trace("WheelMenu: Selected id: " + id + ", close: " + close)
    Actor player = Game.GetPlayer()
    Form item = Game.GetForm(id)
    ; Need to dispell slow time first otherwise it's not possible to use slow time chems
    ; also always dispell regardless of menu opened/closed already
    If (close)
        DispellSlowTime(player)
    Endif
    If (item)
        Debug.Trace("WheelMenu: Equipping item: " + id)
        player.EquipItem(item, false, true)
    EndIf
    If (Ui.IsMenuOpen(WheelMenuName) && close)
        ; UI.CloseMenu(WheelMenuName)
        CloseMenu();
    Endif
EndFunction

Function OnMenuClose()
    Actor player = Game.GetPlayer()
    DispellSlowTime(player)
    CloseMenu();
EndFunction


Group ItemCategories
    string Property MELEE = "MeleeWeapons" AutoReadOnly
    string Property RANGED = "RangedWeapons" AutoReadOnly
    string Property EXPLOSIVE = "Explosives" AutoReadOnly
    string Property FOOD = "Food" AutoReadOnly
    string Property ALCOHOL = "Alcohol" AutoReadOnly
    string Property DRINK = "Drink" AutoReadOnly
    string Property CHEMS = "Chems" AutoReadOnly
    string Property INGESTIBLE = "Ingestible" AutoReadOnly
EndGroup

Group MenuFlags
    int Property FlagNone = 0x0 AutoReadOnly
    int Property PauseGame = 0x01 AutoReadOnly
    int Property DoNotDeleteOnClose = 0x02 AutoReadOnly
    int Property ShowCursor = 0x04 AutoReadOnly
    int Property EnableMenuControl = 0x08 AutoReadOnly
    int Property ShaderdWorld = 0x20 AutoReadOnly
    int Property Open = 0x40 AutoReadOnly
	int Property DoNotPreventGameSave = 0x800 AutoReadOnly
	int Property ApplyDropDownFilter = 0x8000 AutoReadOnly
	int Property BlurBackground = 0x400000 AutoReadOnly
EndGroup