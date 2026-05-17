-- Modules/DataCollector.lua
-- Sammelt beim Login alle Char-Daten, Instanzen und Währungen.
-- Unabhängig von SavedInstances — speichert in AklimeModDB.tracker.
-- Struktur identisch zu SavedInstancesDB damit CharacterTracker beide nutzen kann.

-- ============================================================
-- Alle Currency-IDs (1:1 aus SI Currency.lua)
-- ============================================================
local CURRENCY_IDS = {
    81, 515, 2588, 3363, 241,
    391, 416,
    402, 697, 738, 752, 776, 777, 789,
    823, 824, 994, 1101, 1129, 1149, 1155, 1166,
    1220, 1226, 1273, 1275, 1299, 1314, 1342, 1501, 1508, 1533,
    1710, 1580, 1560, 1587, 1716, 1717, 1718, 1721, 1719, 1755, 1803,
    1754, 1191, 1602, 1792, 1822, 1767, 1828, 1810, 1813, 1816,
    1819, 1820, 1885, 1906, 1931, 1977, 1979, 2009, 2000,
    2003, 2245, 2123, 2797, 2118, 2122,
    2533, 2594, 2650, 2651, 2777, 2796,
    2706, 2707, 2708, 2709,
    2657, 2912, 2806, 2807, 2809, 2812, 2778,
    3089, 2803, 2815, 3056, 3008, 2813, 2914, 2915, 2916, 2917,
    3100, 3090, 3218, 3220, 3226, 3116, 3107, 3108, 3109, 3110,
    3149, 3278, 3303, 3356, 3269, 3284, 3286, 3288, 3290, 3141,
    3319, 3316, 3376, 3377, 3379, 3385, 3392, 3400, 3373, 3393, 3405,
    3256, 3257, 3258, 3259, 3260, 3261, 3262, 3263, 3264, 3265, 3266,
    3028, 3310, 3212, 3378, 3383, 3341, 3343, 3345, 3347, 3418,
}

-- ============================================================
-- EJ-Cache: Name (normalisiert) + EJ-ID → Expansion (0-11)
-- Global damit er per /dump AklimeMod_InstExpCache debuggbar ist.
-- Tier-Name via EJ_GetTierInfo bestimmen (zuverlässiger als Arithmetik).
-- ============================================================

-- Mapping Tier-Name (lowercase) → Expansion-Index
-- Als erste Verteidigungslinie wenn EJ_GetTierInfo einen bekannten Namen liefert.
local TIER_TO_EXP = {
    ["classic"] = 0, ["klassisch"] = 0,
    ["the burning crusade"] = 1, ["der brennende kreuzzug"] = 1,
    ["wrath of the lich king"] = 2, ["zorn des lich-königs"] = 2,
    ["cataclysm"] = 3,
    ["mists of pandaria"] = 4, ["nebel von pandaria"] = 4,
    ["warlords of draenor"] = 5,
    ["legion"] = 6,
    ["battle for azeroth"] = 7, ["kampf um azeroth"] = 7,
    ["shadowlands"] = 8,
    ["dragonflight"] = 9,
    ["the war within"] = 10,
    ["midnight"] = 11, ["mitternacht"] = 11,
}

local function NormName(name)
    if not name then return "" end
    name = name:lower()
    name = name:gsub("^die ", ""):gsub("^der ", ""):gsub("^das ", "")
    return name
end

local function BuildInstanceExpCache()
    AklimeMod_InstExpCache = {}  -- global, debuggbar per /dump
    local numTiers  = EJ_GetNumTiers and EJ_GetNumTiers() or 0
    -- EJ-Tiers sind neueste zuerst (tier 1 = aktuelle Erweiterung).
    -- GetExpansionLevel() gibt die aktuelle Expansion-ID zurueck (z.B. 11 fuer Midnight).
    -- Formel: exp = GetExpansionLevel() - (tier - 1)
    local curExp    = GetExpansionLevel and GetExpansionLevel() or 11
    for tier = 1, numTiers do
        -- Tier-Name-Tabelle als erste Option
        local exp
        if EJ_GetTierInfo then
            local tierName = EJ_GetTierInfo(tier)
            if tierName then exp = TIER_TO_EXP[tierName:lower()] end
        end
        -- Fallback: GetExpansionLevel() - (tier - 1) (korrekt fuer neueste-zuerst)
        if exp == nil then
            exp = curExp - (tier - 1)
        end
        -- Expansion ausserhalb des gueltigen Bereichs: ueberspringen
        if exp < 0 or exp > 11 then
            -- continue (kein goto in Lua 5.1, leere if-Klausel)
        else
            EJ_SelectTier(tier)
            for i = 1, 500 do
                local instID, name = EJ_GetInstanceByIndex(i, true)
                if not instID then break end
                if name then AklimeMod_InstExpCache[NormName(name)] = exp end
                AklimeMod_InstExpCache[instID] = exp
            end
            for i = 1, 500 do
                local instID, name = EJ_GetInstanceByIndex(i, false)
                if not instID then break end
                if name then AklimeMod_InstExpCache[NormName(name)] = exp end
                AklimeMod_InstExpCache[instID] = exp
            end
        end
    end
