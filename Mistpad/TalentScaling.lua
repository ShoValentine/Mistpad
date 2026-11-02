local _, M = ...
local T={frames=setmetatable({}, {__mode="k"})}
M.TalentScaling=T
function T:Settings()
    M.db.talentCanvas=type(M.db.talentCanvas)=="table" and M.db.talentCanvas or {}
    return M.db.talentCanvas
end
function T:Get() return M.TalentDefaults.scale end
function T:Scrollable() return M.TalentDefaults.scroll end
function T:UpdateStatus(message)
    self.status=message
end
function T:Scroll(frame,dx,dy)
    if InCombatLockdown() then return end
    local zoom=math.max(.01,frame:GetZoomLevel())
    frame:AdjustPanOffset(dx/zoom,dy/zoom)
end
function T:CreateNavigation(frame)
    local pad=CreateFrame("Frame",nil,frame)
    pad:SetSize(180,38);pad:SetPoint("BOTTOMRIGHT",frame.ButtonsParent,"BOTTOMRIGHT",-8,8)
    pad:SetFrameLevel(frame.ButtonsParent:GetFrameLevel()+20)
    for index,direction in ipairs({"Left","Up","Down","Right"}) do
        local b=CreateFrame("Button",nil,pad)
        b:SetSize(34,34);b:SetPoint("LEFT",(index-1)*36,0)
        local up=direction~="Down"
        local path="Interface\\Buttons\\UI-ScrollBar-Scroll"..(up and "Up" or "Down").."Button-"
        b:SetNormalTexture(path.."Up");b:SetPushedTexture(path.."Down");b:SetDisabledTexture(path.."Disabled")
        b:SetHighlightTexture(path.."Highlight","ADD")
        local rotation=direction=="Left" and math.pi/2 or direction=="Right" and -math.pi/2 or 0
        if rotation~=0 then
            for _,getter in ipairs({"GetNormalTexture","GetPushedTexture","GetDisabledTexture","GetHighlightTexture"}) do
                local texture=b[getter](b);if texture then texture:SetRotation(rotation) end
            end
        end
        b:SetScript("OnClick",function()
            T:Scroll(frame,direction=="Left" and -110 or direction=="Right" and 110 or 0,
                direction=="Up" and -110 or direction=="Down" and 110 or 0)
        end)
    end
    local home=CreateFrame("Button",nil,pad,"UIPanelButtonTemplate")
    home:SetSize(34,34);home:SetPoint("LEFT",144,0);home:SetText("0")
    home:SetScript("OnClick",function() if not InCombatLockdown() then frame:SetPanOffset(0,0) end end)
    pad:SetScript("OnEnter",function()
        GameTooltip:SetOwner(pad,"ANCHOR_TOP");GameTooltip:SetText("Talent scrolling")
        GameTooltip:AddLine("Wheel: vertical. Shift-wheel: horizontal. Drag empty tree space to pan.",1,1,1,true);GameTooltip:Show()
    end)
    pad:SetScript("OnLeave",function() GameTooltip:Hide() end)
    return pad
end
function T:ApplyFrame(frame,state)
    if not frame:IsShown() then return end
    if InCombatLockdown() then self.pending=true;return end
    if not frame:GetTreeInfoOrLayoutDefaults() then return end
    local oldWidth,oldHeight=frame:GetPanExtents()
    local x=oldWidth>0 and (frame.panOffsetX or 0)/oldWidth or 0
    local y=oldHeight>0 and (frame.panOffsetY or 0)/oldHeight or 0
    frame:SetZoomLevelInternal(self:Get()/100)
    local width,height=frame:GetPanExtents()
    frame:SetPanOffset(width*x,height*y)
    local parent=frame.ButtonsParent
    if self:Scrollable() then
        parent:EnableMouse(true);parent:EnableMouseWheel(true)
        parent:SetScript("OnMouseDown",function()
            if not InCombatLockdown() and parent.StartPanning then parent:StartPanning() end
        end)
        parent:SetScript("OnMouseWheel",function(_,delta)
            if InCombatLockdown() then return end
            if IsShiftKeyDown() then T:Scroll(frame,-delta*90,0)
            else T:Scroll(frame,0,-delta*90) end
        end)
        local update=state.scripts.OnUpdate or (TalentFrameBaseButtonsParentMixin and TalentFrameBaseButtonsParentMixin.OnUpdate)
        parent:SetScript("OnUpdate",function(self,elapsed)
            if not InCombatLockdown() and update then update(self,elapsed) end
        end)
        if state.pad then state.pad:Hide() end
    else
        if parent.StopPanning then parent:StopPanning() end
        for _,script in ipairs({"OnUpdate","OnMouseDown","OnMouseWheel"}) do parent:SetScript(script,state.scripts[script]) end
        parent:EnableMouse(state.mouse);parent:EnableMouseWheel(state.wheel)
        if state.pad then state.pad:Hide() end
    end
    self:LayoutFooter(frame,state)
    if M.TalentPages then M.TalentPages:Apply(frame) end
