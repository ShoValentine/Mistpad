local _, M = ...
local U={originals=setmetatable({}, {__mode="k"}),installed=setmetatable({}, {__mode="k"})}
M.PlayerSpellsTouch=U
function U:Original(object)
    if not object then return end
    local old=self.originals[object]
    if not old then
        old={scale=object.GetScale and object:GetScale(),width=object.GetWidth and object:GetWidth(),height=object.GetHeight and object:GetHeight(),points={}}
        if object.GetFont then old.font,old.fontSize,old.flags=object:GetFont() end
        if object.GetNumPoints then for i=1,object:GetNumPoints() do old.points[i]={object:GetPoint(i)} end end
        self.originals[object]=old
    end
    return old
end
function U:Font(object,factor)
    local old=self:Original(object)
    if old and old.font and old.fontSize then object:SetFont(old.font,old.fontSize*factor,old.flags) end
end
function U:Scale(object,factor)
    local old=self:Original(object)
    if old and old.scale then
        object:SetScale(old.scale*factor)
        if #old.points>0 then
            object:ClearAllPoints()
            for _,point in ipairs(old.points) do object:SetPoint(point[1],point[2],point[3],(point[4] or 0)/factor,(point[5] or 0)/factor) end
        end
    end
end
function U:Specializations(frame)
    if not frame.SpecContentFramePool then return end
    for card in frame.SpecContentFramePool:EnumerateActive() do
        for _,key in ipairs({"Description","RoleName","ActivatedText"}) do self:Font(card[key],1.4) end
        self:Font(card.SampleAbilityText,1.25)
        local description=card.Description
        if description then description:SetWidth(math.max(180,card:GetWidth()-64)) end
        if card.RoleIcon then
            local old=self:Original(card.RoleIcon);card.RoleIcon:SetSize(old.width*1.35,old.height*1.35)
        end
        if card.RoleIcon and card.RoleName and card.SpecName then
            local width=card.RoleIcon:GetWidth()+8+card.RoleName:GetStringWidth()
            card.RoleIcon:ClearAllPoints();card.RoleIcon:SetPoint("TOP",card.SpecName,"BOTTOM",-width/2+card.RoleIcon:GetWidth()/2,-12)
            card.RoleName:ClearAllPoints();card.RoleName:SetPoint("LEFT",card.RoleIcon,"RIGHT",8,0)
        end
        if card.SampleAbilityText and description then
            card.SampleAbilityText:ClearAllPoints();card.SampleAbilityText:SetPoint("TOP",description,"BOTTOM",0,-34)
        end
        if card.SpellButtonPool then
            local index=0
            for button in card.SpellButtonPool:EnumerateActive() do
                index=index+1;self:Scale(button,1.5)
                local scale=button:GetScale();local width=button:GetWidth()*scale
                button:ClearAllPoints();button:SetPoint("TOP",card.SampleAbilityText,"BOTTOM",(index==1 and -1 or 1)*(width+16)/(2*scale),-14/scale)
            end
        end
        if card.ActivateButton then
            self:Scale(card.ActivateButton,1.5)
            local scale=card.ActivateButton:GetScale()
            card.ActivateButton:SetHeight(44/scale)
        end
    end
end
function U:Book(frame)
    local paged=frame.PagedSpellsFrame
    if not paged or not paged.ViewFrames or not paged.UpdateLayouts then return end
    self:Scale(frame.CategoryTabSystem,1.5)
    local state=self.installed[frame]
    if not state.grid then
        -- Scale each page's native contents, then shrink its logical layout
        -- dimensions to keep the same physical parchment area. Native pagination
        -- now fits fewer/larger rows and uses two columns instead of three.
        local factor=1.35
        for _,view in ipairs(paged.ViewFrames) do
            local old=self:Original(view)
            view:SetScale(old.scale*factor);view:SetSize(old.width/factor,old.height/factor)
            view:ClearAllPoints()
            for _,point in ipairs(old.points) do view:SetPoint(point[1],point[2],point[3],(point[4] or 0)/factor,(point[5] or 0)/factor) end
        end
        paged.columnsPerRow=2;state.grid=true
        paged:UpdateLayouts()
    end
    if paged.PagingControls then self:Scale(paged.PagingControls,1.5) end
