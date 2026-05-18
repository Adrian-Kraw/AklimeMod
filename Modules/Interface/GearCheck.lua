-- Modules/Interface/GearCheck.lua
-- Itemlevel, Sockel und Verzauberung an Equipment-Slots.
-- Sockel: line.type == 3 (locale-unabhaengig), Icon = Sockelloch oder Edelstein
-- Verzauberung: ENCHANTED_TOOLTIP_LINE Pattern (locale-unabhaengig)
-- Linke Spalte: Indikatoren rechts vom Slot. Rechte Spalte: links vom Slot.

local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant)       and C_Item.GetItemInfoInstant       or GetItemInfo
local GetDetailedItemLvl = (C_Item and C_Item.GetDetailedItemLevelInfo) and C_Item.GetDetailedItemLevelInfo or GetDetailedItemLevelInfo
local GetInvItemQuality  = (C_Item and C_Item.GetInventoryItemQuality)  and C_Item.GetInventoryItemQuality  or GetInventoryItemQuality
local GetItemQualCol     = (C_Item and C_Item.GetItemQualityColor)      and C_Item.GetItemQualityColor      or GetItemQualityColor

local ENCHANT_PATTERN = ENCHANTED_TOOLTIP_LINE and ENCHANTED_TOOLTIP_LINE:gsub("%%s", "(.+)") or "(.+)"

-- Verzauberbare Slots nach Erweiterungsnummer.
-- Neues DLC: neuen Block [N] = { [INVSLOT_...]=true, ... } hinzufuegen.
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

-- Linke Spalte des Charakterfensters: Indikatoren erscheinen rechts vom Slot.
-- Rechte Spalte und Waffen: Indikatoren links vom Slot.
-- Linke Spalte: Helm(1), Hals(2), Schultern(3), Ruecken(15), Brust(5), Hemd(4), Handgelenk(9), Wappenrock(19), Hauptwaffe(16)
-- Rechte Spalte: Handschuhe(10), Guertel(6), Beine(7), Fuesse(8), Ringe(11,12), Schmuck(13,14), Nebenwaffe(17)
local LEFT_COLUMN = {
    [1]=true,  -- Helm
    [2]=true,  -- Hals
    [3]=true,  -- Schultern
    [4]=true,  -- Hemd
    [5]=true,  -- Brust
    [9]=true,  -- Handgelenk
    [15]=true, -- Ruecken
    [16]=true, -- Hauptwaffe
    [19]=true, -- Wappenrock
}

local MAX_SOCKETS    = 3
local SOCKET_SIZE    = 14
local SOCKET_GAP     = 1
local SIDE_OFFSET    = 3
local EMPTY_SOCK_TEX = "Interface\\ItemSocketingFrame\\UI-EmptySocket-Meta"
local BADGE_FONT     = "Fonts\\FRIZQT__.TTF"

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

local itemLoadQueue = {}

-- ============================================================
-- Prueffunktion: Verzauberung
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
-- UI: Overlays pro Slot-Button
-- ============================================================

local function EnsureOverlays(button)
    if button._gearReady then return end
    button._gearReady = true

    -- Sockel-Texturen (bis zu MAX_SOCKETS): Sockelloch oder Edelstein-Icon
    button._gearSockets = {}
    for i = 1, MAX_SOCKETS do
        local tex = button:CreateTexture(nil, "OVERLAY")
        tex:SetSize(SOCKET_SIZE, SOCKET_SIZE)
        tex:Hide()
        button._gearSockets[i] = tex
    end

    -- Verzauberungs-Text
    local ench = button:CreateFontString(nil, "OVERLAY")
    ench:SetFont(BADGE_FONT, 11, "OUTLINE")
    ench:Hide()
    button._gearEnchant = ench

    -- Itemlevel unten rechts (auf dem Button)
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

local function UpdateSlotForReal(unit, slotID, button)
    if not AklimeMod_GearCheck.IsEnabled() then return end
    EnsureOverlays(button)

    local itemLink = GetInventoryItemLink(unit, slotID)
    if not itemLink then
        HideOverlays(button)
        return
    end

    local isLeft = LEFT_COLUMN[slotID]

    -- Itemlevel in Qualitaetsfarbe
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

    -- Sockel aus Tooltip-Daten lesen (line.type == 3, locale-unabhaengig)
    local socketIcons = {}
    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local data = C_TooltipInfo.GetInventoryItem(unit, slotID)
        if data then
            for _, line in ipairs(data.lines) do
                if line.type == 3 then
                    -- Edelstein eingesetzt: gemIcon. Leer: leftIcon aus Tooltip-Daten (natives WoW-Sockelloch-Icon).
                    local icon = line.gemIcon or line.leftIcon or EMPTY_SOCK_TEX
                    socketIcons[#socketIcons + 1] = icon
                end
            end
        end
    end

    -- Sockel-Texturen positionieren: oben beginnend, nach unten gestapelt
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

    -- Verzauberungs-Text am unteren Rand neben dem Button
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
        button._gearEnchant:SetText("|cFF00DD00Verzaubert|r")
        button._gearEnchant:Show()
    elseif enchStatus == false then
        button._gearEnchant:SetText("|cFFFF3333Nicht verzaubert|r")
        button._gearEnchant:Show()
    else
        button._gearEnchant:Hide()
    end
end

local function UpdateSlot(unit, slotID, button)
    if not button then return end
    if not AklimeMod_GearCheck.IsEnabled() then return end
    local itemLink = GetInventoryItemLink(unit, slotID)
    if itemLink then
        local itemId = GetItemInfoInstant(itemLink)
        if itemId then
            itemLoadQueue[itemId] = { unit=unit, slotID=slotID, button=button }
            C_Item.RequestLoadItemDataByID(itemId)
        end
    else
        EnsureOverlays(button)
        HideOverlays(button)
    end
end

-- ============================================================
-- Modul-API
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
    end
end

-- ============================================================
-- Events und Hooks
-- ============================================================
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("ITEM_DATA_LOAD_RESULT")
f:RegisterEvent("SOCKET_INFO_UPDATE")
f:RegisterEvent("UNIT_INVENTORY_CHANGED")

f:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 == "AklimeMod" then
            hooksecurefunc("PaperDollItemSlotButton_Update", function(button)
                if AklimeMod_GearCheck.IsEnabled() then
                    UpdateSlot("player", button:GetID(), button)
                end
            end)
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
            UpdateSlotForReal(queued.unit, queued.slotID, queued.button)
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
