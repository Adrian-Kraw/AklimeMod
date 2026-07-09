-- Modules/Interface/GearCheck.lua
-- Item level, sockets and enchant on equipment slots.
-- Sockets: line.type == 3 (locale-independent), icon = socket hole or gem
-- Enchant: ENCHANTED_TOOLTIP_LINE pattern (locale-independent)
-- Left column: indicators to the right of the slot. Right column: to the left of the slot.

local L = AklimeModL or {}

local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant)       and C_Item.GetItemInfoInstant       or GetItemInfo
local GetDetailedItemLvl = (C_Item and C_Item.GetDetailedItemLevelInfo) and C_Item.GetDetailedItemLevelInfo or GetDetailedItemLevelInfo
local GetInvItemQuality  = (C_Item and C_Item.GetInventoryItemQuality)  and C_Item.GetInventoryItemQuality  or GetInventoryItemQuality
local GetItemQualCol     = (C_Item and C_Item.GetItemQualityColor)      and C_Item.GetItemQualityColor      or GetItemQualityColor

local ENCHANT_PATTERN = ENCHANTED_TOOLTIP_LINE and ENCHANTED_TOOLTIP_LINE:gsub("%%s", "(.+)") or "(.+)"

-- Enchantable slots by expansion number.
-- New DLC: add a new block [N] = { [INVSLOT_...]=true, ... }.
local ENCHANT_SLOTS_BY_EXP = {
    [11] = {
        [INVSLOT_MAINHAND]=true, [INVSLOT_HEAD]=true,
        [INVSLOT_SHOULDER]=true, [INVSLOT_CHEST]=true,
        [INVSLOT_LEGS]=true,     [INVSLOT_FEET]=true,
        [INVSLOT_FINGER1]=true,  [INVSLOT_FINGER2]=true,
    },
    [10] = {
        [INVSLOT_BACK]=true,    [INVSLOT_CHEST]=true,
        [INVSLOT_WRIST]=true,   [INVSLOT_LEGS]=true,
        [INVSLOT_FEET]=true,    [INVSLOT_MAINHAND]=true,
        [INVSLOT_FINGER1]=true, [INVSLOT_FINGER2]=true,
    },
    [9] = {
        [INVSLOT_HEAD]=true,    [INVSLOT_BACK]=true,
        [INVSLOT_CHEST]=true,   [INVSLOT_WRIST]=true,
        [INVSLOT_WAIST]=true,   [INVSLOT_LEGS]=true,
        [INVSLOT_FEET]=true,    [INVSLOT_MAINHAND]=true,
        [INVSLOT_FINGER1]=true, [INVSLOT_FINGER2]=true,
    },
}

-- Left column of the character frame: indicators appear to the right of the slot.
-- Right column: indicators appear to the left of the slot.
-- Weapons at the bottom: main hand left -> text left (outward), off hand right -> text right (outward).
-- Left column: head(1), neck(2), shoulders(3), back(15), chest(5), shirt(4), wrist(9), tabard(19), off hand(17)
-- Right column: hands(10), waist(6), legs(7), feet(8), rings(11,12), trinkets(13,14), main hand(16)
local LEFT_COLUMN = {
    [1]=true,  -- Head
    [2]=true,  -- Neck
    [3]=true,  -- Shoulders
    [4]=true,  -- Shirt
    [5]=true,  -- Chest
    [9]=true,  -- Wrist
    [15]=true, -- Back
    [17]=true, -- Off hand
    [19]=true, -- Tabard
}

local MAX_SOCKETS    = 3
local SOCKET_SIZE    = 14
local SOCKET_GAP     = 1
local SIDE_OFFSET    = 3
local EMPTY_SOCK_TEX = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Meta"
local BADGE_FONT     = "Fonts\\FRIZQT__.TTF"

