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
        local name, id, expires, diff, locked, extended, mostsig, isRaid, players, diffName =
            GetSavedInstanceInfo(i)
        if name and expires and expires > 0 then
            -- Instanz-Eintrag anlegen/aktualisieren
            if not db.Instances[name] then
                db.Instances[name] = {
                    Raid      = isRaid,
                    Show      = "saved",
                    Expansion = 0,  -- wird unten befüllt
                }
            end
            local inst = db.Instances[name]
            inst.Raid = isRaid

            -- LFDID aus Link ermitteln
            local link = GetSavedInstanceChatLink(i) or ""
            local lid  = link:match(":(%d+):%d+:%d+\124h%[")
            if lid then
                inst.LFDID = tonumber(lid)
            end

            -- Expansion aus LFGDungeonInfo
            if inst.LFDID and (inst.Expansion == 0 or not inst.Expansion) then
                local ok, _, _, _, _, _, _, _, expLevel = pcall(GetLFGDungeonInfo, inst.LFDID)
                if ok and expLevel then inst.Expansion = expLevel end
            end

            -- RecLevel
            if inst.LFDID and not inst.RecLevel then
                local ok, _, _, _, _, recLvl = pcall(GetLFGDungeonInfo, inst.LFDID)
                if ok and recLvl then inst.RecLevel = recLvl end
            end

            -- Char-Eintrag
            inst[toonKey]       = inst[toonKey] or {}
            inst[toonKey][diff] = inst[toonKey][diff] or {}
            local save = inst[toonKey][diff]
            save.Expires  = time() + expires
            save.Locked   = locked
            save.Extended = extended
            save.Link     = link ~= "" and link or nil

            -- ID aus Link
            if link ~= "" then
                local linkID = link:match(":(%d+):%d+:%d+\124h%[")
                save.ID = linkID and tonumber(linkID) or (id or -1)
            else
                save.ID = id or -1
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
-- Event-Frame
-- ============================================================
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("UPDATE_INSTANCE_INFO")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Kurzer Delay damit alle APIs bereit sind
        C_Timer.After(3, CollectToonData)

    elseif event == "PLAYER_MONEY" then
        -- Gold sofort aktualisieren
        local db = GetTrackerDB()
        if not db then return end
        local toonKey = GetToonKey()
        if toonKey and db.Toons[toonKey] then
            db.Toons[toonKey].Money = GetMoney()
        end

    elseif event == "UPDATE_INSTANCE_INFO" then
        -- Instanzen aktualisieren wenn sich was ändert
        local db = GetTrackerDB()
        if not db then return end
        local toonKey = GetToonKey()
        if toonKey then
            CollectInstances(db, toonKey)
        end
    end
end)