end
function T:LayoutFooter(frame,state)
    if InCombatLockdown() then return end
    state.footer=state.footer or setmetatable({}, {__mode="k"})
    local function Scale(control,factor)
        if not control then return end
        if not state.footer[control] then state.footer[control]=control:GetScale() end
        control:SetScale(state.footer[control]*factor)
        return control:GetScale()
    end
    local root=PlayerSpellsFrame or ClassTalentFrame
    if root and root.TabSystem then Scale(root.TabSystem,1.5) end
    local bar=frame.BottomBar
    if not bar then return end
    local width=frame:GetWidth()
    local factor=1.5
    local loadScale=Scale(frame.LoadSystem,factor)
    local searchScale=Scale(frame.SearchBox,factor)
    local applyScale=Scale(frame.ApplyButton,factor)
    Scale(frame.InspectCopyButton,factor)
    local resetScale=Scale(frame.ResetButton,factor)
    local undoScale=Scale(frame.UndoButton,factor)
    local loadWidth=frame.LoadSystem and frame.LoadSystem:GetWidth()*loadScale or 0
    local actionWidth=frame.ApplyButton and frame.ApplyButton:GetWidth()*applyScale or 246
    local resetWidth=math.max(frame.ResetButton and frame.ResetButton:GetWidth()*resetScale or 0,
        frame.UndoButton and frame.UndoButton:GetWidth()*undoScale or 0)
    local groupWidth=actionWidth+12+resetWidth
    if not state.actionGroup then state.actionGroup=CreateFrame("Frame",nil,frame);state.actionGroup:EnableMouse(false) end
    state.actionGroup:SetSize(groupWidth,48)
    state.actionGroup:ClearAllPoints();state.actionGroup:SetPoint("CENTER",bar,"CENTER",0,0)
    local searchWidth=math.min(250,math.max(90,(width-groupWidth)/2-loadWidth-60))
    if frame.LoadSystem then
        frame.LoadSystem:ClearAllPoints();frame.LoadSystem:SetPoint("LEFT",bar,"LEFT",24/loadScale,0)
    end
    if frame.SearchBox then
        frame.SearchBox:SetWidth(searchWidth/searchScale)
        frame.SearchBox:ClearAllPoints();frame.SearchBox:SetPoint("LEFT",bar,"LEFT",(24+loadWidth+16)/searchScale,0)
    end
    if frame.ApplyButton then
        frame.ApplyButton:SetHeight(42/applyScale)
        frame.ApplyButton:ClearAllPoints();frame.ApplyButton:SetPoint("LEFT",state.actionGroup,"LEFT",0,0)
    end
    if frame.InspectCopyButton and frame.ApplyButton then
        frame.InspectCopyButton:ClearAllPoints();frame.InspectCopyButton:SetPoint("CENTER",frame.ApplyButton,"CENTER",0,0)
    end
    if frame.ResetButton and frame.ApplyButton then
        frame.ResetButton:ClearAllPoints();frame.ResetButton:SetPoint("RIGHT",state.actionGroup,"RIGHT",0,0)
    end
    if frame.UndoButton then
        frame.UndoButton:ClearAllPoints();frame.UndoButton:SetPoint("RIGHT",state.actionGroup,"RIGHT",0,0)
    end
end
function T:Schedule()
    if self.scheduled then return end
    self.scheduled=true
    C_Timer.After(0,function() T.scheduled=false;if M.ready then T:Apply() end end)
end
function T:Install(frame)
    if not frame or not frame.ButtonsParent or not frame.SetZoomLevelInternal or not frame.GetPanExtents or not frame.GetZoomLevel
        or not frame.GetTreeInfoOrLayoutDefaults
        or not frame.AdjustPanOffset or not frame.SetPanOffset then return end
    if (frame.IsForbidden and frame:IsForbidden()) or (frame.ButtonsParent.IsForbidden and frame.ButtonsParent:IsForbidden()) then return end
    local state=self.frames[frame]
    if state then return state end
    local parent=frame.ButtonsParent
    state={scripts={},mouse=parent:IsMouseEnabled(),wheel=parent:IsMouseWheelEnabled()}
    for _,script in ipairs({"OnUpdate","OnMouseDown","OnMouseWheel"}) do state.scripts[script]=parent:GetScript(script) end
    self.frames[frame]=state
    frame:HookScript("OnShow",function() T:Schedule() end)
    frame:HookScript("OnHide",function() if state.pad then state.pad:Hide() end end)
    for _,method in ipairs({"LoadTalentTree","UpdateTreeInfo"}) do
        if frame[method] then hooksecurefunc(frame,method,function() T:Schedule() end) end
    end
    return state
end
function T:Apply()
    if not M.db then return end
    if InCombatLockdown() then self.pending=true;self:UpdateStatus("Queued until combat ends");return end
    self.pending=false
    local modern=PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
    local candidates={modern or false,ClassTalentFrame or false}
    local found,active=false,false
    for _,frame in ipairs(candidates) do
        if frame then
            local installed,state=pcall(self.Install,self,frame)
            if not installed then self:UpdateStatus("Talent controls unavailable: "..tostring(state));return end
            if state then
                found=true
                if frame:IsShown() then
                    active=true
                    local zoom=frame:GetZoomLevel()
                    local ok,message=pcall(self.ApplyFrame,self,frame,state)
                    if not ok then
                        -- Leave node purchase/commit handlers and data untouched.
                        for _,script in ipairs({"OnUpdate","OnMouseDown","OnMouseWheel"}) do frame.ButtonsParent:SetScript(script,state.scripts[script]) end
                        if state.pad then state.pad:Hide() end
                        if M.TalentPages and M.TalentPages.states[frame] then pcall(M.TalentPages.Restore,M.TalentPages,M.TalentPages.states[frame]) end
                        pcall(frame.SetZoomLevelInternal,frame,zoom)
                        self:UpdateStatus("Talent scaling unavailable: "..tostring(message));return
                    end
                end
            end
        end
    end
    self:UpdateStatus(active and (self:Get().."% canvas; "..(self:Scrollable() and "scrolling enabled" or "native navigation"))
        or found and "Open the Talents tab to preview" or "Open Spells and Talents to load the native tree")
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","ADDON_LOADED","PLAYER_REGEN_ENABLED","PLAYER_SPECIALIZATION_CHANGED","TRAIT_CONFIG_UPDATED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function() if M.ready then T:Schedule() end end)
