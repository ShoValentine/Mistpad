local _, M = ...
local B={states=setmetatable({}, {__mode="k"}),notes={}}
M.BlizzFrameScaling=B
B.defaults=M.WindowScaleDefaults
B.windows={
    {id="contacts",label="Contacts",frames={"FriendsFrame"}},
    {id="character",label="Character",frames={"CharacterFrame"}},
    {id="professions",label="Professions",frames={"ProfessionsFrame","TradeSkillFrame","ProfessionsBookFrame"}},
    {id="spells",label="Spells and Talents",frames={"PlayerSpellsFrame","ClassTalentFrame","SpellBookFrame"}},
    {id="achievements",label="Achievements",frames={"AchievementFrame"}},
    {id="quests",label="Quests",frames={"WorldMapFrame"}},
    {id="guild",label="Guild and Communities",frames={"CommunitiesFrame","GuildFrame"}},
    {id="group",label="Group Finder",frames={"PVEFrame"}},
    {id="collections",label="Collections",frames={"CollectionsJournal"}},
    {id="guide",label="Adventure Guide",frames={"EncounterJournal"}},
}
function B:Get(id)
    return self.defaults[id] or 100
end
function B:ApplyFrame(frame,state)
    if InCombatLockdown() then self.pending=true;return "Queued until combat ends" end
    if frame.IsForbidden and frame:IsForbidden() then return "Blizzard does not permit access to this window" end
    -- Some clients retain both modern and legacy globals. Scale only the outer
    -- window when two aliases refer to nested frames, avoiding double scaling.
    local parent=frame:GetParent()
    for _=1,20 do
        if not parent then break end
        local ancestor=self.states[parent]
        if ancestor and ancestor.id==state.id then return "Uses its parent window scale" end
        parent=parent:GetParent()
    end
    local owner=M.nativeDragFrames and M.nativeDragFrames[frame]
    if owner and (owner.dragging or owner.snapping) then self.pending=true;return "Applies after the gesture finishes" end
    -- Side gestures already applied this preference before their first frame,
    -- then fitted it to the viewport. Preserve that scale until they close.
    if owner and owner.saved then return "Applied before the side gesture" end
    local percent=self:Get(state.id)
    if percent==100 and not state.changed then return "100% (native size)" end
    if not state.changed then state.base=frame:GetScale() end
    local scale=state.base*percent/100
    if state.id=="spells" then
        -- Native PlayerSpells is a large, responsive window. Its early-load
        -- scale is not necessarily the screen-fitted scale used when shown.
        -- Keep the fixed preference inside the viewport, including bottom tabs.
        local parentRatio=frame:GetParent():GetEffectiveScale()/UIParent:GetEffectiveScale()
        scale=math.min(scale,
            math.max(1,UIParent:GetWidth()-48)/(math.max(1,frame:GetWidth())*parentRatio),
            math.max(1,UIParent:GetHeight()-80)/(math.max(1,frame:GetHeight())*parentRatio))
    end
    local ok,message=pcall(frame.SetScale,frame,scale)
    if not ok then return "Blizzard refused scaling: "..tostring(message) end
    state.changed=percent~=100
    if owner and owner.saved and frame:IsShown() then
        owner.ratio=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
        owner.travel=frame:GetWidth()*owner.ratio-32+24;owner.distance=owner.travel
        if owner.RefreshMapRightOutset then owner:RefreshMapRightOutset() end
        owner:UpdateRestingPosition()
    end
    return percent.."% applied"
end
function B:Apply(id)
    if not M.db then return end
    if InCombatLockdown() then
        self.pending=true
        for _,window in ipairs(self.windows) do if not id or window.id==id then self.notes[window.id]="Queued until combat ends" end end
        return
    end
    for _,window in ipairs(self.windows) do
        if not id or id==window.id then
            local found=false
            for _,name in ipairs(window.frames) do
                local frame=_G[name]
                if frame and frame.SetScale and not (frame.IsForbidden and frame:IsForbidden()) then
                    found=true
                    local state=self.states[frame]
                    if not state then
                        state={id=window.id,base=frame:GetScale()};self.states[frame]=state
                        frame:HookScript("OnShow",function()
                            if state.scheduled then return end
                            state.scheduled=true
                            C_Timer.After(0,function()
                                state.scheduled=false
                                if M.ready and frame:IsShown() then B:Apply(state.id) end
                            end)
                        end)
                        if window.id=="spells" then
                            frame:HookScript("OnSizeChanged",function()
                                if state.scheduled then return end
                                state.scheduled=true
                                C_Timer.After(0,function()
                                    state.scheduled=false
                                    if M.ready and frame:IsShown() then B:Apply(state.id) end
                                end)
                            end)
                        end
                    end
                end
            end
            self.notes[window.id]=found and "Open the native window to preview" or "Saved; open the native window to load it"
            -- Register all aliases before applying so ancestor detection works.
            for _,name in ipairs(window.frames) do
                local frame=_G[name];local state=frame and self.states[frame]
                if state then self.notes[window.id]=self:ApplyFrame(frame,state) end
            end
        end
    end
    if (not id or id=="spells") and M.TalentScaling then M.TalentScaling:Schedule() end
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","ADDON_LOADED","PLAYER_REGEN_ENABLED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function()
    if M.ready then B.pending=false;B:Apply() end
end)