end
function U:Schedule()
    if self.scheduled then return end
    self.scheduled=true
    C_Timer.After(0,function() U.scheduled=false;if M.ready then U:Apply() end end)
end
function U:Watch(frame,kind)
    if not frame then return end
    if not self.installed[frame] then
        self.installed[frame]={kind=kind}
        frame:HookScript("OnShow",function() U:Schedule() end)
        local methods=kind=="spec" and {"UpdateSpecContents"} or {"OnPagedSpellsUpdate","UpdateAttic"}
        for _,method in ipairs(methods) do
            if frame[method] then hooksecurefunc(frame,method,function() U:Schedule() end) end
        end
    end
    if not frame:IsShown() then return end
    local ok,message=pcall(function() if kind=="spec" then U:Specializations(frame) else U:Book(frame) end end)
    if not ok and message~=self.lastError then self.lastError=message;M:Print("Spells touch layout: "..tostring(message)) end
end
function U:Apply()
    if InCombatLockdown() then return end
    local root=PlayerSpellsFrame
    if not root then return end
    local ok,message=pcall(self.Header,self,root)
    if not ok and self.headerError~=message then self.headerError=message;M:Print("Spells title bar: "..tostring(message)) end
    self:Watch(root.SpecFrame,"spec");self:Watch(root.SpellBookFrame,"book")
end
function U:Header(root)
    local portrait=root.PortraitContainer and root.PortraitContainer.portrait
    local portraitBase=portrait and self:Original(portrait).width or 62
    local previousHeight=math.max(56,portraitBase)
    local closeSize=previousHeight-10
    local height=closeSize+12
    local extra=height-20
    local state=self.header
    if not state then
        self.header={root=root,nativeHeight=root:GetHeight()};state=self.header
    end
    -- Add room to the outer window, not subtract it from the bottom-anchored
    -- content frames. Native layout may reset the outer height on tab changes.
    local current=root:GetHeight()
    if state.lastHeight and math.abs(current-state.lastHeight)>.1 then state.nativeHeight=current end
    state.lastHeight=state.nativeHeight+extra
    if math.abs(current-state.lastHeight)>.1 then root:SetHeight(state.lastHeight) end
    if root.NineSlice then
        local slice=root.NineSlice
        if not state.plainLayout then
            NineSliceUtil.ApplyLayoutByName(slice,"ButtonFrameTemplateNoPortrait")
            state.plainLayout=true
        end
        -- Keep all nine native pieces in the same coordinate system. Scaling
        -- only top corners broke their joins with the unchanged side edges.
        local chromeScale=height/20
        slice:SetScale(chromeScale)
        -- The non-portrait layout's left edge sits inside the native content
        -- bounds at this scale. Extend only the chrome, in root-frame units.
        slice:ClearAllPoints();slice:SetPoint("TOPLEFT",root,"TOPLEFT",-16/chromeScale,0);slice:SetPoint("BOTTOMRIGHT",root,"BOTTOMRIGHT",0,0)
    end
    if root.PortraitContainer then root.PortraitContainer:Hide() end
    local title=root.TitleContainer
    if title then
        title:ClearAllPoints();title:SetHeight(height)
        title:SetPoint("TOPLEFT",root,"TOPLEFT",12,0);title:SetPoint("TOPRIGHT",root,"TOPRIGHT",-12,0)
        if title.TitleText then
            title.TitleText:ClearAllPoints();title.TitleText:SetPoint("CENTER",title,"CENTER",0,0)
            title.TitleText:SetFont(STANDARD_TEXT_FONT,23,"")
        end
    end
    local close=root.CloseButton or _G.PlayerSpellsFrameCloseButton
    if close then
        local old=self:Original(close);local scale=closeSize/math.max(1,old.width)
        close:SetScale(scale);close:SetFrameLevel(math.max(close:GetFrameLevel(),title and title:GetFrameLevel()+2 or root:GetFrameLevel()+600))
        if not state.closeSlot then
            state.closeSlot=CreateFrame("Frame",nil,root);state.closeSlot:EnableMouse(false)
        end
        state.closeSlot:SetSize(closeSize,closeSize)
        state.closeSlot:ClearAllPoints();state.closeSlot:SetPoint("TOPRIGHT",root,"TOPRIGHT",-7,-6)
        close:ClearAllPoints();close:SetPoint("CENTER",state.closeSlot,"CENTER",0,0)
        if root.MaximizeMinimizeButton then
            local toggle=root.MaximizeMinimizeButton;local base=self:Original(toggle)
            local s=(previousHeight-14)/math.max(1,base.height)
            toggle:SetScale(s)
            toggle:ClearAllPoints();toggle:SetPoint("RIGHT",close,"LEFT",-6,0)
        end
    end
    -- SpecFrame, TalentsFrame and SpellBookFrame retain their native dimensions.