end

-- ============================================================
-- DB-Zugriff
-- ============================================================
local function GetTrackerDB()
    if not AklimeModDB then return nil end
    AklimeModDB.tracker = AklimeModDB.tracker or {}
    AklimeModDB.tracker.Toons     = AklimeModDB.tracker.Toons     or {}
    AklimeModDB.tracker.Instances = AklimeModDB.tracker.Instances or {}
    return AklimeModDB.tracker
end

-- ============================================================
-- Toon-Name ermitteln (wie SI: "Name - Realm")
-- ============================================================
local function GetToonKey()
    local name  = UnitName("player")
    local realm = GetRealmName()
    if name and realm then
        return name .. " - " .. realm
    end
    return nil
end

-- ============================================================
-- Währungen sammeln (wie SI Currency:UpdateCurrency)
-- ============================================================
local function CollectCurrencies(toon)
    toon.currency = toon.currency or {}
    for _, id in ipairs(CURRENCY_IDS) do
        if C_CurrencyInfo then
            local ok, data = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
            if ok and data and data.discovered then
                toon.currency[id] = toon.currency[id] or {}
                toon.currency[id].amount = data.quantity
                if data.maxQuantity and data.maxQuantity > 0 then
                    toon.currency[id].totalMax = data.maxQuantity
                end
                if data.quantityEarnedThisWeek and data.quantityEarnedThisWeek > 0 then
                    toon.currency[id].earnedThisWeek = data.quantityEarnedThisWeek
                end
            elseif ok and data and not data.discovered then
                toon.currency[id] = nil
            end
        end
    end
end

-- ============================================================
-- Instanzen sammeln (wie SI Refresh / GetSavedInstanceInfo)
-- ============================================================
local function CollectInstances(db, toonKey)
    local numSaved = GetNumSavedInstances()
    if not numSaved or numSaved == 0 then return end

    for i = 1, numSaved do
        local name, id, expires, diff, locked, extended, mostsig, isRaid, players, diffName, numBosses, bossesKilled =
            GetSavedInstanceInfo(i)
        if name and expires and expires > 0 then
            -- Instanz-Eintrag anlegen/aktualisieren
            if not db.Instances[name] then
                db.Instances[name] = {
                    Raid = isRaid,
                    Show = "saved",
                }
            end
            local inst = db.Instances[name]
            inst.Raid = isRaid

            -- LFDID aus Link (korrekte Extraktion: GUID ueberspringen)
            local link = GetSavedInstanceChatLink(i) or ""
            local lid  = link:match("instancelock:[^:]+:(%d+):")
            if lid then
                inst.LFDID = tonumber(lid)
            end

            -- Expansion: Name-Lookup, dann ID-Fallback, dann 0
            local cachedExp = (name and AklimeMod_InstExpCache and AklimeMod_InstExpCache[NormName(name)])
                or (inst.LFDID and AklimeMod_InstExpCache and AklimeMod_InstExpCache[inst.LFDID])
            inst.Expansion = type(cachedExp) == "number" and cachedExp or 0

            -- Char-Eintrag
            inst[toonKey]       = inst[toonKey] or {}
            inst[toonKey][diff] = inst[toonKey][diff] or {}
            local save = inst[toonKey][diff]
            save.Expires  = time() + expires
            save.Locked   = locked
            save.Extended = extended
            save.Link     = link ~= "" and link or nil
            save.ID       = id or -1
            -- Boss-Kills direkt aus API (zuverlässiger als Link-Dekodierung)
            save.Total    = numBosses    or 0
            save.Killed   = bossesKilled or 0
            -- Pro-Boss-Status
            save.bosses = {}
            for j = 1, (numBosses or 0) do
                local bossName, _, isKilled = GetSavedInstanceEncounterInfo(i, j)
                if bossName then
                    save.bosses[j] = { name = bossName, killed = isKilled }
                end
            end
        end
    end

    -- Abgelaufene Einträge für diesen Char bereinigen
    for instName, inst in pairs(db.Instances) do
        if inst[toonKey] then
            for d, save in pairs(inst[toonKey]) do
                if type(d) == "number" and save.Expires and save.Expires < time() then
                    inst[toonKey][d] = nil
                end
            end
            if not next(inst[toonKey]) then
                inst[toonKey] = nil
            end
        end
    end
