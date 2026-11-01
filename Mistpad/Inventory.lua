local _, M = ...
local original, scroll, content, options, scrollbar
local changing, touch
local itemStates, widgetStates, reagentButtons = {}, {}, {}
local pointer = CreateFrame("Frame")
pointer:Hide()

local function Capture(frame)
    local state = {parent = frame:GetParent(), scale = frame:GetScale(), width = frame:GetWidth(),
        height = frame:GetHeight(), points = {}, clamp = frame.IsClampedToScreen and frame:IsClampedToScreen()}
    for i = 1, frame:GetNumPoints() do state.points[i] = {frame:GetPoint(i)} end
    return state
end

local function Restore(frame, state)
    frame:SetParent(state.parent)
    frame:SetScale(state.scale)
    frame:SetSize(state.width, state.height)
    frame:ClearAllPoints()
    for _, point in ipairs(state.points) do frame:SetPoint(unpack(point)) end
end

local function SetScroll(value)
    if not scroll then return end
    local range = math.max(0, content:GetHeight() - scroll:GetHeight())
    value = math.max(0, math.min(range, value))
    scroll:SetVerticalScroll(value)
    scrollbar:SetMinMaxValues(0, range)
    if not changing then
        changing = true
        scrollbar:SetValue(value)
        changing = false
    end
    scrollbar:SetShown(range > 0)
end

local function StopTouch()
    touch = nil
    pointer:Hide()
end

local function BeginTouch(button, mouseButton)
    if M.IsContextOpeningTouch and M:IsContextOpeningTouch(button) then return end
    if button then button.mistpadScrolled = false; button.mistpadContextOpen = false end
    if mouseButton ~= "LeftButton" or InCombatLockdown() or not M.db.inventory then return end
    if button and not button.mistpadItemEnabled then return end
    if CursorHasItem() or IsModifiedClick() then return end
    if M.HideItemContext then M:HideItemContext() end
    local x, y = GetCursorPosition()
    touch = {button = button, x = x, y = y, offset = scroll:GetVerticalScroll(), time = GetTime()}
    pointer:Show()
end

pointer:SetScript("OnUpdate", function()
    if not touch then pointer:Hide(); return end
    if InCombatLockdown() or not scroll:IsShown() or not M.db.inventory then StopTouch(); return end
    local x, y = GetCursorPosition()
    local delta = (y - touch.y) / scroll:GetEffectiveScale()
    local sideways = math.abs(x - touch.x) / scroll:GetEffectiveScale()
    if not IsMouseButtonDown("LeftButton") then StopTouch(); return end
    if math.max(math.abs(delta), sideways) > 10 and not touch.moved then
        if touch.button and GetTime() - touch.time >= 0.45 then
            local button = touch.button
            local saved = itemStates[button]
            StopTouch()
            if saved.drag then saved.drag(button, "LeftButton") end
            return
        end
        touch.moved = true
        if touch.button then touch.button.mistpadScrolled = true end
        GameTooltip:Hide()
    end
    if touch.moved then SetScroll(touch.offset + delta) end
    if touch.button and not touch.moved and GetTime() - touch.time >= (M.db.holdTime or 1.5) then
        local button = touch.button
        button.mistpadScrolled = true
        button.mistpadContextOpen = true
        StopTouch()
        M:ShowItemContext(button)
    end
end)

