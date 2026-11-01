"""Run the actual grid and touch code with simulated native frames (requires lupa)."""
from pathlib import Path
import sys
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.devtools'))
from lupa import LuaRuntime
lua = LuaRuntime()
lua.execute('''
unpack = table.unpack
frames = {}; combat = false; x = 0; y = 0; now = 0; down = false; cursorItem = false
function InCombatLockdown() return combat end
function GetCursorPosition() return x, y end
function GetTime() return now end
function IsMouseButtonDown() return down end
function CursorHasItem() return cursorItem end
function IsModifiedClick() return false end
GameTooltip = {Hide = function() end, SetOwner = function() end, SetText = function() end, Show = function() end}
local function frame(kind, parent)
    local f = {kind = kind, parent = parent, scripts = {}, shown = true, scale = 1, alpha = 1,
        width = 37, height = 37, points = {}, scroll = 0, level = 10}
    function f:GetParent() return self.parent end
    function f:SetParent(p) self.parent = p end
    function f:GetScale() return self.scale end
    function f:SetScale(s) self.scale = s end
    function f:GetEffectiveScale() return self.scale * (self.parent and self.parent:GetEffectiveScale() or 1) end
    function f:GetWidth() return self.width end
    function f:GetHeight()
        if self.kind == 'ScrollFrame' then
            local layout = M and M.bagLayout
            return self.parent.height - (layout and layout.header or 106) - (layout and layout.footer or 42)
        end
        return self.height
    end
    function f:SetSize(w, h) self.width, self.height = w, h end
    function f:SetHeight(h) self.height = h end
    function f:SetWidth(w) self.width = w end
    function f:GetNumPoints() return #self.points end
    function f:GetPoint(i) return table.unpack(self.points[i]) end
    function f:SetPoint(...) table.insert(self.points, {...}) end
    function f:ClearAllPoints() self.points = {} end
    function f:IsClampedToScreen() return self.clamped end
    function f:SetClampedToScreen(v) self.clamped = v end
    function f:GetScript(name) return self.scripts[name] end
    function f:SetScript(name, fn) self.scripts[name] = fn end
    function f:HookScript(name, fn)
        local old = self.scripts[name]
        self.scripts[name] = function(...) if old then old(...) end; fn(...) end
    end
    function f:SetShown(v)
        if self.shown == v then return end
        self.shown = v
        local fn = self.scripts[v and 'OnShow' or 'OnHide']
        if fn then fn(self) end
    end
    function f:Show() self:SetShown(true) end
    function f:Hide() self:SetShown(false) end
    function f:IsShown() return self.shown and (not self.parent or self.parent:IsShown()) end
    function f:EnableMouse(v) self.mouse = v end
    function f:IsMouseEnabled() return self.mouse end
    function f:IsMouseOver() return self.mouseOver or false end
    function f:GetAlpha() return self.alpha end
    function f:SetAlpha(v) self.alpha = v end
    function f:GetFrameLevel() return self.level end
    function f:SetFrameLevel(v) self.level = v end
    function f:SetScrollChild(child) self.child = child end
    function f:GetVerticalScroll() return self.scroll end
    function f:SetVerticalScroll(value) self.scroll = value end
    function f:SetMinMaxValues(a, b) self.minimum, self.maximum = a, b end
    function f:SetValue(v)
        self.value = v
        if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, v) end
    end
    function f:SetText(t) self.text = t end
    function f:GetText() return self.text or '' end
    function f:SetChecked(v) self.checked = v end
    function f:GetChecked() return self.checked end
    function f:SetNormalTexture(t) self.texture = t end
    function f:CreateFontString() return frame('FontString', self) end
    function f:GetBagID() return self.bag end
    function f:GetID() return self.slot end
    function f:Initialize(bag, slot)
        assert(self.parent:IsCombinedBagContainer(), 'native Initialize requires parent contract')
        self.bag, self.slot = bag, slot
    end
    function f:RegisterEvent(event) self.events = self.events or {}; self.events[event] = true end
    for _, name in ipairs({'EnableMouseWheel', 'SetValueStep', 'SetBackdrop', 'SetAllPoints',
        'SetHitRectInsets', 'SetObeyStepOnDrag', 'SetFrameStrata'}) do
        f[name] = function() end
    end
    function f:OnClick() clicks = (clicks or 0) + 1 end
    function f:OnDragStart() pickups = (pickups or 0) + 1 end
    if kind == 'ItemButton' then
        f:SetScript('OnClick', f.OnClick)
        f:SetScript('OnDragStart', f.OnDragStart)
    end
    return f
end
function CreateFrame(kind, name, parent)
    local f = frame(kind, parent)
    table.insert(frames, f)
    return f
end
UIParent = frame('Frame'); UIParent:SetSize(1280, 800)
ContainerFrameCombinedBags = frame('Frame', UIParent)
local bag = ContainerFrameCombinedBags
bag.CloseButton = frame('Button', bag)
bag:SetSize(435, 900); bag.clamped = true; bag.shown = false; bag.Items = {}
function bag:IsCombinedBagContainer() return true end
function bag:EnumerateValidItems() return ipairs(self.Items) end
function bag:UpdateFrameSize() self:SetSize(435, 900) end
function bag:UpdateItemLayout() end
function bag:UpdateSearchBox() end
for slot = 1, 100 do
    local item = frame('ItemButton', bag); item:Initialize(math.floor((slot - 1) / 20), (slot - 1) % 20 + 1)
    bag.Items[#bag.Items + 1] = item
end
BagItemSearchBox = frame('EditBox', bag)
BagItemAutoSortButton = frame('Button', bag)
ContainerFrame6 = frame('Frame', UIParent); ContainerFrame6.shown = false
C_Container = {GetContainerNumSlots = function() return 24 end,
    GetContainerItemInfo = function(bag, slot)
        if emptyBags or (occupiedOnly and slot % 2 == 0) then return end
        return {itemID = bag * 100 + slot, stackCount = 1, hyperlink = 'item:' .. (bag * 100 + slot)}
    end}
ContainerFrameMixin = {UpdateItems = function(adapter)
    for _, button in adapter:EnumerateValidItems() do assert(button:GetBagID() == 5) end
end}
function hooksecurefunc(object, method, hook)
    local old = object[method]
    object[method] = function(...) old(...); hook(...) end
end
M = {db = {inventory = true, bagSize = 'medium'}, nativeDragFrames = {}}
function M:CancelSlide() end
function M:Slide(f, point, x, y) f:ClearAllPoints(); f:SetPoint(point, UIParent, point, x, y) end
function M:CanChange() return not combat end
function M:ShowItemContext(source) contextSource = source; contextCount = (contextCount or 0) + 1 end
''')
for name in ['InventoryLayout', 'InventoryOptions', 'Inventory']:
    lua.execute('assert(load(...))("Mistpad", M)', (ROOT / f'Mistpad/{name}.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
local calculate = M.BagLayout.Calculate
for _, width in ipairs({960, 1280, 1920}) do
    local small, medium, large = calculate('small', width, 800, 124),
        calculate('medium', width, 800, 124), calculate('large', width, 800, 124)
    assert(small.columns == 4 and medium.columns == 8)
    assert(large.width == width - 48)
    assert(large.contentWidth <= large.width - 32, 'large columns fit')
    assert(large.contentWidth + large.pitch > large.width - 32, 'maximum fitting columns')
    assert(small.height <= 704 and medium.height <= 704)
    assert(small.contentHeight > small.viewport, 'small scrolls')
end
assert(calculate('small', 1280, 800, 0).contentHeight > 0, 'empty inventory geometry valid')
local capped = calculate('small', 1280, 800, 200, 0, {maxRows = 3, itemSize = 48})
assert(capped.viewport == 152 and capped.height == 258, 'max height counts visible item rows')
assert(capped.contentHeight > capped.viewport, 'row cap keeps all contents scrollable')
M:InstallInventory()
local pointer = frames[1]
local bag = ContainerFrameCombinedBags
bag:Show()
assert(M.inventoryUsesLayout and M.bagLayout.columns == 8)
assert(not bag.mistpadClose and not bag.mistpadHint and not bag.CloseButton.shown, 'bag header has no close or helper controls')
assert(bag.width == 444 and bag.height <= 704)
local item = bag.Items[1]
local content = item.parent
local scroll = content.parent
assert(content.parent.kind == 'ScrollFrame' and math.abs(item.width * item.scale - 48) < 0.001)
assert(content.height == 16 * 52 - 4, 'all 124 slots in unified content')
ContainerFrame6:Show()
assert(ContainerFrame6.alpha == 0 and not ContainerFrame6.mouse, 'native reagent duplicate hidden')
for _, size in ipairs({'Small', 'Medium', 'Large'}) do
    local option
    for _, f in ipairs(frames) do if f.text == size then option = f end end
    assert(option, 'cog contains size option')
    option.scripts.OnClick()
    assert(M.db.bagSize == string.lower(size))
end
assert(bag.width == 1232 and M.bagLayout.columns == 23)
M.db.bagSize = 'small'; M:RefreshInventory()
assert(M.bagLayout.columns == 4)
local function press()
    down = true; y = 0; now = 0
    item.scripts.OnMouseDown(item, 'LeftButton')
end
press(); y = 100; pointer.scripts.OnUpdate()
assert(scroll.scroll == 100, 'finger scroll follows pointer')
down = false; item.scripts.OnClick(item, 'LeftButton')
assert(not clicks and not pickups, 'scroll neither uses nor picks up item')
press(); down = false; item.scripts.OnClick(item, 'LeftButton')
assert(clicks == 1, 'tap retains native action')
press(); now = 0.5; y = 30; pointer.scripts.OnUpdate()
assert(pickups == 1, 'hold then drag picks up native item')
press(); y = 90; down = false; item.scripts.OnClick(item, 'LeftButton')
assert(clicks == 1 and scroll.scroll == 190, 'fast release before polling is consumed')
cursorItem = true; item.scripts.OnMouseDown(item, 'LeftButton'); item.scripts.OnClick(item, 'LeftButton')
assert(clicks == 2, 'cursor item can be dropped after scrolling'); cursorItem = false
press(); now = 1.49; pointer.scripts.OnUpdate()
assert(not contextSource, 'hold waits for configured delay')
now = 1.5; pointer.scripts.OnUpdate()
assert(contextSource == item and contextCount == 1, 'stationary 1.5 second hold opens context')
item.scripts.OnDragStart(item, 'LeftButton')
assert(pickups == 1, 'moving after context opens cannot pick up item')
down = false; item.scripts.OnClick(item, 'LeftButton')
assert(clicks == 2, 'hold release does not activate item')
item.scripts.OnClick(item, 'LeftButton')
assert(clicks == 2, 'duplicate touchscreen release cannot activate item')
M.db.holdTime = 0.75
press(); now = 0.75; pointer.scripts.OnUpdate()
assert(contextCount == 2, 'custom hold delay')
down = false; item.scripts.OnClick(item, 'LeftButton')
press(); x = 40; down = false; item.scripts.OnClick(item, 'LeftButton')
assert(clicks == 2, 'fast sideways release is not a tap')
x = 0
assert(not BagItemSearchBox.shown and M.bagLayout.header == 64, 'search defaults off and reclaims header')
M.db.searchBar = true; M:RefreshInventory()
assert(BagItemSearchBox.shown and M.bagLayout.header == 96, 'search can be enabled')
M.db.searchBar = false; M:RefreshInventory()
occupiedOnly = true; M.db.dynamicContents = true; M:RefreshInventory()
assert(content.height == 16 * 52 - 4, '62 occupied slots compact into 16 rows of four')
for _, button in ipairs(bag.Items) do
    assert(button.shown == (button.slot % 2 == 1), 'empty native slots hidden')
end
emptyBags = true; M:RefreshInventory()
assert(content.height == 1 and M.bagLayout.rows == 0, 'empty dynamic bags have no placeholder slots')
emptyBags = false; occupiedOnly = false; M.db.dynamicContents = false
M.db.itemSize = 64; M:RefreshInventory()
assert(math.abs(item.width * item.scale - 64) < 0.001 and M.bagLayout.cell == 64, 'item frames scale')
M.db.bagSize = 'large'; M:RefreshInventory()
assert(M.bagLayout.columns == 17, 'large columns adapt to item scale')
M.db.bagSize = 'small'; M.db.itemSize = 48; M:RefreshInventory()
M.db.inventory = false; M:RefreshInventory()
assert(not M.inventoryUsesLayout and item.parent == bag and item.width == 37, 'native item layout restored')
assert(ContainerFrame6.alpha == 1, 'native reagent visibility restored')
assert(item.scripts.OnClick == item.OnClick and item.scripts.OnDragStart == item.OnDragStart, 'native scripts restored')
M.db.inventory = true; M:RefreshInventory()
assert(M.bagLayout.columns == 4 and item.mistpadItemEnabled, 'replacement can be reenabled')
bag:Hide()
assert(not M.inventoryUsesLayout and item.parent == bag, 'closing returns pooled native buttons')
bag:Show()
assert(M.inventoryUsesLayout and item.parent == content, 'reopening reapplies unified grid')
''')
print('PASS: bag layouts, unified slots, size options, touch scroll, tap, hold-drag, fast release, cursor drop, fallback')
lua.execute('assert(load(...))("Mistpad", M)', (ROOT / 'Mistpad/NativePanels.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
ContainerFrameSettingsManager = {IsUsingCombinedBags = function() return true end}
function OpenAllBags() ContainerFrameCombinedBags:Show(); ContainerFrame6:Show() end
function CloseAllBags() ContainerFrameCombinedBags:Hide(); ContainerFrame6:Hide() end
function M:Slide(f, point, x, y, dx, dy, complete)
    f:ClearAllPoints(); f:SetPoint(point, UIParent, point, x, y)
    if complete then complete() end
end
CloseAllBags()
local c = M:GetGesturePanel('BOTTOM')
assert(c:BeginDrag() and M.inventoryUsesLayout, 'bottom pull initializes responsive bag')
assert(c.ratio == 1 and c.frame.width == 236, 'gesture preserves grid width and touch target scale')
c:UpdateDrag(150); c:EndDrag(true)
assert(c.frame:IsShown() and not c.shield:IsShown(), 'dragged bag opens interactively')
CloseAllBags()
assert(not M.inventoryUsesLayout and not c.saved, 'close restores adapter and grid')
assert(c:BeginDrag()); c:UpdateDrag(20); c:EndDrag(false)
assert(not c.frame:IsShown() and not M.inventoryUsesLayout, 'cancelled bottom pull restores native state')
for _, anchor in ipairs({'left', 'middle', 'right'}) do
    M.db.bagAnchor = anchor
    OpenAllBags()
    M:RefreshInventory()
    local expected, expectedX = M.BagLayout.Anchor(M.db)
    assert(ContainerFrameCombinedBags.points[1][1] == expected, 'normal opening uses configured anchor')
    CloseAllBags()
    assert(c:BeginDrag())
    local point, x = c:Position(c.travel)
    assert(point == expected and x == expectedX, 'bottom pull uses same anchor')
    c:EndDrag(false)
end
M.db.bagAnchor = 'middle'
''')
print('PASS: responsive bag integrates with bottom-edge pull, scaling, opening, closing and cancellation')
