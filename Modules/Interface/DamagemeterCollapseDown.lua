-- Modules/Interface/DamageMeterCollapseDown.lua
-- Schadensanzeige: leere Fläche nach unten verschwinden lassen.
-- Blizzard versteckt MinimizeContainer aber lässt Frame auf voller Höhe.
-- Wir setzen die Höhe nach dem Klick auf Header-Höhe.

local function GetDB()
    return AklimeModDB and AklimeModDB.damageMeterCollapseDown
end

local function IsEnabled()
    local db = GetDB()
    return db and db.enabled
end

local function GetWindowDB(idx)
    local db = AklimeModDB and AklimeModDB.damageMeterCollapseDown
    if not db then return nil end
    db.windows = db.windows or {}
    db.windows[idx] = db.windows[idx] or {}
    return db.windows[idx]
end

local function PatchWindow(sw)
    if not sw or sw._dmcd_patched then return end
    sw._dmcd_patched = true

    local mb = sw.MinimizeButton
    if not mb then return end

    local header = sw.Header
    local idx    = sw.sessionWindowIndex or 1
    local wdb    = GetWindowDB(idx)

    -- Beim Login: Falls minimiert und Position gespeichert, sofort korrigieren
    -- und _dmcd_* Variablen aus DB wiederherstellen damit der Click-Handler funktioniert
    C_Timer.After(0.5, function()
        wdb = GetWindowDB(idx)
        if wdb and wdb.absLeft and wdb.fullH then
            -- Immer wiederherstellen, egal ob minimiert oder nicht
            sw._dmcd_absLeft   = wdb.absLeft
            sw._dmcd_absBottom = wdb.absBottom
            sw._dmcd_fullH     = wdb.fullH
            sw._dmcd_fullW     = wdb.fullW
            sw._dmcd_origPoint = { "BOTTOMLEFT", UIParent, "BOTTOMLEFT", wdb.absLeft, wdb.absBottom - wdb.fullH }
            if sw.isMinimized then
                local headerH = header and math.ceil(header:GetHeight()) or 32
                sw:ClearAllPoints()
                sw:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", wdb.absLeft, wdb.absBottom)
                if wdb.fullW then sw:SetWidth(wdb.fullW) end
                sw:SetHeight(headerH)
            end
        end
    end)

    mb:HookScript("OnClick", function()
        if not IsEnabled() then return end

        -- Position VOR Blizzards Aktion speichern
        if not sw._dmcd_origPoint then
            local p1, relTo, p2, x, y = sw:GetPoint()
            sw._dmcd_origPoint = { p1, relTo, p2, x, y }
            sw._dmcd_fullH = sw:GetHeight()
            sw._dmcd_fullW = sw:GetWidth()
            sw._dmcd_absLeft   = sw:GetLeft()
            sw._dmcd_absBottom = sw:GetBottom()
            -- In DB speichern für Reload
            wdb = GetWindowDB(idx)
            if wdb then
                wdb.absLeft   = sw._dmcd_absLeft
                wdb.absBottom = sw._dmcd_absBottom
                wdb.fullH     = sw._dmcd_fullH
                wdb.fullW     = sw._dmcd_fullW
            end
        end

        C_Timer.After(0, function()
            local headerH = header and math.ceil(header:GetHeight()) or 32
            local left   = sw._dmcd_absLeft   or sw:GetLeft()
            local bottom = sw._dmcd_absBottom or sw:GetBottom()
            local fullH  = sw._dmcd_fullH     or sw:GetHeight()
            local fullW  = sw._dmcd_fullW     or sw:GetWidth()

            if sw.isMinimized then
                -- Eingeklappt: Header-Hoehe, absolute Bottom-Position
                sw:ClearAllPoints()
                sw:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
                sw:SetWidth(fullW)
                sw:SetHeight(headerH)
            else
                -- Aufgeklappt: volle Hoehe, gleiche Bottom-Position
                sw:ClearAllPoints()
                sw:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
                sw:SetWidth(fullW)
                sw:SetHeight(fullH)
            end
        end)
    end)
end

local function PatchAllWindows()
    if not DamageMeter then return end
    local maxCount = (DamageMeterMixin and DamageMeterMixin:GetMaxSessionWindowCount()) or 5
    for i = 1, maxCount do
        PatchWindow(_G["DamageMeterSessionWindow" .. i])
    end
    if not DamageMeter._dmcd_hooked then
        DamageMeter._dmcd_hooked = true
        hooksecurefunc(DamageMeter, "SetupSessionWindow", function(_, _, idx)
            C_Timer.After(0.1, function()
                PatchWindow(_G["DamageMeterSessionWindow" .. idx])
            end)
        end)
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "AklimeModTools" then
            frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        elseif arg1 == "Blizzard_DamageMeter" then
            C_Timer.After(1.0, function()
                if IsEnabled() then PatchAllWindows() end
            end)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if DamageMeter and IsEnabled() then
            C_Timer.After(1.0, PatchAllWindows)
        end
    end
end)

AklimeMod_DamageMeterCollapseDown = {
    IsEnabled  = function() return IsEnabled() end,
    SetEnabled = function(v)
        local db = GetDB()
        if db then db.enabled = v end
        if v and DamageMeter then PatchAllWindows() end
    end,
}