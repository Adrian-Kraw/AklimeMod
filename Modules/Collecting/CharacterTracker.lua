-- Modules/CharacterTracker.lua
-- Charakter-Tracker: Raids + Währungen aus SavedInstancesDB.
-- Vollständig dynamisch. Hover-Tooltip auf Charakter-Namen.

-- ============================================================
-- Hidden/DNT Currencies die NICHT angezeigt werden sollen
-- (aus SI Currency.lua Kommentare + hiddenCurrency Logik)
-- ============================================================
local HIDDEN_CURRENCY_IDS = {
    [2409]=true, [2410]=true, [2411]=true, [2412]=true,  -- DNT Crest Fragments
    [2413]=true,  -- 10.1 Professions - S2 Spark (Hidden)
    [2774]=true,  -- 10.2 Professions - S3 Spark (Hidden)
    [2800]=true,  -- 10.2.6 Professions - S4 Spark (Hidden)
    [3010]=true,  -- 10.2.6 Rewards - S4 Dinar (Hidden)
    [3023]=true,  -- 11.0 Professions - S1 Spark (Hidden)
    [3132]=true,  -- 11.1 Professions - S2 Spark (Hidden)
    [1889]=true,  -- Adventure Campaign Progress
    [2045]=true,  -- Dragon Glyph Embers (intern)
}

-- Alle SI Currency-IDs (1:1 aus SI Currency.lua)
local SI_CURRENCY_IDS = {
    -- Saison
    3310, 2803, 3378, 3418, 3028, 3356, 3383, 3341, 3343, 3346, 3347, 3212,
    -- Dungeon & Schlachtzug
    1166,
    -- Spieler gegen Spieler
    391, 2123, 1792, 1602,
    -- Verschiedenes
    2588, 402, 81, 3363, 515, 2032,
    -- Midnight
    3373, 3405, 3393, 3316, 3385, 3376, 3392, 3379, 3377, 3400,
    3256, 3257, 3258, 3260, 3261, 3262, 3263, 3264, 3265, 3266,
    -- The War Within
    3220, 3055, 3093, 3089, 3090, 3056, 3218, 3226, 2815, 3303, 3149,
    -- Dragonflight
    2118, 2657, 2594, 2650, 2122, 2777, 2003,
    -- Shadowlands
    1754, 1979, 1885, 1820, 1931, 2009, 1819, 1813, 1828, 1906, 1767, 1977, 1816, 1904,
    -- Battle for Azeroth
    1717, 1803, 1299, 1560, 1755, 1721, 1710, 1580, 1719,
    -- Legion
    1149, 1533, 1342, 1275, 1226, 1220, 1273, 1155, 1508,
    -- Warlords of Draenor
    994, 823, 824, 1101, 1129,
    -- Mists of Pandaria
    738, 752, 776, 777, 789, 697,
    -- Cataclysm
    416,
    -- Wrath of the Lich King
    241,
    -- The Burning Crusade
    1704,
}

-- ============================================================
-- Difficulty
-- ============================================================
local function GetDiffLabel(inst, diff)
    if not inst.Raid then return nil end
    if diff == 3  then return "10N"  end
    if diff == 4  then return "25N"  end
    if diff == 5  then return "10H"  end
    if diff == 6  then return "25H"  end
    if diff == 7  then return "LFR"  end
    if diff == 14 then return "N"    end
    if diff == 15 then return "H"    end
    if diff == 16 then return "M"    end
    if diff == 17 then return "LFR"  end
    return nil
end

local DIFF_ORDER = { 17, 3, 4, 5, 6, 7, 14, 15, 16 }
local DIFF_COLOR = {
    [17]={r=0.25,g=0.75,b=1.0 }, [7]={r=0.25,g=0.75,b=1.0 },
    [14]={r=0.12,g=0.93,b=0.12}, [3]={r=0.12,g=0.93,b=0.12}, [4]={r=0.12,g=0.93,b=0.12},
    [15]={r=0.0, g=0.44,b=0.87}, [5]={r=0.0, g=0.44,b=0.87}, [6]={r=0.0, g=0.44,b=0.87},
    [16]={r=0.64,g=0.21,b=0.93},
}

local EXP_NAMES = {
    [0]  = "Classic",
    [1]  = "The Burning Crusade",
    [2]  = "Wrath of the Lich King",
    [3]  = "Cataclysm",
    [4]  = "Mists of Pandaria",
    [5]  = "Warlords of Draenor",
    [6]  = "Legion",
    [7]  = "Battle for Azeroth",
    [8]  = "Shadowlands",
    [9]  = "Dragonflight",
    [10] = "The War Within",
    [11] = "Midnight",
    [12] = "Verschiedenes",
    [13] = "Spieler gegen Spieler",
    [14] = "Dungeon & Schlachtzug",
    [15] = "Saison",
}

-- SI speichert expansionLevel direkt als 0-11 — kein Mapping nötig
-- Nur als Sicherheitsnetz falls alte/fehlerhafte Werte vorkommen
local function NormalizeExpansion(exp)
    if not exp then return 0 end
    if exp >= 0 and exp <= 11 then return exp end
    return 0
end

-- ============================================================
-- DB
-- ============================================================
local function GetDB()
    return AklimeModDB and AklimeModDB.savedInstances
end
local function IsRaidExpEnabled(exp)
    local db = GetDB()
    return not (db and db.raidExps and db.raidExps[exp] == false)
end
local function IsCurrencyEnabled(id)
    local db = GetDB()
    return not (db and db.currencies and db.currencies[id] == false)
end

local function GetToonDB()
    if AklimeModDB and AklimeModDB.tracker and AklimeModDB.tracker.Toons then
        return AklimeModDB.tracker.Toons
    end
    return nil
end

local function GetInstanceDB()
    if AklimeModDB and AklimeModDB.tracker and AklimeModDB.tracker.Instances then
        return AklimeModDB.tracker.Instances
    end
    return nil
end

local function GetDataDB()
    local toons = GetToonDB()
    if not toons then return nil end
    return { Toons = toons, Instances = GetInstanceDB() or {} }