end
function U:FinishSwipe()
    local touch=self.touch;self.touch=nil
    if not touch or InCombatLockdown() or not touch.book:IsShown() or GetCursorInfo() or GetTime()-touch.time>3 then return end
    local x,y=GetCursorPosition();local scale=UIParent:GetEffectiveScale()
    local dx,dy=x/scale-touch.x,y/scale-touch.y
    if math.abs(dx)<64 or math.abs(dx)<math.abs(dy)*1.5 then return end
    local paging=touch.book.PagedSpellsFrame.PagingControls
    if paging then if dx<0 then paging:NextPage() else paging:PreviousPage() end end
end
local function Under(object,parent)
    for _=1,30 do
        if not object then return false end
        if object==parent then return true end
        object=object.GetParent and object:GetParent()
    end
    return false
end
local swipe=CreateFrame("Frame")
for _,event in ipairs({"GLOBAL_MOUSE_DOWN","GLOBAL_MOUSE_UP","PLAYER_REGEN_DISABLED","PLAYER_LOGIN","ADDON_LOADED","PLAYER_REGEN_ENABLED"}) do swipe:RegisterEvent(event) end
swipe:SetScript("OnEvent",function(_,event,button)
    if event=="PLAYER_REGEN_DISABLED" then U.touch=nil;return end
    if event~="GLOBAL_MOUSE_DOWN" and event~="GLOBAL_MOUSE_UP" then if M.ready then U:Schedule() end;return end
    if InCombatLockdown() then return end
    if event=="GLOBAL_MOUSE_UP" then
        if U.touch and (not button or button=="LeftButton") then U:FinishSwipe() end
        return
    end
    if button~="LeftButton" then return end
    local book=PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame
    if not book or not book:IsShown() or not book.PagedSpellsFrame then U.touch=nil;return end
    local x,y=GetCursorPosition();local scale=UIParent:GetEffectiveScale();x,y=x/scale,y/scale
    if event=="GLOBAL_MOUSE_DOWN" then
        U.touch=nil
        if GetCursorInfo() or IsControlKeyDown() or IsShiftKeyDown() then return end
        local paged=book.PagedSpellsFrame
        local left,right,top,bottom=paged:GetLeft(),paged:GetRight(),paged:GetTop(),paged:GetBottom()
        if not left or not right or not top or not bottom then return end
        local ratio=paged:GetEffectiveScale()/UIParent:GetEffectiveScale()
        if x<left*ratio or x>right*ratio or y<bottom*ratio or y>top*ratio then return end
        local foci=GetMouseFoci and GetMouseFoci() or {GetMouseFocus and GetMouseFocus()}
        for _,focus in ipairs(foci) do
            -- Preserve native icon drag/cast and all ordinary UI buttons. Swipes
            -- begin on parchment, headers or non-interactive spell text.
            if Under(focus,PlayerSpellsFrame) or (#foci==1 and focus==UIParent) then
                local object=focus;local interactive=false
                while object and object~=PlayerSpellsFrame do
                    if object.IsObjectType and (object:IsObjectType("Button") or object:IsObjectType("EditBox")) then interactive=true;break end
                    object=object.GetParent and object:GetParent()
                end
                if not interactive then U.touch={x=x,y=y,time=GetTime(),book=book,sawHeld=IsMouseButtonDown("LeftButton")};break end
            end
        end
    end
end)
swipe:SetScript("OnUpdate",function()
    if not U.touch then return end
    if GetTime()-U.touch.time>3 then U.touch=nil;return end
    if IsMouseButtonDown("LeftButton") then U.touch.sawHeld=true
    elseif U.touch.sawHeld then U:FinishSwipe() end
end)
