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
    [1904]=true,  -- Tower Knowledge (intern)
    [2045]=true,  -- Dragon Glyph Embers (intern)
}

-- Alle SI Currency-IDs (1:1 aus SI Currency.lua)
local SI_CURRENCY_IDS = {
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
    -- Midnight
    3319, 3316, 3376, 3377, 3379, 3385, 3392, 3400, 3373, 3393, 3405,
    3256, 3257, 3258, 3259, 3260, 3261, 3262, 3263, 3264, 3265, 3266,
    3028, 3310, 3212, 3378, 3383, 3341, 3343, 3345, 3347, 3418,
}

-- ============================================================
-- Difficulty
-- ============================================================
local function GetDiffLabel(inst, diff)
    if not inst.Raid then return nil end
    if inst.Expansion == 0 then return "Classic" end
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
    [0]="Classic",[1]="The Burning Crusade",[2]="Wrath of the Lich King",
    [3]="Cataclysm",[4]="Mists of Pandaria",[5]="Warlords of Draenor",
    [6]="Legion",[7]="Battle for Azeroth",[8]="Shadowlands",
    [9]="Dragonflight",[10]="The War Within",[11]="Midnight",
}

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

-- ============================================================
-- Hilfsfunktionen
-- ============================================================
local function ShortName(full)
    return full:match("^(.-)%s*%-") or full
end

local function ClassCol(lclass)
    if not lclass then return 1, 0.82, 0 end
    local ci = RAID_CLASS_COLORS and RAID_CLASS_COLORS[lclass:upper()]
    if ci then return ci.r, ci.g, ci.b end
    return 1, 0.82, 0
end

local function GetBossKills(save)
    if not save then return 0 end
    if save.Link then
        local bits = save.Link:match(":(%d+)\124h")
        bits = bits and tonumber(bits)
        if bits then
            local k = 0
            while bits > 0 do
                if bit.band(bits, 1) > 0 then k = k + 1 end
                bits = bit.rshift(bits, 1)
            end
            return k
        end
    end
    if save.ID and save.ID < 0 then
        local k = 0
        for i = 1, -1 * save.ID do if save[i] then k = k + 1 end end
        return k
    end
    return 0
end

local function GetBossTotal(lfdid)
    if not lfdid then return 0 end
    local ok, n = pcall(GetLFGDungeonNumEncounters, lfdid)
    return (ok and n) or 0
end

local currInfoCache = {}
local function GetCurrInfo(id)
    if currInfoCache[id] then return currInfoCache[id] end
    if C_CurrencyInfo then
        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
        if ok and info and info.name and info.name ~= "" then
            currInfoCache[id] = { name=info.name, exp=info.expansionID or 0, icon=info.iconFileID }
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

-- ============================================================
-- Daten
-- ============================================================
local function GetSelectedChars()
    local db   = GetDB()
    local siDB = _G.SavedInstancesDB
    if not siDB or not siDB.Toons then return {} end
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
    local siDB = _G.SavedInstancesDB
    if not siDB or not siDB.Instances then return {} end
    local byExp = {}
    for instName, inst in pairs(siDB.Instances) do
        if inst.Raid and inst.Show ~= "never" and IsRaidExpEnabled(inst.Expansion or 0) then
            local exp   = inst.Expansion or 0
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
                    name=instName, lfdid=inst.LFDID,
                    recLevel=inst.RecLevel or 0,
                    diffs=diffs, inst=inst,
                }
            end
        end
    end
    for _, raids in pairs(byExp) do
        table.sort(raids, function(a,b) return (a.recLevel or 0) > (b.recLevel or 0) end)
    end
    return byExp
end

