local _, M = ...
local P={states=setmetatable({}, {__mode="k"})}
M.TalentPages=P
function P:Enabled() return M.TalentDefaults.pages end
function P:Restore(state)
    if InCombatLockdown() then state.restorePending=true;return end
    state.active=false
    for object,shown in pairs(state.hidden) do object:SetShown(shown) end
    state.hidden={}
    if state.bar then state.bar:Hide() end
    local frame=state.frame
    frame:SetBasePanOffset(state.baseX,state.baseY)
    frame:UpdateAllTalentButtonPositions();frame:UpdateAllGatePositions()
    state.restorePending=false
end
function P:Visibility(state,object,visible)
    if not object then return end
    if not visible then
        if state.hidden[object]==nil then state.hidden[object]=object:IsShown() end
        object:Hide()
    elseif state.hidden[object]~=nil then
        object:SetShown(state.hidden[object]);state.hidden[object]=nil
    end
end
function P:Install(frame)
    local state=self.states[frame]
    if state then return state end
    if not frame.EnumerateAllTalentButtons or not frame.GetNodeCost or not frame.SetBasePanOffset
        or not frame.UpdateAllTalentButtonPositions or not frame.UpdateAllGatePositions then return end
    state={frame=frame,hidden={},baseX=frame.basePanOffsetX or 0,baseY=frame.basePanOffsetY or 0}
    self.states[frame]=state
    state.getExtents=frame.GetPanExtents
    frame.GetPanExtents=function(self,...)
        if state.active and state.bounds then
            local b=state.bounds;local zoom=math.max(.01,self:GetZoomLevel())
            local nodeSize=self.GetButtonSize and self:GetButtonSize() or 40
            return math.max(0,(b.maxX-b.minX)/10+80/zoom-self.ButtonsParent:GetWidth()),
                math.max(0,(b.maxY-b.minY)/10+86/zoom+nodeSize-self.ButtonsParent:GetHeight())
        end
        return state.getExtents(self,...)
    end
    local bar=CreateFrame("Frame",nil,frame);state.bar=bar
    bar:SetSize(372,46);bar:SetPoint("TOP",frame.ButtonsParent,"TOP",0,-5)
    bar:SetFrameLevel(frame.ButtonsParent:GetFrameLevel()+30)
    state.buttons={}
    for i,page in ipairs({"class","spec"}) do
        local button=CreateFrame("Button",nil,bar,"UIPanelButtonTemplate")
        button:SetSize(180,40);button:SetPoint("LEFT",(i-1)*188,0);state.buttons[page]=button
        button:SetScript("OnClick",function()
            if not M:CanChange() then return end
            local settings=M.TalentScaling:Settings();settings.page=page
            frame.panOffsetX,frame.panOffsetY=0,0
            M.TalentScaling:Apply()
        end)
    end
    frame:HookScript("OnHide",function() P:Restore(state) end)
    if frame.UpdateAllButtons then hooksecurefunc(frame,"UpdateAllButtons",function() if state.active then M.TalentScaling:Schedule() end end) end
    return state
