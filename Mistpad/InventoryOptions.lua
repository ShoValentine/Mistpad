local _, M = ...
function M:CreateBagOptions(changed)
    local panel = CreateFrame("Frame", "MistpadBagOptions", UIParent, "BackdropTemplate")
    if UISpecialFrames then table.insert(UISpecialFrames, "MistpadBagOptions") end
    panel:SetSize(330, 586)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetFrameLevel(300)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24,
        insets = {left = 6, right = 6, top = 6, bottom = 6}})
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18); title:SetText("Bag Options")
    for i, size in ipairs({"small", "medium", "large"}) do
        local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        button:SetSize(94, 46)
        button:SetPoint("TOPLEFT", 18 + (i - 1) * 100, -50)
        button:SetText(size:sub(1, 1):upper() .. size:sub(2))
        button:SetScript("OnClick", function()
            if not M:CanChange() then return end
            M.db.bagSize = size
            changed()
        end)
    end
    local checks = {}
    local function Check(key, label, y)
        local button = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        button:SetSize(40, 40); button:SetPoint("TOPLEFT", 18, y)
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("LEFT", button, "RIGHT", 4, 0); text:SetText(label)
        button:SetHitRectInsets(0, -240, 0, 0)
        button:SetScript("OnClick", function(self)
            if not M:CanChange() then self:SetChecked(M.db[key]); return end
            M.db[key] = self:GetChecked() and true or false
            changed()
        end)
        checks[key] = button
    end
    Check("dynamicContents", "Dynamic Contents", -108)
    Check("searchBar", "Search Bar", -154)
    local sliders = {}
    local function Slider(key, label, low, high, step, y, format)
        local text = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("TOPLEFT", 22, y)
        local slider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
        slider:SetSize(276, 36); slider:SetPoint("TOPLEFT", 26, y - 24)
        slider:SetMinMaxValues(low, high); slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        if slider.Low then slider.Low:SetText(tostring(low)) end
        if slider.High then slider.High:SetText(tostring(high)) end
        slider:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value / step + 0.5) * step
            text:SetText(label .. ": " .. string.format(format, value))
            if panel.syncing or value == M.db[key] or not M:CanChange() then return end
            M.db[key] = value
            changed()
        end)
        sliders[key] = {widget = slider, label = text, name = label, format = format}
    end
    Slider("itemSize", "Item Size", 32, 80, 4, -216, "%d")
    Slider("holdTime", "Hold for menu", 0.5, 3, 0.25, -310, "%.2f seconds")
    Slider("maxRows", "Max Height (rows)", 1, 16, 1, -394, "%d")
    local anchorTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    anchorTitle:SetPoint("TOPLEFT", 22, -486); anchorTitle:SetText("Anchor")
    for i, anchor in ipairs({"left", "middle", "right"}) do
        local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        button:SetSize(94, 46); button:SetPoint("TOPLEFT", 18 + (i - 1) * 100, -516)
        button:SetText(anchor:sub(1, 1):upper() .. anchor:sub(2))
        button:SetScript("OnClick", function()
            if not M:CanChange() then return end
            M.db.bagAnchor = anchor
            changed()
        end)
    end
    panel:SetScript("OnShow", function()
        panel.syncing = true
        for key, button in pairs(checks) do button:SetChecked(M.db[key]) end
        for key, entry in pairs(sliders) do
            local value = M.db[key] or ({itemSize = 48, holdTime = 1.5, maxRows = 8})[key]
            entry.widget:SetValue(value)
            entry.label:SetText(entry.name .. ": " .. string.format(entry.format, value))
        end
        panel.syncing = false
    end)
    panel:Hide()
    local events = CreateFrame("Frame")
    events:RegisterEvent("GLOBAL_MOUSE_DOWN")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" or (panel:IsShown() and not panel:IsMouseOver()) then panel:Hide() end
    end)
    return panel
end

function M:OpenBagOptions()
    if not self:CanChange() then return end
    self:InstallInventory()
    if self.BagOptions then self.BagOptions:Show() end
end
