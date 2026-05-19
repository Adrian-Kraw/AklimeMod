-- Modules/Interface/HUDFader.lua
-- HUD-Fader, Modus 1: Chill-Modus.
-- Nur in Ruhezonen aktiv. Alles blendet im Idle auf 0 aus.
-- Chat reagiert auf Nachrichten-Events unabhaengig vom Rest.
-- Bewegung fuer 2 Sekunden blendet alles auf die konfigurierte Alpha ein.

local M = {}
AklimeMod_HUDFader = M

-- ============================================================
-- UI-Elemente (SetAlpha-Fade)
-- ============================================================
local ELEMENTS = {
    { key = "actionBars", frames = function()
        local f = {}
        for _, n in ipairs({ "MainActionBar","MultiBarBottomLeft","MultiBarBottomRight",
            "MultiBarRight","MultiBarLeft","MultiBar5","MultiBar6","MultiBar7",
            "StanceBar","PetActionBar" }) do
            if _G[n] then f[#f+1] = _G[n] end
        end
        return f
    end },
    { key = "microMenu", frames = function()
        local f = {}
        for _, n in ipairs({ "CharacterMicroButton","ProfessionMicroButton",
            "PlayerSpellsMicroButton","AchievementMicroButton","QuestLogMicroButton",
            "GuildMicroButton","LFDMicroButton","CollectionsMicroButton",
            "EJMicroButton","StoreMicroButton","MainMenuMicroButton",
            "HousingMicroButton" }) do
            if _G[n] then f[#f+1] = _G[n] end
        end
        if MicroButtonAndBagsBar then f[#f+1] = MicroButtonAndBagsBar end
        return f
    end },
    { key = "bags", frames = function()
        local f = {}
        for _, n in ipairs({ "MainMenuBarBackpackButton","CharacterBag0Slot",
            "CharacterBag1Slot","CharacterBag2Slot","CharacterBag3Slot","BagsBar" }) do
            if _G[n] then f[#f+1] = _G[n] end
        end
        return f
    end },
    -- MinimapCluster fuer den aeusseren Container (smooth fade).
    -- Minimap-Kinder werden per Hide/Show gesteuert (siehe unten).
    { key = "minimap",     frames = function()
        local f = {}
        if MinimapCluster then f[#f+1] = MinimapCluster end
        if Minimap        then f[#f+1] = Minimap        end
        return f
    end },
    { key = "buffs",       frames = function() return BuffFrame        and {BuffFrame}        or {} end },
    { key = "debuffs",     frames = function() return DebuffFrame      and {DebuffFrame}      or {} end },
    { key = "playerFrame", frames = function() return PlayerFrame      and {PlayerFrame}      or {} end },
    { key = "targetFrame", frames = function() return TargetFrame      and {TargetFrame}      or {} end },
    { key = "focusFrame",  frames = function() return FocusFrame       and {FocusFrame}       or {} end },
    { key = "partyFrame",  frames = function() return CompactPartyFrame and {CompactPartyFrame} or {} end },
    { key = "objectives",  frames = function() return ObjectiveTrackerFrame and {ObjectiveTrackerFrame} or {} end },
    { key = "repBar",      frames = function() return StatusTrackingBarManager and {StatusTrackingBarManager} or {} end },
    { key = "expansionBtn", frames = function()
        local f = {}
        for _, n in ipairs({ "ExpansionLandingPageMinimapButton", "GarrisonLandingPageMinimapButton" }) do
            if _G[n] then f[#f+1] = _G[n] end
        end
        return f
    end },
    { key = "socialBtn",   frames = function() return QuickJoinToastButton and {QuickJoinToastButton} or {} end },
    { key = "chatCopyBtn", frames = function()
        local b = _G["AklimeMod_ChatCopyBtn"]
        return b and {b} or {}
    end },
    { key = "damageMeter", frames = function()
        local f = {}
        if DamageMeter then f[#f+1] = DamageMeter end
        local maxCount = DamageMeterMixin and DamageMeterMixin:GetMaxSessionWindowCount() or 5
        for i = 1, maxCount do
            local sw = _G["DamageMeterSessionWindow" .. i]
            if sw then f[#f+1] = sw end
        end
        return f
    end },
}

local CHAT_EVENTS = {
    "CHAT_MSG_SAY","CHAT_MSG_YELL","CHAT_MSG_EMOTE","CHAT_MSG_TEXT_EMOTE",
    "CHAT_MSG_WHISPER","CHAT_MSG_WHISPER_INFORM","CHAT_MSG_PARTY","CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID","CHAT_MSG_RAID_LEADER","CHAT_MSG_GUILD","CHAT_MSG_OFFICER",
    "CHAT_MSG_CHANNEL","CHAT_MSG_INSTANCE_CHAT","CHAT_MSG_INSTANCE_CHAT_LEADER",
}

local CHAT_SHOW_DURATION  = 15  -- Sekunden Chat nach Event sichtbar
local MOVE_ACTIVATE_DELAY =  2  -- Sekunden Bewegung bis Aktivierung
local IDLE_DELAY          = 12  -- Sekunden Stillstand bis Idle

-- ============================================================
-- Fade-Engine (SetAlpha)
-- ============================================================
local fadeTargets = {}
local FADE_SPEED  = 1.5

local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function(_, elapsed)
    for frame, target in pairs(fadeTargets) do
        local cur = frame:GetAlpha()
        if math.abs(cur - target) < 0.01 then
            frame:SetAlpha(target)
            fadeTargets[frame] = nil
        else
            local step = FADE_SPEED * elapsed
            frame:SetAlpha(cur + (target > cur and step or -step))
        end
    end
end)

local function FadeTo(frame, alpha)
    if not frame then return end
    fadeTargets[frame] = math.max(0, math.min(1, alpha))
end

-- ============================================================
-- Minimap-Frames: Hide/Show (umgeht SetIgnoreParentAlpha)
-- Scannt Kinder von MinimapCluster UND Minimap.
-- ============================================================
local hiddenMinimapChildren = {}

local function HideMinimapFrames()
    wipe(hiddenMinimapChildren)
    local function scanAndHide(parent)
        if not parent then return end
        for _, child in ipairs({ parent:GetChildren() }) do
            local ok, shown = pcall(function() return child:IsShown() end)
            if ok and shown then
                local ok2, t = pcall(function() return child:GetObjectType() end)
                local isMinimapWidget = ok2 and t == "Minimap"
                if not isMinimapWidget then
                    hiddenMinimapChildren[#hiddenMinimapChildren + 1] = child
                    child:Hide()
                end
            end
        end
    end
    scanAndHide(MinimapCluster)
    scanAndHide(Minimap)
end

local function ShowMinimapFrames()
    for _, child in ipairs(hiddenMinimapChildren) do
        pcall(function() child:Show() end)
    end
    wipe(hiddenMinimapChildren)
end

-- ============================================================
-- Hilfsfunktionen
-- ============================================================
local function GetDB()
    return AklimeModDB and AklimeModDB.interfaceFade and AklimeModDB.interfaceFade.mode1
end

local function IsEnabled()
    local db = GetDB()
    return db and db.enabled == true
end

local function GetActiveAlpha()
    local db = GetDB()
    return (db and db.alpha or 60) / 100
end

local function GetChatFrames()
    local f = {}
    for i = 1, 10 do
        local cf = _G["ChatFrame" .. i]
        if cf and cf:IsShown() then f[#f+1] = cf end
    end
    if GeneralDockManager then f[#f+1] = GeneralDockManager end
    return f
end

local function CancelTimer(t)
    if t then t:Cancel() end
    return nil
end

-- ============================================================
-- Zustand
-- ============================================================
local state     = "idle"   -- "idle" | "active"
local inCombat  = false
local moveTimer = nil
local idleTimer = nil
local chatTimer = nil

local function FadeAllTo(alpha)
    for _, el in ipairs(ELEMENTS) do
        for _, f in ipairs(el.frames()) do FadeTo(f, alpha) end
    end
    for _, cf in ipairs(GetChatFrames()) do FadeTo(cf, alpha) end
end

local function GoIdle()
    state = "idle"
    FadeAllTo(0)
    HideMinimapFrames()
end

local function GoActive()
    state = "active"
    chatTimer = CancelTimer(chatTimer)
    ShowMinimapFrames()
    FadeAllTo(GetActiveAlpha())
end

local function GoFull()
    ShowMinimapFrames()
    FadeAllTo(1.0)
end

local function StartIdleCountdown()
    idleTimer = CancelTimer(idleTimer)
    idleTimer = C_Timer.NewTimer(IDLE_DELAY, function()
        idleTimer = nil
        if IsEnabled() and IsResting() and not inCombat then
            GoIdle()
        end
    end)
end

-- Chat-Event: nur Chatfenster einblenden, Rest bleibt
local function OnChatEvent()
    if not IsEnabled() or not IsResting() or inCombat then return end
    if state ~= "idle" then return end
    chatTimer = CancelTimer(chatTimer)
    for _, cf in ipairs(GetChatFrames()) do FadeTo(cf, 1.0) end
    chatTimer = C_Timer.NewTimer(CHAT_SHOW_DURATION, function()
        chatTimer = nil
        if IsEnabled() and IsResting() and state == "idle" and not inCombat then
            for _, cf in ipairs(GetChatFrames()) do FadeTo(cf, 0) end
        end
    end)
end

-- ============================================================
-- Events
-- ============================================================
local isChatEvent = {}
for _, ev in ipairs(CHAT_EVENTS) do isChatEvent[ev] = true end

local ef = CreateFrame("Frame")
ef:RegisterEvent("PLAYER_ENTERING_WORLD")
ef:RegisterEvent("PLAYER_STARTED_MOVING")
ef:RegisterEvent("PLAYER_STOPPED_MOVING")
ef:RegisterEvent("PLAYER_REGEN_DISABLED")
ef:RegisterEvent("PLAYER_REGEN_ENABLED")
ef:RegisterEvent("PLAYER_FLAGS_CHANGED")
ef:RegisterEvent("ZONE_CHANGED_INDOORS")
ef:RegisterEvent("ZONE_CHANGED_NEW_AREA")
for _, ev in ipairs(CHAT_EVENTS) do ef:RegisterEvent(ev) end

ef:SetScript("OnEvent", function(_, event)
    if isChatEvent[event] then
        OnChatEvent()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        inCombat = false
        state    = "idle"
        C_Timer.After(2, function()
            if IsEnabled() and IsResting() then
                GoIdle()
                StartIdleCountdown()
            end
        end)

    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        moveTimer = CancelTimer(moveTimer)
        idleTimer = CancelTimer(idleTimer)
        chatTimer = CancelTimer(chatTimer)
        if IsEnabled() then GoFull() end

    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        if IsEnabled() and IsResting() then
            StartIdleCountdown()
        end

    elseif event == "PLAYER_STARTED_MOVING" then
        if not IsEnabled() or inCombat then return end
        idleTimer = CancelTimer(idleTimer)
        moveTimer = CancelTimer(moveTimer)
        moveTimer = C_Timer.NewTimer(MOVE_ACTIVATE_DELAY, function()
            moveTimer = nil
            if IsEnabled() and IsResting() and not inCombat then
                GoActive()
            end
        end)

    elseif event == "PLAYER_STOPPED_MOVING" then
        moveTimer = CancelTimer(moveTimer)
        if not IsEnabled() or inCombat then return end
        if IsResting() and state == "active" then
            StartIdleCountdown()
        end

    elseif event == "PLAYER_FLAGS_CHANGED"
        or event == "ZONE_CHANGED_INDOORS"
        or event == "ZONE_CHANGED_NEW_AREA" then
        if not IsEnabled() then return end
        if not IsResting() then
            -- Ruhezone verlassen
            moveTimer = CancelTimer(moveTimer)
            idleTimer = CancelTimer(idleTimer)
            chatTimer = CancelTimer(chatTimer)
            state = "idle"
            GoFull()
        elseif state == "idle" and not inCombat then
            -- Ruhezone betreten
            GoIdle()
            StartIdleCountdown()
        end
    end
end)

-- ============================================================
-- Debug
-- ============================================================
SLASH_AKMHUD1 = "/akmhud"
SlashCmdList["AKMHUD"] = function()
    local function scanFrame(label, frame)
        if not frame then print("  " .. label .. ": nicht gefunden"); return end
        print(string.format("|cFFFFD100%s|r  alpha=%.2f", label, frame:GetAlpha()))
        local count = 0
        for _, child in ipairs({ frame:GetChildren() }) do
            count = count + 1
            local name  = child:GetName() or "(kein Name)"
            local shown = child:IsShown() and "SHOWN" or "hidden"
            local alpha = string.format("%.2f", child:GetAlpha())
            print(string.format("  [%d] %-45s %s  alpha=%s", count, name, shown, alpha))
        end
        print(string.format("  Gesamt: %d Kinder", count))
    end
    scanFrame("MinimapCluster", MinimapCluster)
    scanFrame("Minimap",        Minimap)
end

-- ============================================================
-- API
-- ============================================================
function M:IsEnabled()
    return IsEnabled()
end

function M:SetEnabled(v)
    local db = GetDB()
    if db then db.enabled = v end
    if v then
        if IsResting() and not inCombat then
            state = "idle"
            GoIdle()
            StartIdleCountdown()
        end
    else
        moveTimer = CancelTimer(moveTimer)
        idleTimer = CancelTimer(idleTimer)
        chatTimer = CancelTimer(chatTimer)
        state = "idle"
        ShowMinimapFrames()
        GoFull()
    end
end
