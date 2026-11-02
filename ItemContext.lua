local _, M = ...
local menu, splitPanel
local buttons = {}

function M:HideItemContext()
    if InCombatLockdown() then return end
    if menu then menu:Hide() end
    if splitPanel then splitPanel:Hide() end
end

function M:IsItemContextMouseOver()
    if menu and menu:IsShown() and menu:IsMouseOver() then return true end
    if splitPanel and splitPanel:IsShown() and splitPanel:IsMouseOver() then return true end
    local popup = StaticPopup_Visible and StaticPopup_Visible("MISTPAD_DROP_ITEM")
    return popup and popup:IsMouseOver() or false
end

function M:IsContextOpeningTouch(source)
    return menu and menu:IsShown() and menu.source == source and not menu.armed
end

local function Valid(item)
    if InCombatLockdown() or not M:IsCurrentItem(item) then
        M:Print("That item changed or is unavailable. Hold it again to refresh the menu.")
        return false
    end
    return true
end

local function Split(item)
    if not splitPanel then
        splitPanel = M:CreatePanel("MistpadSplitStack", "Split Stack", 360, 230)
        local amount = splitPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        amount:SetPoint("TOP", 0, -74)
        local slider = CreateFrame("Slider", nil, splitPanel, "OptionsSliderTemplate")
        slider:SetSize(230, 40); slider:SetPoint("TOP", 0, -104)
        slider:SetValueStep(1); slider:SetObeyStepOnDrag(true)
        slider:SetScript("OnValueChanged", function(_, value)
            splitPanel.amount = math.floor(value + 0.5)
            amount:SetText(tostring(splitPanel.amount))
        end)
        splitPanel.slider = slider
        for i, delta in ipairs({-1, 1}) do
            local step = CreateFrame("Button", nil, splitPanel, "UIPanelButtonTemplate")
            step:SetSize(44, 44); step:SetPoint("TOP", i == 1 and -140 or 140, -100)
            step:SetText(delta == -1 and "-" or "+")
            step:SetScript("OnClick", function()
                slider:SetValue(math.max(1, math.min(splitPanel.item.count - 1, splitPanel.amount + delta)))
            end)
        end
        local accept = CreateFrame("Button", nil, splitPanel, "UIPanelButtonTemplate")
        accept:SetSize(156, 48); accept:SetPoint("BOTTOM", 0, 24); accept:SetText("Split")
        accept:SetScript("OnClick", function()
            if not Valid(splitPanel.item) or CursorHasItem() then return end
            C_Container.SplitContainerItem(splitPanel.item.bag, splitPanel.item.slot, splitPanel.amount)
            splitPanel:Hide()
        end)
    end
    splitPanel.item = item
    splitPanel.slider:SetMinMaxValues(1, item.count - 1)
    splitPanel.slider:SetValue(1)
    splitPanel:ClearAllPoints(); splitPanel:SetPoint("CENTER")
    splitPanel:Show()
end

local function RunAction(action, item, source)
    if not Valid(item) then M:HideItemContext(); return end
    menu:Hide()
    if action.kind == "split" then Split(item)
    elseif action.kind == "compare" then
        GameTooltip:SetOwner(source, "ANCHOR_RIGHT")
        GameTooltip:SetBagItem(item.bag, item.slot)
        GameTooltip:Show()
        GameTooltip_ShowCompareItem(GameTooltip)
    elseif action.kind == "preview" then DressUpItemLink(item.link)
    elseif action.kind == "salvage" then
        C_TradeSkillUI.CraftSalvage(action.recipe, 1, item.location)
    elseif action.kind == "drop" then
        StaticPopup_Show("MISTPAD_DROP_ITEM", (item.link or tostring(item.id)) .. " ×" .. item.count, nil, item)
    end
end

