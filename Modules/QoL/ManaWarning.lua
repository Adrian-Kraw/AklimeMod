-- Modules/QoL/ManaWarning.lua
-- Sendet Gruppenwarnung bei 30% (Low Mana) und 10% (OOM) Mana.
--
-- Strategie:
--   Primaer: UNIT_POWER_UPDATE + UnitPower("player"). Exakte Schwellen,
--   in und ausser Kampf. Jede Schwelle feuert einmal und wird erst wieder
--   scharf wenn das Mana 5 Punkte ueber der Schwelle liegt. Das verhindert
--   Chat-Spam wenn das Mana genau um die Schwelle pendelt.
--
--   Fallback: Im instanzierten Kampf kann Blizzard die Mana-Werte sperren
--   (Secret Values, 12.0). Dann uebernehmen Blizzard-eigene Signale:
--   COMBAT_TEXT_UPDATE "MANA_LOW" fuer Low und der "Nicht genug Mana"
--   Spell-Fail im UIErrorsFrame fuer OOM, je einmal pro Kampf.

-- ============================================================
-- Konstanten
-- ============================================================
local THRESHOLD_LOW = 30
local THRESHOLD_OOM = 10
-- Schwelle gilt erst wieder als scharf wenn Mana so viele Punkte drueber liegt
local REARM_MARGIN  = 5

local MSG_LOW = "BEWARE, I'M LOW ON MANA!"
local MSG_OOM = "OUT OF MANA - BELOW 10%"

-- issecretvalue existiert erst seit 12.0
local issecretvalue = issecretvalue or function() return false end

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

-- Gibt true zurueck wenn tatsaechlich gesendet wurde (Solo: false).
local function Send(msg)
    local ch = GetChatChannel()
    if not ch then return false end
    SendChatMessage(msg, ch)
    return true
end

-- ============================================================
-- State
-- ============================================================
-- Schwellen-Pfad: einmal pro Unterschreitung
local firedLow, firedOOM = false, false
-- Fallback-Pfad: einmal pro Low-Phase
local fallbackLowFired, fallbackOOMFired = false, false

-- Blizzards Signale wiederholen sich alle ~10 Sek solange der Zustand
-- anhaelt. Eine groessere Pause zwischen zwei Signalen bedeutet: dazwischen
-- war das Mana erholt, also wieder scharf stellen.
local FALLBACK_REARM_GAP = 15
local lastFallbackLow, lastFallbackOOM = 0, 0

local function ResetAll()
    firedLow, firedOOM = false, false
    fallbackLowFired, fallbackOOMFired = false, false
    lastFallbackLow, lastFallbackOOM = 0, 0
end

-- ============================================================
-- Mana lesen
-- ============================================================
-- nil = nicht auswertbar (kein Mana-Nutzer oder Werte gesperrt).
local function GetManaPercent()
    if UnitPowerType("player") ~= Enum.PowerType.Mana then return nil end
    local cur = UnitPower("player", Enum.PowerType.Mana)
    local max = UnitPowerMax("player", Enum.PowerType.Mana)
    if issecretvalue(cur) or issecretvalue(max) then return nil end
    if not max or max == 0 then return nil end
    return cur / max * 100
end

-- ============================================================
-- Schwellen-Logik (Primaer-Pfad)
-- ============================================================
local function CheckThresholds()
    if not IsEnabled() then return end
    local pct = GetManaPercent()
    if not pct then return end

    -- Rearm: erst deutlich ueber der Schwelle wird wieder scharf gestellt
    if pct >= THRESHOLD_LOW + REARM_MARGIN then firedLow = false end
    if pct >= THRESHOLD_OOM + REARM_MARGIN then firedOOM = false end

    if pct <= THRESHOLD_OOM then
        -- Beide Flags setzen damit nicht zusaetzlich die 30%-Nachricht kommt
        if not firedOOM and Send(MSG_OOM) then
            firedOOM = true
            firedLow = true
        end
    elseif pct <= THRESHOLD_LOW then
        if not firedLow and Send(MSG_LOW) then
            firedLow = true
        end
    end
end

