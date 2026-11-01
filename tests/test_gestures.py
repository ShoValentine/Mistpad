"""Run with a Python environment containing lupa (Lua runtime)."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.devtools'))
from lupa import LuaRuntime

lua = LuaRuntime()
for path in (ROOT / 'Mistpad').glob('*.lua'):
    lua.execute('assert(load(...))', path.read_text(encoding='utf-8-sig'))

lua.execute('''
frames = {}
x, y, down, combat = 0, 0, false, false
UIParent = { GetEffectiveScale = function() return 1 end }
function GetCursorPosition() return x, y end
function IsMouseButtonDown() return down end
function InCombatLockdown() return combat end
local methods = {}
function methods:SetScript(name, fn) self.scripts[name] = fn end
function methods:Hide()
    self.shown = false
    if self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:Show() self.shown = true end
function methods:SetShown(value) if value then self:Show() else self:Hide() end end
function methods:SetText(value) self.text = value end
function methods:CreateTexture() return setmetatable({scripts = {}}, {__index = methods}) end
methods.CreateFontString = methods.CreateTexture
for _, name in ipairs({'SetFrameStrata', 'EnableMouse', 'SetHeight', 'SetWidth',
    'SetPoint', 'SetSize', 'SetColorTexture', 'SetAllPoints', 'SetAlpha'}) do
    methods[name] = function() end
end
function CreateFrame()
    local frame = setmetatable({scripts = {}}, {__index = methods})
    table.insert(frames, frame)
    return frame
end
calls = {bags = 0, menu = 0, quests = 0, map = 0}
M = {db = {gestures = true}}
function M:ToggleInventory() calls.bags = calls.bags + 1 end
function M:ToggleMenu() calls.menu = calls.menu + 1 end
M.Menu = {}
function M.Menu:BeginDrag() self.dragging = true; return true end
function M.Menu:UpdateDrag(distance) self.distance = distance end
function M.Menu:EndDrag(open)
    self.dragging = false
    if open then calls.menu = calls.menu + 1 end
end
local panels = {TOP = M.Menu}
function M:GetGesturePanel(side)
    if not panels[side] then
        local key = ({BOTTOM = 'bags', LEFT = 'quests', RIGHT = 'map'})[side]
        panels[side] = {
            BeginDrag = function(self) self.dragging = true; return true end,
            UpdateDrag = function(self, distance) self.distance = distance end,
            EndDrag = function(self, open)
                self.dragging = false
                if open then calls[key] = calls[key] + 1 end
            end,
        }
    end
    return panels[side]
end
function ToggleQuestLog() calls.quests = calls.quests + 1 end
function ToggleWorldMap() calls.map = calls.map + 1 end
''')
lua.execute('assert(load(...))("Mistpad", M)', (ROOT / 'Mistpad/Gestures.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
M:CreateGestures()
local tracker = frames[1]
local function begin(index)
    x, y, down = 0, 0, true
    frames[index].scripts.OnMouseDown(frames[index], 'LeftButton')
end
local function move(a, b, pressed)
    x, y, down = a, b, pressed
    if tracker.shown then tracker.scripts.OnUpdate() end
end
local directions = {{2, 0, 80, 'bags'}, {3, 0, -80, 'menu'},
    {4, 80, 0, 'quests'}, {5, -80, 0, 'map'}}
for _, spec in ipairs(directions) do
    begin(spec[1]); move(spec[2], spec[3], true)
    assert(calls[spec[4]] == 0, 'must wait for release')
    move(spec[2], spec[3], false)
    assert(calls[spec[4]] == 1, 'direction must open correct destination')
    move(spec[2], spec[3], false)
    assert(calls[spec[4]] == 1, 'must open only once')
end
begin(2); move(0, 30, false); assert(calls.bags == 1, 'short swipe')
begin(2); move(0, -30, true); move(0, 90, false); assert(calls.bags == 1, 'outward rejection persists')
begin(2); move(80, 10, true); move(0, 90, false); assert(calls.bags == 1, 'sideways rejection persists')
begin(2); move(0, 90, true); combat = true; move(0, 90, false)
assert(calls.bags == 1, 'combat cancellation'); combat = false
begin(2); move(0, 90, true); M:SetGesturesVisible(false); move(0, 90, false)
assert(calls.bags == 1, 'hidden gesture cancellation')
M:SetGesturesVisible(true)
UIParent.GetEffectiveScale = function() return 2 end
begin(2); move(0, 100, false); assert(calls.bags == 1, 'threshold uses UI scale')
begin(2); move(0, 160, false); assert(calls.bags == 2, 'scaled swipe commits')
''')
print('PASS: all Lua files compile; four directions, release, single action, cancellation, combat, disable, UI scale')

# Exercise the real menu's positioning and snap targets independently of native frames.
lua.execute('''
local function widget()
    local w = {scripts = {}, shown = false}
    function w:SetSize(width, height) self.height = height end
    function w:GetHeight() return self.height end
    function w:SetPoint(...) self.point = {...} end
    function w:ClearAllPoints() end
    function w:SetClampedToScreen(value) self.clamped = value end
    function w:EnableMouse(value) self.mouse = value end
    function w:SetText() end
    function w:SetFontObject() end
    function w:SetScript(name, fn) self.scripts[name] = fn end
    function w:HookScript(name, fn) self.scripts[name] = fn end
    function w:IsShown() return self.shown end
    function w:Show() self.shown = true end
    function w:Hide()
        self.shown = false
        if self.scripts.OnHide then self.scripts.OnHide() end
    end
    function w:GetFontString() return self end
    function w:CreateFontString() return self end
    return w
end
function M:CreatePanel(_, _, width, height)
    local panel = widget()
    panel:SetSize(width, height)
    panel.close = widget()
    return panel
end
function CreateFrame() return widget() end
function M:CancelSlide() end
GameTooltip = {Hide = function() end}
function M:Slide(frame, point, x, y, dx, dy, complete)
    snap = {target = y, from = y + dy, complete = complete}
end
''')
for name in ['MicroMenu', 'Menu']:
    lua.execute('assert(load(...))("Mistpad", M)', (ROOT / f'Mistpad/{name}.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
M:CreateMenu()
local panel = M.Menu
assert(panel.clamped == false, 'panel must extend above screen')
assert(panel:BeginDrag() and panel:IsShown(), 'touch immediately reveals panel')
assert(panel.point[5] == panel:GetHeight() - 32, '32-unit peek')
assert(not panel.mouse, 'drag cannot activate menu buttons')
panel:UpdateDrag(100)
assert(panel.point[5] == panel:GetHeight() - 132, 'panel follows finger one-to-one')
panel:UpdateDrag(1000)
assert(panel.point[5] == -24, 'drag stops at open position')
panel:EndDrag(true)
assert(snap.target == -24 and snap.from == -24, 'snap starts at current position')
snap.complete()
assert(panel.mouse and panel:IsShown(), 'open snap enables controls')
assert(not panel:BeginDrag(), 'open menu is not pulled out again')
panel:Hide()
panel:BeginDrag(); panel:UpdateDrag(20); panel:EndDrag(false)
assert(snap.from == panel:GetHeight() - 52 and snap.target == panel:GetHeight() + 8, 'cancel retracts from current position')
snap.complete()
assert(not panel:IsShown(), 'cancel hides menu after animation')
panel:BeginDrag(); panel:Hide()
assert(not panel.dragging, 'Escape/combat hide clears drag state')
''')
print('PASS: menu peek, finger tracking, clamp, interaction gating, open/close snap, external hide')
