-- Modules/PvP/NameplateColorizer.lua  [v7]
-- Färbt die HP-Bar von Namensplaketten im PvP:
--   Eigene Gruppe  → grün
--   Gegner         → rot
-- Namen: werden von Blizzard grün gefärbt für Freunde — wir setzen
-- sie aktiv auf weiß zurück, ohne sie selbst einzufärben.

-- ============================================================
-- DB / State
-- ============================================================
local function GetDB()
    return AklimeModDB and AklimeModDB.pvpNameplateColor
end

local function IsEnabled()
    local db = GetDB()
    return db and db.enabled
end

local inPvP = false

local function IsInPvPInstance()
    local inInstance, instanceType = IsInInstance()
    return inInstance and (instanceType == "pvp" or instanceType == "arena")
end

local function RefreshPvPState()
    local wasInPvP = inPvP
    inPvP = IsInPvPInstance()
    return wasInPvP, inPvP
end

-- ============================================================
-- Unit-Token Guard
-- ============================================================
local BLOCKED_PREFIXES = { "raid", "party", "boss", "arena", "pet", "vehicle" }

local function IsNameplateCompatibleUnit(unit)
    if not unit then return false end
    for _, prefix in ipairs(BLOCKED_PREFIXES) do
        if unit:sub(1, #prefix) == prefix then return false end
    end
    return true
end

-- ============================================================
-- Färbe-Logik
-- ============================================================
local COLOR_ALLY  = { r = 0.0, g = 1.0, b = 0.0 }
local COLOR_ENEMY = { r = 1.0, g = 0.2, b = 0.2 }

local function IsAlly(unit)
    if not UnitIsPlayer(unit) then return false end
    return UnitIsFriend("player", unit)
end

local function GetHealthBar(nameplate)
    if not nameplate or not nameplate.UnitFrame then return nil end
    local uf = nameplate.UnitFrame
    return uf.healthBar
        or uf.HealthBar
        or (uf.HealthBarsContainer and uf.HealthBarsContainer.healthBar)
end

local function GetNameText(nameplate)
    if not nameplate or not nameplate.UnitFrame then return nil end
    local uf = nameplate.UnitFrame
    return uf.name
        or (uf.NameContainer and uf.NameContainer.nameText)
end

local function ApplyColor(nameplate)
    if not nameplate or not nameplate.UnitFrame then return end
    local unit = nameplate.UnitFrame.unit
    if not unit or not UnitExists(unit) then return end

    -- HP-Bar einfärben
    local col = IsAlly(unit) and COLOR_ALLY or COLOR_ENEMY
    local hpBar = GetHealthBar(nameplate)
    if hpBar then hpBar:SetStatusBarColor(col.r, col.g, col.b) end

    -- Namen immer weiß lassen — Blizzard färbt Freunde sonst grün
    local nameText = GetNameText(nameplate)
    if nameText then nameText:SetTextColor(1, 1, 1) end
end

local function ResetNameplate(nameplate)
    if not nameplate or not nameplate.UnitFrame then return end
    local uf = nameplate.UnitFrame
    -- Blizzards eigene Funktionen aufrufen → setzt korrekte Originalfarben
    if CompactUnitFrame_UpdateHealthColor then
        pcall(CompactUnitFrame_UpdateHealthColor, uf)
    end
    if CompactUnitFrame_UpdateName then
        pcall(CompactUnitFrame_UpdateName, uf)
    end
end

local function ResetAll()
    for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
        ResetNameplate(nameplate)
    end
end

local function UpdateAll()
    for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
        if IsEnabled() and inPvP then
            ApplyColor(nameplate)
        else
            ResetNameplate(nameplate)
        end
    end
end

-- ============================================================
-- Hook gegen Blizzard-interne HP-Bar-Farb-Resets
-- ============================================================
local hooked = false

local function SetupHook()
    if hooked then return end

    local function OnHealthColorUpdate(frame)
        if not IsEnabled() or not inPvP then return end
        local unit = frame and frame.unit
        if not unit or not UnitExists(unit) then return end
        if not IsNameplateCompatibleUnit(unit) then return end
        local np = C_NamePlate.GetNamePlateForUnit(unit)
        if not np then return end
        local col = IsAlly(unit) and COLOR_ALLY or COLOR_ENEMY
        local hpBar = GetHealthBar(np)
        if hpBar then hpBar:SetStatusBarColor(col.r, col.g, col.b) end
    end

    if CompactUnitFrame_UpdateHealthColor then
        hooksecurefunc("CompactUnitFrame_UpdateHealthColor", OnHealthColorUpdate)
        hooked = true
    elseif UnitFrame_UpdateHealthbarColor then
        hooksecurefunc("UnitFrame_UpdateHealthbarColor", OnHealthColorUpdate)
        hooked = true
    end
end

-- Hook für Namenstext: Blizzard färbt in UpdateNameColor den Namen
-- nach Reaktion ein. Wir hängen uns dahinter und setzen ihn auf weiß.
local nameHooked = false

local function SetupNameHook()
    if nameHooked then return end
    if not CompactUnitFrame_UpdateName then return end

    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
        if not IsEnabled() or not inPvP then return end
        local unit = frame and frame.unit
        if not unit or not UnitExists(unit) then return end
        if not IsNameplateCompatibleUnit(unit) then return end
        local np = C_NamePlate.GetNamePlateForUnit(unit)
        if not np then return end
        local nameText = GetNameText(np)
        if nameText then nameText:SetTextColor(1, 1, 1) end
    end)

    nameHooked = true
