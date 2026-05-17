-- Modules/QoL/QuestTracker.lua
-- Quest-Tracker-Erweiterungen:
-- 1. Quest-Anzahl im Tracker-Header (z.B. "15/25")
-- 2. Header ausblenden wenn zugeklappt (nur Minimieren-Button sichtbar)
-- 3. Zugeklappten Zustand zwischen Sessions merken

local function GetDB()
    if AklimeModDB and AklimeModDB.questTracker then return AklimeModDB.questTracker end
    return {}
end

-- ============================================================
-- Quest-Anzahl
-- ============================================================

local QUEST_COUNT_COLOR = { r = 1, g = 210 / 255, b = 0 }
local countFrame, countText

local function GetQuestCountText()
    if not C_QuestLog then return "" end
    local numEntries = C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetNumQuestLogEntries()
    local visible = 0
    if numEntries and numEntries > 0 then
        for i = 1, numEntries do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHidden and info.questID and info.questID > 0 then
                visible = visible + 1
            end
        end
    end
    local max = C_QuestLog.GetMaxNumQuestsCanAccept and C_QuestLog.GetMaxNumQuestsCanAccept()
    if not max or max <= 0 then
        return visible > 0 and tostring(visible) or ""
    end
    return string.format("%d/%d", visible, max)
end

local function GetTrackerHeader()
    return QuestObjectiveTracker and QuestObjectiveTracker.Header
end

local function PositionCountFrame()
    local header = GetTrackerHeader()
    if not header or not countFrame then return end
    local db = GetDB()
    countFrame:ClearAllPoints()
    countFrame:SetPoint("CENTER", header, "CENTER", db.questCountOffsetX or 0, db.questCountOffsetY or 0)
end

local function EnsureCountFrame()
    local header = GetTrackerHeader()
    if not header then return end
    if not countFrame then
        countFrame = CreateFrame("Frame", nil, header)
        countFrame:SetSize(1, 1)
    end
    countFrame:SetParent(header)
    if not countText then
        countText = countFrame:CreateFontString(nil, "OVERLAY")
        countText:SetPoint("TOPLEFT")
        countText:SetJustifyH("LEFT")
        countText:SetJustifyV("TOP")
    end
    local refFont = header.Text and header.Text:GetFontObject()
    if refFont then
        countText:SetFontObject(refFont)
    else
        countText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    end
    countText:SetTextColor(QUEST_COUNT_COLOR.r, QUEST_COUNT_COLOR.g, QUEST_COUNT_COLOR.b)
end

local function UpdateQuestCount()
    local db = GetDB()
    if not db.showQuestCount then
        if countFrame then countFrame:Hide() end
        return
    end
    local header = GetTrackerHeader()
    if not header then
        if countFrame then countFrame:Hide() end
        return
    end
    EnsureCountFrame()
    if not countFrame or not countText then return end
    PositionCountFrame()
    local text = GetQuestCountText()
    if text == "" then
        countFrame:Hide()
        return
    end
    countText:SetText(text)
    countFrame:SetSize(
        math.max(1, countText:GetStringWidth()),
        math.max(1, countText:GetStringHeight())
    )
    countFrame:Show()
    countText:Show()
end

-- ============================================================
-- Minimieren-Button (nur Button wenn zugeklappt)
-- ============================================================

local MINIMIZE_ANCHORS = {
    TOPLEFT     = { point = "TOPLEFT",     x =  1, y =  0 },
    TOPRIGHT    = { point = "TOPRIGHT",    x = -1, y =  0 },
    BOTTOMLEFT  = { point = "BOTTOMLEFT",  x =  1, y =  0 },
    BOTTOMRIGHT = { point = "BOTTOMRIGHT", x = -1, y =  0 },
}

local minimizeHooked = false
local collapseHooked = false