end

-- ============================================================
-- Hilfsfunktionen
-- ============================================================
local function ShortName(full)
    return full:match("^(.-)%s*%-") or full
end

local function ClassCol(lclass)
    if not lclass then return 1, 0.82, 0 end
    -- RAID_CLASS_COLORS braucht englischen Großbuchstaben-Key (z.B. "WARRIOR")
    local ci = RAID_CLASS_COLORS and RAID_CLASS_COLORS[lclass:upper()]
    if ci then return ci.r, ci.g, ci.b end
    return 1, 0.82, 0
end

-- Klassenfarbe aus Toon-Daten holen (Class = englisch groß, LClass = lokalisiert)
local function ToonClassCol(toon)
    if not toon then return 1, 0.82, 0 end
    -- Class ist englisch großgeschrieben (WARRIOR, EVOKER etc.) → direkt für RAID_CLASS_COLORS
    if toon.Class then
        local ci = RAID_CLASS_COLORS and RAID_CLASS_COLORS[toon.Class:upper()]
        if ci then return ci.r, ci.g, ci.b end
    end
    -- Fallback LClass (funktioniert auf englischen Clients)
    if toon.LClass then
        local ci = RAID_CLASS_COLORS and RAID_CLASS_COLORS[toon.LClass:upper()]
        if ci then return ci.r, ci.g, ci.b end
    end
    return 1, 0.82, 0
end

local function GetBossKills(save)
    if not save then return 0 end
    -- Direkt aus API (DataCollector speichert save.Killed)
    if save.Killed and save.Killed > 0 then return save.Killed end
    -- Fallback: Link-Bitmask (aeltere gespeicherte Daten)
    if save.Link then
        local bits = save.Link:match(":(%d+)\124h")
        bits = bits and tonumber(bits)
        if bits and bits > 1 then  -- > 1 weil isExtended (0/1) nicht zaehlt
            local k = 0
            while bits > 0 do
                if bit.band(bits, 1) > 0 then k = k + 1 end
                bits = bit.rshift(bits, 1)
            end
            return k
        end
    end
    return 0
end

local function GetBossTotal(save)
    -- Direkt aus API (DataCollector: numBosses aus GetSavedInstanceInfo)
    if save and save.Total and save.Total > 0 then return save.Total end
    -- Fallback: Anzahl gespeicherter Bosse
    if save and save.bosses then
        local n = #save.bosses
        if n > 0 then return n end
    end
    return 0
end

-- Manuelle Expansion-Zuweisung (da C_CurrencyInfo.expansionID oft nil)
-- 1:1 aus SI Currency.lua Struktur — ALLE IDs müssen hier gemappt sein
local CURRENCY_EXP = {}
local function SetExp(exp, ids)
    for _, id in ipairs(ids) do CURRENCY_EXP[id] = exp end
end
-- Saison (15) — Morgenlichtwappen + Saison-Währungen
SetExp(15, {3310,2803,3378,3418,3028,3356,3383,3341,3343,3346,3347,3212})
-- Dungeon & Schlachtzug (14)
SetExp(14, {1166})
-- Spieler gegen Spieler (13)
SetExp(13, {391,2123,1792,1602})
-- Verschiedenes (12)
SetExp(12, {2588,402,81,3363,515,2032})
-- Midnight (11) — Content + Tatkraft-Berufswährungen
SetExp(11, {3373,3405,3393,3316,3385,3376,3392,3379,3377,3400,
            3256,3257,3258,3260,3261,3262,3263,3264,3265,3266})
-- The War Within (10)
SetExp(10, {3220,3055,3093,3089,3090,3056,3218,3226,2815,3303,3149})
-- Dragonflight (9)
SetExp(9,  {2118,2657,2594,2650,2122,2777,2003})
-- Shadowlands (8)
SetExp(8,  {1754,1979,1885,1820,1931,2009,1819,1813,1828,1906,1767,1977,1816,1904})
-- Battle for Azeroth (7)
SetExp(7,  {1717,1803,1299,1560,1755,1721,1710,1580,1719})
-- Legion (6)
SetExp(6,  {1149,1533,1342,1275,1226,1220,1273,1155,1508})
-- Warlords of Draenor (5)
SetExp(5,  {994,823,824,1101,1129})
-- Mists of Pandaria (4)
SetExp(4,  {738,752,776,777,789,697})
-- Cataclysm (3)
SetExp(3,  {416})
-- Wrath of the Lich King (2)
SetExp(2,  {241})
-- The Burning Crusade (1)
SetExp(1,  {1704})

local currInfoCache = {}
local function GetCurrInfo(id)
    local cached = currInfoCache[id]
    if cached ~= nil then return cached or nil end
    if C_CurrencyInfo then
        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
        if ok and info and info.name and info.name ~= "" then
            -- Expansion aus manueller Tabelle
            -- Wenn nicht gemappt → nil zurückgeben (nicht anzeigen)
            local exp = CURRENCY_EXP[id]
            if exp == nil then
                currInfoCache[id] = false  -- false = bekannt aber nicht anzeigen
                return nil
            end
            currInfoCache[id] = {
                name = info.name,
                exp  = exp,
                icon = info.iconFileID,
            }
            return currInfoCache[id]
        end
    end
    return nil
end

local function FormatAmount(a)
    if not a or a == 0 then return nil end
    if a >= 1000000 then return string.format("%.1fM", a/1000000) end
    if a >= 1000    then return string.format("%.1fk", a/1000) end
    return tostring(a)
end

