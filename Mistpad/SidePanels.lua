local _, M = ...
M.SidePanelTargets = {
    character = {label = "Character", frame = "CharacterFrame", open = function() ToggleCharacter("PaperDollFrame") end},
    quests = {label = "Quest Journal", frame = "WorldMapFrame", open = function() ToggleQuestLog() end},
    map = {label = "World Map", frame = "WorldMapFrame", open = function() ToggleWorldMap() end},
}

function M:GetSidePanelTarget(side)
    local key = side == "LEFT" and "leftPanel" or "rightPanel"
    local value = self.db[key]
    if not self.SidePanelTargets[value] then value = side == "LEFT" and "character" or "quests" end
    return self.SidePanelTargets[value], value
end

function M:SetSidePanelTarget(side, value)
    if not self:CanChange() or not self.SidePanelTargets[value] then return end
    if self.CloseSidePanels then self:CloseSidePanels() end
    self.db[side == "LEFT" and "leftPanel" or "rightPanel"] = value
end

function M:ShowSidePanelSettings()
    if not self:CanChange() then return end
    if not self.SidePanelSettings then
        local panel = self:CreatePanel("MistpadSidePanelSettings", "Side Panels", 400, 286)
        self.SidePanelSettings = panel
        panel.choices = {}
        for index, side in ipairs({"LEFT", "RIGHT"}) do
            local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            label:SetPoint("TOPLEFT", 24, -64 - (index - 1) * 104)
            label:SetText(side == "LEFT" and "Left Edge" or "Right Edge")
            for column, value in ipairs({"character", "quests", "map"}) do
                local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
                button:SetSize(112, 50)
                button:SetPoint("TOPLEFT", 24 + (column - 1) * 120, -94 - (index - 1) * 104)
                button:SetText(value == "quests" and "Quests" or self.SidePanelTargets[value].label)
                button:SetScript("OnClick", function()
                    M:SetSidePanelTarget(side, value)
                    panel:Refresh()
                end)
                panel.choices[#panel.choices + 1] = {button = button, side = side, value = value}
            end
        end
        function panel:Refresh()
            for _, entry in ipairs(self.choices) do
                local _, selected = M:GetSidePanelTarget(entry.side)
                entry.button:SetEnabled(entry.value ~= selected)
            end
        end
    end
    self.SidePanelSettings:Refresh()
    self.SidePanelSettings:ClearAllPoints(); self.SidePanelSettings:SetPoint("CENTER")
    self.SidePanelSettings:Show()
end
