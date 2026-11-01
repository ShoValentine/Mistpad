"""Exercise action selection and menu wiring; secure game execution needs Retail QA."""
from pathlib import Path
import runpy

state = runpy.run_path(str(Path(__file__).with_name('test_inventory.py')))
lua, ROOT = state['lua'], state['ROOT']
lua.execute('''
framesByName = {}; known = {}; profession = nil; secureUses = {}; casts = {}
UISpecialFrames = {}; StaticPopupDialogs = {}; CANCEL = 'Cancel'
ITEM_MILLABLE = 'Millable'; ITEM_PROSPECTABLE = 'Prospectable'
ITEM_DISENCHANT_NOT_DISENCHANTABLE = 'Cannot be disenchanted'
Enum = {TradeskillRecipeType = {Salvage = 2}}
local create = CreateFrame
function CreateFrame(kind, name, parent, template)
    local f = create(kind, name, parent)
    if name then framesByName[name] = f end
    f.attributes = {}
    function f:SetAttribute(k, v) self.attributes[k] = v end
    function f:GetAttribute(k) return self.attributes[k] end
    function f:RegisterForClicks() end
    function f:SetFrameStrata() end
    function f:SetEnabled(v) self.enabled = v end
    if template and template:find('SecureActionButtonTemplate', 1, true) then
        f.templatedClick = function(self)
            if self.attributes.type == 'item' then table.insert(secureUses, self.attributes.item)
            elseif self.attributes.type == 'spell' then
                casts[#casts + 1] = {spell = self.attributes.spell, bag = self.attributes['target-bag'], slot = self.attributes['target-slot']}
            end
        end
        f:SetScript('OnClick', f.templatedClick)
    end
    return f
end
function RegisterStateDriver(f, state, expression) f.stateDriver = expression end
function M:Print(text) message = text end
fixtures = {
    [100] = {name = 'Potion', class = 0, subclass = 1, quality = 1, use = true},
    [200] = {name = 'Sword', class = 2, subclass = 7, quality = 3, equip = true},
    [300] = {name = 'Herb', class = 7, subclass = 9, quality = 1, marker = ITEM_MILLABLE},
    [400] = {name = 'Ore', class = 7, subclass = 7, quality = 1, marker = ITEM_PROSPECTABLE},
    [500] = {name = 'Stone', class = 7, subclass = 7, quality = 1},
    [600] = {name = 'Legendary', class = 2, subclass = 7, quality = 5, equip = true},
}
inventory = {}
function put(id, count)
    inventory['0:1'] = {itemID = id, hyperlink = 'item:' .. id, stackCount = count, guid = 'GUID-' .. id}
end
function C_Container.GetContainerItemInfo(bag, slot) return inventory[bag .. ':' .. slot] end
ItemLocation = {CreateFromBagAndSlot = function(_, bag, slot) return {bag = bag, slot = slot} end}
C_Item = {}
function C_Item.GetItemGUID(location)
    local info = inventory[location.bag .. ':' .. location.slot]
    return info and info.guid
end
local function fixture(link) return fixtures[tonumber(tostring(link):match('(%d+)$'))] end
function C_Item.GetItemInfo(link)
    local item = fixture(link)
    return item.name, link, item.quality, 1, 1, '', '', 20, item.equip and 'INVTYPE_WEAPON' or '',
        0, 0, item.class, item.subclass
end
function C_Item.IsEquippableItem(link) return fixture(link).equip or false end
function C_Item.GetItemSpell(link) return fixture(link).use and 'Use Potion' end
function C_Item.IsCosmeticItem() return false end
C_SpellBook = {IsSpellKnown = function(id) return known[id] or false end}
function GetProfessions() return profession and 1 end
function GetProfessionInfo() return 'Profession', nil, nil, nil, nil, nil, profession end
C_TooltipInfo = {GetBagItem = function(bag, slot)
    local info = C_Container.GetContainerItemInfo(bag, slot)
    local data = info and fixtures[info.itemID]
    return {lines = data and data.marker and {{leftText = data.marker}} or {}}
end}
function StaticPopup_Show(name, text, _, data) popup = {name = name, data = data, text = text} end
function DeleteCursorItem() deleted = true; cursorItem = false end
function C_Container.PickupContainerItem(bag, slot) picked = {bag, slot}; cursorItem = true end
function C_Container.SplitContainerItem(bag, slot, amount) split = {bag, slot, amount} end
function GameTooltip:SetBagItem(bag, slot) tooltipItem = {bag, slot} end
function GameTooltip_ShowCompareItem() compared = true end
function DressUpItemLink(link) preview = link end
''')
for name in ['Panels', 'ItemActions', 'ItemContext']:
    lua.execute('assert(load(...))("Mistpad", M)', (ROOT / f'Mistpad/{name}.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
local function actions(id, count)
    put(id, count)
    local result = {}
    for _, a in ipairs(M:GetItemActions(M:SnapshotItem(0, 1))) do result[a.label] = a end
    return result
end
local a = actions(100, 10)
assert(a.Use and a.Split and a.Drop and not a.Equip, 'consumable actions')
a = actions(200, 1)
assert(a.Equip and a.Compare and a.Preview and not a.Disenchant and not a.Split, 'gear actions')
known[13262] = true; a = actions(200, 1)
assert(a.Disenchant and a.Disenchant.kind == 'spell', 'known disenchant')
assert(not actions(600, 1).Disenchant, 'legendary is not offered for disenchanting')
known[51005] = true; known[31252] = true
assert(actions(300, 10).Mill and not actions(300, 10).Prospect, 'herbs mill')
assert(actions(400, 4).Prospect.disabled, 'prospecting needs five')
assert(not actions(500, 10).Prospect, 'stone is not ore')
known[51005] = nil; profession = 773
assert(actions(300, 10).Mill.disabled, 'profession without learned recipe explains missing action')
C_TradeSkillUI = {
    GetAllRecipeIDs = function() return {901} end,
    GetRecipeInfo = function() return {learned = true} end,
    GetRecipeSchematic = function() return {recipeType = 2} end,
    GetSalvagableItemIDs = function() return {300} end,
    CraftSalvage = function(recipe, count, location) salvaged = {recipe, count, location.bag, location.slot} end,
}
assert(actions(300, 10).Mill.kind == 'salvage', 'modern recipe uses exact salvage targets')
profession = nil
put(100, 10)
local snapshot = M:SnapshotItem(0, 1)
inventory['0:1'].guid = 'replacement'
assert(not M:IsCurrentItem(snapshot), 'same item ID with different GUID is rejected')
put(100, 10)
local source = CreateFrame('ItemButton', nil, ContainerFrameCombinedBags)
source:Initialize(0, 1)
ContainerFrameCombinedBags:Show()
local function show(id, count)
    put(id, count); down = false; M:ShowItemContext(source)
    return framesByName.MistpadItemContext
end
local function find(label)
    for _, button in ipairs(frames) do
        if button.parent == framesByName.MistpadItemContext and button.text == label and button.shown then return button end
    end
    error('missing menu button ' .. label)
end
local function click(label)
    local button = find(label)
    assert(button:GetScript('OnClick') == button.templatedClick, 'secure template handler preserved')
    assert(button.width == 148 and button.height == 48, 'touch sized action')
    button.scripts.PreClick(button)
    button.scripts.OnClick(button)
    button.scripts.PostClick(button)
end
local menu = show(100, 10)
assert(menu.stateDriver == '[combat] 1; 0' and menu.parent == UIParent, 'combat driver on independent secure menu')
click('Use'); assert(secureUses[#secureUses] == '0 1', 'use targets specific bag slot')
show(200, 1); click('Equip'); assert(secureUses[#secureUses] == '0 1')
show(200, 1); click('Disenchant')
assert(casts[#casts].spell == 13262 and casts[#casts].bag == 0 and casts[#casts].slot == 1, 'secure spell targets selected item')
show(200, 1); click('Compare'); assert(compared and tooltipItem[2] == 1)
show(200, 1); click('Preview'); assert(preview == 'item:200')
show(100, 10); click('Split')
local splitPanel = framesByName.MistpadSplitStack
assert(splitPanel:IsShown() and splitPanel.slider.minimum == 1 and splitPanel.slider.maximum == 9)
splitPanel.slider:SetValue(3)
for _, button in ipairs(frames) do
    if button.parent == splitPanel and button.text == 'Split' then button.scripts.OnClick() end
end
assert(split[3] == 3, 'split amount selected through touch controls')
show(100, 10); click('Drop')
assert(popup.name == 'MISTPAD_DROP_ITEM' and not deleted, 'drop requires confirmation')
put(200, 1)
StaticPopupDialogs.MISTPAD_DROP_ITEM.OnAccept(nil, popup.data)
assert(not deleted, 'stale drop confirmation cannot delete replacement item')
show(100, 10); click('Drop')
StaticPopupDialogs.MISTPAD_DROP_ITEM.OnAccept(nil, popup.data)
assert(deleted and picked[1] == 0 and picked[2] == 1, 'confirmed drop targets original stack')
show(100, 10); put(200, 1); click('Use')
assert(find('Use'):GetAttribute('type') == nil, 'stale secure action is disarmed')
profession = 773; show(300, 10); click('Mill')
assert(salvaged[1] == 901 and salvaged[4] == 1, 'modern salvage receives exact location')
menu = show(100, 10); down = true; menu.armed = false
local previous = #secureUses
click('Use'); assert(#secureUses == previous and menu:IsShown(), 'hold-release cannot activate action')
down = false; menu.scripts.OnUpdate()
click('Use'); assert(#secureUses == previous + 1, 'next intentional tap rearms secure action')
menu = show(100, 10)
down = true; menu.armed = false
assert(M:IsContextOpeningTouch(source), 'opening touch identified until release')
down = false; source:Hide(); menu.scripts.OnUpdate()
assert(menu:IsShown() and menu.armed, 'menu survives release and source-frame recycling')
local events
for _, f in ipairs(frames) do
    if f.events and f.events.GLOBAL_MOUSE_DOWN and f.events.BAG_UPDATE_DELAYED then events = f end
end
assert(events)
events.scripts.OnEvent(events, 'BAG_UPDATE_COOLDOWN')
menu.scripts.OnUpdate()
assert(menu:IsShown(), 'routine cooldown refresh does not dismiss latched menu')
events.scripts.OnEvent(events, 'PLAYER_MONEY')
menu.scripts.OnUpdate()
assert(menu:IsShown(), 'money refresh does not dismiss latched menu')
menu.mouseOver = true
events.scripts.OnEvent(events, 'GLOBAL_MOUSE_DOWN')
assert(ContainerFrameCombinedBags:IsShown(), 'context menu counts as inside the bag module')
menu.mouseOver = false
local closed = 0
function M:AnimateBagClosing(f)
    assert(f:IsShown() and M.inventoryUsesLayout, 'close visual captured before native cleanup')
    closed = closed + 1
end
events.scripts.OnEvent(events, 'GLOBAL_MOUSE_DOWN')
assert(not ContainerFrameCombinedBags:IsShown() and closed == 1, 'outside touch closes and animates bag')
OpenAllBags(); ContainerFrameCombinedBags:Hide()
assert(closed == 2, 'native direct hides also animate')
''')
print('PASS: dynamic item actions, professions, secure wiring, split, comparison, preview, drop confirmation, stale-item guards')
