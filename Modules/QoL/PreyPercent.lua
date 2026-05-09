-- Modules/QoL/PreyPercent.lua
-- % Leiste oben mittig wenn Jagd aktiv.
-- progressState direkt aus PreyHunt-Frame gelesen.

local BAR_W      = 200
local BAR_H      = 16
local FILL_INSET = 2

-- ============================================================
-- DB
-- ============================================================
local function GetDB()
    return AklimeModDB and AklimeModDB.preyPercent
end
local function IsEnabled()
    local db = GetDB()
    return db and db.enabled
end

-- ============================================================
-- Hilfsfunktionen
-- ============================================================
local function IsValidQuestID(id)
    return type(id) == "number" and id > 0
end

local function GetActivePreyQuestID()
    if C_QuestLog and C_QuestLog.GetActivePreyQuest then
        local ok, id = pcall(C_QuestLog.GetActivePreyQuest)
        if ok and IsValidQuestID(id) then return id end
    end
    return nil
end

local cachedPreyFrame = nil

local function FindPreyFrame()
    if cachedPreyFrame then return cachedPreyFrame end
    local container = _G.UIWidgetPowerBarContainerFrame
    if not container then return nil end
    local ok, children = pcall(function() return { container:GetChildren() } end)
    if not ok then return nil end
    for _, child in ipairs(children) do
        if type(child.ResetAnimState) == "function"
        and type(child.Setup) == "function" then
            cachedPreyFrame = child
            return child
        end
    end
    return nil
end

-- progressState: 0=25%, 1=50%, 2=75%, 3=100%
local function GetPercent()
    local f = FindPreyFrame()
    if not f then return nil end
    local ok, ps = pcall(function() return f.progressState end)
    if not ok or ps == nil then return nil end
    local n = tonumber(tostring(ps))
    if n == nil then return nil end
    if n == 0 then return 25 end
    if n == 1 then return 50 end
    if n == 2 then return 75 end
    if n >= 3 then return 100 end
    return nil
end

-- ============================================================
-- Bar-Frame
-- ============================================================
local barFrame  = nil
local barFill   = nil
local barText   = nil
local isShowing = false

local function EnsureBar()
    if barFrame then return end

    barFrame = CreateFrame("Frame", "AklimeModPreyBar", UIParent)
    barFrame:SetSize(BAR_W, BAR_H)
    barFrame:SetPoint("TOP", UIParent, "TOP", 0, -22)
    barFrame:SetFrameStrata("MEDIUM")
    barFrame:SetFrameLevel(5)
    barFrame:Hide()

    local bg = barFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(barFrame)
    bg:SetColorTexture(0, 0, 0, 0.55)

    local border = CreateFrame("Frame", nil, barFrame, "BackdropTemplate")
    border:SetAllPoints(barFrame)
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    border:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.9)

    barFill = barFrame:CreateTexture(nil, "ARTWORK")
    barFill:SetPoint("BOTTOMLEFT", barFrame, "BOTTOMLEFT", FILL_INSET, FILL_INSET)
    barFill:SetSize(0, BAR_H - 2 * FILL_INSET)
    barFill:SetColorTexture(0.85, 0.2, 0.2, 0.95)
    barFill:Hide()

    barText = barFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    barText:SetPoint("CENTER", barFrame, "CENTER", 0, 0)
    barText:SetDrawLayer("OVERLAY", 9)
    barText:SetText("0%")
end

local function UpdateBar(pct)
    if not barFrame then return end
    pct = math.min(math.max(pct or 0, 0), 100)

    local innerW = BAR_W - 2 * FILL_INSET
    local fillW  = math.max(0, innerW * (pct / 100))
    if fillW > 0 then
        barFill:SetWidth(fillW)
        barFill:Show()
    else
        barFill:SetWidth(0)
        barFill:Hide()
    end

    local r, g, b
    if     pct >= 75 then r, g, b = 0.2,  0.85, 0.2
    elseif pct >= 50 then r, g, b = 0.85, 0.75, 0.1
    elseif pct >= 25 then r, g, b = 0.85, 0.45, 0.1
    else                  r, g, b = 0.85, 0.2,  0.2
    end
    barFill:SetColorTexture(r, g, b, 0.95)

    local p = math.floor(pct + 0.5)
    barText:SetText(p >= 100 and "100% " or (p .. "%"))
end

local function ShowBar(pct)
    if not IsEnabled() then return end
    EnsureBar()
    UpdateBar(pct)
    barFrame:Show()
    isShowing = true
end

local function HideBar()
    if barFrame then barFrame:Hide() end
    isShowing = false
end

-- ============================================================
-- Ticker — läuft dauerhaft wenn enabled
-- ============================================================
local ticker = nil

local function StartTicker()
    if ticker then return end
    ticker = C_Timer.NewTicker(0.5, function()
        if not IsEnabled() then
            HideBar()
            ticker:Cancel()
            ticker = nil
            return
        end

        local qid = GetActivePreyQuestID()
        if not IsValidQuestID(qid) then
            if isShowing then HideBar() end
            return
        end

        -- Quest aktiv: nur zeigen wenn PreyHunt-Frame auch sichtbar (= in der Zone)
        local f = FindPreyFrame()
        if not f or not f:IsShown() then
            if isShowing then HideBar() end
            return
        end
        local pct = GetPercent()
        ShowBar(pct or 0)
    end)
end

local function StopTicker()
    if ticker then ticker:Cancel(); ticker = nil end
end

-- ============================================================
-- Events — nur für Cleanup
-- ============================================================
local eventFrame = CreateFrame("Frame")
local registered = false

local function OnEvent(self, event, arg1)
    if not IsEnabled() then return end
    if event == "ZONE_CHANGED_NEW_AREA" then
        cachedPreyFrame = nil
    elseif event == "QUEST_REMOVED" then
        C_Timer.After(0.3, function()
            if not IsValidQuestID(GetActivePreyQuestID()) then HideBar() end
        end)
    end
end

local function RegisterEvents()
    if registered then return end
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("QUEST_REMOVED")
    eventFrame:SetScript("OnEvent", OnEvent)
    registered = true
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
AklimeMod_PreyPercent = {}

function AklimeMod_PreyPercent.IsEnabled()
    return IsEnabled()
end

function AklimeMod_PreyPercent.SetEnabled(v)
    local db = GetDB()
    if not db then return end
    db.enabled = v
    if v then
        RegisterEvents()
        StartTicker()
    else
        UnregisterEvents()
        StopTicker()
        HideBar()
    end
end

function AklimeMod_PreyPercent.Init()
    if IsEnabled() then
        RegisterEvents()
        StartTicker()  -- einfach sofort starten, Ticker verträgt nil-Quest problemlos
    end
end