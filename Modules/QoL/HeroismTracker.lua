-- Modules/QoL/HeroismTracker.lua
-- Zeigt "HT AKTIV" auf dem Bildschirm wenn Heldentum / Bloodlust /
-- Trommeln oder der zugehörige Erschöpfungs-Debuff aktiv ist.
-- Position frei verschiebbar, wird gespeichert.

-- ============================================================
-- Spell-IDs
-- ============================================================

-- Aktive Haste-Buffs (40 Sekunden)
local BUFF_IDS = {
    [2825]    = true, -- Bloodlust
    [32182]   = true, -- Heroism (Heldentum)
    [80353]   = true, -- Time Warp (Zeitsprung)
    [90355]   = true, -- Ancient Hysteria (Kerbelwind)
    [160452]  = true, -- Netherwinds
    [264667]  = true, -- Primal Rage (Urtümliche Raserei)
    [390386]  = true, -- Fury of the Aspects (Zorn der Aspekte, Rufer)
    [466904]  = true, -- Harrier's Cry (Jäger Treffsicherheit, seit 11.1)
    [178207]  = true, -- Trommeln des Zorns (WoD)
    [230935]  = true, -- Trommeln des Berges (Legion)
    [256740]  = true, -- Trommeln des Mahlstroms (BfA)
    [309658]  = true, -- Trommeln der tödlichen Wildheit (SL)
    [381301]  = true, -- Trommeln der Wut (DF)
    [424258]  = true, -- Donnernde Trommeln (TWW)
    [424261]  = true, -- Leerenberührte Trommeln (TWW)
    [1243972] = true, -- Leerentrommel (Midnight)
}

-- Erschoepfungs-Debuffs der Lust-Quellen. Im instanzierten Kampf sperrt
-- Blizzard die Haste-Buffs selbst (Secret Values), die Erschoepfung bleibt
-- aber lesbar (in-game verifiziert). Sie erscheint im selben Moment wie der
-- Buff und haelt immer 600 Sekunden, daraus laesst sich das Buff-Ende exakt
-- ableiten, egal wer den Lust gewirkt hat und welche Aura-ID der Buff hat.
local SATED_IDS = {
    [57723]  = true, -- Erschöpfung (Heldentum, Trommeln)
    [57724]  = true, -- Übersättigt (Kampfrausch)
    [80354]  = true, -- Zeitliche Verschiebung (Zeitsprung)
    [264689] = true, -- Ermüdet (Urtümliche Raserei)
    [390435] = true, -- Erschöpfung (Zorn der Aspekte)
}

local BUFF_DURATION  = 40  -- Lust-Buffs dauern immer 40 Sekunden
local SATED_DURATION = 600 -- Erschoepfung dauert immer 10 Minuten


-- ============================================================
-- DB
-- ============================================================
local function GetDB()
    if AklimeModDB and AklimeModDB.heroismTracker then return AklimeModDB.heroismTracker end
    return {}
end

-- ============================================================
-- Aura-Prüfung
-- ============================================================
-- issecretvalue existiert erst seit 12.0
local issecretvalue = issecretvalue or function() return false end

-- true = Buff aktiv, false = kein Buff, nil = Werte gesperrt (Secret).
-- Bei true wird zusaetzlich expirationTime geliefert falls lesbar.
-- Achtung: Im instanzierten Kampf sperrt Blizzard einzelne Auren komplett.
-- Die Per-ID-Abfrage gibt fuer gesperrte Auren nil zurueck (leugnet sie),
-- deshalb kann ein aktiver Lust-Buff hier unsichtbar sein.
local function CheckAuras()
    -- GetPlayerAuraBySpellID: Spell-ID wird als Parameter uebergeben,
    -- kein Zugriff auf geschuetzte Felder der Rueckgabe-Tabelle noetig.
    -- UnitBuff und aura.spellId sind in TWW nicht zugaenglich.
    local secretSeen = false
    for spellID in pairs(BUFF_IDS) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
        if issecretvalue(aura) then
            secretSeen = true
        elseif aura then
            local expires = aura.expirationTime
            if issecretvalue(expires) then expires = nil end
            return true, expires
        end
    end
    if secretSeen then return nil end
    return false
end

-- Leitet das Buff-Ende aus der Erschoepfung ab (GetTime-Basis).
-- Erschoepfung erscheint zusammen mit dem Buff und haelt 600 Sekunden:
-- Buff-Ende = Erschoepfungs-Ende - 600 + 40.
-- nil wenn keine lesbare Erschoepfung aktiv ist.
local function GetBuffEndFromSated()
    for spellID in pairs(SATED_IDS) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
        if not issecretvalue(aura) and aura then
            local expires = aura.expirationTime
            if not issecretvalue(expires) and type(expires) == "number" and expires > 0 then
                return expires - SATED_DURATION + BUFF_DURATION
            end
        end
    end
    return nil
