"""Run the actual enlarged micro-menu and Settings routing with simulated UI."""
from pathlib import Path
import sys
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.devtools'))
from lupa import LuaRuntime
lua = LuaRuntime()
lua.execute('''
frames = {}; named = {}; UISpecialFrames = {}; combat = false; called = {}; closed = 0
function InCombatLockdown() return combat end
GameTooltip = {Hide = function() end, SetOwner = function() end, SetText = function() end, Show = function() end}
local methods = {}
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:GetWidth() return self.width or 32 end
function methods:GetHeight() return self.height or 40 end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:SetScale(s) self.scale = s end
function methods:GetEffectiveScale() return (self.scale or 1) * (self.parent and self.parent:GetEffectiveScale() or 1) end
function methods:GetLeft() return 0 end
function methods:GetTop() return 100 end
function methods:SetPoint(...) self.point = {...} end
function methods:ClearAllPoints() self.point = nil end
function methods:SetParent(p) self.parent = p end
function methods:GetParent() return self.parent end
function methods:GetName() return self.name end
function methods:SetScript(name, fn) self.scripts[name] = fn end
function methods:GetScript(name) return self.scripts[name] end
function methods:HookScript(name, fn)
    local old = self.scripts[name]
    self.scripts[name] = function(...) if old then old(...) end; fn(...) end
end
function methods:RegisterEvent(name) self.events[name] = true end
function methods:Show() self.shown = true end
function methods:Hide()
    self.shown = false
    if self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:IsShown() return self.shown end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:EnableMouse(v) self.mouse = v end
function methods:IsMouseOver() return self.mouseOver end
function methods:SetEnabled(v) self.enabled = v end
function methods:IsEnabled() return self.enabled end
function methods:GetButtonState() return 'NORMAL' end
function methods:SetClampedToScreen(v) self.clamped = v end
function methods:SetClipsChildren(v) self.clips = v end
function methods:SetText(v) self.text = v end
function methods:GetText() return self.text end
function methods:GetFontString() return self end
function methods:GetFrameLevel() return 10 end
function methods:GetTexture() return self.texture end
function methods:GetAtlas() return self.atlas end
function methods:SetTexture(v) self.texture = v end
function methods:SetAtlas(v) self.atlas = v end
function methods:GetTexCoord() return 0, 1, 0, 1 end
function methods:GetVertexColor() return 1, 1, 1, 1 end
function methods:GetBlendMode() return 'BLEND' end
function methods:GetDrawLayer() return 'ARTWORK', 0 end
function methods:GetNormalTexture() return self.normal end
function methods:GetPushedTexture() return self.pushed end
function methods:GetHighlightTexture() return self.highlight end
function methods:GetDisabledTexture() return self.disabled end
function methods:GetRegions() return table.unpack(self.regions) end
function methods:GetChildren() return table.unpack(self.children) end
function methods:IsObjectType(kind) return self.kind == kind end
for _, name in ipairs({'SetFrameStrata', 'SetBackdrop', 'SetFontObject', 'RegisterForClicks', 'SetJustifyH',
    'SetTexCoord', 'SetVertexColor', 'SetBlendMode', 'SetDrawLayer', 'SetAlpha', 'SetWordWrap', 'SetJustifyV',
    'SetNonSpaceWrap'}) do methods[name] = function() end end
local function object(kind, name, parent)
    return setmetatable({kind = kind, name = name, parent = parent, scripts = {}, events = {},
        shown = true, enabled = true, regions = {}, children = {}}, {__index = methods})
end
function CreateFrame(kind, name, parent)
    local f = object(kind, name, parent); frames[#frames + 1] = f
    if name then named[name] = f end
    return f
end
function methods:CreateTexture()
    local t = object('Texture', nil, self); self.regions[#self.regions + 1] = t; return t
end
function methods:CreateFontString() return object('FontString', nil, self) end
function methods:CreateMaskTexture()
    local t = object('MaskTexture', nil, self); self.regions[#self.regions + 1] = t; return t
end
function methods:AddMaskTexture(mask) self.mask = mask end
function methods:SetDesaturated(value) self.desaturated = value end
function SetPortraitTexture(texture, unit) texture.texture = 'Portrait-' .. unit end
UIParent = object('Frame'); UIParent:SetSize(1280, 800)
hud = object('Frame', 'NativeHUD', UIParent)
for _, name in ipairs({'CharacterMicroButton', 'ProfessionMicroButton', 'PlayerSpellsMicroButton', 'HelpMicroButton', 'MainMenuMicroButton'}) do
    local native = object('Button', name, hud)
    native:SetSize(32, 40)
    for _, state in ipairs({'normal', 'pushed', 'highlight', 'disabled'}) do
        local texture = native:CreateTexture(); texture.texture = name .. '-' .. state
        native[state] = texture
    end
    native.Background = native:CreateTexture(); native.Background.texture = 'NativeButtonBackground'
    native:SetScript('OnClick', function(self) called[#called + 1] = self.name end)
    _G[name] = native
end
CharacterMicroButton.Portrait = CharacterMicroButton:CreateTexture()
CharacterMicroButton.PortraitMask = CharacterMicroButton:CreateMaskTexture()
CharacterMicroButton.PortraitMask:SetAtlas('NativePortraitMask')
HelpMicroButton.FlashContent = HelpMicroButton:CreateTexture()
HelpMicroButton.FlashContent:SetTexture('OversizedSupportFlash')
HelpMicroButton.FlashContent:SetSize(4096, 2048)
local unrelated = HelpMicroButton:CreateTexture()
unrelated:SetTexture('UnrelatedSupportSheet'); unrelated:SetSize(2048, 2048)
local supportPopup = object('Frame', nil, HelpMicroButton)
local banner = supportPopup:CreateTexture()
banner:SetTexture('SupportPopupBanner'); banner:SetSize(4096, 2048)
HelpMicroButton.children = {supportPopup}
M = {db = {animation = true}}
function M:CanChange() return not combat end
function M:CancelSlide() end
function M:CancelPanelClosing(edge) cancelled = edge end
function M:AnimatePanelClosing(source, edge) assert(source:IsShown()); closed = closed + 1; closingEdge = edge end
function M:Slide(f, point, x, y, dx, dy, complete)
    f:ClearAllPoints(); f:SetPoint(point, UIParent, point, x, y)
    if complete then complete() end
end
function M:OpenBagOptions() bagOptionsOpened = true end
function ToggleGameMenu() gameMenuOpened = true end
''')
for name in ['Panels', 'MicroMenu', 'SidePanels', 'Settings', 'Menu']:
    lua.execute('assert(load(...))("Mistpad", M)', (ROOT / f'Mistpad/{name}.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
M:CreateMenu()
local panel = M.Menu
local function Open()
    if panel:IsShown() then panel:Hide() end
    panel:Toggle()
    frames[1].scripts.OnUpdate(frames[1], 0.22)
end
assert(#panel.entries == 5 and #panel.buttons == 5, 'native micro-menu entries replace old shortcut list')
assert(not panel.close, 'no close button')
assert(not panel.title and panel.height == 192, 'title-free menu trims vertical padding')
assert(panel.buttons[1].width == 84 and panel.buttons[1].height == 168, 'large touch tiles')
assert(panel.buttons[1].artwork.scale == 2, 'native artwork enlarged twofold')
local copied = false
for _, texture in ipairs(panel.buttons[1].artwork.regions) do
    if texture.texture == 'CharacterMicroButton-normal' then copied = true end
end
assert(copied, 'native normal artwork copied exactly')
local portrait
for _, texture in ipairs(panel.buttons[1].artwork.regions) do
    if texture.texture == 'Portrait-player' then portrait = texture end
end
assert(portrait and portrait.mask and portrait.mask.atlas == 'NativePortraitMask', 'live player portrait preserves native mask')
assert(CharacterMicroButton.parent == hud and CharacterMicroButton.width == 32, 'persistent HUD remains unchanged')
Open()
panel.buttons[1].scripts.OnClick(panel.buttons[1])
assert(called[1] == 'CharacterMicroButton' and closingEdge == 'TOP',
    'native window action and slide-back on selection: ' .. tostring(called[1]) .. '/' .. tostring(closingEdge))
local support = panel.buttons[4]
assert(support.entry.label == 'Customer\\nSupport')
assert(support.artworkClip.clips and support.artworkClip.width == 84 and support.artworkClip.height == 136)
local supportIcon = false
for _, texture in ipairs(support.artwork.regions) do
    assert(texture.texture ~= 'OversizedSupportFlash' and texture.texture ~= 'UnrelatedSupportSheet'
        and texture.texture ~= 'SupportPopupBanner', 'support extra textures must not be copied')
    assert(texture:GetWidth() <= 64 and texture:GetHeight() <= 80, 'copied artwork stays bounded')
    if texture.texture == 'HelpMicroButton-normal' then supportIcon = true end
end
assert(supportIcon, 'customer support keeps its own native button icon')
Open(); support.scripts.OnClick(support)
assert(called[#called] == 'HelpMicroButton', 'customer support still opens native help')
Open(); local settings = panel.buttons[5]
assert(settings.entry.label == 'Settings')
settings.scripts.OnClick(settings)
assert(M.SettingsPanel:IsShown(), 'settings tile opens Mistpad settings')
local option
for _, f in ipairs(frames) do if f.parent == M.SettingsPanel and f.text == 'Bag Options' then option = f end end
assert(option); option.scripts.OnClick()
assert(bagOptionsOpened, 'bag options reachable from top settings')
M:ShowSidePanelSettings()
local sideSettings = M.SidePanelSettings
assert(sideSettings:IsShown() and #sideSettings.choices == 6 and not sideSettings.close, 'side assignment settings are touch based and title only')
local _, leftDefault = M:GetSidePanelTarget('LEFT')
local _, rightDefault = M:GetSidePanelTarget('RIGHT')
assert(leftDefault == 'character' and rightDefault == 'quests', 'side defaults')
for _, choice in ipairs(sideSettings.choices) do
    if choice.side == 'LEFT' and choice.value == 'map' then choice.button.scripts.OnClick() end
end
assert(M.db.leftPanel == 'map', 'touch selector saves left assignment')
sideSettings:Hide()
Open(); ProfessionMicroButton.enabled = false
panel.buttons[2]:UpdateArtwork(ProfessionMicroButton)
assert(not panel.buttons[2].enabled, 'native disabled state respected')
local before = #called; panel.buttons[2].scripts.OnClick(panel.buttons[2]); assert(#called == before)
ProfessionMicroButton.enabled = true
UIParent:SetSize(400, 800); panel:Refresh()
assert(panel.height == 360 and panel.width <= 352, 'narrow layout wraps to two rows')
panel:Hide(); local count = closed
assert(panel:BeginDrag()); panel:UpdateDrag(20); panel:EndDrag(false)
assert(closed == count, 'cancelled drag does not play a second close animation')
Open()
local outside
for _, f in ipairs(frames) do if f.events.GLOBAL_MOUSE_DOWN then outside = outside or f end end
panel.mouseOver = true; outside.scripts.OnEvent(outside, 'GLOBAL_MOUSE_DOWN'); assert(panel:IsShown())
panel.mouseOver = false; outside.scripts.OnEvent(outside, 'GLOBAL_MOUSE_DOWN'); assert(not panel:IsShown())
''')
print('PASS: native micro artwork, enlarged controls, HUD preservation, actions, Settings route, wrapping and touch dismissal')

