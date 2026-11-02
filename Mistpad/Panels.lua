local _, M = ...
local motion = CreateFrame("Frame")
local active = {}
motion:Hide()
motion:SetScript("OnUpdate", function(_, elapsed)
    for frame, state in pairs(active) do
        state.time = math.min(state.time + elapsed, 0.22)
        local t = state.time / 0.22
        local eased = 1 - (1 - t) ^ 3
        frame:ClearAllPoints()
        frame:SetPoint(state.point, UIParent, state.point,
            state.x + state.dx * (1 - eased), state.y + state.dy * (1 - eased))
        if t == 1 then
            active[frame] = nil
            if state.complete then state.complete() end
        end
    end
    if not next(active) then motion:Hide() end
end)

function M:CancelSlide(frame)
    active[frame] = nil
end

function M:Slide(frame, point, x, y, dx, dy, complete)
    self:CancelSlide(frame)
    frame:ClearAllPoints()
    frame:SetPoint(point, UIParent, point, x, y)
    if not self.db.animation then
        if complete then complete() end
        return
    end
    frame:SetPoint(point, UIParent, point, x + dx, y + dy)
    active[frame] = {point = point, x = x, y = y, dx = dx, dy = dy, time = 0, complete = complete}
    motion:Show()
end

function M:CreatePanel(name, title, width, height)
    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetPoint("TOP", 0, -24)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true,
        tileSize = 32, edgeSize = 32, insets = {left = 10, right = 10, top = 10, bottom = 10}})
    if title then
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        label:SetPoint("TOP", 0, -25)
        label:SetText(title)
        frame.title = label
    end
    frame:SetScript("OnHide", function() M:CancelSlide(frame) end)
    local events = CreateFrame("Frame")
    events:RegisterEvent("GLOBAL_MOUSE_DOWN")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then frame:Hide()
        elseif frame:IsShown() and not frame.keepOpen and not frame.dragging and not frame.opening and not frame:IsMouseOver() then frame:Hide() end
    end)
    frame:Hide()
    table.insert(UISpecialFrames, name)
    return frame
end