end

-- ============================================================
-- Frame
-- ============================================================
local M = {}
AklimeMod_HeroismTracker = M

local frame = nil

local function SavePosition()
    local db = GetDB()
    local x, y = frame:GetCenter()
    local scale = frame:GetEffectiveScale()
    db.x = x * scale
    db.y = y * scale
end

local function ApplyPosition()
    local db = GetDB()
    frame:ClearAllPoints()
    if db.x and db.y then
        local scale = frame:GetEffectiveScale()
        frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", db.x / scale, db.y / scale)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    end
end

-- Bis zu diesem GetTime()-Zeitpunkt gilt der Buff als sicher aktiv.
-- Gesetzt durch die zuletzt lesbare Aura oder die Erschoepfungs-Ableitung.
-- Traegt die Anzeige durch Phasen, in denen die Aura-Daten gesperrt sind.
local forcedUntil = 0

local function UpdateDisplay()
    if not frame then return end
    local db = GetDB()
    if not db.enabled then
        frame:Hide()
        return
    end
    local now = GetTime()
    local active, expires = CheckAuras()
    if active then
        if expires and expires > now then forcedUntil = expires end
        frame:Show()
        return
    end
    -- Kein direkter Treffer: Buff-Ende aus der Erschoepfung ableiten.
    -- Deckt im Kampf gesperrte Buffs und unbekannte Aura-IDs ab,
    -- unabhaengig davon wer den Lust gewirkt hat.
    local satedEnd = GetBuffEndFromSated()
    if satedEnd and satedEnd > now then
        forcedUntil = satedEnd
        frame:Show()
        return
    end
    if active == false then
        -- Werte lesbar, kein Buff, keine frische Erschoepfung: definitiv aus
        forcedUntil = 0
        frame:Hide()
        return
    end
    -- Werte gesperrt: letztes sicheres Wissen entscheidet
    if now < forcedUntil then
        frame:Show()
    else
        frame:Hide()
    end
end

local function SliderToPx(v)
    -- 0 = 18px (Standard), 100 = 72px (Riesig)
    return math.floor(18 + v * 0.54)
end

local function ApplyFontSize()
    if not frame then return end
    local px = SliderToPx(GetDB().fontSizeSlider or 20)
    frame.text:SetFont("Fonts\\FRIZQT__.TTF", px, "OUTLINE")
    -- Breite großzügig bemessen damit OUTLINE nicht abgeschnitten wird
    frame:SetSize(px * 10, px * 2)
end

