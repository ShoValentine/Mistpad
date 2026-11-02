local _, M = ...
local controllers = {}
M.nativeDragFrames = {}
local PEEK, MARGIN = 32, 24

local function Capture(frame)
    local state = {scale = frame:GetScale(), clamp = frame:IsClampedToScreen(), points = {}}
    for i = 1, frame:GetNumPoints() do state.points[i] = {frame:GetPoint(i)} end
    return state
end

local function Restore(controller)
    local frame, saved = controller.frame, controller.saved
    if not saved or InCombatLockdown() then return end
    controller.saved = nil
    M:CancelSlide(frame)
    frame:SetScale(saved.scale)
    frame:SetClampedToScreen(saved.clamp)
    frame:ClearAllPoints()
    for _, point in ipairs(saved.points) do frame:SetPoint(unpack(point)) end
    if saved.close then saved.close:SetShown(saved.closeShown) end
    M.nativeDragFrames[frame] = nil
end

function M:CloseSidePanels()
    if InCombatLockdown() then return end
    for side, controller in pairs(controllers) do
        if side ~= "BOTTOM" and controller.saved and controller.frame:IsShown() then controller.close(controller.frame) end
    end
end

local outside = CreateFrame("Frame")
outside:RegisterEvent("GLOBAL_MOUSE_DOWN")
outside:SetScript("OnEvent", function()
    if InCombatLockdown() then return end
    if M.IsScalingPanelMouseOver and M:IsScalingPanelMouseOver() then return end
    for side, controller in pairs(controllers) do
        if side ~= "BOTTOM" and controller.saved and controller.frame:IsShown()
            and not controller.dragging and not controller.snapping and not controller.frame:IsMouseOver() then
            controller.close(controller.frame)
        end
    end
end)

function M:FreezeNativeDrags()
    for _, controller in pairs(controllers) do
        if controller.saved and (controller.dragging or controller.snapping) then
            self:CancelSlide(controller.frame)
            controller.dragging, controller.snapping = false, true
        end
    end
end

function M:ResetNativeDrags()
    for _, controller in pairs(controllers) do
        if controller.saved then
            if controller.dragging or controller.snapping then
                controller.dragging, controller.snapping = false, false
                self:CancelSlide(controller.frame)
                controller.shield:Hide()
                controller.close(controller.frame)
            end
            if not controller.frame:IsShown() then Restore(controller) end
        end
    end
end