local function GetSelectedChars()
    local db   = GetDB()
    local siDB = GetDataDB()
    if not siDB then return {} end
    local sel = {}
    if db and db.chars then
        for name, on in pairs(db.chars) do
            if on and siDB.Toons[name] then sel[#sel+1] = name end
        end
    end
    table.sort(sel)
    return sel
end

local function BuildRaids(sel)
    local siDB = GetDataDB()
    if not siDB or not siDB.Instances then return {} end
    local byExp = {}
    for instName, inst in pairs(siDB.Instances) do
        -- Nur echte Raids (maxPlayers > 5), keine Dungeons, keine zufälligen
        if inst.Raid and not inst.Random and inst.Show ~= "never"
        and IsRaidExpEnabled(NormalizeExpansion(inst.Expansion or 0)) then
            local exp   = NormalizeExpansion(inst.Expansion or 0)
            local diffs = {}
            local hasSave = false
            for _, ch in ipairs(sel) do
                if inst[ch] then
                    for diff, save in pairs(inst[ch]) do
                        if type(diff) == "number" and save and save.Expires and save.Expires > 0 then
                            if not diffs[diff] then diffs[diff] = {} end
                            diffs[diff][ch] = save
                            hasSave = true
                        end
                    end
                end
            end
            if hasSave then
                if not byExp[exp] then byExp[exp] = {} end
                byExp[exp][#byExp[exp]+1] = {
                    name      = instName,
                    lfdid     = inst.LFDID,
                    recLevel  = inst.RecLevel or 0,
                    diffs     = diffs,
                    inst      = inst,
                    worldBoss = inst.WorldBoss ~= nil,
                }
            end
        end
    end
    for _, raids in pairs(byExp) do
        table.sort(raids, function(a,b)
            -- Weltbosse ans Ende
            if a.worldBoss ~= b.worldBoss then return not a.worldBoss end
            return (a.recLevel or 0) > (b.recLevel or 0)
        end)
    end
    return byExp
end

local function BuildCurrencies(sel)
    local siDB = GetDataDB()
    if not siDB then return {} end

    -- IDs die mind. 1 Char > 0 hat
    local present = {}
    for _, ch in ipairs(sel) do
        local toon = siDB.Toons[ch]
        if toon and toon.currency then
            for id, data in pairs(toon.currency) do
                if type(id) == "number" and data.amount and data.amount > 0
                and not HIDDEN_CURRENCY_IDS[id] then
                    present[id] = true
                end
            end
        end
    end

    local siSet = {}
    for _, id in ipairs(SI_CURRENCY_IDS) do siSet[id] = true end

    local result = {}
    for id in pairs(present) do
        if IsCurrencyEnabled(id) then
            local info = GetCurrInfo(id)
            if info then
                local nameLower = info.name:lower()
                -- Nur offensichtlich interne/hidden rausfiltern
                if not nameLower:find("%(hidden%)") and not nameLower:find("dnt")
                and not nameLower:find("personal tracker") then
                    result[#result+1] = { id=id, exp=info.exp, name=info.name, icon=info.icon }
                end
            end
        end
    end

    table.sort(result, function(a, b)
        if a.exp ~= b.exp then return a.exp > b.exp end
        return a.name < b.name
    end)
    return result
end

-- ============================================================
-- Layout-Konstanten
-- ============================================================
local ROW_H = 16
local LAB_W = 260   -- Genug Platz für Raid-Namen
local COL_W = 68
local PAD   = 6

-- ============================================================
-- UI
-- ============================================================
local mainFrame    = nil
local contentFrame = nil
local view         = "main"

local function ClearContent()
    if not contentFrame then return end
    for _, c in ipairs({contentFrame:GetChildren()}) do c:SetParent(nil); c:Hide() end
    for _, r in ipairs({contentFrame:GetRegions()})  do r:Hide() end
end

local function CreateUI()
    if mainFrame then return end

    mainFrame = CreateFrame("Frame", "AklimeModCTFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(960, 640)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetFrameStrata("HIGH")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop",  mainFrame.StopMovingOrSizing)
    mainFrame:SetClampedToScreen(true)
    mainFrame:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets   = { left=3, right=3, top=3, bottom=3 },
    })
    mainFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    mainFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
    mainFrame:Hide()

    -- ESC schließt
    table.insert(UISpecialFrames, "AklimeModCTFrame")

    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", mainFrame, "TOP", 0, -10)
    title:SetText(NORMAL_FONT_COLOR_CODE .. "Charakter-Tracker" .. FONT_COLOR_CODE_CLOSE)

    -- Gold-Summary oben links
    local goldBtn = CreateFrame("Button", nil, mainFrame)
    goldBtn:SetSize(120, 28)
    goldBtn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 8, -4)
    local goldLabel = goldBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    goldLabel:SetAllPoints(goldBtn)
    goldLabel:SetJustifyH("LEFT")
    goldLabel:SetText("|cFFFFD100Gold-Übersicht|r")

    mainFrame.goldBtn   = goldBtn
    mainFrame.goldLabel = goldLabel

    -- Instanz-Timer rechts vom Gold-Label
    local instBtn = CreateFrame("Button", nil, mainFrame)
    instBtn:SetSize(150, 28)
    instBtn:SetPoint("LEFT", goldBtn, "RIGHT", 4, 0)
    local instLabel = instBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instLabel:SetAllPoints(instBtn)
    instLabel:SetJustifyH("LEFT")

    -- Label dynamisch: zeigt Anzahl kürzlicher Instanzen (eigenes Tracking)
    local function GetInstHistory()
        return AklimeModDB and AklimeModDB.tracker and AklimeModDB.tracker.instanceHistory or {}
    end
    local function CountRecentInst()
        local now, cnt = time(), 0
        for _, e in ipairs(GetInstHistory()) do
            if type(e) == "table" and e.t and now - e.t < 3600 then cnt = cnt + 1 end
        end
        return cnt
    end
    local function UpdateInstLabel()
        local cnt = CountRecentInst()
        if cnt > 0 then
            local color = cnt >= 8 and "|cFFFF4444" or cnt >= 5 and "|cFFFFD100" or "|cFF00FF00"
            instLabel:SetText(color .. cnt .. "/10|r Instanzen")
        else
            instLabel:SetText("|cFFAAAAAA0/10 Instanzen|r")
        end
    end
    UpdateInstLabel()
    mainFrame.UpdateInstLabel = UpdateInstLabel

    instBtn:SetScript("OnEnter", function(self)
        UpdateInstLabel()
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cFFFFD100Kürzliche Instanzen|r")
        GameTooltip:AddLine(" ")

        local history = GetInstHistory()
        local now     = time()
        local recent  = {}
        for _, e in ipairs(history) do
            if type(e) == "table" and e.t and now - e.t < 3600 then
                recent[#recent+1] = e
            end
        end
        -- Ältester Eintritt zuerst
        table.sort(recent, function(a, b) return a.t < b.t end)

        if #recent > 0 then
            for _, e in ipairs(recent) do
                local remaining = e.t + 3600 - now
                local m = math.floor(remaining / 60)
                local s = remaining % 60
                local timeStr = string.format("|cFFFF4444%d Min. %d Sek.|r", m, s)
                GameTooltip:AddDoubleLine(timeStr, e.name or "?", 1,1,1, 0.8,0.8,0.8)
            end
            GameTooltip:AddLine(" ")
            if #recent >= 10 then
                local freeIn = recent[1].t + 3600 - now
                local m = math.floor(freeIn / 60)
                GameTooltip:AddLine(string.format("Nächster Slot frei in: |cFF00FF00%d Min.|r", m))
            else
                GameTooltip:AddLine(string.format("Noch |cFF00FF00%d|r Instanzen verfügbar", 10 - #recent))
            end
        else
            GameTooltip:AddLine("Keine kürzlichen Instanzen.", 0.6,0.6,0.6)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Limit: 10 Instanzen pro Stunde (Account)", 0.5,0.5,0.5)
        GameTooltip:Show()
    end)
    instBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    goldBtn:SetScript("OnEnter", function(self)
        local siDB = GetDataDB()
        if not siDB then return end

        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cFFFFD100Gold-Übersicht|r")

        -- ALLE bekannten Chars (nicht nur ausgewählte)
        local byRealm = {}
        local realmOrder = {}

        for name, toon in pairs(siDB.Toons) do
            local realm = name:match("%-(.+)$") or "?"
            if not byRealm[realm] then
                byRealm[realm] = { total=0, chars={} }
                realmOrder[#realmOrder+1] = realm
            end
            local money = toon.Money or 0
            local gold  = math.floor(money / 10000)
            byRealm[realm].total = byRealm[realm].total + gold
            byRealm[realm].chars[#byRealm[realm].chars+1] = { name=name, toon=toon, gold=gold }
        end
        table.sort(realmOrder)

        local grandTotal = 0
        for _, realm in ipairs(realmOrder) do
            local data = byRealm[realm]
            grandTotal = grandTotal + data.total
            -- Realm-Header
            GameTooltip:AddLine("|cFF888888" .. realm .. "|r")
            -- Chars sortiert
            table.sort(data.chars, function(a,b) return a.name < b.name end)
            for _, entry in ipairs(data.chars) do
                local r, g, b = ToonClassCol(entry.toon)
                local nameStr = string.format("|cFF%02x%02x%02x%s|r", r*255, g*255, b*255, ShortName(entry.name))
                GameTooltip:AddDoubleLine(
                    nameStr,
                    "|cFFFFD100" .. (FormatAmount(entry.gold) or "0") .. " g|r",
                    1,1,1, 1,1,1)
            end
            -- Realm-Summe
            GameTooltip:AddDoubleLine(
                "|cFFFFFFFF  Gesamt|r",
                "|cFFFFD100" .. (FormatAmount(data.total) or "0") .. " g|r",
                1,1,1, 1,1,1)
            GameTooltip:AddLine(" ")
        end

        -- Kriegsmeutengeld
        local guildTotal = 0
        for _, toon in pairs(siDB.Toons) do
            if toon.GuildMoney and toon.GuildMoney > 0 then
                guildTotal = guildTotal + math.floor(toon.GuildMoney / 10000)
            end
        end
        if guildTotal > 0 then
            GameTooltip:AddDoubleLine(
                "|cFFCCCCCCKriegsmeutengeld|r",
                "|cFFFFD100" .. (FormatAmount(guildTotal) or "0") .. " g|r",
                1,1,1, 1,1,1)
            grandTotal = grandTotal + guildTotal
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(
            "|cFFFFFFFFGesamt Geld|r",
            "|cFFFFD100" .. (FormatAmount(grandTotal) or "0") .. " g|r",
            1,1,1, 1,1,1)
        GameTooltip:Show()
    end)
    goldBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 2, 2)
    closeBtn:SetScript("OnClick", function() mainFrame:Hide() end)

    local charBtn = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    charBtn:SetSize(110, 20)
    charBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -28, -8)
    charBtn:SetText("Charaktere")
    charBtn:SetScript("OnClick", function()
        if view == "main" then
            view = "chars"
            charBtn:SetText("Übersicht")
            AklimeMod_CT_ShowChars()
        else
            view = "main"
            charBtn:SetText("Charaktere")
            AklimeMod_CT_Refresh()
        end
    end)

    local scroll = CreateFrame("ScrollFrame", nil, mainFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     mainFrame, "TOPLEFT",     6, -34)
    scroll:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -24, 6)

    contentFrame = CreateFrame("Frame", nil, scroll)
    contentFrame:SetWidth(920)
    contentFrame:SetHeight(1000)
    scroll:SetScrollChild(contentFrame)
end

-- Zeile
local function MkRow(parent, y, even)
    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(ROW_H)
    f:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, -y)
    f:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -y)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    bg:SetColorTexture(even and 0.09 or 0.06, even and 0.09 or 0.06, even and 0.09 or 0.06, 0.7)
    return f