local function ApplyMinimizeStyle()
    local db = GetDB()
    local tracker = ObjectiveTrackerFrame
    local header = tracker and tracker.Header
    if not header then return end

    local bg  = header.Background
    local txt = header.Text
    local btn = header.MinimizeButton

    if bg  and bg._aklAlpha  == nil and bg.GetAlpha  then bg._aklAlpha  = bg:GetAlpha()  end
    if txt and txt._aklAlpha == nil and txt.GetAlpha then txt._aklAlpha = txt:GetAlpha() end

    local collapsed  = tracker.IsCollapsed and tracker:IsCollapsed()
    local hideHeader = db.minimizeButtonOnly == true and collapsed

    if bg  and bg.SetAlpha  then bg:SetAlpha( hideHeader and 0 or (bg._aklAlpha  or 1)) end
    if txt and txt.SetAlpha then txt:SetAlpha(hideHeader and 0 or (txt._aklAlpha or 1)) end

    if btn and btn.GetPoint then
        if not btn._aklDefaultPoint then
            local pt = { btn:GetPoint() }
            if pt[1] then btn._aklDefaultPoint = pt end
        end
        if hideHeader then
            local anchorKey = db.minimizeButtonAnchor or "TOPRIGHT"
            local anchor = MINIMIZE_ANCHORS[anchorKey] or MINIMIZE_ANCHORS.TOPRIGHT
            btn:ClearAllPoints()
            btn:SetPoint(anchor.point, tracker, anchor.point, anchor.x, anchor.y)
            btn._aklAnchorApplied = true
        elseif btn._aklAnchorApplied and btn._aklDefaultPoint then
            local pt = btn._aklDefaultPoint
            btn:ClearAllPoints()
            btn:SetPoint(pt[1], pt[2], pt[3], pt[4], pt[5])
            btn._aklAnchorApplied = nil
        end
    end
end

local function EnsureMinimizeHooks()
    local tracker = ObjectiveTrackerFrame
    local header  = tracker and tracker.Header
    if not header then return end

    if not collapseHooked then
        collapseHooked = true
        hooksecurefunc(tracker, "SetCollapsed", function(_, collapsed)
            if GetDB().rememberState then
                GetDB().collapsed = collapsed and true or false
            end
        end)
    end

    if not minimizeHooked then
        minimizeHooked = true
        hooksecurefunc(header, "SetCollapsed", function()
            ApplyMinimizeStyle()
        end)
    end

    ApplyMinimizeStyle()
end

local function ApplyRememberedState()
    local db = GetDB()
    if not db.rememberState then return end
    local tracker = ObjectiveTrackerFrame
    if not tracker or not tracker.IsCollapsed or not tracker.SetCollapsed then return end
    local saved = db.collapsed
    if saved == nil then
        db.collapsed = tracker:IsCollapsed() and true or false
        return
    end
    if tracker:IsCollapsed() ~= saved then
        tracker:SetCollapsed(saved)
    end
end

-- ============================================================
-- API
-- ============================================================

local M = {}
AklimeMod_QuestTracker = M

function M:IsShowQuestCountEnabled() return GetDB().showQuestCount      == true end
function M:IsMinimizeButtonOnly()    return GetDB().minimizeButtonOnly   == true end
function M:IsRememberStateEnabled()  return GetDB().rememberState        == true end

function M:SetShowQuestCount(v)
    GetDB().showQuestCount = v and true or false
    UpdateQuestCount()
end

function M:SetMinimizeButtonOnly(v)
    GetDB().minimizeButtonOnly = v and true or false
    ApplyMinimizeStyle()
end

function M:SetRememberState(v)
    GetDB().rememberState = v and true or false
    if v then
        local tracker = ObjectiveTrackerFrame
        if tracker and tracker.IsCollapsed then
            GetDB().collapsed = tracker:IsCollapsed() and true or false
        end
        EnsureMinimizeHooks()
    end
end

-- ============================================================
-- Init
-- ============================================================

local questCountWatcher

local function InitWatchers()
    if questCountWatcher then return end
    questCountWatcher = CreateFrame("Frame")
    questCountWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    questCountWatcher:RegisterEvent("QUEST_ACCEPTED")
    questCountWatcher:RegisterEvent("QUEST_REMOVED")
    questCountWatcher:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(0.5, UpdateQuestCount)
        else
            UpdateQuestCount()
        end
    end)
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name ~= "Blizzard_ObjectiveTracker" then return end
    RunNextFrame(function()
        EnsureMinimizeHooks()
        ApplyRememberedState()
    end)
    if event == "PLAYER_LOGIN" then
        InitWatchers()
        C_Timer.After(0.5, UpdateQuestCount)
    end
end)