end

-- ============================================================
-- Haupt-Sammelfunktion (beim Login aufrufen)
-- ============================================================
local function CollectToonData()
    local db = GetTrackerDB()
    if not db then return end

    local toonKey = GetToonKey()
    if not toonKey then return end

    -- Toon-Eintrag anlegen
    db.Toons[toonKey] = db.Toons[toonKey] or {}
    local t = db.Toons[toonKey]

    -- Basis-Infos (wie SI toonInit + UpdateToonData)
    local lclass, class = UnitClass("player")
    t.LClass = lclass
    t.Class  = class
    t.Level  = UnitLevel("player")

    local IL, ILe = GetAverageItemLevel()
    if IL and tonumber(IL) and tonumber(IL) > 0 then
        t.IL  = tonumber(IL)
        t.ILe = tonumber(ILe)
    end

    local faction = UnitFactionGroup("player")
    t.Faction = faction

    local lrace = UnitRace("player")
    t.Race = lrace

    local zone = GetRealZoneText()
    if zone and #zone > 0 then t.Zone = zone end

    t.Money    = GetMoney()
    t.LastSeen = time()
    t.MaxXP    = UnitXPMax("player")

    -- Wartungsmodus/Resting
    t.isResting = IsResting()

    -- Währungen sammeln
    CollectCurrencies(t)

    -- Instanzen sammeln
    CollectInstances(db, toonKey)
end

-- ============================================================
-- Weekly Reset: abgelaufene Instanzen aus DB entfernen
-- ============================================================
local function CleanExpiredInstances()
    local db = GetTrackerDB()
    if not db or not db.Instances then return end
    local now = time()
    for instName, inst in pairs(db.Instances) do
        for key, val in pairs(inst) do
            if type(val) == "table" and type(key) == "string" and key:find(" - ") then
                -- Char-Eintrag
                for diff, save in pairs(val) do
                    if type(diff) == "number" and save.Expires and save.Expires > 0
                    and save.Expires < now then
                        val[diff] = nil
                    end
                end
                if not next(val) then inst[key] = nil end
            end
        end
    end
end

-- ============================================================
-- Event-Frame
-- ============================================================
-- ============================================================
-- Instanz-Betreten tracken (fuer 10/h Limit-Anzeige)
-- ============================================================
local function TrackInstanceEntry()
    local db = GetTrackerDB()
    if not db then return end
    local inInstance, _, instanceType = IsInInstance()
    if not inInstance or instanceType == "none" then return end

    db.instanceHistory = db.instanceHistory or {}
    local now = time()

    -- Nicht doppelt eintragen wenn kurz zuvor schon eingetragen
    local last = db.instanceHistory[#db.instanceHistory]
    if last and (now - last.t) < 10 then return end

    local instanceName = GetInstanceInfo and select(1, GetInstanceInfo()) or "?"
    table.insert(db.instanceHistory, { t = now, name = instanceName or "?" })

    -- Nur Eintraege der letzten Stunde behalten
    local cutoff = now - 3600
    while #db.instanceHistory > 0 and db.instanceHistory[1].t < cutoff do
        table.remove(db.instanceHistory, 1)
    end
end

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("UPDATE_INSTANCE_INFO")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Abgelaufene Instanzen bereinigen (Weekly Reset)
        CleanExpiredInstances()
        -- Instanz-Betreten tracken
        TrackInstanceEntry()
        -- Delay: EJ-Daten sind beim Login noch nicht vollständig geladen.
        -- Cache aufbauen und danach sofort Daten sammeln.
        C_Timer.After(3, function()
            BuildInstanceExpCache()
            CollectToonData()
        end)

    elseif event == "PLAYER_MONEY" then
        local db = GetTrackerDB()
        if not db then return end
        local toonKey = GetToonKey()
        if toonKey and db.Toons[toonKey] then
            db.Toons[toonKey].Money = GetMoney()
        end

    elseif event == "UPDATE_INSTANCE_INFO" then
        -- Instanzen aktualisieren + abgelaufene bereinigen
        local db = GetTrackerDB()
        if not db then return end
        local toonKey = GetToonKey()
        if toonKey then
            CollectInstances(db, toonKey)
        end
        CleanExpiredInstances()
    end
end)