-- Average item level text on the Inspect window: font size and offset from
-- the frame's top right corner (title row, clear of close button and the
-- model viewer's hover controls further down).
local AVG_GS_FONT_SIZE = 14
local AVG_GS_OFFSET_X  = -14
local AVG_GS_OFFSET_Y  = -34

local CHAR_FRAMES = {
    "CharacterHeadSlot",      "CharacterNeckSlot",
    "CharacterShoulderSlot",  "CharacterChestSlot",
    "CharacterWaistSlot",     "CharacterLegsSlot",
    "CharacterFeetSlot",      "CharacterWristSlot",
    "CharacterHandsSlot",     "CharacterFinger0Slot",
    "CharacterFinger1Slot",   "CharacterTrinket0Slot",
    "CharacterTrinket1Slot",  "CharacterBackSlot",
    "CharacterMainHandSlot",  "CharacterSecondaryHandSlot",
}
local INSPECT_FRAMES = {
    "InspectHeadSlot",        "InspectNeckSlot",
    "InspectShoulderSlot",    "InspectChestSlot",
    "InspectWaistSlot",       "InspectLegsSlot",
    "InspectFeetSlot",        "InspectWristSlot",
    "InspectHandsSlot",       "InspectFinger0Slot",
    "InspectFinger1Slot",     "InspectTrinket0Slot",
    "InspectTrinket1Slot",    "InspectBackSlot",
    "InspectMainHandSlot",    "InspectSecondaryHandSlot",
}

-- Slots counted for the average item level (shirt and tabard excluded).
-- Weapon count varies (one two-hander or one/two one-handers): both weapon
-- slots are listed, an empty one is simply skipped when averaging.
local GS_SLOT_IDS = {
    INVSLOT_HEAD, INVSLOT_NECK, INVSLOT_SHOULDER, INVSLOT_CHEST,
    INVSLOT_WAIST, INVSLOT_LEGS, INVSLOT_FEET, INVSLOT_WRIST,
    INVSLOT_HAND, INVSLOT_FINGER1, INVSLOT_FINGER2,
    INVSLOT_TRINKET1, INVSLOT_TRINKET2, INVSLOT_BACK,
    INVSLOT_MAINHAND, INVSLOT_OFFHAND,
}

local itemLoadQueue = {} -- itemId -> array of pending update descriptors

local function QueueItemLoad(itemId, descriptor)
    itemLoadQueue[itemId] = itemLoadQueue[itemId] or {}
    table.insert(itemLoadQueue[itemId], descriptor)
    C_Item.RequestLoadItemDataByID(itemId)
end

-- ============================================================
-- Check function: enchant
-- ============================================================

local function GetEnchantStatus(unit, slotID)
    local expansion = GetExpansionForLevel and GetExpansionForLevel(UnitLevel(unit))
    local slots = expansion and ENCHANT_SLOTS_BY_EXP[expansion] or {}
    local canEnchant = slots[slotID]
    if not canEnchant and slotID == INVSLOT_OFFHAND then
        local link = GetInventoryItemLink(unit, slotID)
        if link then
            local equiploc = select(4, GetItemInfoInstant(link))
            canEnchant = equiploc ~= "INVTYPE_HOLDABLE" and equiploc ~= "INVTYPE_SHIELD"
        end
    end
    if not canEnchant then return nil end
    if not (C_TooltipInfo and C_TooltipInfo.GetInventoryItem) then return nil end
    local data = C_TooltipInfo.GetInventoryItem(unit, slotID)
    if not data then return nil end
    for _, line in ipairs(data.lines) do
        if line.leftText and line.leftText:match(ENCHANT_PATTERN) then
            return true
        end
    end
    return false
end

-- ============================================================
-- UI: overlays per slot button
-- ============================================================