local function AdaptItem(button)
    local saved = itemStates[button]
    if not saved then
        saved = Capture(button)
        saved.click, saved.drag = button:GetScript("OnClick"), button:GetScript("OnDragStart")
        itemStates[button] = saved
    end
    if button.mistpadItemEnabled then return end
    button.mistpadItemEnabled = true
    if not button.mistpadTouchHook then
        button.mistpadTouchHook = true
        button:HookScript("OnMouseDown", BeginTouch)
    end
    button:SetScript("OnDragStart", function(self, mouseButton)
        if self.mistpadContextOpen then return end
        if not self.mistpadItemEnabled or not touch or touch.button ~= self then
            if saved.drag then saved.drag(self, mouseButton) end
        elseif GetTime() - touch.time >= 0.45 and not touch.moved then
            StopTouch()
            if saved.drag then saved.drag(self, mouseButton) end
        end
        -- A quick drag is consumed by the scroll tracker, rather than picking up an item.
    end)
    button:SetScript("OnClick", function(self, mouseButton)
        if self.mistpadContextOpen then self.mistpadScrolled = false; return end
        -- The release event can arrive before the next polling tick on a fast swipe.
        if touch and touch.button == self then
            local x, y = GetCursorPosition()
            local delta = (y - touch.y) / scroll:GetEffectiveScale()
            local sideways = math.abs(x - touch.x) / scroll:GetEffectiveScale()
            if math.max(math.abs(delta), sideways) > 10 then
                self.mistpadScrolled = true
                SetScroll(touch.offset + delta)
            end
            StopTouch()
        end
        if self.mistpadScrolled then self.mistpadScrolled = false; return end
        if saved.click then saved.click(self, mouseButton) end
    end)
end

local function SaveWidget(widget)
    if widget and not widgetStates[widget] then
        widgetStates[widget] = Capture(widget)
        widgetStates[widget].shown = widget:IsShown()
    end
end

local function CreateControls(frame)
    scroll = CreateFrame("ScrollFrame", nil, frame)
    scroll:SetPoint("TOPLEFT", 16, -106)
    scroll:SetPoint("BOTTOMRIGHT", -16, 42)
    scroll:EnableMouse(true)
    scroll:EnableMouseWheel(true)
    content = CreateFrame("Frame", nil, scroll)
    -- Pooled native buttons may be initialized again while parented to this canvas.
    content.IsCombinedBagContainer = function() return true end
    scroll:SetScrollChild(content)
    scroll:SetScript("OnMouseDown", function(_, button) BeginTouch(nil, button) end)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        if M.HideItemContext then M:HideItemContext() end
        SetScroll(scroll:GetVerticalScroll() - delta * (M.bagLayout and M.bagLayout.pitch or 52))
    end)
    scrollbar = CreateFrame("Slider", nil, frame, "UIPanelScrollBarTemplate")
    scrollbar:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 11, -16)
    scrollbar:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 11, 16)
    scrollbar:SetValueStep(1)
    scrollbar:SetScript("OnValueChanged", function(_, value)
        if not changing then
            if M.HideItemContext then M:HideItemContext() end
            SetScroll(value)
        end
    end)
    options = M:CreateBagOptions(function()
        if M.HideItemContext then M:HideItemContext() end
        M:RefreshInventory()
        SetScroll(0)
    end)
    M.BagOptions = options
end

function M:CloseInventory()
    if not self:CanChange() then return end
    StopTouch()
    if self.HideItemContext then self:HideItemContext() end
    CloseAllBags()
end

function M:RestoreInventory()
    if not original or InCombatLockdown() then return end
    changing = true
    StopTouch()
    if self.HideItemContext then self:HideItemContext() end
    for button, saved in pairs(itemStates) do
        if button.mistpadItemEnabled then
            button.mistpadItemEnabled = false
            button:SetScript("OnClick", saved.click)
            button:SetScript("OnDragStart", saved.drag)
            Restore(button, saved)
        end
    end
    itemStates = {}
    for widget, saved in pairs(widgetStates) do
        Restore(widget, saved)
        if saved.shown ~= nil then widget:SetShown(saved.shown) end
    end
    widgetStates = {}
    for _, button in ipairs(reagentButtons) do button:Hide() end
    if self.reagentFrameState then
        local reagent = self.reagentFrameState
        reagent.frame:SetAlpha(reagent.alpha)
        reagent.frame:EnableMouse(reagent.mouse)
        for child, enabled in pairs(reagent.children) do child:EnableMouse(enabled) end
        self.reagentFrameState = nil
    end
    local frame = self.inventoryFrame
    self:CancelSlide(frame)
    Restore(frame, original)
    frame:SetClampedToScreen(original.clamp)
    original = nil
    self.inventoryUsesLayout = false
    scroll:Hide(); scrollbar:Hide()
    frame:UpdateFrameSize()
    frame:UpdateItemLayout()
    changing = false
end

