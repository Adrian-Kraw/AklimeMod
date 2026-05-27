-- Modules/QoL/ManaWarning.lua
-- Sendet Gruppenwarnung bei Low Mana und OOM.
--
-- Strategie:
--   COMBAT_TEXT_UPDATE "MANA_LOW" — Blizzard feuert dieses Event selbst
--   alle ~10 Sek solange Mana niedrig ist. Wir senden direkt bei jedem Feuern.
--   Kein eigener Ticker noetig.
--
--   UIErrorsFrame "Nicht genug Mana" — OOM bei Spell-Fail.
--   Einmalig pro OOM-Phase, Reset wenn Mana wieder ueber Schwelle
--   (PLAYER_REGEN_ENABLED als Proxy — nach Kampf meist wieder Mana).

-- ============================================================
-- DB / Toggle
-- ============================================================
local function GetDB()
    return AklimeModDB and AklimeModDB.manaWarning
end

local function IsEnabled()
    local db = GetDB()
    return db and db.enabled
end

-- ============================================================
-- Kanal
-- ============================================================
local INSTANCE_CAT = LE_PARTY_CATEGORY_INSTANCE or 2

local function GetChatChannel()
    if IsInGroup(INSTANCE_CAT) then return "INSTANCE_CHAT" end
    if IsInRaid()              then return "RAID"           end
    if IsInGroup()             then return "PARTY"          end
    return nil
end

local function Send(msg)
    local ch = GetChatChannel()
    if not ch then return end
    SendChatMessage(msg, ch)
end

-- ============================================================
-- State
-- ============================================================
local oomFired = false  -- OOM einmalig pro Phase

local function ResetOOM()
    oomFired = false
end

-- ============================================================
-- Blizzard-Strings (lokalisiert)
-- ============================================================
local S_OUT_OF_MANA = nil

local function CacheStrings()
    S_OUT_OF_MANA = OUT_OF_MANA or ""
end

-- ============================================================
-- UIErrorsFrame Hook — nur fuer OOM
-- ============================================================
local uiHooked = false

local function HookUIErrors()
    if uiHooked then return end
    if not UIErrorsFrame then return end

    hooksecurefunc(UIErrorsFrame, "AddMessage", function(self, text)
        if not IsEnabled() then return end
        if type(text) ~= "string" then return end
        if oomFired then return end
        if S_OUT_OF_MANA == "" then return end

        local clean = text:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
        if clean:find(S_OUT_OF_MANA, 1, true) then
            oomFired = true
            Send("OUT OF MANA - BELOW 10%")
        end
    end)

    uiHooked = true
end

-- ============================================================
-- Events
-- ============================================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "AklimeModTools" then
        frame:RegisterEvent("COMBAT_TEXT_UPDATE")
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        CacheStrings()
        HookUIErrors()

    elseif event == "COMBAT_TEXT_UPDATE" then
        -- Blizzard feuert MANA_LOW selbst alle ~10 Sek solange Mana niedrig.
        -- Wir senden direkt bei jedem Event — kein eigener Ticker noetig.
        if arg1 == "MANA_LOW" then
            if not IsEnabled() then return end
            Send("BEWARE, I'M LOW ON MANA!")
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Nach Kampf OOM-Flag zuruecksetzen
        ResetOOM()

    elseif event == "PLAYER_ENTERING_WORLD" then
        CacheStrings()
        HookUIErrors()
        ResetOOM()
    end
end)

-- ============================================================
-- Debug
-- ============================================================
SLASH_AKM_MANA1 = "/akmana"
SlashCmdList["AKM_MANA"] = function(input)
    local cmd = strtrim(input or ""):lower()

    if cmd == "test" then
        local ch = GetChatChannel()
        if not ch then
            print("|cFFFF4444Aklime Mod Tools:|r Solo - kein Kanal verfuegbar.")
            return
        end
        SendChatMessage("BEWARE, I'M LOW ON MANA!", ch)
        SendChatMessage("OUT OF MANA - BELOW 10%",  ch)
    else
        local ch = GetChatChannel() or "nil (Solo)"
        print(string.format(
            "|cFFFFD100Aklime Mod Tools Mana:|r Kanal: %s | Modul: %s | Hook: %s",
            ch,
            IsEnabled() and "|cFF00FF00aktiv|r" or "|cFFFF4444inaktiv|r",
            uiHooked    and "|cFF00FF00ja|r"     or "|cFFFF4444nein|r"
        ))
        print(string.format(
            "  oomFired: %s | OUT_OF_MANA='%s'",
            tostring(oomFired), S_OUT_OF_MANA or "nil"
        ))
    end
end

-- ============================================================
-- API (Categories.lua)
-- ============================================================
AklimeMod_ManaWarning = {
    IsEnabled  = function() return IsEnabled() end,
    SetEnabled = function(v)
        local db = GetDB()
        if db then db.enabled = v end
        if not v then ResetOOM() end
    end,
}