-- ============================================================
-- Blizzard-Strings (lokalisiert)
-- ============================================================
local S_OUT_OF_MANA = nil

local function CacheStrings()
    S_OUT_OF_MANA = OUT_OF_MANA or ""
end

-- ============================================================
-- UIErrorsFrame Hook (Fallback fuer OOM bei gesperrten Werten)
-- ============================================================
local uiHooked = false

local function HookUIErrors()
    if uiHooked then return end
    if not UIErrorsFrame then return end

    hooksecurefunc(UIErrorsFrame, "AddMessage", function(_, text)
        if not IsEnabled() then return end
        if type(text) ~= "string" then return end
        if S_OUT_OF_MANA == "" then return end
        -- Nur einspringen wenn der Schwellen-Pfad die Werte nicht lesen kann
        if GetManaPercent() ~= nil then return end

        local clean = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        if clean:find(S_OUT_OF_MANA, 1, true) then
            local now = GetTime()
            -- Lange Pause seit dem letzten OOM-Fail: Mana war erholt, rearm
            if fallbackOOMFired and (now - lastFallbackOOM) > FALLBACK_REARM_GAP then
                fallbackOOMFired = false
            end
            lastFallbackOOM = now
            if not fallbackOOMFired then
                fallbackOOMFired = true
                -- Low-Fallback und Schwellen-Flags mitsetzen damit direkt
                -- danach keine redundante 30%-Warnung kommt
                fallbackLowFired = true
                lastFallbackLow = now
                firedOOM = true
                firedLow = true
                Send(MSG_OOM)
            end
        end
    end)

    uiHooked = true
end

-- ============================================================
-- Events
-- ============================================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" and arg1 == "AklimeModTools" then
        frame:UnregisterEvent("ADDON_LOADED")
        frame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
        frame:RegisterEvent("COMBAT_TEXT_UPDATE")
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        CacheStrings()
        HookUIErrors()

    elseif event == "UNIT_POWER_UPDATE" then
        if arg2 == "MANA" then
            CheckThresholds()
        end

    elseif event == "COMBAT_TEXT_UPDATE" then
        -- Fallback fuer Low Mana: Blizzard feuert MANA_LOW selbst, alle
        -- ~10 Sek solange das Mana niedrig ist.
        -- Nur einspringen wenn der Schwellen-Pfad die Werte nicht lesen kann.
        if arg1 == "MANA_LOW" and IsEnabled() then
            if GetManaPercent() == nil then
                local now = GetTime()
                -- Lange Pause seit dem letzten MANA_LOW: Mana war erholt, rearm
                if fallbackLowFired and (now - lastFallbackLow) > FALLBACK_REARM_GAP then
                    fallbackLowFired = false
                end
                lastFallbackLow = now
                if not fallbackLowFired then
                    fallbackLowFired = true
                    firedLow = true
                    Send(MSG_LOW)
                end
            end
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Kampfende ist immer ein sicherer Reset fuer den Fallback-Pfad
        fallbackLowFired = false
        fallbackOOMFired = false
        -- Falls die Werte jetzt wieder lesbar sind: Stand pruefen
        CheckThresholds()

    elseif event == "PLAYER_ENTERING_WORLD" then
        CacheStrings()
        HookUIErrors()
        ResetAll()
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
        SendChatMessage(MSG_LOW, ch)
        SendChatMessage(MSG_OOM, ch)
    else
        local ch = GetChatChannel() or "nil (Solo)"
        local pct = GetManaPercent()
        print(string.format(
            "|cFFFFD100Aklime Mod Tools Mana:|r Kanal: %s | Modul: %s | Mana: %s",
            ch,
            IsEnabled() and "|cFF00FF00aktiv|r" or "|cFFFF4444inaktiv|r",
            pct and string.format("%.1f%%", pct) or "nicht lesbar"
        ))
        print(string.format(
            "  firedLow: %s | firedOOM: %s | fallbackLow: %s | fallbackOOM: %s",
            tostring(firedLow), tostring(firedOOM),
            tostring(fallbackLowFired), tostring(fallbackOOMFired)
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
        if not v then ResetAll() end
    end,
}