local function BuildFrame()
    if frame then return end

    frame = CreateFrame("Frame", "AklimeMod_HeroismTrackerFrame", UIParent)
    frame:SetSize(200, 48)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", SliderToPx(GetDB().fontSizeSlider or 20), "OUTLINE")
    text:SetAllPoints(frame)
    text:SetText("HT AKTIV")
    text:SetTextColor(1, 1, 1, 1)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetWordWrap(false)
    frame.text = text

    -- Drag: RegisterForDrag wuerde frame:Show() im Kampf (InCombatLockdown) blockieren.
    -- OnMouseDown/OnMouseUp erreichen dasselbe ohne diese Einschraenkung.
    frame:SetMovable(true)
    frame:EnableMouse(GetDB().locked == false)
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not M:IsLocked() then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)

    -- Tooltip wenn nicht gesperrt
    frame:SetScript("OnEnter", function(self)
        if not GetDB().locked then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("HT-Tracker", 1, 0.82, 0)
            GameTooltip:AddLine("Drag zum Verschieben", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    ApplyFontSize()
    ApplyPosition()
    frame:Hide()
end

-- ============================================================
-- API
-- ============================================================
function M:IsEnabled() return GetDB().enabled == true end
-- nil und true gelten als gesperrt. Nur explizit false = entsperrt.
function M:IsLocked()  return GetDB().locked ~= false end

function M:SetEnabled(v)
    GetDB().enabled = v and true or false
    if v then
        BuildFrame()
        UpdateDisplay()
    elseif frame then
        frame:Hide()
    end
end

function M:SetLocked(v)
    GetDB().locked = v ~= false  -- false bleibt false, nil/true wird true
    if frame and not InCombatLockdown() then
        frame:EnableMouse(GetDB().locked == false)
    end
end

function M:GetFontSizeSlider() return GetDB().fontSizeSlider or 20 end
function M:SetFontSizeSlider(v)
    GetDB().fontSizeSlider = v
    ApplyFontSize()
end

function M:ShowPreview()
    BuildFrame()
    frame:Show()
end

function M:HidePreview()
    UpdateDisplay()
end

-- ============================================================
-- Events
-- ============================================================

-- Ticker laeuft nur waehrend des Kampfes und pollt UpdateDisplay jede Sekunde.
-- Fallback falls UNIT_AURA nicht zuverlaessig feuert.
local combatTicker = nil

local eventFrame = CreateFrame("Frame")
-- RegisterUnitEvent garantiert UNIT_AURA-Zustellung fuer den Spieler-Unit.
eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        local db = GetDB()
        -- Alten Ticker aufraumen: nach einem Zonenwechsel ist der Combat-State
        -- zurueckgesetzt, ein veralteter Ticker wuerde sonst weiterlaufen.
        if combatTicker then combatTicker:Cancel(); combatTicker = nil end
        if db.enabled then
            BuildFrame()
            UpdateDisplay()
            -- Reconnect oder Instanzeintritt mitten im Kampf:
            -- PLAYER_REGEN_DISABLED feuert nicht nochmal, Ticker manuell starten.
            if UnitAffectingCombat("player") then
                combatTicker = C_Timer.NewTicker(1, function()
                    if GetDB().enabled then UpdateDisplay() end
                end)
            end
        end
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        if GetDB().enabled then
            -- Sofort pruefen (z.B. Trommeln vor dem Zug)
            C_Timer.After(0, UpdateDisplay)
            -- Ticker als Fallback falls UNIT_AURA ausbleibt
            if not combatTicker then
                combatTicker = C_Timer.NewTicker(1, function()
                    if GetDB().enabled then UpdateDisplay() end
                end)
            end
        end
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        if combatTicker then combatTicker:Cancel(); combatTicker = nil end
        C_Timer.After(0, UpdateDisplay)
        return
    end

    if event == "UNIT_AURA" then
        -- Sofortige Reaktion, auch ausserhalb des Kampfes (z.B. Preview).
        if GetDB().enabled then C_Timer.After(0, UpdateDisplay) end
    end
end)

-- ============================================================
-- Debug
-- ============================================================
SLASH_AKM_HT1 = "/akht"
SlashCmdList["AKM_HT"] = function(input)
    local cmd = strtrim(input or ""):lower()

    -- "/akht buffs": alle aktiven Buffs mit Spell-ID auflisten,
    -- um unbekannte Lust-Varianten zu identifizieren
    if cmd == "buffs" then
        print("|cFFFFD100Aklime Mod Tools HT:|r Aktive Buffs:")
        local found = false
        for i = 1, 60 do
            local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
            if not aura then break end
            found = true
            if issecretvalue(aura) then
                print("  [gesperrt]")
            else
                local name = aura.name
                local sid  = aura.spellId
                if issecretvalue(name) then name = "[gesperrt]" end
                if issecretvalue(sid)  then sid  = "[gesperrt]" end
                print(string.format("  %s = %s", tostring(name), tostring(sid)))
            end
        end
        if not found then print("  (keine)") end
        return
    end

    local db = GetDB()
    print(string.format(
        "|cFFFFD100Aklime Mod Tools HT:|r Modul: %s | Frame: %s | Kampf: %s",
        db.enabled and "|cFF00FF00aktiv|r" or "|cFFFF4444inaktiv|r",
        (frame and frame:IsShown()) and "|cFF00FF00sichtbar|r" or "versteckt",
        UnitAffectingCombat("player") and "ja" or "nein"
    ))

    local foundBuff, buffSecret = nil, false
    for spellID in pairs(BUFF_IDS) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
        if issecretvalue(aura) then
            buffSecret = true
        elseif aura then
            foundBuff = spellID
            break
        end
    end
    local foundSated, satedSecret = nil, false
    for spellID in pairs(SATED_IDS) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
        if issecretvalue(aura) then
            satedSecret = true
        elseif aura then
            foundSated = spellID
            break
        end
    end

    local buffText = "|cFFFF4444keiner|r"
    if foundBuff then
        buffText = "|cFF00FF00" .. foundBuff .. "|r"
    elseif buffSecret then
        buffText = "|cFFFF8800GESPERRT|r"
    end
    local satedText = "nein"
    if foundSated then
        satedText = "|cFFFF4444" .. foundSated .. "|r"
    elseif satedSecret then
        satedText = "|cFFFF8800GESPERRT|r"
    end

    -- Aus der Erschoepfung abgeleitetes Buff-Ende
    local derivedText = "nein"
    local satedEnd = GetBuffEndFromSated()
    if satedEnd then
        local remain = satedEnd - GetTime()
        if remain > 0 then
            derivedText = string.format("|cFF00FF00noch %.0fs|r", remain)
        else
            derivedText = "abgelaufen"
        end
    end

    print(string.format(
        "  HT-Buff: %s | Erschoepfung: %s | Buff laut Ableitung: %s | Ticker: %s",
        buffText,
        satedText,
        derivedText,
        combatTicker and "laeuft" or "aus"
    ))
end
