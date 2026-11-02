local _, M = ...
function M:CreateMenu()
    local panel = self:CreatePanel("MistpadMenu", nil, 600, 192)
    self.Menu = panel
    panel:SetClampedToScreen(false)
    local buttons = {}
    panel.buttons = buttons
    local PEEK, OPEN_Y = 32, -24
    local function SetInteractive(enabled)
        panel:EnableMouse(enabled)
        for _, button in ipairs(buttons) do button:EnableMouse(enabled) end
    end
    function panel:Refresh()
        self.entries = M:GetMicroMenuEntries()
        local width = UIParent.GetWidth and UIParent:GetWidth() or 1280
        local count = math.max(1, #self.entries)
        local rowWidth = count * 88 - 4
        -- Always keep one row. Scale tiles uniformly to fit narrower screens,
        -- retaining the artwork's proportions and the full set of buttons.
        local tileScale = math.min(1, math.max(1, width - 96) / rowWidth)
        self:SetSize(math.max(240, rowWidth * tileScale + 48), 24 + 168 * tileScale)
        for _, button in ipairs(buttons) do button:Hide() end
        for index, entry in ipairs(self.entries) do
            local button = buttons[index]
            if not button then
                button = CreateFrame("Button", nil, self)
                button:SetSize(84, 168)
                button:RegisterForClicks("LeftButtonUp")
                M:CreateMicroArtwork(button)
                local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                label:SetPoint("BOTTOM", 0, 8); label:SetWidth(84); label:SetHeight(32)
                label:SetWordWrap(true)
                if label.SetNonSpaceWrap then label:SetNonSpaceWrap(true) end
                label:SetJustifyH("CENTER")
                label:SetJustifyV("TOP")
                button.label = label
                button:SetScript("OnMouseDown", function(self)
                    self.pressed = true; self:UpdateArtwork(self.entry.source)
                end)
                button:SetScript("OnMouseUp", function(self)
                    self.pressed = false; self:UpdateArtwork(self.entry.source)
                end)
                button:SetScript("OnEnter", function(self)
                    self.hovered = true; self:UpdateArtwork(self.entry.source)
                    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
                    GameTooltip:SetText(self.entry.contacts and "Contacts" or self.entry.source.disabledTooltip or self.entry.source.tooltipText or self.entry.label)
                    GameTooltip:Show()
                end)
                button:SetScript("OnLeave", function(self)
                    self.hovered = false; self.pressed = false
                    self:UpdateArtwork(self.entry.source); GameTooltip:Hide()
                end)
                button:SetScript("OnClick", function(self)
                    if panel.dragging or panel.opening or not M:CanChange() or (not self.entry.contacts and not self.entry.source:IsEnabled()) then return end
                    panel:Hide()
                    M:ActivateMicroEntry(self.entry, self)
                end)
                buttons[index] = button
            end
            button.entry = entry
            button.pressed, button.hovered = false, false
            button.label:SetText(entry.label)
            local inset = (self:GetWidth() - rowWidth * tileScale) / 2
            button:SetScale(tileScale)
            button:ClearAllPoints(); button:SetPoint("TOPLEFT", self, "TOPLEFT", inset / tileScale + (index - 1) * 88, -12 / tileScale)
            button:UpdateArtwork(entry.source)
            button:Show()
        end
    end
    function panel:BeginDrag()
        if self:IsShown() then return false end
        if M.CancelPanelClosing then M:CancelPanelClosing("TOP") end
        self:Refresh()
        M:CancelSlide(self)
        self.dragging = true
        self.dragY = self:GetHeight() - PEEK
        SetInteractive(false)
        self:ClearAllPoints(); self:SetPoint("TOP", UIParent, "TOP", 0, self.dragY)
        self:Show()
        return true
    end
    function panel:UpdateDrag(distance)
        if not self.dragging then return end
        self.dragY = math.max(OPEN_Y, self:GetHeight() - PEEK - math.max(0, distance))
        self:ClearAllPoints(); self:SetPoint("TOP", UIParent, "TOP", 0, self.dragY)
    end
    function panel:EndDrag(open)
        if not self.dragging then return end
        self.dragging = false
        self.opening, self.retracting = open, not open
        local target = open and OPEN_Y or self:GetHeight() + 8
        M:Slide(self, "TOP", 0, target, 0, self.dragY - target, function()
            self.opening = false
            if open then SetInteractive(true) else self:Hide() end
        end)
    end
    panel:HookScript("OnHide", function()
        panel.dragging, panel.opening, panel.retracting = false, false, false
        SetInteractive(true)
        GameTooltip:Hide()
    end)
    local hide = panel.Hide
    panel.Hide = function(self, ...)
        if self:IsShown() and not self.dragging and not self.retracting and M.AnimatePanelClosing then
            local ok, message = pcall(M.AnimatePanelClosing, M, self, "TOP")
            if not ok then M:CancelPanelClosing("TOP"); M:Print("Menu close animation failed: " .. tostring(message)) end
        end
        return hide(self, ...)
    end
    function panel:Toggle()
        if self:IsShown() then self:Hide(); return end
        if M.CancelPanelClosing then M:CancelPanelClosing("TOP") end
        self:Refresh()
        self.opening = true
        SetInteractive(false)
        self:Show()
        M:Slide(self, "TOP", 0, OPEN_Y, 0, self:GetHeight() + 32, function()
            self.opening = false; SetInteractive(true)
        end)
    end
    local elapsed = 0
    panel:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed < 0.2 then return end
        elapsed = 0
        for _, button in ipairs(buttons) do
            if button:IsShown() then button:UpdateArtwork(button.entry.source) end
        end
    end)
    panel:Refresh()
end
