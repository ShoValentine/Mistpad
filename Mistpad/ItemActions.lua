local _, M = ...

function M:SnapshotItem(bag, slot)
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if not info then return end
    local location = ItemLocation and ItemLocation:CreateFromBagAndSlot(bag, slot)
    return {bag = bag, slot = slot, id = info.itemID, link = info.hyperlink,
        count = info.stackCount or 1, locked = info.isLocked,
        guid = location and C_Item.GetItemGUID and C_Item.GetItemGUID(location), location = location}
end

function M:IsCurrentItem(item)
    if not item then return false end
    local current = self:SnapshotItem(item.bag, item.slot)
    return current and not current.locked and current.id == item.id and current.link == item.link
        and current.count == item.count and (not item.guid or current.guid == item.guid)
end

local function KnowsSpell(id)
    if C_SpellBook and C_SpellBook.IsSpellKnown then return C_SpellBook.IsSpellKnown(id) end
    return IsPlayerSpell and IsPlayerSpell(id) or false
end

local function HasProfession(skill)
    if not GetProfessions then return false end
    for _, index in pairs({GetProfessions()}) do
        local _, _, _, _, _, _, skillLine = GetProfessionInfo(index)
        if skillLine == skill then return true end
    end
    return false
end

local function FindSalvageRecipe(itemID)
    local api = C_TradeSkillUI
    if not api or not api.GetAllRecipeIDs or not api.GetRecipeInfo
        or not api.GetRecipeSchematic or not api.GetSalvagableItemIDs then return end
    local salvage = Enum and Enum.TradeskillRecipeType and Enum.TradeskillRecipeType.Salvage
    if not salvage then return end
    for _, recipe in ipairs(api.GetAllRecipeIDs() or {}) do
        local info = api.GetRecipeInfo(recipe)
        if info and info.learned then
            local schematic = api.GetRecipeSchematic(recipe, false)
            if schematic and schematic.recipeType == salvage then
                for _, candidate in ipairs(api.GetSalvagableItemIDs(recipe) or {}) do
                    if candidate == itemID then return recipe end
                end
            end
        end
    end
end

local function TooltipHas(item, marker)
    if not marker or not C_TooltipInfo or not C_TooltipInfo.GetBagItem then return nil end
    local data = C_TooltipInfo.GetBagItem(item.bag, item.slot)
    if not data then return nil end
    for _, line in ipairs(data.lines or {}) do
        if line.leftText and line.leftText:find(marker, 1, true) then return true end
    end
    return false
end

function M:GetItemActions(item)
    local actions = {}
    if not item or item.locked then return actions end
    local link = item.link or item.id
    local _, _, quality, _, _, _, _, _, equipLoc, _, _, class, subclass = C_Item.GetItemInfo(link)
    local equippable = C_Item.IsEquippableItem(link)
    local gear = equippable and (class == 2 or class == 4)
    if equippable then
        actions[#actions + 1] = {label = "Equip", kind = "item"}
    else
        local spell = C_Item.GetItemSpell and C_Item.GetItemSpell(link)
        local info = C_Container.GetContainerItemInfo(item.bag, item.slot)
        if spell or (info and (info.hasLoot or info.isReadable or info.IsReadable)) then
            actions[#actions + 1] = {label = "Use", kind = "item"}
        end
    end
    if item.count > 1 then actions[#actions + 1] = {label = "Split", kind = "split"} end
    if gear then
        actions[#actions + 1] = {label = "Compare", kind = "compare"}
        actions[#actions + 1] = {label = "Preview", kind = "preview"}
    end
    local label, spell, profession
    if gear and quality and quality >= 2 and quality <= 4
        and not (C_Item.IsCosmeticItem and C_Item.IsCosmeticItem(link))
        and not TooltipHas(item, ITEM_DISENCHANT_NOT_DISENCHANTABLE)
        and equipLoc ~= "INVTYPE_TABARD" and equipLoc ~= "INVTYPE_BODY" then
        label, spell, profession = "Disenchant", 13262, 333
    elseif class == 7 and subclass == 9 then label, spell, profession = "Mill", 51005, 773
    elseif class == 7 and subclass == 7 then label, spell, profession = "Prospect", 31252, 755 end
    if label and (KnowsSpell(spell) or HasProfession(profession)) then
        local recipe = FindSalvageRecipe(item.id)
        local marker = label == "Mill" and ITEM_MILLABLE or label == "Prospect" and ITEM_PROSPECTABLE
        if marker and TooltipHas(item, marker) == false and not recipe then
            actions[#actions + 1] = {label = "Drop", kind = "drop"}
            return actions
        end
        if recipe then
            actions[#actions + 1] = {label = label, kind = "salvage", recipe = recipe}
        elseif KnowsSpell(spell) then
            actions[#actions + 1] = {label = label, kind = "spell", spell = spell,
                disabled = label ~= "Disenchant" and item.count < 5 and "Requires a stack of at least 5." or nil}
        else
            actions[#actions + 1] = {label = label, kind = "unavailable",
                disabled = "Learn or open the matching processing recipe in your profession window."}
        end
    end
    actions[#actions + 1] = {label = "Drop", kind = "drop"}
    return actions
end
