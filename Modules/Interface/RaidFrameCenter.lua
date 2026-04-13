-- RaidFrameCenter.lua
-- Zentriert den Raid-Frame-Container dynamisch basierend auf aktiver Gruppenanzahl.
-- Im Bearbeitungsmodus (EditMode) bleibt Blizzards Standard-Positionierung erhalten.

-- ============================================================
-- DB-Defaults
-- ============================================================
AklimeMod_Defaults = AklimeMod_Defaults or {}
AklimeMod_Defaults.raidFrameCenter = {
    enabled = true,
    offsetX = 0,
}

local function GetDB()
    if AklimeModDB and AklimeModDB.raidFrameCenter then
        return AklimeModDB.raidFrameCenter
    end
    return AklimeMod_Defaults.raidFrameCenter
end

-- ============================================================
-- Kern-Logik
-- ============================================================
local repositionPending = false

local function RepositionContainer()
    repositionPending = false

    if not GetDB().enabled then return end

    -- Im Bearbeitungsmodus: nicht eingreifen
    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then return end

    local container = CompactRaidFrameContainer
    if not container or not container:IsShown() then return end

    -- Nur im echten Raid (6+ Mitglieder)
    local numMembers = GetNumGroupMembers()
    if numMembers < 6 then return end

    -- Breite einer einzelnen Gruppe ermitteln
    local groupWidth = 0
    local groupSpacing = 3

    for i = 1, NUM_RAID_GROUPS do
        local g = _G["CompactRaidGroup" .. i]
        if g and g:IsShown() then
            groupWidth = g:GetWidth()
            if groupWidth > 0 then break end
        end
    end

    if groupWidth == 0 then groupWidth = 220 end

    -- Aktive Gruppen zählen
    local activeGroups = 0
    for i = 1, NUM_RAID_GROUPS do
        local g = _G["CompactRaidGroup" .. i]
        if g and g:IsShown() then
            activeGroups = activeGroups + 1
        end
    end
    if activeGroups == 0 then
        activeGroups = math.max(1, math.min(math.ceil(numMembers / 5), 8))
    end

    -- Gesamtbreite berechnen
    local totalWidth = (activeGroups * groupWidth) + ((activeGroups - 1) * groupSpacing)

    -- Aktuelle Y-Position des Containers beibehalten
    local currentY = 0
    local numPoints = container:GetNumPoints()
    for i = 1, numPoints do
        local _, _, _, _, y = container:GetPoint(i)
        if y then currentY = y; break end
    end

    -- X so setzen dass Container-Mitte = Bildschirmmitte
    local screenW = GetScreenWidth()
    local offsetX = GetDB().offsetX or 0
    local newX = (screenW / 2) - (totalWidth / 2) + offsetX

    container:ClearAllPoints()
    container:SetPoint("TOPLEFT", UIParent, "TOPLEFT", newX, currentY)
end

local function RequestReposition()
    if repositionPending then return end
    repositionPending = true
    C_Timer.After(0.25, RepositionContainer)
end

-- ============================================================
-- Events statt hooksecurefunc (sicherer in 12.0.1)
-- ============================================================
local eventFrame = CreateFrame("Frame", "AklimeMod_RaidFrameCenter")

eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(_, event)
    RequestReposition()
end)

-- EditMode verlassen → neu zentrieren
if EditModeManagerFrame then
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
        C_Timer.After(0.5, RepositionContainer)
    end)
end

-- Sicherer Hook: nur wenn die Funktion existiert
if CompactRaidFrameContainer_UpdateLayout then
    hooksecurefunc("CompactRaidFrameContainer_UpdateLayout", RequestReposition)
elseif CompactRaidFrameContainer and CompactRaidFrameContainer.UpdateLayout then
    -- 12.0.1: Methode am Frame-Objekt statt globale Funktion
    hooksecurefunc(CompactRaidFrameContainer, "UpdateLayout", RequestReposition)
end

-- ============================================================
-- Öffentliche API
-- ============================================================
AklimeMod_RaidFrameCenter = {

    IsEnabled = function()
        return GetDB().enabled
    end,

    SetEnabled = function(enabled)
        GetDB().enabled = enabled
        if enabled then
            RequestReposition()
        else
            -- Blizzard-Layout wiederherstellen via Event
            local container = CompactRaidFrameContainer
            if container then
                container:ClearAllPoints()
                container:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
                    UIParent:GetWidth() * 0.5 - 200, UIParent:GetHeight() * 0.5)
            end
        end
    end,

    SetOffsetX = function(x)
        GetDB().offsetX = x
        RequestReposition()
    end,

    GetOffsetX = function()
        return GetDB().offsetX or 0
    end,

    Update = function()
        RequestReposition()
    end,
}

-- Einmalig beim Laden
C_Timer.After(2.0, RepositionContainer)