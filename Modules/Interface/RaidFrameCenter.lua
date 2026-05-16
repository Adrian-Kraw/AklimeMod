-- Modules/Interface/RaidFrameCenter.lua
-- Zentriert Raid-Frames horizontal. Y-Position bleibt erhalten.
-- MT-Frame haengt links raus und wird beim Zentrieren ignoriert.

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

local savedY    = nil
local hasModified = false
local lastCount = 0
local lastMtOffset = 0

local function RestorePosition()
    if not hasModified then return end
    if InCombatLockdown() then return end
    hasModified = false
    lastCount   = 0
    lastMtOffset = 0
end

local function RepositionContainer()
    if IsInEditMode() then return end
    if InCombatLockdown() then return end
    if not GetDB().enabled then return end

    local c = CompactRaidFrameContainer
    if not c or not c:IsShown() then return end

    if savedY == nil then
        local _, _, _, _, y = c:GetPoint(1)
        savedY = y or (c:GetTop() - GetScreenHeight())
    end
    if savedY == nil then return end

    if not IsInRaid() then
        hasModified  = false
        lastCount    = 0
        lastMtOffset = 0
        return
    end

    local count  = 0
    local gWidth = 0
    for i = 1, NUM_RAID_GROUPS do
        local g = _G["CompactRaidGroup" .. i]
        if g and g:IsShown() then
            count = count + 1
            if gWidth == 0 then gWidth = g:GetWidth() end
        end
    end
    if count == 0 then
        count = math.max(1, math.min(math.ceil(GetNumGroupMembers() / 5), 8))
    end
    if gWidth == 0 then gWidth = 220 end

    -- MT-Offset messen (immer aktuell, relativ zwischen Container und Group1)
    local mtOffset = 0
    local g1 = _G["CompactRaidGroup1"]
    if g1 and g1:IsShown() then
        local off = g1:GetLeft() - c:GetLeft()
        if off and off > 10 then mtOffset = off end
    end

    -- Nur neu setzen wenn sich Gruppenanzahl ODER MT-Offset geaendert hat
    if count == lastCount and mtOffset == lastMtOffset and hasModified then return end
    lastCount    = count
    lastMtOffset = mtOffset

    local totalWidth = count * gWidth
    local group1X    = (GetScreenWidth() / 2) - (totalWidth / 2) + (GetDB().offsetX or 0)
    local newX       = group1X - mtOffset

    c:ClearAllPoints()
    c:SetPoint("TOPLEFT", UIParent, "TOPLEFT", newX, savedY)
    hasModified = true
end

local pendingTimer = nil
local function RequestReposition()
    if IsInEditMode() then return end
    if InCombatLockdown() then return end
    if pendingTimer then pendingTimer:Cancel(); pendingTimer = nil end
    pendingTimer = C_Timer.NewTimer(0.4, function()
        pendingTimer = nil
        RepositionContainer()
    end)
end

local f = CreateFrame("Frame", "AklimeMod_RaidFrameCenter")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("PLAYER_ROLES_ASSIGNED")
f:RegisterEvent("RAID_ROSTER_UPDATE")

f:SetScript("OnEvent", function(_, event)
    if IsInEditMode() then return end

    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2.0, function()
            if IsInEditMode() then return end
            savedY       = nil
            hasModified  = false
            lastCount    = 0
            lastMtOffset = 0
            RepositionContainer()
        end)
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        C_Timer.After(0.2, RepositionContainer)
        return
    end

    if IsInRaid() then
        RequestReposition()
    end
end)

if EditModeManagerFrame then
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
        C_Timer.After(0.5, function()
            savedY       = nil
            hasModified  = false
            lastCount    = 0
            lastMtOffset = 0
            RepositionContainer()
        end)
    end)
end

AklimeMod_RaidFrameCenter = {
    IsEnabled  = function() return GetDB().enabled end,
    SetEnabled = function(v)
        GetDB().enabled = v
        if v then RepositionContainer() else RestorePosition() end
    end,
    SetOffsetX = function(x) GetDB().offsetX = x; lastCount = 0; RepositionContainer() end,
    GetOffsetX = function() return GetDB().offsetX or 0 end,
    Update     = function() lastCount = 0; lastMtOffset = 0; hasModified = false; RepositionContainer() end,
}

-- SetMainTank/ClearMainTank direkt hooken
if SetMainTank then
    hooksecurefunc("SetMainTank", function() RequestReposition() end)
end
if ClearMainTank then
    hooksecurefunc("ClearMainTank", function() RequestReposition() end)
end

C_Timer.After(3.0, function()
    if IsInEditMode() then return end
    RepositionContainer()
end)