function M:GetGesturePanel(side)
    if side == "TOP" then return self.Menu end
    if controllers[side] then return controllers[side] end
    local controller = {side = side}
    controllers[side] = controller

    function controller:BeginDrag(targetOverride)
        if InCombatLockdown() then return false end
        local frame
        if self.side == "BOTTOM" then
            if not M.db.inventory then
                M:Print("Enable Inventory presentation with /mistpad inventory first.")
                return false
            end
            M:InstallInventory()
            frame = ContainerFrameCombinedBags
            local manager = ContainerFrameSettingsManager
            if not frame or not manager or not manager:IsUsingCombinedBags() then
                M:Print("Enable Blizzard's combined bags option to drag Inventory.")
                return false
            end
            if frame:IsShown() then return false end
            -- Suppress the ordinary bag opening animation before Blizzard shows it.
            M.nativeDragFrames[frame] = self
            OpenAllBags()
            self.close = function() CloseAllBags() end
        else
            local target = targetOverride or M:GetSidePanelTarget(self.side)
            frame = M:ResolveSidePanelFrame(target)
            if frame and frame:IsShown() then return false end
            target.open()
            frame = M:ResolveSidePanelFrame(target)
            self.close = target.custom and function(f) f:Hide() end or function(f) HideUIPanel(f) end
        end
        if not frame or not frame:IsShown() then
            if frame then M.nativeDragFrames[frame] = nil end
            return false
        end
        self.frame = frame
        M:CancelSlide(frame)
        if self.side~="BOTTOM" then
            -- Finish the window's layout and fixed sizing synchronously, before
            -- recording its scale or calculating the gesture's travel distance.
            if frame==PlayerSpellsFrame and M.PlayerSpellsTouch then M.PlayerSpellsTouch:Apply() end
            if M.BlizzFrameScaling then M.BlizzFrameScaling:Apply() end
            if frame==PlayerSpellsFrame and M.TalentScaling then M.TalentScaling:Apply() end
        end
        self.saved = Capture(frame)
        if self.side ~= "BOTTOM" then
            local close = frame.CloseButton or (frame.GetCloseButton and frame:GetCloseButton())
            if close then self.saved.close = close; self.saved.closeShown = close:IsShown(); close:Hide() end
            if not frame.mistpadSideHideHook then
                local hide = frame.Hide
                frame.Hide = function(f, ...)
                    local owner = M.nativeDragFrames[f]
                    if owner and owner.side ~= "BOTTOM" and not owner.dragging and not owner.retracting
                        and f:IsShown() and M.AnimatePanelClosing then
                        local ok, message = pcall(M.AnimatePanelClosing, M, f, owner.side)
                        if not ok then
                            M:CancelPanelClosing(owner.side)
                            M:Print("Side panel close animation failed: " .. tostring(message))
                        end
                    end
                    return hide(f, ...)
                end
                frame.mistpadSideHideHook = true
            end
        end
        M.nativeDragFrames[frame] = self
        self.shields = self.shields or {}
        self.shield = self.shields[frame]
        if not self.shield then
            self.shield = CreateFrame("Frame", nil, frame)
            local shield = self.shield
            self.shields[frame] = shield
            self.shield:SetAllPoints(frame)
            self.shield:EnableMouse(true)
            self.shield:EnableMouseWheel(true)
            self.shield:SetScript("OnMouseWheel", function() end)
            frame:HookScript("OnHide", function()
                shield:Hide()
                if self.frame ~= frame then return end
                self.dragging, self.snapping = false, false
                self.retracting = false
                M:CancelSlide(frame)
                Restore(self)
            end)
        end
        self.shield:SetFrameLevel(frame:GetFrameLevel() + 1000)
        self.shield:Show()
        local width, height = math.max(1, frame:GetWidth()), math.max(1, frame:GetHeight())
        -- Work in UIParent units even when the native frame has a scaled parent.
        local parentRatio = frame:GetParent():GetEffectiveScale() / UIParent:GetEffectiveScale()
        local desired = self.side == "BOTTOM" and (not M.inventoryUsesLayout and 1.45 or 1)
            or self.saved.scale*parentRatio
        self.ratio = math.min(desired,
            (UIParent:GetWidth() - MARGIN * 2) / width,
            (UIParent:GetHeight() - MARGIN * 2) / height)
        frame:SetScale(self.ratio / parentRatio)
        self:RefreshMapRightOutset()
        frame:SetClampedToScreen(false)
        self.distance = 0
        self.travel = (self.side == "BOTTOM" and height or width) * self.ratio - PEEK + MARGIN
        self.dragging = true
        self:UpdateDrag(0)
        return true
    end

    function controller:RefreshMapRightOutset()
        self.mapRightOutset=nil
        if self.side~="RIGHT" or self.frame~=WorldMapFrame then return end
        local ratio=self.ratio
        local protrusion=24*ratio
        -- The ordinary resting position is 24 units beyond the screen edge.
        self.mapRightOutset=MARGIN+protrusion+4
    end

    function controller:Position(distance)
        local ratio = self.ratio
        local closed = self.travel - MARGIN
        local offset = (closed - distance) / ratio
        local point = self.side
        local x = self.side == "LEFT" and -offset or self.side == "RIGHT" and offset or 0
        local y = self.side == "BOTTOM" and -offset or 0
        if self.side == "RIGHT" and self.mapRightOutset then
            local progress=math.max(0,math.min(1,distance/math.max(1,self.travel)))
            x=x-self.mapRightOutset*progress/ratio
        end
        if self.side == "BOTTOM" and M.inventoryUsesLayout and M.BagLayout then
            point, x = M.BagLayout.Anchor(M.db, ratio)
        end
        return point, x, y
    end

    function controller:UpdateDrag(distance)
        if not self.dragging then return end
        self.distance = math.max(0, math.min(self.travel, distance))
        local point, x, y = self:Position(self.distance)
        self.frame:ClearAllPoints()
        self.frame:SetPoint(point, UIParent, point, x, y)
    end

    function controller:UpdateRestingPosition()
        if self.dragging or self.snapping then return end
        M:CancelSlide(self.frame)
        local point, x, y = self:Position(self.distance)
        self.frame:ClearAllPoints(); self.frame:SetPoint(point, UIParent, point, x, y)
    end

    function controller:EndDrag(open)
        if not self.dragging then return end
        self.dragging = false
        if InCombatLockdown() then
            self.snapping = true -- Cleanup is deferred until combat ends.
            return
        end
        local point, fromX, fromY = self:Position(self.distance)
        local _, x, y = self:Position(open and self.travel or -PEEK - 8)
        self.snapping = true
        self.retracting = not open
        M:Slide(self.frame, point, x, y, fromX - x, fromY - y, function()
            self.snapping = false
            self.shield:Hide()
            if not open then self.close(self.frame) end
            if open and M.BlizzFrameScaling then M.BlizzFrameScaling:Apply() end
        end)
    end
    return controller
end