end

local function MkHdr(parent, y)
    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(ROW_H)
    f:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, -y)
    f:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -y)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(f)
    bg:SetColorTexture(0.15, 0.15, 0.15, 0.9)
    return f
end

local function MkTxt(parent, text, x, w, font, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormalSmall")
    fs:SetPoint("LEFT", parent, "LEFT", x, 0)
    fs:SetWidth(w)
    fs:SetJustifyH(justify or "LEFT")
    fs:SetText(text or "")
    return fs
end

-- Charakter-Header-Button mit Hover-Tooltip (wie SI)
local function MkCharHeader(parent, y, colX, sel, siDB)
    local hRow = MkHdr(parent, y)
    for i, name in ipairs(sel) do
        local toon = siDB.Toons[name]
        local label = ShortName(name)
        local r, g, b = ToonClassCol(toon)

        -- Unsichtbarer Button über der Spalte für Hover-Tooltip
        local btn = CreateFrame("Button", nil, hRow)
        btn:SetSize(COL_W, ROW_H)
        btn:SetPoint("LEFT", hRow, "LEFT", colX + (i-1)*COL_W, 0)

        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetAllPoints(btn)
        fs:SetJustifyH("CENTER")
        fs:SetText(string.format("|cFF%02x%02x%02x%s|r", r*255, g*255, b*255, label))

        -- Tooltip mit Char-Infos (wie SI)
        local n = name
        btn:SetScript("OnEnter", function(self)
            local t = siDB.Toons[n]
            if not t then return end
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:ClearLines()
            local tr, tg, tb = ToonClassCol(t)
            GameTooltip:AddLine(string.format("|cFF%02x%02x%02x%s|r", tr*255, tg*255, tb*255, n))
            if t.Class then
                -- Erste Buchstabe groß, Rest klein
                local class = t.Class:sub(1,1):upper() .. t.Class:sub(2):lower()
                GameTooltip:AddLine(class, 0.8, 0.8, 0.8)
            end
            if t.Level then
                GameTooltip:AddDoubleLine("Level", tostring(t.Level), 0.8,0.8,0.8, 1,0.82,0)
            end
            if t.IL then
                GameTooltip:AddDoubleLine("Gegenstandsstufe", string.format("%.1f", t.IL), 0.8,0.8,0.8, 1,0.82,0)
            end
            if t.Money and t.Money > 0 then
                local gold   = math.floor(t.Money / 10000)
                local silver = math.floor((t.Money % 10000) / 100)
                local copper = t.Money % 100
                local goldStr = string.format("|cFFFFD100%dg|r |cFFCCCCCC%ds|r |cFFCC6633%dc|r",
                    gold, silver, copper)
                GameTooltip:AddDoubleLine("Gold", goldStr, 0.8,0.8,0.8, 1,1,1)
            end
            if t.LastSeen then
                local d = date("%d.%m.%Y %H:%M", t.LastSeen)
                GameTooltip:AddDoubleLine("Zuletzt gesehen", d, 0.8,0.8,0.8, 0.7,0.7,0.7)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    return hRow
end

-- ============================================================
-- Hauptansicht
-- ============================================================
function AklimeMod_CT_Refresh()
    CreateUI()
    ClearContent()
    view = "main"
    if mainFrame and mainFrame.charBtn then mainFrame.charBtn:SetText("Charaktere") end

    local siDB = GetDataDB()
    if not siDB then
        local fs = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("CENTER", contentFrame, "CENTER")
        fs:SetText("Keine Daten. Logge dich mit deinen Charakteren ein.")
        fs:SetTextColor(0.7, 0.7, 0.7, 1)
        contentFrame:Show(); return
    end

    local sel = GetSelectedChars()
    if #sel == 0 then
        local fs = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("CENTER", contentFrame, "CENTER")
        fs:SetText("Keine Charaktere ausgewählt.\nKlicke auf 'Charaktere'.")
        fs:SetTextColor(0.7, 0.7, 0.7, 1)
        contentFrame:Show(); return
    end

    -- Fensterbreite anpassen
    local totalW = LAB_W + PAD + #sel * COL_W + 40
    mainFrame:SetWidth(math.max(700, totalW))
    contentFrame:SetWidth(math.max(660, totalW - 40))

    local colX = LAB_W + PAD
    local y    = 4

    -- Charakter-Header mit Hover-Tooltip
    MkCharHeader(contentFrame, y, colX, sel, siDB)
    y = y + ROW_H

    -- ── Große Schatzkammer ────────────────────────────────────
    local hasVaultData = false
    for _, ch in ipairs(sel) do
        local toon = siDB.Toons[ch]
        if toon and toon.weeklyVault then hasVaultData = true; break end
    end

    if hasVaultData then
        y = y + 4
        local vHdr = MkHdr(contentFrame, y)
        local vFs = vHdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        vFs:SetPoint("LEFT", vHdr, "LEFT", 8, 0)
        vFs:SetText(NORMAL_FONT_COLOR_CODE .. "Große Schatzkammer" .. FONT_COLOR_CODE_CLOSE)
        y = y + ROW_H

        local VAULT_ROWS = {
            { key = "raid",    label = "Schlachtzüge" },
            { key = "dungeon", label = "Dungeons" },
            { key = "world",   label = "Weltaktivitäten" },
        }
        for ri, vr in ipairs(VAULT_ROWS) do
            local row = MkRow(contentFrame, y, ri%2==0)
            MkTxt(row, NORMAL_FONT_COLOR_CODE .. vr.label .. FONT_COLOR_CODE_CLOSE,
                8, LAB_W - 4, "GameFontNormalSmall", "LEFT")
            for ci, ch in ipairs(sel) do
                local toon = siDB.Toons[ch]
                local vault = toon and toon.weeklyVault
                local slots = vault and vault[vr.key]
                local txt
                if slots == nil then
                    txt = GRAY_FONT_COLOR_CODE .. "-" .. FONT_COLOR_CODE_CLOSE
                elseif slots >= 3 then
                    txt = GREEN_FONT_COLOR_CODE .. "3/3" .. FONT_COLOR_CODE_CLOSE
                elseif slots > 0 then
                    txt = NORMAL_FONT_COLOR_CODE .. slots .. "/3" .. FONT_COLOR_CODE_CLOSE
                else
                    txt = GRAY_FONT_COLOR_CODE .. "0/3" .. FONT_COLOR_CODE_CLOSE
                end
                MkTxt(row, txt, colX + (ci-1)*COL_W, COL_W, "GameFontNormalSmall", "CENTER")
            end
            y = y + ROW_H
        end

        -- Vierte Zeile: offen = Belohnung verfügbar aber noch nicht abgeholt
        local rewardRow = MkRow(contentFrame, y, false)
        MkTxt(rewardRow, NORMAL_FONT_COLOR_CODE .. "Belohnung" .. FONT_COLOR_CODE_CLOSE,
            8, LAB_W - 4, "GameFontNormalSmall", "LEFT")
        for ci, ch in ipairs(sel) do
            local toon = siDB.Toons[ch]
            local vault = toon and toon.weeklyVault
            local txt
            if vault and vault.hasRewards then
                txt = GREEN_FONT_COLOR_CODE .. "offen" .. FONT_COLOR_CODE_CLOSE
            else
                txt = GRAY_FONT_COLOR_CODE .. "-" .. FONT_COLOR_CODE_CLOSE
            end
            MkTxt(rewardRow, txt, colX + (ci-1)*COL_W, COL_W, "GameFontNormalSmall", "CENTER")
        end
        y = y + ROW_H
    end

    -- ── Raids ─────────────────────────────────────────────────
    local raidsByExp = BuildRaids(sel)
    local expIDs = {}
    for e in pairs(raidsByExp) do expIDs[#expIDs+1] = e end
    table.sort(expIDs, function(a,b) return a > b end)

    if #expIDs > 0 then
        y = y + 4
        local raidHdr = MkHdr(contentFrame, y)
        local secFs = raidHdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        secFs:SetPoint("LEFT", raidHdr, "LEFT", 8, 0)
        secFs:SetText(NORMAL_FONT_COLOR_CODE .. "Schlachtzüge" .. FONT_COLOR_CODE_CLOSE)
        y = y + ROW_H

        for _, exp in ipairs(expIDs) do
            -- Trennlinie + Erweiterungs-Header (gleicher Style wie Realm)
            y = y + 4
            local sep = contentFrame:CreateTexture(nil, "ARTWORK")
            sep:SetHeight(1)
            sep:SetPoint("TOPLEFT",  contentFrame, "TOPLEFT",  0, -y)
            sep:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", 0, -y)
            sep:SetColorTexture(0.4, 0.35, 0.1, 0.7)
            y = y + 2
            local expHdr = MkHdr(contentFrame, y)
            local expFs  = expHdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            expFs:SetPoint("LEFT", expHdr, "LEFT", 8, 0)
            expFs:SetText(NORMAL_FONT_COLOR_CODE .. (EXP_NAMES[exp] or ("Expansion "..exp)) .. FONT_COLOR_CODE_CLOSE)
            y = y + ROW_H + 2

            for ri, raid in ipairs(raidsByExp[exp]) do
                local activeDiffs = {}
                for _, d in ipairs(DIFF_ORDER) do
                    if raid.diffs[d] then activeDiffs[#activeDiffs+1] = d end
                end

                for _, diff in ipairs(activeDiffs) do
                    local diffLabel = GetDiffLabel(raid.inst, diff) or ("D"..diff)
                    local dc        = DIFF_COLOR[diff] or {r=1,g=1,b=1}
                    local dcHex     = string.format("|cFF%02x%02x%02x", dc.r*255, dc.g*255, dc.b*255)

                    -- Name: wenn mehrere Diffs, Kürzel anhängen
                    local displayName = raid.name
                    if #activeDiffs > 1 then
                        displayName = raid.name .. " " .. dcHex .. "[" .. diffLabel .. "]" .. FONT_COLOR_CODE_CLOSE
                    end

                    local row = MkRow(contentFrame, y, ri%2==0)

                    local anySaved = false
                    for _, ch in ipairs(sel) do
                        if raid.diffs[diff] and raid.diffs[diff][ch] then anySaved = true; break end
                    end

                    MkTxt(row,
                        (anySaved and NORMAL_FONT_COLOR_CODE or GRAY_FONT_COLOR_CODE)
                        .. displayName .. FONT_COLOR_CODE_CLOSE,
                        8, LAB_W - 4, "GameFontNormalSmall", "LEFT")

                    for ci, ch in ipairs(sel) do
                        local save = raid.diffs[diff] and raid.diffs[diff][ch]
                        local txt  = ""
                        if save then
                            local killed = GetBossKills(save)
                            local total  = GetBossTotal(save)

                            if total > 0 then
                                txt = dcHex .. killed .. "/" .. total .. FONT_COLOR_CODE_CLOSE
                            else
                                txt = dcHex .. (killed > 0 and tostring(killed) or "L") .. FONT_COLOR_CODE_CLOSE
                            end

                            -- Hover-Button für Boss-Liste
                            local btn = CreateFrame("Button", nil, row)
                            btn:SetSize(COL_W, ROW_H)
                            btn:SetPoint("LEFT", row, "LEFT", colX + (ci-1)*COL_W, 0)
                            local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                            fs:SetAllPoints(btn)
                            fs:SetJustifyH("CENTER")
                            fs:SetText(txt)

                            local saveRef = save
                            local raidName = raid.name
                            local charName = ch
                            local diffLabel2 = diffLabel
                            local dc2 = dc
                            btn:SetScript("OnEnter", function(self)
                                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                                GameTooltip:ClearLines()
                                -- Header
                                GameTooltip:AddLine(NORMAL_FONT_COLOR_CODE .. raidName .. FONT_COLOR_CODE_CLOSE
                                    .. "  " .. string.format("|cFF%02x%02x%02x%s|r",
                                        dc2.r*255, dc2.g*255, dc2.b*255, diffLabel2))
                                local toon = siDB and siDB.Toons and siDB.Toons[charName]
                                if toon then
                                    local r, g, b = ToonClassCol(toon)
                                    GameTooltip:AddLine(string.format("|cFF%02x%02x%02x%s|r",
                                        r*255, g*255, b*255, ShortName(charName)))
                                end
                                -- Verbleibende Zeit
                                if saveRef.Expires and saveRef.Expires > time() then
                                    local secs = saveRef.Expires - time()
                                    local h = math.floor(secs / 3600)
                                    local m = math.floor((secs % 3600) / 60)
                                    GameTooltip:AddDoubleLine("Verbleibende Zeit:",
                                        string.format("%d Std. %d Min.", h, m),
                                        0.8,0.8,0.8, 1,0.82,0)
                                end
                                GameTooltip:AddLine(" ")
                                -- Boss-Liste aus gespeichertem save.bosses (von DataCollector)
                                if saveRef.bosses and #saveRef.bosses > 0 then
                                    for _, boss in ipairs(saveRef.bosses) do
                                        if boss.killed then
                                            GameTooltip:AddDoubleLine(boss.name, "Bezwungen", 1,1,1, 1,0.2,0.2)
                                        else
                                            GameTooltip:AddDoubleLine(boss.name, "Verfügbar", 1,1,1, 0.2,1,0.2)
                                        end
                                    end
                                elseif saveRef.Link then
                                    -- Fallback: Boss-Namen per LFG-API
                                    local lid = saveRef.Link:match("instancelock:[^:]+:(%d+):")
                                    lid = lid and tonumber(lid)
                                    if lid then
                                        local ok2, bossCount = pcall(GetLFGDungeonNumEncounters, lid)
                                        if ok2 and bossCount and bossCount > 0 then
                                            for bi = 1, bossCount do
                                                local bossName = GetLFGDungeonEncounterInfo(lid, bi)
                                                if bossName then
                                                    GameTooltip:AddLine(bossName, 0.8, 0.8, 0.8)
                                                end
                                            end
                                        end
                                    end
                                end
                                GameTooltip:Show()
                            end)
                            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                        else
                            MkTxt(row, txt, colX + (ci-1)*COL_W, COL_W, "GameFontNormalSmall", "CENTER")
                        end
                    end
                    y = y + ROW_H
                end
            end
        end
    end

    -- ── Währungen ─────────────────────────────────────────────
    local currencies = BuildCurrencies(sel)
    if #currencies > 0 then
        y = y + 4
        local wHdr = MkHdr(contentFrame, y)
        local wFs  = wHdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        wFs:SetPoint("LEFT", wHdr, "LEFT", 8, 0)
        wFs:SetText(NORMAL_FONT_COLOR_CODE .. "Währungen" .. FONT_COLOR_CODE_CLOSE)
        y = y + ROW_H

        local lastExp = -999  -- Sentinel der nie matcht
        for ri, ce in ipairs(currencies) do
            if ce.exp ~= lastExp then
                lastExp = ce.exp
                -- Trennlinie
                y = y + 4
                local sep = contentFrame:CreateTexture(nil, "ARTWORK")
                sep:SetHeight(1)
                sep:SetPoint("TOPLEFT",  contentFrame, "TOPLEFT",  0, -y)
                sep:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", 0, -y)
                sep:SetColorTexture(0.4, 0.35, 0.1, 0.7)
                y = y + 2
                -- Expansion-Header (gleicher Style wie Realm-Header)
                local eHdr = MkHdr(contentFrame, y)
                local eFs  = eHdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                eFs:SetPoint("LEFT", eHdr, "LEFT", 8, 0)
                eFs:SetText(NORMAL_FONT_COLOR_CODE .. (EXP_NAMES[ce.exp] or ("Expansion "..ce.exp)) .. FONT_COLOR_CODE_CLOSE)
                y = y + ROW_H + 2
            end

            local row = MkRow(contentFrame, y, ri%2==0)
            -- Icon + Name
            local iconStr = ce.icon and ("|T" .. ce.icon .. ":14:14:0:0|t ") or ""
            MkTxt(row, iconStr .. NORMAL_FONT_COLOR_CODE .. ce.name .. FONT_COLOR_CODE_CLOSE,
                8, LAB_W - 4, "GameFontNormalSmall", "LEFT")

            for ci, ch in ipairs(sel) do
                local toon = siDB.Toons[ch]
                local amt  = toon and toon.currency and toon.currency[ce.id]
                           and toon.currency[ce.id].amount
                local txt
                if amt and amt > 0 then
                    txt = GREEN_FONT_COLOR_CODE .. FormatAmount(amt) .. FONT_COLOR_CODE_CLOSE
                else
                    txt = GRAY_FONT_COLOR_CODE .. "-" .. FONT_COLOR_CODE_CLOSE
                end

                -- Hover-Button: alle Chars für diese Währung anzeigen
                local btn = CreateFrame("Button", nil, row)
                btn:SetSize(COL_W, ROW_H)
                btn:SetPoint("LEFT", row, "LEFT", colX + (ci-1)*COL_W, 0)
                local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                fs:SetAllPoints(btn); fs:SetJustifyH("CENTER"); fs:SetText(txt)

                local ceid = ce.id
                local ceicon = ce.icon
                local cename = ce.name
                local allSel = sel
                btn:SetScript("OnEnter", function(self)
                    local db2 = GetDataDB()
                    if not db2 then return end
                    GameTooltip:SetOwner(self, "ANCHOR_TOP")
                    GameTooltip:ClearLines()
                    local iStr = ceicon and ("|T"..ceicon..":14:14|t ") or ""
                    GameTooltip:AddLine(iStr .. NORMAL_FONT_COLOR_CODE .. cename .. FONT_COLOR_CODE_CLOSE)
                    GameTooltip:AddLine(" ")
                    for _, charName in ipairs(allSel) do
                        local t = db2.Toons[charName]
                        local a = t and t.currency and t.currency[ceid] and t.currency[ceid].amount
                        if a and a > 0 then
                            local r2,g2,b2 = ToonClassCol(t)
                            local nameStr = string.format("|cFF%02x%02x%02x%s|r", r2*255,g2*255,b2*255, ShortName(charName))
                            GameTooltip:AddDoubleLine(nameStr,
                                GREEN_FONT_COLOR_CODE .. FormatAmount(a) .. FONT_COLOR_CODE_CLOSE,
                                1,1,1, 1,1,1)
                        end
                    end
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
            y = y + ROW_H
        end
    end

    y = y + 12
    contentFrame:SetHeight(y)
    contentFrame:Show()
end

-- ============================================================
-- Char-Auswahl
-- ============================================================
function AklimeMod_CT_ShowChars()
    CreateUI()
    ClearContent()
    view = "chars"
    if mainFrame and mainFrame.charBtn then mainFrame.charBtn:SetText("Übersicht") end

    local siDB = GetDataDB()
    local myDB = GetDB()
    if not siDB or not siDB.Toons or not myDB then
        contentFrame:Show(); return
    end
    myDB.chars = myDB.chars or {}

    local toons = {}
    for name, data in pairs(siDB.Toons) do
        toons[#toons+1] = { name=name, data=data }
    end
    table.sort(toons, function(a, b)
        local ra = a.name:match("%-(.+)$") or ""
        local rb = b.name:match("%-(.+)$") or ""
        if ra ~= rb then return ra < rb end
        return a.name < b.name
    end)

    local y = 10
    local hdr = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 8, -y)
    hdr:SetText(NORMAL_FONT_COLOR_CODE .. "Charaktere auswählen" .. FONT_COLOR_CODE_CLOSE
        .. "  — Haken = in Übersicht anzeigen")
    y = y + 24

    local chdr = MkHdr(contentFrame, y)
    MkTxt(chdr, "Charakter", 36, 200, "GameFontNormal")
    MkTxt(chdr, "Klasse",   240, 130, "GameFontNormal")
    MkTxt(chdr, "Level",    375,  50, "GameFontNormal")
    MkTxt(chdr, "iLvl",     430,  55, "GameFontNormal")
    y = y + ROW_H + 2

    local lastRealm = nil
    for ri, entry in ipairs(toons) do
        local name  = entry.name
        local data  = entry.data
        local realm = name:match("%-(.+)$") or ""

        -- Realm-Header VOR den Chars dieses Realms
        if realm ~= lastRealm then
            lastRealm = realm
            -- Trennlinie
            y = y + 4
            local sep = contentFrame:CreateTexture(nil, "ARTWORK")
            sep:SetHeight(1)
            sep:SetPoint("TOPLEFT",  contentFrame, "TOPLEFT",  0, -y)
            sep:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", 0, -y)
            sep:SetColorTexture(0.4, 0.35, 0.1, 0.7)
            y = y + 2
            -- Realm-Name
            local rHdr = MkHdr(contentFrame, y)
            local rFs = rHdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rFs:SetPoint("LEFT", rHdr, "LEFT", 8, 0)
            rFs:SetText(NORMAL_FONT_COLOR_CODE .. (realm ~= "" and realm or "?") .. FONT_COLOR_CODE_CLOSE)
            y = y + ROW_H + 2
        end

        local row = MkRow(contentFrame, y, ri%2==0)

        local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        cb:SetSize(18, 18)
        cb:SetPoint("LEFT", row, "LEFT", 8, 0)
        cb:SetChecked(myDB.chars[name] == true)
        local n = name
        cb:SetScript("OnClick", function(self)
            myDB.chars[n] = self:GetChecked() and true or nil
        end)

        local dispName = ShortName(name)
        local r, g, b = ToonClassCol(data)
        MkTxt(row, string.format("|cFF%02x%02x%02x%s|r", r*255, g*255, b*255, dispName),
            36, 200, "GameFontNormalSmall")
        -- Klasse: erste Buchstabe groß
        local classDisp = data.Class and (data.Class:sub(1,1):upper() .. data.Class:sub(2):lower()) or "-"
        MkTxt(row, classDisp, 240, 130, "GameFontNormalSmall")
        MkTxt(row, tostring(data.Level or "-"), 375, 50, "GameFontNormalSmall")
        MkTxt(row, data.IL and string.format("%.0f", data.IL) or "-", 430, 55, "GameFontNormalSmall")

        -- Löschen-Button
        local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        delBtn:SetSize(60, 16)
        delBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        delBtn:SetText("Löschen")
        delBtn:GetFontString():SetTextColor(1, 0.3, 0.3)
        local delName = name
        delBtn:SetScript("OnClick", function()
            -- Aus Auswahl und aus Tracker-DB entfernen
            if myDB.chars then myDB.chars[delName] = nil end
            local tdb = AklimeModDB and AklimeModDB.tracker
            if tdb then
                if tdb.Toons then tdb.Toons[delName] = nil end
                if tdb.Instances then
                    for _, inst in pairs(tdb.Instances) do
                        inst[delName] = nil
                    end
                end
            end
            AklimeMod_CT_ShowChars()
        end)
        y = y + ROW_H
    end

    y = y + 8
    local btnAll = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    btnAll:SetSize(130, 22); btnAll:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 8, -y)
    btnAll:SetText("Alle auswählen")
    btnAll:SetScript("OnClick", function()
        for _, e in ipairs(toons) do myDB.chars[e.name] = true end
        AklimeMod_CT_ShowChars()
    end)

    local btnNone = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    btnNone:SetSize(130, 22); btnNone:SetPoint("LEFT", btnAll, "RIGHT", 6, 0)
    btnNone:SetText("Alle abwählen")
    btnNone:SetScript("OnClick", function()
        myDB.chars = {}; AklimeMod_CT_ShowChars()
    end)

    local btnOK = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    btnOK:SetSize(110, 22); btnOK:SetPoint("LEFT", btnNone, "RIGHT", 6, 0)
    btnOK:SetText("Übernehmen")
    btnOK:SetScript("OnClick", function()
        view = "main"; AklimeMod_CT_Refresh()
    end)

    y = y + 30
    contentFrame:SetHeight(y + 10)
    contentFrame:Show()
end

-- ============================================================
-- Toggle
-- ============================================================
function AklimeMod_CT_Toggle()
    CreateUI()
    if mainFrame:IsShown() then mainFrame:Hide()
    else AklimeMod_CT_Refresh(); mainFrame:Show() end
end