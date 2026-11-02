local _, M = ...
local function Micro(name)
    return function() M:OpenMicroWindow(name) end
end
M.SidePanelOrder={"character","professions","spells","achievements","quests","housing","guild","group","collections","guide","contacts","map"}
M.SidePanelTargets = {
    character = {label="Character",frame="CharacterFrame",open=function() ToggleCharacter("PaperDollFrame") end},
    professions = {label="Professions",frames={"ProfessionsBookFrame","ProfessionsFrame","TradeSkillFrame"},open=Micro("ProfessionMicroButton")},
    spells = {label="Spells & Talents",frames={"PlayerSpellsFrame","ClassTalentFrame","SpellBookFrame"},open=Micro("PlayerSpellsMicroButton")},
    achievements = {label="Achievements",frame="AchievementFrame",open=Micro("AchievementMicroButton")},
    quests = {label="Quest Journal",frame="WorldMapFrame",open=function() ToggleQuestLog() end},
    housing = {label="Housing",frame="HousingDashboardFrame",open=Micro("HousingMicroButton")},
    guild = {label="Guild & Communities",frames={"CommunitiesFrame","GuildFrame"},open=Micro("GuildMicroButton")},
    group = {label="Group Finder",frame="PVEFrame",open=Micro("LFDMicroButton")},
    collections = {label="Collections",frame="CollectionsJournal",open=Micro("CollectionsMicroButton")},
    guide = {label="Adventure Guide",frame="EncounterJournal",open=Micro("EJMicroButton")},
    contacts = {label="Contacts",frame="FriendsFrame",open=function() ToggleFriendsFrame(1) end},
    map = {label="World Map",frame="WorldMapFrame",open=function() ToggleWorldMap() end},
}
function M:ResolveSidePanelFrame(target)
    if target.frame then return _G[target.frame] end
    local first
    for _,name in ipairs(target.frames or {}) do
        local frame=_G[name]
        if frame then
            first=first or frame
            if frame:IsShown() then return frame end
        end
    end
    return first
end

function M:GetSidePanelTarget(side)
    local key = side == "LEFT" and "leftPanel" or "rightPanel"
    local value = self.db[key]
    if not self.SidePanelTargets[value] then value = side == "LEFT" and "character" or "quests" end
    return self.SidePanelTargets[value], value
end

function M:SetSidePanelTarget(side, value)
    if not self:CanChange() or not self.SidePanelTargets[value] then return end
    if self.CloseSidePanels then self:CloseSidePanels() end
    self.db[side == "LEFT" and "leftPanel" or "rightPanel"] = value
end

function M:ShowSidePanelSettings()
    if not self:CanChange() then return end
    if not self.SidePanelSettings then
        local panel=self:CreatePanel("MistpadSidePanelSettings","Side Panels",620,math.min(690,UIParent:GetHeight()-40))
        self.SidePanelSettings=panel
        panel.choices={}
        for index,side in ipairs({"LEFT","RIGHT"}) do
            local label=panel:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
            label:SetPoint("TOPLEFT",28+(index-1)*278,-58)
            label:SetText(side=="LEFT" and "Left Edge" or "Right Edge")
        end
        local scroll=CreateFrame("ScrollFrame",nil,panel,"UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",24,-88);scroll:SetPoint("BOTTOMRIGHT",-40,24)
        local content=CreateFrame("Frame",nil,scroll)
        content:SetSize(550,#M.SidePanelOrder*58);scroll:SetScrollChild(content)
        for row,value in ipairs(M.SidePanelOrder) do
            for column,side in ipairs({"LEFT","RIGHT"}) do
                local button=CreateFrame("Button",nil,content,"UIPanelButtonTemplate")
                button:SetSize(266,50);button:SetPoint("TOPLEFT",(column-1)*278,-(row-1)*58)
                button:SetText(M.SidePanelTargets[value].label)
                button:SetScript("OnClick",function()
                    M:SetSidePanelTarget(side,value);panel:Refresh()
                end)
                panel.choices[#panel.choices+1]={button=button,side=side,value=value}
            end
        end
        function panel:Refresh()
            for _,entry in ipairs(self.choices) do
                local _,selected=M:GetSidePanelTarget(entry.side)
                entry.button:SetEnabled(entry.value~=selected)
            end
        end
    end
    self.SidePanelSettings:Refresh()
    self.SidePanelSettings:ClearAllPoints();self.SidePanelSettings:SetPoint("CENTER")
    self.SidePanelSettings:Show()
end

function M:ToggleCharacterPanel()
    if not self.ready or not self:CanChange() then return end
    ToggleCharacter("PaperDollFrame")
end
