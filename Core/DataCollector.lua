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
-- Weekly Vault (Große Schatzkammer)
-- Enum.WeeklyRewardChestThresholdType: Raid=1, MythicPlus=2, World=4
-- ============================================================
local VAULT_TYPES = {
    { key = "raid",    typeID = 1 },
    { key = "dungeon", typeID = 2 },
    { key = "world",   typeID = 4 },
}

local function CollectWeeklyVault(toon)
    if not C_WeeklyRewards then return end
    toon.weeklyVault = toon.weeklyVault or {}
    local vault = toon.weeklyVault

    for _, vt in ipairs(VAULT_TYPES) do
        local ok, activities = pcall(C_WeeklyRewards.GetActivities, vt.typeID)
        if ok and activities then
            local slots = 0
            for _, act in ipairs(activities) do
                if act.progress and act.threshold and act.progress >= act.threshold then
                    slots = slots + 1
                end
            end
            vault[vt.key] = slots
        else
            vault[vt.key] = vault[vt.key] or 0
        end
    end

    local ok2, hasRewards = pcall(C_WeeklyRewards.HasAvailableRewards)
    vault.hasRewards = ok2 and hasRewards == true or false
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
    -- GUID fuer eindeutige Zuordnung bei Waehrungs-Transfers
    t.GUID     = UnitGUID("player")

    -- Wartungsmodus/Resting
    t.isResting = IsResting()

    -- Währungen sammeln
    CollectCurrencies(t)

    -- Weekly Vault sammeln
    CollectWeeklyVault(t)

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
-- Instanz-Betreten tracken (fuer 10/h Limit-Anzeige)
-- Logik nach SavedInstances: Dict statt Array, Key = instName:diff.
-- Gleiche Instanz zaehlt nur einmal (last-Timestamp wird aktualisiert).
-- ============================================================
local function TrackInstanceEntry()
    local db = GetTrackerDB()
    if not db then return end

    local instName, instType, diff = GetInstanceInfo()
    if not instName or not instType
    or instType == "none" or instType == "pvp" or instType == "arena" then
        return
    end

    db.instanceHistory = db.instanceHistory or {}
    local now = time()

    -- Jeden Eintritt einzeln speichern (gleiche Instanz zaehlt mehrfach)
    db.instanceHistory[#db.instanceHistory + 1] = { t = now, name = instName }

    -- Eintraege aelter als 1 Stunde entfernen
    local cutoff  = now - 3600
    local cleaned = {}
    for _, e in ipairs(db.instanceHistory) do
        if e.t >= cutoff then cleaned[#cleaned + 1] = e end
    end
    db.instanceHistory = cleaned
end

-- ============================================================
-- Waehrungs-Transfer zwischen eigenen Chars (Account-Waehrungen)
-- Beim Transfer aendert sich der Stand des Quell-Chars, ohne dass er
-- eingeloggt ist. Nach jedem Transfer werden deshalb die echten Salden
-- aller Chars vom Server geholt und in die Tracker-DB geschrieben.
-- ============================================================

local function NormRealm(realm)
    return (realm or ""):gsub("[%s%-']", ""):lower()
end

-- Findet den Toon-Key zu einem Account-Currency-Eintrag.
-- Reihenfolge: GUID (eindeutig), voller Name mit Realm, eindeutiger Kurzname.
local function FindToonKey(db, entry)
    if entry.characterGUID then
        for key, toon in pairs(db.Toons) do
            if toon.GUID == entry.characterGUID then return key end
        end
    end
    local full = entry.fullCharacterName
    if full and full ~= "" then
        local n, r = full:match("^([^%-]+)%-(.+)$")
        if n and r then
            local rNorm = NormRealm(r)
            for key in pairs(db.Toons) do
                local kn, kr = key:match("^(.-)%s*%-%s*(.+)$")
                if kn == n and NormRealm(kr) == rNorm then return key end
            end
        end
    end
    if entry.characterName then
        local found, count = nil, 0
        for key in pairs(db.Toons) do
            local kn = key:match("^(.-)%s*%-")
            if kn == entry.characterName then
                found = key
                count = count + 1
            end
        end
        if count == 1 then return found end
    end
    return nil
end

local function SyncCurrencyFromAccountData(currencyID)
    local db = GetTrackerDB()
    if not db or not C_CurrencyInfo.FetchCurrencyDataFromAccountCharacters then return end
    local ok, list = pcall(C_CurrencyInfo.FetchCurrencyDataFromAccountCharacters, currencyID)
    if not ok or type(list) ~= "table" then return end
    for _, entry in ipairs(list) do
        local key = FindToonKey(db, entry)
        local toon = key and db.Toons[key]
        if toon and type(entry.quantity) == "number" then
            toon.currency = toon.currency or {}
            toon.currency[currencyID] = toon.currency[currencyID] or {}
            toon.currency[currencyID].amount = entry.quantity
        end
    end
    if AklimeModCTFrame and AklimeModCTFrame:IsShown() and AklimeMod_CT_Refresh then
        AklimeMod_CT_Refresh()
    end
end

-- Waehrungen mit ausstehendem Server-Abgleich nach einem Transfer
local currencySyncPending = {}

-- Frische Daten anfordern und abgleichen. Timer-Fallbacks (1s und 3s)
-- greifen, falls das ACCOUNT_CHARACTER-Event nie feuert.
local function RequestAndSync(cid)
    currencySyncPending[cid] = true
    if C_CurrencyInfo.RequestCurrencyDataForAccountCharacters then
        pcall(C_CurrencyInfo.RequestCurrencyDataForAccountCharacters, cid)
    end
    C_Timer.After(1, function()
        if currencySyncPending[cid] then SyncCurrencyFromAccountData(cid) end
    end)
    C_Timer.After(3, function()
        if currencySyncPending[cid] then
            currencySyncPending[cid] = nil
            SyncCurrencyFromAccountData(cid)
        end
    end)
end

-- Zweiter Ausloeser neben dem Log-Event: der Transfer-Klick selbst.
-- Die Argumente werden defensiv durchsucht, jede Zahl die eine gueltige
-- Waehrungs-ID ist wird abgeglichen (ueberzaehlige Syncs sind unschaedlich,
-- es wird immer nur der Serverstand uebernommen).
if C_CurrencyInfo.RequestCurrencyTransfer then
    hooksecurefunc(C_CurrencyInfo, "RequestCurrencyTransfer", function(...)
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            if type(v) == "number" and v > 0 then
                local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, v)
                if ok and info and info.name and info.name ~= "" then
                    -- Verzoegert: der Server braucht einen Moment zum Verbuchen
                    C_Timer.After(0.5, function() RequestAndSync(v) end)
                end
            end
        end
    end)
end

-- Eigener Char: Waehrungsstand bei jeder Aenderung nachziehen (gebuendelt)
local ownCurrencyDirty = false
local function CollectOwnCurrenciesSoon()
    if ownCurrencyDirty then return end
    ownCurrencyDirty = true
    C_Timer.After(1, function()
        ownCurrencyDirty = false
        local db = GetTrackerDB()
        local toonKey = GetToonKey()
        if db and toonKey and db.Toons[toonKey] then
            CollectCurrencies(db.Toons[toonKey])
        end
    end)
end

-- ============================================================
-- Event-Frame
-- ============================================================
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("UPDATE_INSTANCE_INFO")
eventFrame:RegisterEvent("WEEKLY_REWARDS_UPDATE")
eventFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
-- Transfer-Events: pcall falls ein Event in dieser Client-Version fehlt
pcall(eventFrame.RegisterEvent, eventFrame, "CURRENCY_TRANSFER_LOG_UPDATE")
pcall(eventFrame.RegisterEvent, eventFrame, "ACCOUNT_CHARACTER_CURRENCY_DATA_RECEIVED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        if event == "PLAYER_ENTERING_WORLD" then
            CleanExpiredInstances()
            -- EJ-Cache + Toon-Daten nach laengerem Delay
            C_Timer.After(3, function()
                BuildInstanceExpCache()
                CollectToonData()
            end)
        else
            -- ZONE_CHANGED_NEW_AREA: Instanz-Eintritt zaehlen
            -- Delay: GetInstanceInfo() ist beim Zonenwechsel noch nicht stabil
            C_Timer.After(2, TrackInstanceEntry)
        end

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

    elseif event == "WEEKLY_REWARDS_UPDATE" then
        C_Timer.After(0.3, function()
            local db = GetTrackerDB()
            if not db then return end
            local toonKey = GetToonKey()
            if toonKey and db.Toons[toonKey] then
                CollectWeeklyVault(db.Toons[toonKey])
                if AklimeModCTFrame and AklimeModCTFrame:IsShown() then
                    AklimeMod_CT_Refresh()
                end
            end
        end)

    elseif event == "CURRENCY_DISPLAY_UPDATE" then
        -- Eigener Char: Stand aktuell halten (looten, ausgeben, Transfer)
        CollectOwnCurrenciesSoon()

    elseif event == "CURRENCY_TRANSFER_LOG_UPDATE" then
        -- Ein Transfer wurde verbucht: betroffene Waehrungen ermitteln und
        -- frische Account-Daten anfordern (Antwort kommt asynchron)
        if C_CurrencyInfo.FetchCurrencyTransferTransactions then
            local ok, txs = pcall(C_CurrencyInfo.FetchCurrencyTransferTransactions)
            if ok and type(txs) == "table" then
                for _, tx in ipairs(txs) do
                    local cid = tx and (tx.currencyType or tx.currencyID)
                    if cid then currencySyncPending[cid] = true end
                end
            end
        end
        for cid in pairs(currencySyncPending) do
            if C_CurrencyInfo.RequestCurrencyDataForAccountCharacters then
                pcall(C_CurrencyInfo.RequestCurrencyDataForAccountCharacters, cid)
            else
                -- Keine Request-API: direkt mit dem Cache abgleichen
                SyncCurrencyFromAccountData(cid)
                currencySyncPending[cid] = nil
            end
        end

    elseif event == "ACCOUNT_CHARACTER_CURRENCY_DATA_RECEIVED" then
        -- Frische Daten sind da: angeforderte Waehrungen abgleichen
        if type(arg1) == "number" then
            SyncCurrencyFromAccountData(arg1)
            currencySyncPending[arg1] = nil
        else
            for cid in pairs(currencySyncPending) do
                SyncCurrencyFromAccountData(cid)
                currencySyncPending[cid] = nil
            end
        end
    end
end)