local function EnsureOverlays(button)
    if button._gearReady then return end
    button._gearReady = true

    -- Socket textures (up to MAX_SOCKETS): socket hole or gem icon
    button._gearSockets = {}
    for i = 1, MAX_SOCKETS do
        local tex = button:CreateTexture(nil, "OVERLAY")
        tex:SetSize(SOCKET_SIZE, SOCKET_SIZE)
        tex:Hide()
        button._gearSockets[i] = tex
    end

    -- Enchant text
    local ench = button:CreateFontString(nil, "OVERLAY")
    ench:SetFont(BADGE_FONT, 11, "OUTLINE")
    ench:Hide()
    button._gearEnchant = ench

    -- Item level bottom right (on the button)
    local ilvl = button:CreateFontString(nil, "OVERLAY")
    ilvl:SetFont(BADGE_FONT, 11, "OUTLINE")
    ilvl:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    ilvl:SetJustifyH("RIGHT")
    ilvl:Hide()
    button._gearILvl = ilvl
end

local function HideOverlays(button)
    if button._gearSockets then
        for _, tex in ipairs(button._gearSockets) do tex:Hide() end
    end
    if button._gearEnchant then button._gearEnchant:Hide() end
    if button._gearILvl    then button._gearILvl:Hide()    end
end

-- ============================================================
-- Average item level (Inspect window)
-- ============================================================
local inspectAvgText = nil

local function EnsureInspectAvgText()
    if inspectAvgText then return inspectAvgText end
    if not InspectFrame then return nil end
    local fs = InspectFrame:CreateFontString(nil, "OVERLAY")
    fs:SetFont(BADGE_FONT, AVG_GS_FONT_SIZE, "OUTLINE")
    fs:SetPoint("TOPRIGHT", InspectFrame, "TOPRIGHT", AVG_GS_OFFSET_X, AVG_GS_OFFSET_Y)
    inspectAvgText = fs
    return fs
end

local function ComputeAverageItemLevel(unit)
    local sum, count = 0, 0
    for _, slotID in ipairs(GS_SLOT_IDS) do
        local itemLink = GetInventoryItemLink(unit, slotID)
        if itemLink then
            local ilvl = GetDetailedItemLvl and GetDetailedItemLvl(itemLink)
            if ilvl and ilvl > 0 then
                sum = sum + ilvl
                count = count + 1
            end
        end
    end
    if count == 0 then return nil end
    return sum / count
end

local function UpdateInspectAverageDisplay(unit)
    local fs = EnsureInspectAvgText()
    if not fs then return end
    local avg = ComputeAverageItemLevel(unit)
    if avg then
        fs:SetText(string.format("%s: %.0f", L["gc_avg_gs"] or "GS", avg))
        fs:Show()
    else
        fs:Hide()
    end
end