end
function P:Apply(frame)
    if InCombatLockdown() then return end
    local state=self:Install(frame)
    if not state then return end
    if frame.IsInspecting and frame:IsInspecting() then
        if state.active then self:Restore(state) end
        return
    end
    if not self:Enabled() then
        if state.active then self:Restore(state);frame:SetPanOffset(0,0) end
        return
    end
    local currency=frame.treeCurrencyInfo or {}
    local classID=currency[1] and currency[1].traitCurrencyID
    local specID=currency[2] and currency[2].traitCurrencyID
    if not classID or not specID then if state.active then self:Restore(state) end;return end
    local nodes,byButton={},{}
    local classMax,specMin
    for button in frame:EnumerateAllTalentButtons() do
        local info=button:GetNodeInfo()
        if info and info.posX and info.posY and (button:IsShown() or state.hidden[button]==true) then
            local group
            for _,cost in ipairs(frame:GetNodeCost(info.ID or button:GetNodeID()) or {}) do
                if cost.ID==classID then group="class";break elseif cost.ID==specID then group="spec";break end
            end
            if group=="class" then classMax=math.max(classMax or info.posX,info.posX)
            elseif group=="spec" then specMin=math.min(specMin or info.posX,info.posX) end
            local node={button=button,info=info,group=group};nodes[#nodes+1]=node;byButton[button]=node
        end
    end
    if #nodes==0 or not classMax or not specMin then return end
    local split=(classMax+specMin)/2
    local page=M.TalentScaling:Settings().page=="spec" and "spec" or "class"
    local bounds
    for _,node in ipairs(nodes) do
        node.group=node.group or (node.info.posX<split and "class" or "spec")
        local selected=node.group==page
        self:Visibility(state,node.button,selected)
        if selected then
            if not bounds then bounds={minX=node.info.posX,maxX=node.info.posX,minY=node.info.posY,maxY=node.info.posY}
            else
                bounds.minX=math.min(bounds.minX,node.info.posX);bounds.maxX=math.max(bounds.maxX,node.info.posX)
                bounds.minY=math.min(bounds.minY,node.info.posY);bounds.maxY=math.max(bounds.maxY,node.info.posY)
            end
        end
    end
    if not bounds then return end
    state.bounds=bounds;state.active=true
    if frame.edgePool then
        for edge in frame.edgePool:EnumerateActive() do
            local first=edge.GetStartButton and byButton[edge:GetStartButton()]
            local last=edge.GetEndButton and byButton[edge:GetEndButton()]
            if first and last then self:Visibility(state,edge,first.group==page and last.group==page) end
        end
    end
    if frame.gatePool then
        for gate in frame.gatePool:EnumerateActive() do
            local anchor=gate.GetAnchorButton and byButton[gate:GetAnchorButton()]
            if anchor then self:Visibility(state,gate,anchor.group==page) end
        end
    end
    self:Visibility(state,frame.ClassCurrencyDisplay,false);self:Visibility(state,frame.SpecCurrencyDisplay,false)
    self:Visibility(state,frame.HeroTalentsContainer,page=="spec")
    if frame.SelectionChoiceFrame then frame.SelectionChoiceFrame:Hide() end
    local zoom=math.max(.01,frame:GetZoomLevel())
    local contentWidth=(bounds.maxX-bounds.minX)/10+80/zoom
    local viewport=frame.ButtonsParent:GetWidth()
    local x=contentWidth<=viewport and (bounds.minX+bounds.maxX)/20-viewport/2 or bounds.minX/10-40/zoom
    -- Node coordinates describe their centres. Reserve the page selector's
    -- height, a visible gap, and half the enlarged first node above its centre.
    local nodeSize=frame.GetButtonSize and frame:GetButtonSize() or 40
    local topSpace=46+20+nodeSize*zoom/2
    local changed=state.page~=page or state.zoom~=zoom or state.viewport~=viewport
    if changed then state.centerCorrection=0 end
    frame:SetBasePanOffset(x+(state.centerCorrection or 0),bounds.minY/10-topSpace/zoom)
    frame:UpdateAllTalentButtonPositions();frame:UpdateAllGatePositions()
    local panWidth=frame:GetPanExtents()
    frame:SetPanOffset(changed and panWidth/2 or (frame.panOffsetX or 0),frame.panOffsetY or 0)
    state.page,state.zoom,state.viewport=page,zoom,viewport
    if changed then
        C_Timer.After(0,function()
            if InCombatLockdown() or not frame:IsShown() or not state.active or state.page~=page or state.zoom~=zoom then return end
            local left,right
            for _,node in ipairs(nodes) do
                if node.group==page and node.button:IsShown() then
                    local l,r=node.button:GetLeft(),node.button:GetRight()
                    if l and r then
                        local scale=node.button:GetEffectiveScale()
                        left=math.min(left or l*scale,l*scale);right=math.max(right or r*scale,r*scale)
                    end
                end
            end
            local parent=frame.ButtonsParent;local l,r=parent:GetLeft(),parent:GetRight()
            if not left or not l or not r then return end
            local scale=parent:GetEffectiveScale()
            local correction=((left+right)/2-(l+r)*scale/2)/scale
            if math.abs(correction)<1 then return end
            state.centerCorrection=(state.centerCorrection or 0)+correction
            frame:SetBasePanOffset(frame.basePanOffsetX+correction,frame.basePanOffsetY)
            frame:UpdateAllTalentButtonPositions();frame:UpdateAllGatePositions()
        end)
    end
    state.buttons.class:SetText(UnitClass("player") or "Class")
    local spec=GetSpecialization and GetSpecialization()
    local specName=spec and select(2,GetSpecializationInfo(spec)) or "Specialization"
    state.buttons.spec:SetText(specName)
    state.buttons.class:SetEnabled(page~="class");state.buttons.spec:SetEnabled(page~="spec")
    state.bar:Show()
end
local events=CreateFrame("Frame");events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent",function()
    for _,state in pairs(P.states) do if state.restorePending then P:Restore(state) end end
    if M.ready then M.TalentScaling:Schedule() end
end)
