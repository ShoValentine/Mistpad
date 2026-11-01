local addonName, M = ...
_G.Mistpad = M
M.name = addonName
M.modules = {}
BINDING_HEADER_MISTPAD = "Mistpad"
BINDING_NAME_MISTPAD_MENU = "Open Mistpad Menu"
BINDING_NAME_MISTPAD_INVENTORY = "Toggle Inventory"

function M:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffd9b668Mistpad:|r " .. message)
end

function M:CanChange()
    if InCombatLockdown() then
        self:Print("Window changes are available after combat.")
        return false
    end
    return true
end

function M:ToggleMenu()
    if not self.ready or not self:CanChange() then return end
    self.Menu:Toggle()
end

function M:ToggleInventory()
    if not self.ready or not self:CanChange() then return end
    if self.inventoryUsesLayout and self.inventoryFrame:IsShown() then self:CloseInventory(); return end
    ToggleAllBags()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        MistpadDB = type(MistpadDB) == "table" and MistpadDB or {}
        M.db = MistpadDB
        if M.db.inventory == nil then M.db.inventory = true end
        if M.db.gestures == nil then M.db.gestures = true end
        if M.db.animation == nil then M.db.animation = true end
        if M.db.bagSize ~= "small" and M.db.bagSize ~= "medium" and M.db.bagSize ~= "large" then
            M.db.bagSize = "medium"
        end
        if M.db.dynamicContents == nil then M.db.dynamicContents = false end
        if M.db.searchBar == nil then M.db.searchBar = false end
        M.db.itemSize = math.max(32, math.min(80, tonumber(M.db.itemSize) or 48))
        M.db.holdTime = math.max(0.5, math.min(3, tonumber(M.db.holdTime) or 1.5))
        M.db.maxRows = math.max(1, math.min(16, math.floor(tonumber(M.db.maxRows) or 8)))
        if M.db.bagAnchor ~= "left" and M.db.bagAnchor ~= "right" then M.db.bagAnchor = "middle" end
        if not M.SidePanelTargets[M.db.leftPanel] then M.db.leftPanel = "character" end
        if not M.SidePanelTargets[M.db.rightPanel] then M.db.rightPanel = "quests" end
        local loaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
        if loaded and loaded("WoWU") then
            M:Print("WoWU is enabled. Disable it and reload before using Mistpad.")
            return
        end
        M:CreateMenu()
        M:CreateGestures()
        M.ready = true
        M:InstallInventory()
        M:Print("Prototype ready. /mistpad opens the menu; /mistpad help lists options.")
    elseif M.ready then
        if event == "PLAYER_REGEN_DISABLED" then
            if M.inventoryFrame then M:CancelSlide(M.inventoryFrame) end
            if M.CancelBagClosing then M:CancelBagClosing() end
            if M.CancelPanelClosing then M:CancelPanelClosing("TOP") end
            if M.CancelPanelClosing then M:CancelPanelClosing("LEFT"); M:CancelPanelClosing("RIGHT") end
            M.Menu:Hide()
            M:SetGesturesVisible(false)
            M:FreezeNativeDrags()
        elseif event == "PLAYER_REGEN_ENABLED" then
            M:ResetNativeDrags()
            M:SetGesturesVisible(M.db.gestures)
            M:InstallInventory()
            M:RefreshInventory()
        elseif event == "ADDON_LOADED" then
            M:InstallInventory()
        end
    end
end)

SLASH_MISTPAD1 = "/mistpad"
SlashCmdList.MISTPAD = function(input)
    if not M.ready then M:Print("Not active. Check for WoWU and reload."); return end
    local command = strtrim(input or ""):lower()
    if command == "" then M:ToggleMenu()
    elseif command == "bags" then M:ToggleInventory()
    elseif command == "gestures" then
        if not M:CanChange() then return end
        M.db.gestures = not M.db.gestures
        M:SetGesturesVisible(M.db.gestures)
        M:Print("Edge gestures " .. (M.db.gestures and "enabled." or "disabled."))
    elseif command == "inventory" then
        if not M:CanChange() then return end
        M.db.inventory = not M.db.inventory
        M:RefreshInventory()
        M:Print("Inventory presentation " .. (M.db.inventory and "enabled." or "disabled; original bags restored."))
    elseif command == "animation" then
        M.db.animation = not M.db.animation
        M:Print("Animations " .. (M.db.animation and "enabled." or "disabled."))
    elseif command == "status" then
        local version, build, _, interface = GetBuildInfo()
        M:Print("Client " .. version .. " (" .. build .. "), interface " .. interface)
        M:Print("Inventory: " .. (M.inventoryFrame and "adapter available" or "original bags (no combined bag frame)"))
    else
        M:Print("/mistpad | bags | inventory (toggle) | gestures (toggle) | animation (toggle) | status")
    end
end
