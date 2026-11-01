"""Check pooled close-animation rendering without a WoW client."""
from pathlib import Path
import sys
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.devtools'))
from lupa import LuaRuntime
lua = LuaRuntime()
lua.execute('''
combat = false; frames = {}; regions = {}; slides = {}
function InCombatLockdown() return combat end
local methods = {}
function methods:Hide() self.shown = false end
function methods:Show() self.shown = true end
function methods:IsShown() return self.shown end
function methods:SetParent(p) self.parent = p end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:GetLeft() return self.left end
function methods:GetBottom() return self.bottom end
function methods:GetTop() return self.bottom + self.height end
function methods:GetEffectiveScale() return self.scale or 1 end
function methods:ClearAllPoints() self.point = nil end
function methods:SetPoint(...) self.point = {...} end
function methods:GetFrameStrata() return 'MEDIUM' end
function methods:SetFrameStrata() end
function methods:GetFrameLevel() return self.level or 10 end
function methods:SetFrameLevel(v) self.level = v end
function methods:GetAlpha() return self.alpha or 1 end
function methods:SetAlpha(a) self.alpha = a end
function methods:SetClipsChildren(v) self.clipped = v end
function methods:IsObjectType(kind) return self.kind == kind end
function methods:GetRegions() return table.unpack(self.regions or {}) end
function methods:GetChildren() return table.unpack(self.children or {}) end
function methods:EnableMouse(v) self.mouse = v end
function methods:GetAtlas() return self.atlas end
function methods:GetTexture() return self.texture end
function methods:SetAtlas(v) self.atlas = v end
function methods:SetTexture(v) self.texture = v end
function methods:GetTexCoord() return 0, 1, 0, 1 end
function methods:GetVertexColor() return 1, 1, 1, 1 end
function methods:GetBlendMode() return 'BLEND' end
function methods:GetDrawLayer() return 'ARTWORK', 0 end
function methods:GetText() return self.text end
function methods:SetText(v) self.text = v end
function methods:GetFont() return 'Fonts/FRIZQT__.TTF', 14, '' end
function methods:GetTextColor() return 1, 0.8, 0, 1 end
function methods:GetJustifyH() return 'LEFT' end
function methods:GetJustifyV() return 'MIDDLE' end
function methods:GetShadowColor() return 0, 0, 0, 1 end
function methods:GetShadowOffset() return 1, -1 end
function methods:SetFont(file, size) self.fontSize = size end
for _, name in ipairs({'SetTexCoord', 'SetVertexColor', 'SetBlendMode', 'SetDrawLayer',
    'SetTextColor', 'SetJustifyH', 'SetJustifyV', 'SetShadowColor', 'SetShadowOffset'}) do
    methods[name] = function() end
end
local function object(kind, parent)
    return setmetatable({kind = kind, parent = parent, shown = true, left = 24, bottom = 24,
        width = 236, height = 300, regions = {}, children = {}}, {__index = methods})
end
function CreateFrame(kind, _, parent)
    local f = object(kind, parent); frames[#frames + 1] = f; return f
end
function methods:CreateTexture()
    local t = object('Texture', self); regions[#regions + 1] = t; return t
end
function methods:CreateFontString()
    local t = object('FontString', self); regions[#regions + 1] = t; return t
end
UIParent = object('Frame'); source = object('Frame', UIParent)
local texture, text = object('Texture', source), object('FontString', source)
texture.texture = 'Interface/DialogFrame/UI-DialogBox-Background'; text.text = 'Bags'
source.regions = {texture, text}
local scroll = object('ScrollFrame', source)
local content = object('Frame', scroll)
scroll.children = {content}; source.children = {scroll}
M = {db = {animation = true}}
function M:CancelSlide(f) cancelled = f end
function M:Slide(f, point, x, y, dx, dy, complete)
    slides[#slides + 1] = {frame = f, point = point, x = x, y = y, dx = dx, dy = dy, complete = complete}
end
''')
lua.execute('assert(load(...))("Mistpad", M)', (ROOT / 'Mistpad/BagClosing.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
M:AnimateBagClosing(source)
local slide = slides[#slides]
assert(slide.point == 'BOTTOMLEFT' and slide.x == 24 and slide.y == -308, 'slides off bottom at original horizontal position')
assert(slide.y + slide.dy == 24, 'starts at current visible position')
assert(slide.frame:IsShown() and not slide.frame.mouse, 'visual copy cannot intercept touches')
assert(source:IsShown(), 'renderer leaves native visibility alone')
local clipped = false
for _, frame in ipairs(frames) do if frame.clipped then clipped = true end end
assert(clipped, 'scroll viewport clipping preserved')
local count = #frames + #regions
slide.complete(); assert(not slide.frame:IsShown(), 'completion hides visual copy')
M:AnimateBagClosing(source)
assert(#frames + #regions == count, 'render objects are reused on repeated closes')
M:CancelBagClosing(); assert(not slide.frame:IsShown(), 'reopen cancels closing visual')
local before = #slides
combat = true; M:AnimateBagClosing(source); assert(#slides == before, 'no snapshot during combat')
combat = false; M.db.animation = false; M:AnimateBagClosing(source)
assert(#slides == before, 'reduced animation option respected')
M.db.animation = true
M:AnimateBagClosing(source)
local bottom = slides[#slides]
M:AnimatePanelClosing(source, 'TOP')
local top = slides[#slides]
assert(top.y == UIParent:GetHeight() + 8 and top.y + top.dy == 24, 'top menu retracts above screen')
assert(top.frame ~= bottom.frame, 'top and bottom closing animations have independent visuals')
M:CancelPanelClosing('TOP')
assert(not top.frame:IsShown() and bottom.frame:IsShown(), 'cancelling top leaves bag animation intact')
M:AnimatePanelClosing(source, 'LEFT')
local left = slides[#slides]
assert(left.x == -source:GetWidth() - 8 and left.y == 24 and left.x + left.dx == 24, 'left panel slides back to left edge')
M:AnimatePanelClosing(source, 'RIGHT')
local right = slides[#slides]
assert(right.x == UIParent:GetWidth() + 8 and right.y == 24 and right.x + right.dx == 24, 'right panel slides back to right edge')
''')
print('PASS: close renderer, bottom trajectory, input passthrough, clipping, pooling, cancellation and combat gate')