local function CreateMenu()
    menu = CreateFrame("Frame", "MistpadItemContext", UIParent, "SecureHandlerStateTemplate,BackdropTemplate")
    menu:SetFrameStrata("DIALOG"); menu:SetFrameLevel(2000)
    menu:SetClampedToScreen(true); menu:EnableMouse(true)
    menu:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24,
        insets = {left = 6, right = 6, top = 6, bottom = 6}})
    menu.title = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    menu.title:SetPoint("TOPLEFT", 16, -16); menu.title:SetWidth(300)
    menu.title:SetHeight(20)
    menu:SetAttribute("_onstate-combat", "if newstate == '1' then self:Hide() end")
    RegisterStateDriver(menu, "combat", "[combat] 1; 0")
    local combat = CreateFrame("Frame")
    combat:RegisterEvent("PLAYER_REGEN_DISABLED")
    combat:RegisterEvent("GLOBAL_MOUSE_DOWN")
    combat:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            if splitPanel then splitPanel:Hide() end
        elseif menu:IsShown() and menu.armed and not menu:IsMouseOver() then menu:Hide() end
    end)
    table.insert(UISpecialFrames, "MistpadItemContext")
    menu:SetScript("OnUpdate", function()
        if not IsMouseButtonDown("LeftButton") then menu.armed = true end
        if not InCombatLockdown() and (not M:IsCurrentItem(menu.item)
            or not M.inventoryFrame or not M.inventoryFrame:IsShown()) then menu:Hide() end
    end)
    StaticPopupDialogs.MISTPAD_DROP_ITEM = {
        text = "Drop %s?\nThis permanently deletes the entire stack.", button1 = "Drop", button2 = CANCEL,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
        OnAccept = function(_, item)
            if not Valid(item) or CursorHasItem() then return end
            C_Container.PickupContainerItem(item.bag, item.slot)
            if CursorHasItem() then DeleteCursorItem() end
        end,
    }
    menu:Hide()
end

function M:ShowItemContext(source)
    if InCombatLockdown() then return end
    local item = self:SnapshotItem(source:GetBagID(), source:GetID())
    if not item or item.locked then return end
    if not menu then CreateMenu() end
    self:HideItemContext()
    local actions = self:GetItemActions(item)
    menu.item, menu.source, menu.armed = item, source, not IsMouseButtonDown("LeftButton")
    menu.title:SetText(item.link or "Item Actions")
    local columns = 2
    local rows = math.ceil(#actions / columns)
    menu:SetSize(336, 50 + rows * 56)
    for _, button in ipairs(buttons) do button:Hide() end
    for index = 1, #actions do
        local action = actions[index]
        local button = buttons[index]
        if not button then
            button = CreateFrame("Button", nil, menu, "SecureActionButtonTemplate,UIPanelButtonTemplate")
            button:RegisterForClicks("LeftButtonUp")
            button:SetAttribute("useOnKeyDown", false)
            button:SetSize(148, 48)
            buttons[index] = button
        end
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", 16 + ((index - 1) % columns) * 156, -44 - math.floor((index - 1) / columns) * 56)
        button:SetText(action.label)
        button:SetAttribute("type", nil); button:SetAttribute("spell", nil); button:SetAttribute("item", nil)
        button:SetAttribute("target-bag", nil); button:SetAttribute("target-slot", nil)
        if action.kind == "item" then
            button:SetAttribute("type", "item")
            button:SetAttribute("item", item.bag .. " " .. item.slot)
        elseif action.kind == "spell" then
            button:SetAttribute("type", "spell"); button:SetAttribute("spell", action.spell)
            button:SetAttribute("target-bag", item.bag); button:SetAttribute("target-slot", item.slot)
        end
        button:SetEnabled(not action.disabled)
        button:SetScript("OnEnter", function(self)
            if action.disabled then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(action.disabled); GameTooltip:Show()
            end
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        button:SetScript("PreClick", function(self)
            if not menu.armed or not Valid(item) then self:SetAttribute("type", nil)
            elseif action.kind == "item" or action.kind == "spell" then
                self:SetAttribute("type", action.kind)
            end
        end)
        -- Keep the template's secure OnClick intact. Non-secure work follows it.
        button:SetScript("PostClick", function()
            if not menu.armed or InCombatLockdown() then return end
            if action.kind == "item" or action.kind == "spell" or action.kind == "close" then menu:Hide()
            else RunAction(action, item, source) end
        end)
        button:Show()
    end
    menu:ClearAllPoints(); menu:SetPoint("TOPLEFT", source, "TOPRIGHT", 8, 0)
    local right = source.GetRight and source:GetRight()
    local top = source.GetTop and source:GetTop()
    if right and top then
        local ratio = source:GetEffectiveScale() / menu:GetEffectiveScale()
        menu:ClearAllPoints()
        menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", right * ratio + 8, top * ratio)
    end
    GameTooltip:Hide()
    menu:Show()
end