end

-- ============================================================
-- Events
-- ============================================================
local eventFrame = CreateFrame("Frame")
local registered = false

local function OnEvent(self, event, ...)
    if event == "NAME_PLATE_UNIT_ADDED" then
        if not IsEnabled() or not inPvP then return end
        local unit = ...
        C_Timer.After(0, function()
            if not IsEnabled() or not inPvP then return end
            local np = C_NamePlate.GetNamePlateForUnit(unit)
            if np then ApplyColor(np) end
        end)

    elseif event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "UPDATE_BATTLEFIELD_STATUS" then
        C_Timer.After(0.2, function()
            local was, now = RefreshPvPState()
            if now then
                UpdateAll()
            elseif was then
                ResetAll()
            end
        end)

    elseif event == "PLAYER_REGEN_DISABLED"
        or event == "PLAYER_REGEN_ENABLED"
        or event == "GROUP_ROSTER_UPDATE" then
        if inPvP then UpdateAll() end
    end
end

local function RegisterEvents()
    if registered then return end
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:SetScript("OnEvent", OnEvent)
    registered = true
    SetupHook()
    SetupNameHook()
end

local function UnregisterEvents()
    if not registered then return end
    eventFrame:UnregisterAllEvents()
    eventFrame:SetScript("OnEvent", nil)
    registered = false
end

-- ============================================================
-- Public API
-- ============================================================
AklimeMod_PvPNameplateColor = {}

function AklimeMod_PvPNameplateColor.IsEnabled()
    return IsEnabled()
end

function AklimeMod_PvPNameplateColor.SetEnabled(v)
    local db = GetDB()
    if not db then return end
    db.enabled = v
    if v then
        RefreshPvPState()
        RegisterEvents()
        UpdateAll()
    else
        UnregisterEvents()
        inPvP = false
        -- Sofort + nach kurzem Delay resetten: Blizzard braucht
        -- einen Frame um seine eigenen Updates abzuschließen
        ResetAll()
        C_Timer.After(0.1, ResetAll)
    end
end

function AklimeMod_PvPNameplateColor.Toggle()
    local db = GetDB()
    if not db then return end
    AklimeMod_PvPNameplateColor.SetEnabled(not db.enabled)
    return db.enabled
end

function AklimeMod_PvPNameplateColor.Init()
    if IsEnabled() then
        RefreshPvPState()
        RegisterEvents()
    end
end