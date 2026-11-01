"""Verify real native-window controllers with simulated WoW frames."""
from pathlib import Path
import sys
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.devtools'))
from lupa import LuaRuntime
lua = LuaRuntime()
lua.execute('''
unpack = table.unpack
combat = false
function InCombatLockdown() return combat end
UIParent = {
    GetWidth = function() return 1280 end,
    GetHeight = function() return 800 end,
    GetEffectiveScale = function() return 1 end,
}
local function frame(width, height)
    local f = {width = width, height = height, scale = 1, clamped = true,
        points = {{'CENTER', UIParent, 'CENTER', 10, 20}}, shown = false, hooks = {}}
    function f:GetWidth() return self.width end
    function f:GetHeight() return self.height end
    function f:GetScale() return self.scale end
    function f:SetScale(value) self.scale = value end
    function f:IsClampedToScreen() return self.clamped end
    function f:SetClampedToScreen(value) self.clamped = value end
    function f:GetParent() return UIParent end
    function f:GetNumPoints() return #self.points end
    function f:GetPoint(i) return table.unpack(self.points[i]) end
    function f:ClearAllPoints() self.points = {} end
    function f:SetPoint(...) self.points[#self.points + 1] = {...} end
    function f:IsShown() return self.shown end
    function f:Show() self.shown = true end
    function f:Hide()
        self.shown = false
        for _, hook in ipairs(self.hooks) do hook() end
    end
    function f:HookScript(_, fn) table.insert(self.hooks, fn) end
    function f:GetFrameLevel() return 10 end
    for _, name in ipairs({'SetAllPoints', 'EnableMouse', 'EnableMouseWheel', 'SetScript', 'SetFrameLevel', 'RegisterEvent'}) do
        f[name] = function() end
    end
    return f
end
function CreateFrame() return frame(1, 1) end
ContainerFrameCombinedBags = frame(500, 500)
ContainerFrameSettingsManager = {IsUsingCombinedBags = function() return true end}
WorldMapFrame = frame(1000, 700)
CharacterFrame = frame(400, 600)
function ToggleCharacter(tab) mode = 'character'; CharacterFrame:Show() end
function OpenAllBags() ContainerFrameCombinedBags:Show() end
function CloseAllBags() ContainerFrameCombinedBags:Hide() end
function ToggleQuestLog() mode = 'quests'; WorldMapFrame:Show() end
function ToggleWorldMap() mode = 'map'; WorldMapFrame:Show() end
function HideUIPanel(f) f:Hide() end
M = {db = {inventory = true}, Menu = {}}
function M:InstallInventory() end
function M:CanChange() return not combat end
function M:Print(text) message = text end
function M:CancelSlide() snap = nil end
function M:Slide(f, point, x, y, dx, dy, complete)
    snap = {frame = f, point = point, x = x, y = y, dx = dx, dy = dy, complete = complete}
end
''')
for name in ['SidePanels', 'NativePanels']:
    lua.execute('assert(load(...))("Mistpad", M)', (ROOT / f'Mistpad/{name}.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
assert(M:GetGesturePanel('TOP') == M.Menu)
for _, side in ipairs({'BOTTOM', 'LEFT', 'RIGHT'}) do
    local c = M:GetGesturePanel(side)
    assert(c:BeginDrag(), side .. ' begins')
    local f = c.frame
    assert(f:IsShown() and not f.clamped and c.shield:IsShown(), 'peek rendered with input shield')
    assert(not c:BeginDrag(), 'already open window is not toggled shut')
    local _, startX, startY = c:Position(0)
    c:UpdateDrag(100)
    local _, x, y = c:Position(c.distance)
    local delta = side == 'BOTTOM' and (y - startY) or (x - startX)
    assert(math.abs(math.abs(delta * c.ratio) - 100) < 0.001, 'one-to-one UI movement')
    assert(side ~= 'LEFT' or mode == 'character')
    assert(side ~= 'RIGHT' or mode == 'quests')
    c:EndDrag(true)
    assert(snap.point == side, 'correct snap edge')
    assert(math.abs((side == 'BOTTOM' and snap.y or snap.x) * c.ratio) == 24, 'open margin')
    snap.complete()
    assert(f:IsShown() and not c.shield:IsShown(), 'open enables native controls')
    f:Hide()
    assert(f.scale == 1 and f.clamped and f.points[1][1] == 'CENTER', 'native geometry restored')
    assert(not M.nativeDragFrames[f])
    assert(c:BeginDrag())
    c:UpdateDrag(20); c:EndDrag(false); snap.complete()
    assert(not f:IsShown() and f.scale == 1, 'cancel closes and restores')
    assert(c:BeginDrag())
    combat = true; c:EndDrag(false); M:FreezeNativeDrags()
    assert(c.saved and c.snapping, 'combat defers geometry changes')
    combat = false; M:ResetNativeDrags()
    assert(not f:IsShown() and not c.saved and f.clamped, 'post-combat cleanup')
end
M.db.inventory = false
assert(not M:GetGesturePanel('BOTTOM'):BeginDrag(), 'inventory fallback respected')
M.db.inventory = true
ContainerFrameSettingsManager.IsUsingCombinedBags = function() return false end
assert(not M:GetGesturePanel('BOTTOM'):BeginDrag(), 'individual bags remain native')
local left = M:GetGesturePanel('LEFT')
M:SetSidePanelTarget('LEFT', 'map')
assert(left:BeginDrag() and left.frame == WorldMapFrame and mode == 'map', 'left side can be reassigned to map')
left:EndDrag(true); snap.complete()
M:SetSidePanelTarget('LEFT', 'character')
assert(not WorldMapFrame:IsShown(), 'changing assignment closes and restores active side panel')
assert(left:BeginDrag() and left.frame == CharacterFrame, 'switching targets reuses the controller')
assert(left.shield == left.shields[CharacterFrame] and left.shield ~= left.shields[WorldMapFrame], 'each native target has its own input shield')
CharacterFrame:Hide()
M:SetSidePanelTarget('RIGHT', 'character')
assert(M:GetGesturePanel('RIGHT'):BeginDrag() and mode == 'character', 'right side can use character')
CharacterFrame:Hide()
M.db.leftPanel = 'invalid'
local fallback = M:GetSidePanelTarget('LEFT')
assert(fallback.frame == 'CharacterFrame', 'invalid assignment falls back to left default')
''')
print('PASS: three native controllers; peek, tracking, snap, shield, mode, restoration, combat, fallbacks')
