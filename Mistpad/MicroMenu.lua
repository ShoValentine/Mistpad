local _, M = ...
local definitions = {
    {"CharacterMicroButton", "CHARACTER_BUTTON", "Character"},
    {"ProfessionMicroButton", "PROFESSIONS_BUTTON", "Professions"},
    {"PlayerSpellsMicroButton", "PLAYERSPELLS_BUTTON", "Spells &\nTalents"},
    {"AchievementMicroButton", "ACHIEVEMENT_BUTTON", "Achievements"},
    {"QuestLogMicroButton", "QUESTLOG_BUTTON", "Quests"},
    {"HousingMicroButton", "HOUSING_MICRO_BUTTON", "Housing"},
    {"GuildMicroButton", "GUILD", "Guild &\nCommunities"},
    {"LFDMicroButton", "DUNGEONS_BUTTON", "Group Finder"},
    {"CollectionsMicroButton", "COLLECTIONS", "Collections"},
    {"EJMicroButton", "ADVENTURE_JOURNAL", "Adventure\nGuide"},
    {"HelpMicroButton", nil, "Contacts"},
    {"StoreMicroButton", "BLIZZARD_STORE", "Shop"},
    {"MainMenuMicroButton", nil, "Settings"},
}

function M:GetMicroMenuEntries()
    local entries, names = {}, {}
    for _, definition in ipairs(definitions) do names[definition[1]] = definition end
    local infos = MicroMenu and MicroMenu.GenerateButtonInfos and MicroMenu:GenerateButtonInfos()
    if not infos then
        infos = {}
        for _, definition in ipairs(definitions) do
            if _G[definition[1]] then infos[#infos + 1] = {button = _G[definition[1]]} end
        end
    end
    for _, info in ipairs(infos) do
        local source = info.button
        local blocked = info.gameRule and C_GameRules and C_GameRules.IsGameRuleActive(info.gameRule)
        if info.callback and info.callback() then blocked = true end
        if source and not blocked then
            local name = source:GetName()
            local definition = names[name]
            entries[#entries + 1] = {source = source, name = name,
                label = definition and definition[3] or source.tooltipText or name, contacts = name == "HelpMicroButton"}
        end
    end
    return entries
end

-- Copy native artwork into an independent canvas; never move or resize the HUD.
function M:CreateMicroArtwork(button)
    local clip = CreateFrame("Frame", nil, button)
    clip:SetSize(84, 136)
    clip:SetPoint("TOP", button, "TOP")
    clip:SetClipsChildren(true)
    clip:EnableMouse(false)
    button.artworkClip = clip
    local canvas = CreateFrame("Frame", nil, clip)
    button.artwork = canvas
    canvas:SetScale(2)
    canvas:SetSize(32, 40)
    canvas:SetPoint("CENTER", clip, "CENTER")
    canvas:EnableMouse(false)
    local glowFrame=CreateFrame("Frame",nil,clip)
    glowFrame:SetAllPoints(clip);glowFrame:EnableMouse(false)
    glowFrame:SetFrameLevel(canvas:GetFrameLevel()+1)
    local glow=glowFrame:CreateTexture(nil,"OVERLAY")
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD");glow:SetVertexColor(1,.8,.15,.85)
    glow:SetSize(104,112);glow:SetPoint("CENTER",clip,"CENTER")
    glow:Hide()
    local copies = {}
    local mask
    function button:UpdateArtwork(source)
        glow:SetShown(self.hovered and (self.entry and self.entry.contacts or source:IsEnabled()))
        if self.entry and self.entry.contacts then
            for _, copy in pairs(copies) do copy:Hide() end
            canvas:Hide()
            if not self.contactsIcon then
                self.contactsBackground=clip:CreateTexture(nil,"BACKGROUND")
                self.contactsBackground:SetSize(64,80)
                self.contactsBackground:SetPoint("CENTER",clip,"CENTER")
                self.contactsIcon=clip:CreateTexture(nil,"ARTWORK")
                self.contactsIcon:SetTexture("Interface\\FriendsFrame\\Battlenet-Portrait")
                self.contactsIcon:SetSize(56,56);self.contactsIcon:SetPoint("CENTER",clip,"CENTER",0,0)
            end
            self.contactsBackground:SetAtlas(self.pressed and "UI-HUD-MicroMenu-ButtonBG-Down" or "UI-HUD-MicroMenu-ButtonBG-Up")
            self.contactsBackground:Show()
            self.contactsIcon:Show();self:SetEnabled(true);self:SetAlpha(1)
            return
        end
        if self.contactsIcon then self.contactsIcon:Hide() end
        if self.contactsBackground then self.contactsBackground:Hide() end
        canvas:Show()
        canvas:SetSize(source:GetWidth(), source:GetHeight())
        local enabled = source:IsEnabled()
        self:SetEnabled(enabled)
        local pressed = self.pressed or source:GetButtonState() == "PUSHED"
        local normal, pushed = source:GetNormalTexture(), source:GetPushedTexture()
        local highlight, disabled = source:GetHighlightTexture(), source:GetDisabledTexture()
        for _, copy in pairs(copies) do copy:Hide() end
        local originX, originY = source:GetLeft(), source:GetTop()
        local originScale = source:GetEffectiveScale()
        local function CopyRegions(frame, regions)
            for _, region in ipairs(regions) do
                if region:IsObjectType("Texture") and not region:IsObjectType("MaskTexture") then
                    local texture, atlas = region:GetTexture(), region:GetAtlas()
                    local ratio = frame:GetEffectiveScale() / originScale
                    local width, height = region:GetWidth() * ratio, region:GetHeight() * ratio
                    if (texture or atlas or region == source.Portrait) and width > 0 and height > 0
                        and width <= source:GetWidth() * 2 and height <= source:GetHeight() * 2 then
                        local copy = copies[region]
                        if not copy then copy = canvas:CreateTexture(); copies[region] = copy end
                        if region == source.Portrait then SetPortraitTexture(copy, "player")
                        elseif atlas then copy:SetAtlas(atlas) else copy:SetTexture(texture) end
                        copy:SetTexCoord(region:GetTexCoord()); copy:SetVertexColor(region:GetVertexColor())
                        copy:SetBlendMode(region:GetBlendMode()); copy:SetDrawLayer(region:GetDrawLayer())
                        copy:SetSize(width, height)
                        copy:ClearAllPoints()
                        local x, y = region:GetLeft(), region:GetTop()
                        if originX and originY and x and y then
                            copy:SetPoint("TOPLEFT", canvas, "TOPLEFT", x * ratio - originX, y * ratio - originY)
                        else copy:SetPoint("CENTER", canvas, "CENTER") end
                        local shown = region:IsShown()
                        if region == normal then shown = enabled and not pressed
                        elseif region == pushed then shown = enabled and pressed
                        elseif region == highlight then shown = false -- Independent gold glow preserves the normal artwork.
                        elseif region == disabled then shown = not enabled
                        elseif region == source.Background then shown = not pressed
                        elseif region == source.PushedBackground or region == source.PushedShadow then shown = pressed end
                        copy:SetAlpha(1); copy:SetShown(shown)
                        if region == source.Portrait then
                            copy:SetDesaturated(not enabled)
                            if source.PortraitMask and not mask then
                                mask = canvas:CreateMaskTexture()
                                mask:SetAtlas(source.PortraitMask:GetAtlas())
                                mask:SetSize(source.PortraitMask:GetWidth(), source.PortraitMask:GetHeight())
                                mask:SetPoint("CENTER", canvas, "CENTER")
                                copy:AddMaskTexture(mask)
                            end
                        end
                    end
                end
            end
        end
        -- Micro buttons can own support/performance/alert frames with screen-sized
        -- textures. Copy only their button surfaces, never arbitrary descendants.
        local regions, seen = {}, {}
        local function Include(region)
            if region and not seen[region] then regions[#regions + 1] = region; seen[region] = true end
        end
        Include(normal); Include(pushed); Include(highlight); Include(disabled)
        for _, key in ipairs({"Background", "PushedBackground", "Shadow", "Portrait", "PushedShadow",
            "Emblem", "HighlightEmblem", "FlashBorder", "FlashContent"}) do Include(source[key]) end
        CopyRegions(source, regions)
        if source.NotificationOverlay and source.NotificationOverlay:IsShown() then
            CopyRegions(source.NotificationOverlay, {source.NotificationOverlay:GetRegions()})
        end
        self:SetAlpha(enabled and 1 or 0.5)
    end
end

function M:ActivateMicroEntry(entry, tile)
    if not self:CanChange() or (not entry.contacts and not entry.source:IsEnabled()) then return end
    if entry.contacts then ToggleFriendsFrame(1); return end
    if entry.name == "MainMenuMicroButton" then self:ShowMistpadSettings(); return end
    if entry.name == "CharacterMicroButton" and self.ToggleCharacterPanel then self:ToggleCharacterPanel(); return end
    local click = entry.source:GetScript("OnClick")
    if click then click(entry.source, "LeftButton", false) end
end

function M:OpenMicroWindow(name)
    for _,entry in ipairs(self:GetMicroMenuEntries()) do
        if entry.name==name then self:ActivateMicroEntry(entry);return end
    end
    self:Print("This window is not available for the current character.")
end
