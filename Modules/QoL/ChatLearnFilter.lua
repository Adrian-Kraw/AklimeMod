-- Modules/QoL/ChatLearnFilter.lua
-- Hides learn/unlearn messages in the chat.

local function GetDB()
    if AklimeModDB and AklimeModDB.chatLearnFilter then return AklimeModDB.chatLearnFilter end
    return { enabled = false }
end

-- Converts a Blizzard format string ("You have learned %s.") into a Lua pattern.
local function FmtToPattern(fmt)
    if type(fmt) ~= "string" then return nil end
    local pattern = fmt
        :gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
        :gsub("%%s", ".+")
        :gsub("%%d", "%%d+")
    return pattern
end

local patterns = nil

local function BuildPatterns()
    if patterns then return end
    patterns = {}
    local sources = {
        ERR_LEARN_PASSIVE_S,
        ERR_LEARN_SPELL_S,
        ERR_LEARN_ABILITY_S,
        ERR_SPELL_UNLEARNED_S,
    }
    for _, fmt in ipairs(sources) do
        local p = FmtToPattern(fmt)
        if p then patterns[#patterns + 1] = p end
    end
end

-- Fallback for the retail format with spell links.
-- Retail uses a new format: "You have learned a new spell: [X]"
-- where [X] is a real |Hspell: hyperlink.
local LEARN_VERBS = { "erlernt", "gelernt", "verlernt", "learned", "unlearned" }

local function IsRetailLearnMessage(msg)
    if not msg:find("|Hspell:", 1, true) and not msg:find("|Htalent:", 1, true) then
        return false
    end
    for _, verb in ipairs(LEARN_VERBS) do
        if msg:find(verb, 1, true) then return true end
    end
    return false
end

local function LearnFilter(_, _, msg)
    if not msg then return false end
    if issecretvalue and issecretvalue(msg) then return false end
    for _, pat in ipairs(patterns) do
        if msg:match(pat) then return true end
    end
    if IsRetailLearnMessage(msg) then return true end
    return false
end

local M = {}
AklimeMod_ChatLearnFilter = M

local registered = false

function M:IsEnabled()
    return GetDB().enabled == true
end

function M:SetEnabled(v)
    GetDB().enabled = v and true or false
    BuildPatterns()
    if v and not registered then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", LearnFilter)
        registered = true
    elseif not v and registered then
        ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", LearnFilter)
        registered = false
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    if GetDB().enabled then M:SetEnabled(true) end
end)
