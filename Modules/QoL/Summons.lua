-- Modules/QoL/Summons.lua
-- Nimmt Beschwörungsanfragen automatisch an.

local M = {}
AklimeMod_Summons = M

-- ============================================================
-- DB
-- ============================================================
local function GetDB()
    if AklimeModDB and AklimeModDB.summons then return AklimeModDB.summons end
    return {}
end

-- ============================================================
-- API
-- ============================================================
function M:IsEnabled() return GetDB().enabled == true end

function M:SetEnabled(v)
    GetDB().enabled = v and true or false
end

-- ============================================================
-- Events
-- ============================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CONFIRM_SUMMON")
eventFrame:SetScript("OnEvent", function(_, event)
    if event ~= "CONFIRM_SUMMON" then return end
    if not GetDB().enabled then return end

    local summoner = GetSummonConfirmSummoner and GetSummonConfirmSummoner() or "?"
    local area     = GetSummonConfirmAreaName and GetSummonConfirmAreaName() or "?"

    ConfirmSummon()
    StaticPopup_Hide("CONFIRM_SUMMON")

    print("|cFFFFD100Aklime Mod Tools:|r Beschwörung von " .. summoner .. " nach " .. area .. " automatisch angenommen.")
end)