local function UpdateSlotForReal(unit, slotID, button)
    if not AklimeMod_GearCheck.IsEnabled() then return end
    EnsureOverlays(button)

    local itemLink = GetInventoryItemLink(unit, slotID)
    if not itemLink then
        HideOverlays(button)
        return
    end

    local isLeft = LEFT_COLUMN[slotID]

    -- Item level in quality color
    local ilvl = GetDetailedItemLvl and GetDetailedItemLvl(itemLink)
    if ilvl and ilvl > 0 then
        local quality = GetInvItemQuality(unit, slotID)
        local hex = quality and select(4, GetItemQualCol(quality))
        local text = hex and ("|c" .. hex .. ilvl .. "|r") or tostring(ilvl)
        button._gearILvl:SetText(text)
        button._gearILvl:Show()
    else
        button._gearILvl:Hide()
    end

    -- Read sockets from tooltip data (line.type == 3, locale-independent)
    local socketIcons = {}
    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local data = C_TooltipInfo.GetInventoryItem(unit, slotID)
        if data then
            for _, line in ipairs(data.lines) do
                if line.type == 3 then
                    -- Gem inserted: gemIcon. Empty: leftIcon from tooltip data (native WoW socket-hole icon).
                    local icon = line.gemIcon or line.leftIcon or EMPTY_SOCK_TEX
                    socketIcons[#socketIcons + 1] = icon
                end
            end
        end
    end

    -- Position socket textures: starting at the top, stacked downward
    for i = 1, MAX_SOCKETS do
        local tex = button._gearSockets[i]
        if i <= #socketIcons then
            tex:SetTexture(socketIcons[i] or EMPTY_SOCK_TEX)
            local yOff = -((i - 1) * (SOCKET_SIZE + SOCKET_GAP))
            tex:ClearAllPoints()
            if isLeft then
                tex:SetPoint("TOPLEFT", button, "TOPRIGHT", SIDE_OFFSET, yOff)
            else
                tex:SetPoint("TOPRIGHT", button, "TOPLEFT", -SIDE_OFFSET, yOff)
            end
            tex:Show()
        else
            tex:Hide()
        end
    end

    -- Enchant text at the bottom next to the button
    button._gearEnchant:ClearAllPoints()
    if isLeft then
        button._gearEnchant:SetPoint("BOTTOMLEFT", button, "BOTTOMRIGHT", SIDE_OFFSET, 0)
        button._gearEnchant:SetJustifyH("LEFT")
    else
        button._gearEnchant:SetPoint("BOTTOMRIGHT", button, "BOTTOMLEFT", -SIDE_OFFSET, 0)
        button._gearEnchant:SetJustifyH("RIGHT")
    end

    local enchStatus = GetEnchantStatus(unit, slotID)
    if enchStatus == true then
        button._gearEnchant:SetText("|cFF00DD00" .. (L["gc_enchanted"] or "Enchanted") .. "|r")
        button._gearEnchant:Show()
    elseif enchStatus == false then
        button._gearEnchant:SetText("|cFFFF3333" .. (L["gc_not_enchanted"] or "Not enchanted") .. "|r")
        button._gearEnchant:Show()
    else
        button._gearEnchant:Hide()
    end

    if unit ~= "player" then
        UpdateInspectAverageDisplay(unit)
    end
end

local function UpdateSlot(unit, slotID, button)
    if not button then return end
    if not AklimeMod_GearCheck.IsEnabled() then return end
    local itemLink = GetInventoryItemLink(unit, slotID)
    if itemLink then
        local itemId = GetItemInfoInstant(itemLink)
        if itemId then
            QueueItemLoad(itemId, { kind = "equip", unit = unit, slotID = slotID, button = button })
        end
    else
        EnsureOverlays(button)
        HideOverlays(button)
        if unit ~= "player" then UpdateInspectAverageDisplay(unit) end
    end
end

-- ============================================================
-- Bags: item level badge on container item buttons
-- ============================================================
local bagButtons = {}

local function EnsureBagOverlay(button)
    if button._gearBagReady then return end
    button._gearBagReady = true

    local ilvl = button:CreateFontString(nil, "OVERLAY")
    ilvl:SetFont(BADGE_FONT, 11, "OUTLINE")
    ilvl:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    ilvl:SetJustifyH("RIGHT")
    ilvl:Hide()
    button._gearBagILvl = ilvl
end

local function UpdateContainerButtonForReal(bag, slot, button)
    if not AklimeMod_GearCheck.IsEnabled() then return end
    EnsureBagOverlay(button)

    local info = C_Container.GetContainerItemInfo(bag, slot)
    local itemLink = info and info.hyperlink
    if not itemLink then
        button._gearBagILvl:Hide()
        return
    end

    local ilvl = GetDetailedItemLvl and GetDetailedItemLvl(itemLink)
    if ilvl and ilvl > 0 then
        local hex = info.quality and select(4, GetItemQualCol(info.quality))
        button._gearBagILvl:SetText(hex and ("|c" .. hex .. ilvl .. "|r") or tostring(ilvl))
        button._gearBagILvl:Show()
    else
        button._gearBagILvl:Hide()
    end
end

local function UpdateContainerButton(button, bag, slot)
    if not button then return end
    if not AklimeMod_GearCheck.IsEnabled() then return end
    EnsureBagOverlay(button)
    bagButtons[button] = true

    local info = C_Container.GetContainerItemInfo(bag, slot)
    if not (info and info.hyperlink) then
        button._gearBagILvl:Hide()
        return
    end

    if info.itemID then
        QueueItemLoad(info.itemID, { kind = "bag", bag = bag, slot = slot, button = button })
    end
end

-- ============================================================
-- Module API
-- ============================================================
AklimeMod_GearCheck = {}

function AklimeMod_GearCheck.IsEnabled()
    return AklimeModDB and AklimeModDB.gearCheck and AklimeModDB.gearCheck.enabled == true
end

function AklimeMod_GearCheck.SetEnabled(v)
    if AklimeModDB and AklimeModDB.gearCheck then
        AklimeModDB.gearCheck.enabled = v
    end
    if not v then
        for _, name in ipairs(CHAR_FRAMES)    do HideOverlays(_G[name] or {}) end
        for _, name in ipairs(INSPECT_FRAMES) do HideOverlays(_G[name] or {}) end
        for button in pairs(bagButtons) do
            if button._gearBagILvl then button._gearBagILvl:Hide() end
        end
        if inspectAvgText then inspectAvgText:Hide() end
    end
end

-- ============================================================
-- Events and hooks
-- ============================================================
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("ITEM_DATA_LOAD_RESULT")
f:RegisterEvent("SOCKET_INFO_UPDATE")
f:RegisterEvent("UNIT_INVENTORY_CHANGED")

f:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 == "AklimeModTools" then
            hooksecurefunc("PaperDollItemSlotButton_Update", function(button)
                if AklimeMod_GearCheck.IsEnabled() then
                    UpdateSlot("player", button:GetID(), button)
                end
            end)

            if ContainerFrameCombinedBags then
                local function UpdateAllContainerButtons(containerFrame)
                    for _, itemButton in containerFrame:EnumerateValidItems() do
                        UpdateContainerButton(itemButton, itemButton:GetBagID(), itemButton:GetID())
                    end
                end
                hooksecurefunc(ContainerFrameCombinedBags, "UpdateItems", UpdateAllContainerButtons)
                for _, bagFrame in ipairs((ContainerFrameContainer or UIParent).ContainerFrames) do
                    hooksecurefunc(bagFrame, "UpdateItems", UpdateAllContainerButtons)
                end
            end
        elseif arg1 == "Blizzard_InspectUI" then
            hooksecurefunc("InspectPaperDollItemSlotButton_Update", function(button)
                if AklimeMod_GearCheck.IsEnabled() and InspectFrame then
                    UpdateSlot(InspectFrame.unit or "target", button:GetID(), button)
                end
            end)
        end

    elseif event == "ITEM_DATA_LOAD_RESULT" then
        local queued = itemLoadQueue[arg1]
        if queued then
            for _, entry in ipairs(queued) do
                if entry.kind == "bag" then
                    UpdateContainerButtonForReal(entry.bag, entry.slot, entry.button)
                else
                    UpdateSlotForReal(entry.unit, entry.slotID, entry.button)
                end
            end
            itemLoadQueue[arg1] = nil
        end

    elseif event == "SOCKET_INFO_UPDATE" then
        if AklimeMod_GearCheck.IsEnabled() and CharacterFrame and CharacterFrame:IsShown() then
            for _, name in ipairs(CHAR_FRAMES) do
                local btn = _G[name]
                if btn then UpdateSlot("player", btn:GetID(), btn) end
            end
        end

    elseif event == "UNIT_INVENTORY_CHANGED" then
        if arg1 == "player" and AklimeMod_GearCheck.IsEnabled()
        and CharacterFrame and CharacterFrame:IsShown() then
            for _, name in ipairs(CHAR_FRAMES) do
                local btn = _G[name]
                if btn then UpdateSlot("player", btn:GetID(), btn) end
            end
        end
    end
end)
