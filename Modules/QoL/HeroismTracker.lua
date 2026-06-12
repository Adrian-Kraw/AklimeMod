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
local function CheckAuras()
    -- GetPlayerAuraBySpellID: Spell-ID wird als Parameter uebergeben,
    -- kein Zugriff auf geschuetzte Felder der Rueckgabe-Tabelle noetig.
    -- UnitBuff und aura.spellId sind in TWW nicht zugaenglich.
    for spellID in pairs(BUFF_IDS) do
        if C_UnitAuras.GetPlayerAuraBySpellID(spellID) then
            return true
        end
    end
    return false
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

local function UpdateDisplay()
    if not frame then return end
    local db = GetDB()
    if not db.enabled then
        frame:Hide()
        return
    end
    if CheckAuras() then
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
