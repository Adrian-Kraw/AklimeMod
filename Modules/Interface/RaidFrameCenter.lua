-- Modules/Interface/RaidFrameCenter.lua
-- Zentriert Raid-Frames horizontal basierend auf aktiven Gruppen.
-- EditMode und InCombatLockdown werden NIE angefasst.
-- Y-Position bleibt immer erhalten.

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

local origAnchor   = nil
local hasModified  = false
local cachedOffset = nil   -- Maintank-Offset: einmalig gemessen, dann gecacht

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
    if InCombatLockdown() then return end          -- geschützte Funktion: im Kampf nicht anfassen
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

-- Berechnet die Gesamtbreite nur der sichtbaren CompactRaidGroup<n>-Frames.
-- Maintank/Assist-Header werden ignoriert: wir prüfen explizit nur
-- _G["CompactRaidGroup"..i] — alle anderen Kind-Frames des Containers
-- (Maintank-Header, flowFrames etc.) fließen nicht ein.
-- Wir zählen einfach Anzahl * Breite eines Frames, da sie nebeneinander
-- ohne Lücken angeordnet sind — absolute Koordinaten können durch
-- Maintank-Frames verfälscht sein.
local function GetRaidGroupsWidth()
    local count     = 0
    local frameW    = 0
    for i = 1, NUM_RAID_GROUPS do
        local g = _G["CompactRaidGroup" .. i]
        if g and g:IsShown() then
            count = count + 1
            if frameW == 0 then
                frameW = g:GetWidth()
            end
        end
    end
    if count == 0 then return nil end
    if frameW == 0 then frameW = 220 end
    -- Blizzard setzt keinen Abstand zwischen Gruppen-Frames (spacing = 0 in TWW)
    return count * frameW
end

local function RepositionContainer()
    if IsInEditMode() then return end
    if InCombatLockdown() then return end          -- ADDON_ACTION_BLOCKED vermeiden
    if not GetDB().enabled then return end

    local container = CompactRaidFrameContainer
    if not container or not container:IsShown() then return end

    local numMembers = GetNumGroupMembers()
    local isRaid     = IsInRaid()

    if not isRaid or numMembers < 2 then
        RestoreOriginalPosition()
        return
    end

    -- Originalanker einmalig lesen (vor erstem Eingriff)
    if not origAnchor then
        origAnchor = ReadAnchor(container)
        if not origAnchor then return end
    end

    -- Breite nur der echten Raid-Gruppen (CompactRaidGroup1-8)
    local totalWidth = GetRaidGroupsWidth()
    if not totalWidth or totalWidth < 10 then
        local activeGroups = math.max(1, math.min(math.ceil(numMembers / 5), 8))
        totalWidth = activeGroups * 220
    end

    -- Offset der ersten Gruppe zum Container-Anfang einmalig cachen
    -- (Maintank-Frames sitzen links im Container und verfälschen sonst die Mitte).
    -- Nur messen solange der Container noch nicht von uns verschoben wurde.
    if cachedOffset == nil and not hasModified then
        local firstGroup = _G["CompactRaidGroup1"]
        if firstGroup and firstGroup:IsShown() then
            local cLeft = container:GetLeft()
            local gLeft = firstGroup:GetLeft()
            if cLeft and gLeft then
                cachedOffset = gLeft - cLeft
            end
        end
    end
    local groupOffset = cachedOffset or 0

    -- Container so setzen dass Mitte der Gruppen = Bildschirmmitte:
    -- newX = screenW/2 - totalWidth/2 - groupOffset
    local screenW = GetScreenWidth()
    local offsetX = GetDB().offsetX or 0
    local newX    = (screenW / 2) - (totalWidth / 2) - groupOffset + offsetX

    container:ClearAllPoints()
    container:SetPoint(
        origAnchor.point,
        origAnchor.relativeTo,
        origAnchor.relativePoint,
        newX,
        origAnchor.y
    )
    hasModified = true
end

local pending = false
local function RequestReposition(instant)
    if IsInEditMode() then return end
    if InCombatLockdown() then return end
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
f:RegisterEvent("PLAYER_REGEN_ENABLED")   -- nach Kampfende: aufgeschobene Repositions nachholen

f:SetScript("OnEvent", function(_, event)
    if IsInEditMode() then return end

    if event == "PLAYER_REGEN_ENABLED" then
        -- Kampf vorbei → aufgeschobene Reposition jetzt nachholen
        C_Timer.After(0.2, RepositionContainer)
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        -- Nach Login/Reload: Anchor einlesen bevor wir irgendwas verschieben
        C_Timer.After(1.0, function()
            if IsInEditMode() then return end
            local container = CompactRaidFrameContainer
            if container and not origAnchor then
                origAnchor = ReadAnchor(container)
            end
            RepositionContainer()
        end)
        return
    end

    local isRaid = IsInRaid()
    if not isRaid then
        C_Timer.After(0.1, RestoreOriginalPosition)
    else
        C_Timer.After(0.05, RepositionContainer)
    end
end)

-- EditMode verlassen
if EditModeManagerFrame then
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
        origAnchor   = nil
        hasModified  = false
        cachedOffset = nil
        C_Timer.After(0.5, RepositionContainer)
    end)
end

-- Layout-Hook: nur außerhalb Kampf aufrufen
if CompactRaidFrameContainer_UpdateLayout then
    hooksecurefunc("CompactRaidFrameContainer_UpdateLayout", function()
        if not InCombatLockdown() then RequestReposition() end
    end)
elseif CompactRaidFrameContainer and CompactRaidFrameContainer.UpdateLayout then
    hooksecurefunc(CompactRaidFrameContainer, "UpdateLayout", function()
        if not InCombatLockdown() then RequestReposition() end
    end)
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

C_Timer.After(3.0, function()
    if IsInEditMode() then return end
    -- origAnchor jetzt einlesen während der Container an seiner
    -- vom User gesetzten Position ist (vor dem ersten Raid-Beitritt)
    local container = CompactRaidFrameContainer
    if container and not origAnchor then
        origAnchor = ReadAnchor(container)
    end
    RepositionContainer()
end)