-- Modules/Interface/CombatTooltip.lua
-- Blendet den HUD-Tooltip waehrend des Kampfes aus.
-- Taucht nach dem Kampf wieder auf wenn die Maus erneut ueber etwas faehrt.

local M = {}
AklimeMod_CombatTooltip = M

local inCombat = false

local function IsEnabled()
    return AklimeModDB and AklimeModDB.combatTooltip and AklimeModDB.combatTooltip.enabled
end

-- ============================================================
-- Hook
-- ============================================================

GameTooltip:HookScript("OnShow", function(self)
    if IsEnabled() and inCombat then
        self:Hide()
    end
end)

-- ============================================================
-- Events
-- ============================================================

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")

f:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        if IsEnabled() then
            GameTooltip:Hide()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
    end
end)

-- ============================================================
-- API
-- ============================================================

function M:IsEnabled()
    return IsEnabled() == true
end

function M:SetEnabled(v)
    AklimeModDB.combatTooltip.enabled = v
    if v and inCombat then
        GameTooltip:Hide()
    end
end
