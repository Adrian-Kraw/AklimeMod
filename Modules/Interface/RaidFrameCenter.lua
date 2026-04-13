-- RaidFrameCenter.lua
-- Zentriert Raid-Frames horizontal basierend auf aktiven Gruppen.
-- EditMode wird NIE angefasst. Y-Position bleibt immer erhalten.

AklimeMod_Defaults = AklimeMod_Defaults or {}
AklimeMod_Defaults.raidFrameCenter = { enabled = true, offsetX = 0 }

local function GetDB()
    if AklimeModDB and AklimeModDB.raidFrameCenter then return AklimeModDB.raidFrameCenter end
    return AklimeMod_Defaults.raidFrameCenter
end

local function IsInEditMode()
    if EditModeManagerFrame and EditModeManagerFrame:IsShown() then return true end
    if C_EditMode and C_EditMode.IsEditModeActive and C_EditMode.IsEditModeActive() then return true end
    return false
end

-- Originalanker: einmalig gespeichert wenn das Addon das erste Mal eingreift.
-- Wird beim EditMode-Exit neu eingelesen (User hat evtl. Position geändert).
-- Wird beim Raid-Leave wiederhergestellt.
local origAnchor = nil
local hasModified = false  -- hat das Addon den Container jemals verschoben?

local function ReadAnchor(container)
    local point, relativeTo, relativePoint, x, y = container:GetPoint(1)
    if not point then return nil end
    return {
        point         = point,
        relativeTo    = relativeTo or UIParent,
        relativePoint = relativePoint,
        x             = x,
        y             = y,
    }
end

local function RestoreOriginalPosition()
    if not origAnchor then return end
    if not hasModified then return end
    local container = CompactRaidFrameContainer
    if not container then return end
    container:ClearAllPoints()
    container:SetPoint(
        origAnchor.point,
        origAnchor.relativeTo,
        origAnchor.relativePoint,
        origAnchor.x,
        origAnchor.y
    )
    hasModified = false
end

local function RepositionContainer()
    if IsInEditMode() then return end
    if not GetDB().enabled then return end

    local container = CompactRaidFrameContainer
    if not container or not container:IsShown() then return end

    local numMembers = GetNumGroupMembers()
    local isRaid = IsInRaid()

    -- Kein Raid → Originalposition wiederherstellen
    if not isRaid or numMembers < 2 then
        RestoreOriginalPosition()
        return
    end

    -- Originalanker einmalig lesen (vor erstem Eingriff)
    if not origAnchor then
        origAnchor = ReadAnchor(container)
        if not origAnchor then return end
    end

    -- Alle sichtbaren Gruppen-Frames sammeln (egal welche Nummer)
    local activeFrames = {}
    for i = 1, NUM_RAID_GROUPS do
        local g = _G["CompactRaidGroup" .. i]
        if g and g:IsShown() then
            table.insert(activeFrames, g)
        end
    end

    local activeGroups = #activeFrames
    if activeGroups == 0 then
        activeGroups = math.max(1, math.min(math.ceil(numMembers / 5), 8))
    end

    -- Gruppenbreite vom ersten aktiven Frame lesen
    local groupWidth = 0
    if activeFrames[1] then
        groupWidth = activeFrames[1]:GetWidth()
    end
    if groupWidth == 0 then groupWidth = 220 end

    -- Gesamtbreite aller aktiven Gruppen
    local groupSpacing = 3
    local totalWidth = (activeGroups * groupWidth) + ((activeGroups - 1) * groupSpacing)

    -- Neues X: Bildschirmmitte minus halbe Gesamtbreite
    local screenW = GetScreenWidth()
    local offsetX = GetDB().offsetX or 0
    local newX    = (screenW / 2) - (totalWidth / 2) + offsetX

    container:ClearAllPoints()
    container:SetPoint(
        origAnchor.point,
        origAnchor.relativeTo,
        origAnchor.relativePoint,
        newX,
        origAnchor.y  -- Y bleibt immer wie vom User gesetzt
    )
    hasModified = true
end

local pending = false
local function RequestReposition(instant)
    if IsInEditMode() then return end
    if pending then return end
    if instant then
        RepositionContainer()
        return
    end
    pending = true
    C_Timer.After(0.3, function()
        pending = false
        RepositionContainer()
    end)
end

-- ============================================================
-- Events
-- ============================================================
local f = CreateFrame("Frame", "AklimeMod_RaidFrameCenter")
f:RegisterEvent("RAID_ROSTER_UPDATE")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")

f:SetScript("OnEvent", function(_, event)
    if IsInEditMode() then return end

    local isRaid = IsInRaid()

    if not isRaid then
        -- Gruppe verlassen oder Raid → Gruppe Downgrade → sofort zurücksetzen
        C_Timer.After(0.1, RestoreOriginalPosition)
    else
        -- Raid gejoint oder Roster geändert → sofort zentrieren
        -- Kürzere Verzögerung damit Blizzard seinen Frame-Layout-Pass fertig macht
        C_Timer.After(0.05, RepositionContainer)
    end
end)

-- EditMode verlassen:
-- 1. origAnchor neu einlesen (User hat Position evtl. geändert)
-- 2. hasModified zurücksetzen (damit RestoreOriginal nicht alte Pos nimmt)
-- 3. Neu zentrieren
if EditModeManagerFrame then
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
        origAnchor  = nil   -- wird beim nächsten Reposition neu gelesen
        hasModified = false
        C_Timer.After(0.5, RepositionContainer)
    end)
end

-- Layout-Hook
if CompactRaidFrameContainer_UpdateLayout then
    hooksecurefunc("CompactRaidFrameContainer_UpdateLayout", RequestReposition)
elseif CompactRaidFrameContainer and CompactRaidFrameContainer.UpdateLayout then
    hooksecurefunc(CompactRaidFrameContainer, "UpdateLayout", RequestReposition)
end

-- ============================================================
-- API
-- ============================================================
AklimeMod_RaidFrameCenter = {
    IsEnabled  = function() return GetDB().enabled end,
    SetEnabled = function(v)
        GetDB().enabled = v
        if v then
            RequestReposition()
        else
            RestoreOriginalPosition()
        end
    end,
    SetOffsetX = function(x) GetDB().offsetX = x; RequestReposition() end,
    GetOffsetX = function() return GetDB().offsetX or 0 end,
    Update     = function() RequestReposition() end,
}

-- Initial nur außerhalb EditMode
C_Timer.After(3.0, function()
    if not IsInEditMode() then RepositionContainer() end
end)