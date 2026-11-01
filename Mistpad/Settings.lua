local _, M = ...
function M:ShowMistpadSettings()
    if not self:CanChange() then return end
    if not self.SettingsPanel then
        local panel = self:CreatePanel("MistpadSettings", "Settings", 360, 314)
        self.SettingsPanel = panel
        local entries = {
            {"Bag Options", function() M:OpenBagOptions() end},
            {"Side Panels", function() M:ShowSidePanelSettings() end},
            {"Game Menu", function() ToggleGameMenu() end},
        }
        for index, entry in ipairs(entries) do
            local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
            button:SetSize(300, 58); button:SetPoint("TOP", 0, -66 - (index - 1) * 74)
            button:SetText(entry[1])
            button:GetFontString():SetFontObject(GameFontNormalLarge)
            button:SetScript("OnClick", function()
                if not M:CanChange() then return end
                panel:Hide(); entry[2]()
            end)
        end
    end
    self.SettingsPanel:ClearAllPoints(); self.SettingsPanel:SetPoint("CENTER")
    self.SettingsPanel:Show()
end
