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

    -- Drag
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not GetDB().locked then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
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
function M:IsLocked()  return GetDB().locked  == true end

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
    GetDB().locked = v and true or false
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
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then
        local db = GetDB()
        if db.enabled then
            BuildFrame()
            UpdateDisplay()
        end
        return
    end
    if unit == "player" then
        UpdateDisplay()
    end
end)
