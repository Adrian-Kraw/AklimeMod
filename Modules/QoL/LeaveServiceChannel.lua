-- Modules/QoL/LeaveServiceChannel.lua
-- Addon toggle on  -> LeaveChannelByName("Dienste")  (toggle off, entry stays)
-- Addon toggle off -> JoinChannelByName("Dienste")   (toggle on)
-- If the player manually does /join Dienste -> automatically disable the addon toggle

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
-- Filter system messages
-- ============================================================
local suppress = false

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(_, _, msg)
    if type(msg) ~= "string" then return false end

    -- Suppress our own leave/join messages
    if suppress and msg:find(CHANNEL_NAME, 1, true) then
        return true
    end

    -- Player joins manually -> disable the addon toggle
    if IsEnabled() and msg:find(CHANNEL_NAME, 1, true) then
        if msg:find("beigetreten") or msg:find("joined") then
            local db = GetDB()
            if db then db.enabled = false end
            -- Refresh the UI checkbox (no rebuild, that would collapse all
            -- expanded sections)
            if AklimeModFrame and AklimeModFrame:IsShown() and AklimeMod_RefreshRightToggles then
                AklimeMod_RefreshRightToggles()
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
    -- Enable the display toggle in the chat UI (show channel messages)
    C_Timer.After(0.5, function()
        local idx = GetChannelName(CHANNEL_NAME)
        if idx and idx > 0 then
            for i = 1, NUM_CHAT_WINDOWS do
                local cf = _G["ChatFrame" .. i]
                if cf and cf:IsShown() then
                    cf:AddChannel(CHANNEL_NAME)
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