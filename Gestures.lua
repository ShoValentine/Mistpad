local _, M = ...
local edges = {}
local tracker = CreateFrame("Frame")
local current
local THRESHOLD, DEADZONE = 64, 12
tracker:Hide()

local function Stop(finished)
    if current then
        if not finished then current.panel:EndDrag(false) end
    end
    current = nil
    tracker:Hide()
end

function M:SetGesturesVisible(visible)
    Stop()
    for _, edge in ipairs(edges) do edge:SetShown(visible and not InCombatLockdown()) end
end

tracker:SetScript("OnUpdate", function()
    if not current then tracker:Hide(); return end
    if InCombatLockdown() or not M.db.gestures then Stop(); return end
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    local dx, dy = (x - current.x) / scale, (y - current.y) / scale
    local inward = (current.spec.vertical and dy or dx) * current.spec.sign
    local sideways = math.abs(current.spec.vertical and dx or dy)
    if inward < -DEADZONE or (sideways > DEADZONE and sideways > math.max(inward, DEADZONE) * 1.3) then
        current.cancelled = true
    end
    local armed = not current.cancelled and inward >= THRESHOLD and inward > sideways * 1.3
    if not current.panel.dragging then Stop(); return end
    current.panel:UpdateDrag(current.cancelled and 0 or inward)
    if not IsMouseButtonDown("LeftButton") then
        current.panel:EndDrag(armed)
        Stop(true)
    end
end)

function M:CreateGestures()
    local specs = {
        {side = "BOTTOM", vertical = true, sign = 1, label = "Inventory"},
        {side = "TOP", vertical = true, sign = -1, label = "Mistpad Menu"},
        {side = "LEFT", vertical = false, sign = 1, label = "Character"},
        {side = "RIGHT", vertical = false, sign = -1, label = "Quest Journal"},
    }
    for _, spec in ipairs(specs) do
        local edge = CreateFrame("Frame", nil, UIParent)
        -- Higher-strata HUD controls retain priority at overlapping screen edges.
        edge:SetFrameStrata("LOW")
        edge:EnableMouse(true)
        if spec.vertical then
            edge:SetHeight(64)
            edge:SetPoint(spec.side .. "LEFT", UIParent, spec.side .. "LEFT", 64, 0)
            edge:SetPoint(spec.side .. "RIGHT", UIParent, spec.side .. "RIGHT", -64, 0)
        else
            edge:SetWidth(64)
            edge:SetPoint("TOP" .. spec.side, UIParent, "TOP" .. spec.side, 0, -64)
            edge:SetPoint("BOTTOM" .. spec.side, UIParent, "BOTTOM" .. spec.side, 0, 64)
        end
        edge:SetScript("OnMouseDown", function(_, button)
            if button ~= "LeftButton" or InCombatLockdown() or current then return end
            local panel = M:GetGesturePanel(spec.side)
            if (spec.side == "LEFT" or spec.side == "RIGHT") and M.GetSidePanelTarget then
                local target = M:GetSidePanelTarget(spec.side)
                spec.label = target.label
            end
            if not panel:BeginDrag() then return end
            local x, y = GetCursorPosition()
            current = {edge = edge, spec = spec, panel = panel, x = x, y = y}
            tracker:Show()
        end)
        edge:SetScript("OnHide", function()
            if current and current.edge == edge then Stop() end
        end)
        edges[#edges + 1] = edge
    end
    self:SetGesturesVisible(self.db.gestures)
end
