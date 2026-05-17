-- Modules/QoL/ChatIcons.lua
-- Zeigt Item- und Waehrungssymbole vor Links im Chat.

local ICON_SIZE = 12
local ITEM_LINK_PATTERN = "|Hitem:.-|h%[.-%]|h|r"
local CURRENCY_LINK_PATTERN = "(|Hcurrency:(%d+)[^|]*|h%[[^%]]+%]|h|r)"

local CHAT_EVENTS = {
    "CHAT_MSG_LOOT",
    "CHAT_MSG_CURRENCY",
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_COMMUNITIES_CHANNEL",
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_BN_WHISPER",
    "CHAT_MSG_BN_WHISPER_INFORM",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_BATTLEGROUND",
    "CHAT_MSG_BATTLEGROUND_LEADER",
    "CHAT_MSG_EMOTE",
    "CHAT_MSG_SYSTEM",
    "CHAT_MSG_ACHIEVEMENT",
    "CHAT_MSG_GUILD_ACHIEVEMENT",
    "CHAT_MSG_GUILD_ITEM_LOOTED",
}

local function GetDB()
    if AklimeModDB and AklimeModDB.chatIcons then return AklimeModDB.chatIcons end
    return { enabled = false }
end

local function GetItemTexture(link)
    local itemID = link:match("item:(%d+)")
    if itemID and C_Item and C_Item.GetItemIconByID then
        return C_Item.GetItemIconByID(tonumber(itemID))
    end
    return nil
end

local function AppendIcon(texture, link)
    if not texture then return link end
    return string.format("|T%s:%d|t%s", texture, ICON_SIZE, link)
end

local function FormatCurrencyLink(link, id)
    id = tonumber(id)
    if not id or not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return link end
    local info = C_CurrencyInfo.GetCurrencyInfo(id)
    local texture = info and (info.iconFileID or info.icon)
    return AppendIcon(texture, link)
end

local registeredEvents = {}

local function FilterChatMessage(_, event, message, ...)
    if issecretvalue and issecretvalue(message) then return end
    if type(message) ~= "string" or message == "" then return false end

    message = message:gsub(ITEM_LINK_PATTERN, function(link)
        return AppendIcon(GetItemTexture(link), link)
    end)

    if event == "CHAT_MSG_LOOT" or event == "CHAT_MSG_CURRENCY" then
        message = message:gsub(CURRENCY_LINK_PATTERN, FormatCurrencyLink)
    end

    return false, message, ...
end

local M = {}
AklimeMod_ChatIcons = M

function M:IsEnabled()
    return GetDB().enabled == true
end

function M:SetEnabled(enabled)
    GetDB().enabled = enabled and true or false

    if enabled then
        for _, event in ipairs(CHAT_EVENTS) do
            if not registeredEvents[event] then
                ChatFrame_AddMessageEventFilter(event, FilterChatMessage)
                registeredEvents[event] = true
            end
        end
    else
        for event in pairs(registeredEvents) do
            ChatFrame_RemoveMessageEventFilter(event, FilterChatMessage)
        end
        registeredEvents = {}
    end
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    if GetDB().enabled then M:SetEnabled(true) end
end)
