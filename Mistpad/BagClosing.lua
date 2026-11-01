local _, M = ...
local states = {}

function M:CancelPanelClosing(edge)
    local state = states[edge]
    if state and state.ghost then self:CancelSlide(state.ghost); state.ghost:Hide() end
end

function M:CancelBagClosing()
    self:CancelPanelClosing("BOTTOM")
end

-- A visual-only copy lets Blizzard finish closing bags immediately (including
-- its keybind bookkeeping) while their last rendered contents slide offscreen.
function M:AnimateBagClosing(source)
    self:AnimatePanelClosing(source, "BOTTOM")
end

function M:AnimatePanelClosing(source, edge)
    if not self.db.animation or InCombatLockdown() or not source.GetRegions or not source:GetLeft() then return end
    self:CancelPanelClosing(edge)
    if not states[edge] then states[edge] = {frames = {}, textures = {}, fonts = {}} end
    local state = states[edge]
    local ghost, frames, textures, fonts = state.ghost, state.frames, state.textures, state.fonts
    if not ghost then
        ghost = CreateFrame("Frame", nil, UIParent)
        ghost:EnableMouse(false)
        state.ghost = ghost
    end
    for _, f in ipairs(frames) do f:Hide() end
    for _, t in ipairs(textures) do t:Hide() end
    for _, f in ipairs(fonts) do f:Hide() end
    local scale = source:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local left, bottom = source:GetLeft() * scale, source:GetBottom() * scale
    local top = bottom + source:GetHeight() * scale
    local height = source:GetHeight() * scale
    ghost:SetSize(source:GetWidth() * scale, height)
    ghost:SetFrameStrata(source:GetFrameStrata())
    ghost:SetFrameLevel(source:GetFrameLevel() + 1)
    ghost:SetAlpha(source:GetAlpha())
    local fi, ti, si = 0, 0, 0
    local function Position(copy, original, factor)
        local x, y = original:GetLeft(), original:GetTop()
        if not x or not y then return false end
        copy:ClearAllPoints()
        copy:SetSize(math.max(1, original:GetWidth() * factor), math.max(1, original:GetHeight() * factor))
        copy:SetPoint("TOPLEFT", ghost, "TOPLEFT", x * factor - left, y * factor - top)
        return true
    end
    local function Clone(original, parent, isRoot)
        if not isRoot and not original:IsShown() then return end
        fi = fi + 1
        local copy = frames[fi]
        if not copy then copy = CreateFrame("Frame", nil, parent); copy:EnableMouse(false); frames[fi] = copy end
        copy:SetParent(parent)
        local factor = original:GetEffectiveScale() / UIParent:GetEffectiveScale()
        if not Position(copy, original, factor) then return end
        copy:SetFrameLevel(ghost:GetFrameLevel() + math.max(0, original:GetFrameLevel() - source:GetFrameLevel()))
        copy:SetAlpha(isRoot and 1 or original:GetAlpha())
        copy:SetClipsChildren(original:IsObjectType("ScrollFrame"))
        copy:Show()
        for _, region in ipairs({original:GetRegions()}) do
            if region:IsShown() then
                local visual
                if region:IsObjectType("Texture") then
                    local atlas, texture = region:GetAtlas(), region:GetTexture()
                    if atlas or texture then
                        ti = ti + 1
                        visual = textures[ti]
                        if not visual then visual = copy:CreateTexture(); textures[ti] = visual end
                        visual:SetParent(copy)
                        if atlas then visual:SetAtlas(atlas) else visual:SetTexture(texture) end
                        visual:SetTexCoord(region:GetTexCoord())
                        visual:SetVertexColor(region:GetVertexColor())
                        visual:SetBlendMode(region:GetBlendMode())
                    end
                elseif region:IsObjectType("FontString") and region:GetText() then
                    si = si + 1
                    visual = fonts[si]
                    if not visual then visual = copy:CreateFontString(); fonts[si] = visual end
                    visual:SetParent(copy)
                    local file, size, flags = region:GetFont()
                    if file then visual:SetFont(file, size * factor, flags) end
                    visual:SetText(region:GetText())
                    visual:SetTextColor(region:GetTextColor())
                    visual:SetJustifyH(region:GetJustifyH()); visual:SetJustifyV(region:GetJustifyV())
                    visual:SetShadowColor(region:GetShadowColor())
                    local x, y = region:GetShadowOffset(); visual:SetShadowOffset(x * factor, y * factor)
                end
                if visual and Position(visual, region, factor) then
                    visual:SetDrawLayer(region:GetDrawLayer())
                    visual:SetAlpha(region:GetAlpha()); visual:Show()
                end
            end
        end
        for _, child in ipairs({original:GetChildren()}) do Clone(child, copy, false) end
    end
    Clone(source, ghost, true)
    ghost:Show()
    local target = edge == "TOP" and UIParent:GetHeight() + 8 or -height - 8
    local targetX, targetY = left, target
    if edge == "LEFT" then targetX, targetY = -source:GetWidth() * scale - 8, bottom
    elseif edge == "RIGHT" then targetX, targetY = UIParent:GetWidth() + 8, bottom end
    self:Slide(ghost, "BOTTOMLEFT", targetX, targetY, left - targetX, bottom - targetY, function() ghost:Hide() end)
end