function M:RefreshInventory(animate)
    local frame = self.inventoryFrame
    if not frame or changing or InCombatLockdown() then return end
    if not self.db.inventory then self:RestoreInventory(); return end
    if not frame:IsShown() then self:RestoreInventory(); return end
    changing = true
    if not original then original = Capture(frame) end
    self.inventoryUsesLayout = true
    scroll:Show()
    local close = frame.CloseButton or (frame.GetCloseButton and frame:GetCloseButton())
    if close then SaveWidget(close); close:Hide() end
    local items = {}
    for _, button in frame:EnumerateValidItems() do items[#items + 1] = button end
    -- Retail keeps the reagent bag separate. Add its real slot buttons to this grid.
    local reagentBag = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag or 5
    local reagentSlots = C_Container.GetContainerNumSlots(reagentBag)
    local activeReagents = {}
    for slot = 1, reagentSlots do
        local button = reagentButtons[slot]
        if not button then
            button = CreateFrame("ItemButton", nil, content, "ContainerFrameItemButtonTemplate")
            reagentButtons[slot] = button
        end
        button:Initialize(reagentBag, slot)
        activeReagents[#activeReagents + 1] = button
        items[#items + 1] = button
    end
    for slot = reagentSlots + 1, #reagentButtons do reagentButtons[slot]:Hide() end
    local visibleItems = {}
    for _, button in ipairs(items) do
        AdaptItem(button)
        button:SetParent(content)
        if not self.db.dynamicContents or C_Container.GetContainerItemInfo(button:GetBagID(), button:GetID()) then
            visibleItems[#visibleItems + 1] = button
        else button:Hide() end
    end
    items = visibleItems
    table.sort(items, function(a, b)
        if a:GetBagID() == b:GetBagID() then return a:GetID() < b:GetID() end
        return a:GetBagID() < b:GetBagID()
    end)
    local manager = ContainerFrameSettingsManager
    local tokens = manager and manager.GetTokenTrackerIfShown and manager:GetTokenTrackerIfShown(frame)
    local layout = self.BagLayout.Calculate(self.db.bagSize, UIParent:GetWidth(), UIParent:GetHeight(),
        #items, tokens and tokens:GetHeight() or 0, self.db)
    self.bagLayout = layout
    frame:SetScale(UIParent:GetEffectiveScale() / frame:GetParent():GetEffectiveScale())
    frame:SetSize(layout.width, layout.height)
    if frame.SetTitle then frame:SetTitle(BAGS or "Bags") end
    if frame.TitleContainer then
        SaveWidget(frame.TitleContainer)
        frame.TitleContainer:ClearAllPoints()
        frame.TitleContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 62, -8)
        frame.TitleContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -8)
        frame.TitleContainer:SetHeight(28)
    end
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT", layout.padding, -layout.header)
    scroll:SetPoint("BOTTOMRIGHT", -layout.padding, layout.footer)
    content:SetSize(math.max(1, layout.contentWidth), math.max(1, layout.contentHeight))
    for index, button in ipairs(items) do
        AdaptItem(button)
        button:SetParent(content)
        local base = itemStates[button]
        local scale = layout.cell / base.width
        button:SetSize(base.width, base.height)
        button:SetScale(scale)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", content, "TOPLEFT", (index - 1) % layout.columns * layout.pitch / scale,
            -math.floor((index - 1) / layout.columns) * layout.pitch / scale)
        button:Show()
    end
    if #activeReagents > 0 then
        ContainerFrameMixin.UpdateItems({EnumerateValidItems = function() return ipairs(activeReagents) end})
    end
    local search = BagItemSearchBox
    if search and search:GetParent() == frame then
        SaveWidget(search)
        search:ClearAllPoints(); search:SetPoint("TOPLEFT", 18, -64)
        search:SetWidth(layout.width - 50)
        search:SetHeight(26)
        search:SetShown(self.db.searchBar and true or false)
        if not self.db.searchBar and search:GetText() ~= "" then search:SetText("") end
    end
    local sort = BagItemAutoSortButton
    if sort and sort:GetParent() == frame then
        SaveWidget(sort)
        sort:ClearAllPoints(); sort:SetPoint("BOTTOMLEFT", 18, 7)
        sort:SetSize(28, 28)
    end
    SetScroll(scroll:GetVerticalScroll())
    if not (self.nativeDragFrames and self.nativeDragFrames[frame]) then
        self:CancelSlide(frame)
        frame:SetClampedToScreen(false)
        local anchor, x = self.BagLayout.Anchor(self.db)
        if animate then self:Slide(frame, anchor, x, 24, 0, -layout.height)
        else frame:ClearAllPoints(); frame:SetPoint(anchor, UIParent, anchor, x, 24) end
    end
    changing = false
end

function M:InstallInventory()
    if self.inventoryFrame or InCombatLockdown() then return end
    local frame = ContainerFrameCombinedBags
    if not frame then return end
    self.inventoryFrame = frame
    CreateControls(frame)
    frame:HookScript("OnShow", function()
        if M.CancelBagClosing then M:CancelBagClosing() end
        M:RefreshInventory(true)
    end)
    frame:HookScript("OnHide", function()
        StopTouch(); M:CancelSlide(frame)
        M:RestoreInventory()
    end)
    for _, method in ipairs({"UpdateItemLayout", "UpdateFrameSize", "UpdateSearchBox"}) do
        if type(frame[method]) == "function" then
            hooksecurefunc(frame, method, function() M:RefreshInventory() end)
        end
    end
    if type(UpdateContainerFrameAnchors) == "function" then
        hooksecurefunc("UpdateContainerFrameAnchors", function() M:RefreshInventory() end)
    end
    local events = CreateFrame("Frame")
    for _, event in ipairs({"BAG_UPDATE_DELAYED", "ITEM_LOCK_CHANGED", "BAG_UPDATE_COOLDOWN",
        "INVENTORY_SEARCH_UPDATE", "PLAYER_MONEY", "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED", "GLOBAL_MOUSE_DOWN"}) do
        events:RegisterEvent(event)
    end
    events:SetScript("OnEvent", function(_, event)
        if event == "GLOBAL_MOUSE_DOWN" then
            if not InCombatLockdown() and M.inventoryUsesLayout and frame:IsShown() and not frame:IsMouseOver()
                and not (options:IsShown() and options:IsMouseOver())
                and not (M.IsItemContextMouseOver and M:IsItemContextMouseOver()) then
                local drag = M.nativeDragFrames and M.nativeDragFrames[frame]
                if not drag or not (drag.dragging or drag.snapping) then M:CloseInventory() end
            end
            return
        end
        if (event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED") and M.HideItemContext then M:HideItemContext() end
        if event == "BAG_UPDATE_DELAYED" then StopTouch() end
        if event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" then SetScroll(0) end
        M:RefreshInventory()
    end)
    local nativeHide = frame.Hide
    frame.Hide = function(self, ...)
        if M.inventoryUsesLayout and self:IsShown() and M.AnimateBagClosing then
            local ok, message = pcall(M.AnimateBagClosing, M, self)
            if not ok then
                if M.CancelBagClosing then M:CancelBagClosing() end
                M:Print("Close animation failed: " .. tostring(message))
            end
        end
        return nativeHide(self, ...)
    end
    -- Keep the native reagent window logically open for Blizzard's bag-key toggle,
    -- but render its contents only in the unified grid.
    local reagent = ContainerFrame6
    if reagent then
        reagent:HookScript("OnShow", function()
            if M.db.inventory and frame:IsShown() and not InCombatLockdown() then
                if not M.reagentFrameState then
                    M.reagentFrameState = {frame = reagent, alpha = reagent:GetAlpha(),
                        mouse = reagent:IsMouseEnabled(), children = {}}
                end
                local function BlockChildren(parent)
                    if not parent.GetChildren then return end
                    for _, child in ipairs({parent:GetChildren()}) do
                        if M.reagentFrameState.children[child] == nil then
                            M.reagentFrameState.children[child] = child:IsMouseEnabled()
                        end
                        child:EnableMouse(false)
                        BlockChildren(child)
                    end
                end
                BlockChildren(reagent)
                reagent:SetAlpha(0); reagent:EnableMouse(false)
            end
        end)
    end
    self:RefreshInventory()
end