local function BuildCurrencies(sel)
    local siDB = _G.SavedInstancesDB
    if not siDB or not siDB.Toons then return {} end

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
        if siSet[id] and IsCurrencyEnabled(id) then
            local info = GetCurrInfo(id)
            if info then
                -- Zusätzlich: Namen die "Hidden" oder "DNT" enthalten herausfiltern
                local nameLower = info.name:lower()
                if not nameLower:find("hidden") and not nameLower:find("dnt")
                and not nameLower:find("personal tracker")
                and not nameLower:find("loot ") then
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
    goldBtn:SetSize(140, 28)
    goldBtn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 8, -4)
    local goldLabel = goldBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    goldLabel:SetAllPoints(goldBtn)
    goldLabel:SetJustifyH("LEFT")
    goldLabel:SetText("|cFFFFD100Gold-Übersicht|r")

    mainFrame.goldBtn   = goldBtn
    mainFrame.goldLabel = goldLabel

    goldBtn:SetScript("OnEnter", function(self)
        local siDB = _G.SavedInstancesDB
        if not siDB or not siDB.Toons then return end

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
                local r, g, b = ClassCol(entry.toon.LClass)
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
        if view == "main" then view = "chars"; AklimeMod_CT_ShowChars()
        else view = "main"; AklimeMod_CT_Refresh() end
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
        local r, g, b = ClassCol(toon and toon.LClass)

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
            local tr, tg, tb = ClassCol(t.LClass)
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

    local siDB = _G.SavedInstancesDB
    if not siDB or not siDB.Toons then
        local fs = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("CENTER", contentFrame, "CENTER")
        fs:SetText("SavedInstances Addon nicht gefunden.")
        fs:SetTextColor(1, 0.3, 0.3, 1)
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

    -- ── Raids ─────────────────────────────────────────────────
    local raidsByExp = BuildRaids(sel)
    local expIDs = {}
    for e in pairs(raidsByExp) do expIDs[#expIDs+1] = e end
    table.sort(expIDs, function(a,b) return a > b end)

    if #expIDs > 0 then
        y = y + 4
        MkHdr(contentFrame, y)
        local secFs = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        secFs:SetPoint("LEFT", contentFrame, "LEFT", 4, -(y + ROW_H/2))
        secFs:SetText(NORMAL_FONT_COLOR_CODE .. "Schlachtzüge" .. FONT_COLOR_CODE_CLOSE)
        y = y + ROW_H

        for _, exp in ipairs(expIDs) do
            -- Trennlinie + Erweiterungs-Label
            y = y + 4
            local sep = contentFrame:CreateTexture(nil, "ARTWORK")
            sep:SetHeight(1)
            sep:SetPoint("TOPLEFT",  contentFrame, "TOPLEFT",  0, -(y))
            sep:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", 0, -(y))
            sep:SetColorTexture(0.3, 0.3, 0.3, 0.6)
            y = y + 2
            local expFs = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            expFs:SetPoint("LEFT", contentFrame, "LEFT", 4, -(y + ROW_H/2))
            expFs:SetTextColor(0.7, 0.65, 0.4, 1)
            expFs:SetText(EXP_NAMES[exp] or ("Expansion "..exp))
            y = y + ROW_H

            for ri, raid in ipairs(raidsByExp[exp]) do
                local activeDiffs = {}
                for _, d in ipairs(DIFF_ORDER) do
                    if raid.diffs[d] then activeDiffs[#activeDiffs+1] = d end
                end

                for _, diff in ipairs(activeDiffs) do
                    local diffLabel = GetDiffLabel(raid.inst, diff) or ("D"..diff)
                    local total     = GetBossTotal(raid.lfdid)
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
                            if total > 0 then
                                txt = dcHex .. killed .. "/" .. total .. FONT_COLOR_CODE_CLOSE
                            else
                                txt = dcHex .. (killed > 0 and tostring(killed) or "L") .. FONT_COLOR_CODE_CLOSE
                            end
                        end
                        MkTxt(row, txt, colX + (ci-1)*COL_W, COL_W, "GameFontNormalSmall", "CENTER")
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
        MkHdr(contentFrame, y)
        local wFs = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        wFs:SetPoint("LEFT", contentFrame, "LEFT", 4, -(y + ROW_H/2))
        wFs:SetText(NORMAL_FONT_COLOR_CODE .. "Währungen" .. FONT_COLOR_CODE_CLOSE)
        y = y + ROW_H

        local lastExp = -1
        for ri, ce in ipairs(currencies) do
            if ce.exp ~= lastExp then
                lastExp = ce.exp
                y = y + 4
                local sep = contentFrame:CreateTexture(nil, "ARTWORK")
                sep:SetHeight(1)
                sep:SetPoint("TOPLEFT",  contentFrame, "TOPLEFT",  0, -(y))
                sep:SetPoint("TOPRIGHT", contentFrame, "TOPRIGHT", 0, -(y))
                sep:SetColorTexture(0.3, 0.3, 0.3, 0.6)
                y = y + 2
                local eFs = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                eFs:SetPoint("LEFT", contentFrame, "LEFT", 4, -(y + ROW_H/2))
                eFs:SetTextColor(0.7, 0.65, 0.4, 1)
                eFs:SetText(EXP_NAMES[ce.exp] or ("Expansion "..ce.exp))
                y = y + ROW_H
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
                MkTxt(row, txt, colX + (ci-1)*COL_W, COL_W, "GameFontNormalSmall", "CENTER")
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

    local siDB = _G.SavedInstancesDB
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
    MkTxt(chdr, "Charakter", 36, 170, "GameFontNormal")
    MkTxt(chdr, "Klasse",   210, 130, "GameFontNormal")
    MkTxt(chdr, "Level",    345,  50, "GameFontNormal")
    MkTxt(chdr, "iLvl",     400,  55, "GameFontNormal")
    MkTxt(chdr, "Realm",    460, 200, "GameFontNormal")
    y = y + ROW_H + 2

    local lastRealm = nil
    for ri, entry in ipairs(toons) do
        local name  = entry.name
        local data  = entry.data
        local realm = name:match("%-(.+)$") or ""

        if realm ~= lastRealm then
            lastRealm = realm
            y = y + 2
            local rFs = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rFs:SetPoint("LEFT", contentFrame, "LEFT", 8, -(y + ROW_H/2))
            rFs:SetText(NORMAL_FONT_COLOR_CODE .. (realm ~= "" and realm or "?") .. FONT_COLOR_CODE_CLOSE)
            y = y + ROW_H
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
        local r, g, b = ClassCol(data.LClass)
        MkTxt(row, string.format("|cFF%02x%02x%02x%s|r", r*255, g*255, b*255, dispName),
            36, 170, "GameFontNormalSmall")
        MkTxt(row, data.Class or "-",  210, 130, "GameFontNormalSmall")
        MkTxt(row, tostring(data.Level or "-"), 345, 50, "GameFontNormalSmall")
        MkTxt(row, data.IL and string.format("%.0f", data.IL) or "-", 400, 55, "GameFontNormalSmall")
        MkTxt(row, realm, 460, 200, "GameFontNormalSmall")
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