-- Modules/QoL/LeaveServiceChannel.lua
-- Haken im Addon an  -> LeaveChannelByName("Dienste")  (Haken raus, Eintrag bleibt)
-- Haken im Addon aus -> JoinChannelByName("Dienste")   (Haken rein)
-- Wenn Spieler manuell /join Dienste macht -> Addon-Haken automatisch deaktivieren

local CHANNEL_NAME = "Dienste"

local function GetDB()
    return AklimeModDB and AklimeModDB.leaveServiceChannel
end

local function IsEnabled()
    local db = GetDB()
    return db and db.enabled
end

local function IsInChannel()
    local idx = GetChannelName(CHANNEL_NAME)
    return idx and idx > 0
end

-- ============================================================
-- Systemnachrichten filtern
-- ============================================================
local suppress = false

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(_, _, msg)
    if type(msg) ~= "string" then return false end

    -- Eigene Leave/Join Nachrichten unterdruecken
    if suppress and msg:find(CHANNEL_NAME, 1, true) then
        return true
    end

    -- Spieler tritt manuell bei -> Addon-Haken deaktivieren
    if IsEnabled() and msg:find(CHANNEL_NAME, 1, true) then
        if msg:find("beigetreten") or msg:find("joined") then
            local db = GetDB()
            if db then db.enabled = false end
            -- UI Checkbox aktualisieren
            if AklimeModFrame and AklimeModFrame:IsShown() then
                C_Timer.After(0.1, function()
                    if AklimeMod_BuildQoLContent then AklimeMod_BuildQoLContent() end
                end)
            end
        end
    end

    return false
end)

-- ============================================================
-- Leave / Join
-- ============================================================
local function DoLeave()
    if IsInChannel() then
        suppress = true
        LeaveChannelByName(CHANNEL_NAME)
        C_Timer.After(1.0, function() suppress = false end)
    end
end

local function DoJoin()
    suppress = true
    JoinChannelByName(CHANNEL_NAME)
    -- Anzeige-Haken in der Chat-UI aktivieren (Channel-Nachrichten einblenden)
    C_Timer.After(0.5, function()
        local idx = GetChannelName(CHANNEL_NAME)
        if idx and idx > 0 then
            for i = 1, NUM_CHAT_WINDOWS do
                local cf = _G["ChatFrame" .. i]
                if cf and cf:IsShown() then
                    ChatFrame_AddChannel(cf, CHANNEL_NAME)
                end
            end
        end
        suppress = false
    end)
end

-- ============================================================
-- Events
-- ============================================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(_, event, isLogin, isReload)
    if isLogin or isReload then
        C_Timer.After(3.0, function()
            if IsEnabled() then DoLeave() end
        end)
    end
end)

-- ============================================================
-- API (Categories.lua)
-- ============================================================
AklimeMod_LeaveServiceChannel = {
    IsEnabled  = function() return IsEnabled() end,
    SetEnabled = function(v)
        local db = GetDB()
        if db then db.enabled = v end
        if v then DoLeave() else DoJoin() end
    end,
}