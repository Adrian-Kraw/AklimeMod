-- Modules/QoL/ChatLearnFilter.lua
-- Hides learn/unlearn messages in the chat.
-- Optional sub-feature: hide the "unspent talent points" alert popup.

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

-- ============================================================
-- Talent alert bubble suppression
-- ============================================================

local bubbleHooked = {}

local function IsBubbleEnabled()
    local db = GetDB()
    return db.hideTalentBubble == true
end

local function SuppressBubble(f)
    if not f or bubbleHooked[f] then return end
    bubbleHooked[f] = true
    f:HookScript("OnShow", function(self)
        if IsBubbleEnabled() then self:Hide() end
    end)
    if IsBubbleEnabled() and f.IsShown and f:IsShown() then f:Hide() end
end

-- The talent alert is an anonymous UIParent child with a FontString region
-- containing the "unspent talent points" text. We find it once by text and cache it.
local talentBubble = nil

local BUBBLE_PATTERNS = {
    "unverteilte Talentpunkt", -- deDE
    "unspent talent point",    -- enUS
}

local function FindTalentBubble()
    if talentBubble then return talentBubble end
    for i = 1, UIParent:GetNumChildren() do
        local f = select(i, UIParent:GetChildren())
        local ok, nr = pcall(function() return f:GetNumRegions() end)
        if ok and nr then
            for j = 1, nr do
                local r = select(j, f:GetRegions())
                if r.GetText then
                    local ok2, t = pcall(function() return r:GetText() end)
                    if ok2 and t then
                        for _, pat in ipairs(BUBBLE_PATTERNS) do
                            if t:find(pat, 1, true) then
                                talentBubble = f
                                return f
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function ApplyBubbleHide()
    if not IsBubbleEnabled() then return end
    local f = FindTalentBubble()
    if f then SuppressBubble(f) end
end

local function HookShowAlert()
    -- Keep as secondary strategy: hook ShowAlert on the talent button if available
    local btn = _G["PlayerSpellsMicroButton"]
    if not btn or btn._talentAlertHooked then return end
    btn._talentAlertHooked = true
    if btn.ShowAlert then
        hooksecurefunc(btn, "ShowAlert", function()
            if IsBubbleEnabled() then C_Timer.After(0, ApplyBubbleHide) end
        end)
    end
end

local bubbleFrame = CreateFrame("Frame")

local function SetupBubbleEvents(on)
    if on then
        bubbleFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
        bubbleFrame:RegisterEvent("PLAYER_LEVEL_UP")
        bubbleFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    else
        bubbleFrame:UnregisterAllEvents()
    end
end

bubbleFrame:SetScript("OnEvent", function()
    C_Timer.After(0, ApplyBubbleHide)
end)

-- ============================================================
-- Public API
-- ============================================================

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

function M:IsBubbleEnabled()
    return IsBubbleEnabled()
end

function M:SetBubbleEnabled(v)
    local db = GetDB()
    db.hideTalentBubble = v and true or false
    SetupBubbleEvents(v)
    if v then
        C_Timer.After(0.5, function()
            HookShowAlert()
            ApplyBubbleHide()
        end)
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    if GetDB().enabled then M:SetEnabled(true) end
    if GetDB().hideTalentBubble then
        SetupBubbleEvents(true)
        C_Timer.After(2, function()
            HookShowAlert()
            ApplyBubbleHide()
        end)
    end
end)
