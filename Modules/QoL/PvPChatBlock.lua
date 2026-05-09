-- Modules/QoL/PvPChatBlock.lua
-- Blockiert Enter (Chat öffnen) in PvP-Instanzen (Arena + Schlachtfeld, rated + unrated).
-- Toggle über den Minimap-Radialmenü-Button.

-- ============================================================
-- DB
-- ============================================================
local function GetDB()
    return AklimeModDB and AklimeModDB.pvpChatBlock
end

local function IsEnabled()
    local db = GetDB()
    return db and db.enabled
end

-- ============================================================
-- PvP-Instanz erkennen
-- ============================================================
local function IsInPvPInstance()
    local inInstance, instanceType = IsInInstance()
    return inInstance and (instanceType == "pvp" or instanceType == "arena")
end

-- ============================================================
-- Chat-Block
-- ============================================================
local blocked = false
local hooked  = false

local function Block()
    if blocked then return end
    blocked = true

    -- ChatFrame1EditBox ist die Haupteingabe
    -- Wir hookon das OnKeyDown um Enter abzufangen
    if not hooked and ChatFrame1EditBox then
        hooked = true
        hooksecurefunc(ChatFrame1EditBox, "Show", function(self)
            if IsEnabled() and IsInPvPInstance() then
                self:Hide()
            end
        end)
    end

    -- Alle ChatFrameEditBoxen verstecken falls gerade offen
    for i = 1, 50 do
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox and editBox:IsShown() then
            editBox:Hide()
        end
        if not _G["ChatFrame" .. i] then break end
    end
end

local function Unblock()
    blocked = false
    -- Hook bleibt aber IsEnabled() gibt false zurück → Show() wird nicht geblockt
end

-- ============================================================
-- Events
-- ============================================================
local eventFrame = CreateFrame("Frame")
local registered = false

local function OnEvent(self, event)
    if not IsEnabled() then
        Unblock()
        return
    end

    if IsInPvPInstance() then
        Block()
    else
        Unblock()
    end
end

local function RegisterEvents()
    if registered then return end
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
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
AklimeMod_PvPChatBlock = {}

function AklimeMod_PvPChatBlock.IsEnabled()
    return IsEnabled()
end

function AklimeMod_PvPChatBlock.Toggle()
    local db = GetDB()
    if not db then return end
    db.enabled = not db.enabled
    if db.enabled then
        RegisterEvents()
        if IsInPvPInstance() then Block() end
    else
        UnregisterEvents()
        Unblock()
    end
    return db.enabled
end

function AklimeMod_PvPChatBlock.SetEnabled(v)
    local db = GetDB()
    if not db then return end
    db.enabled = v
    if v then
        RegisterEvents()
        if IsInPvPInstance() then Block() end
    else
        UnregisterEvents()
        Unblock()
    end
end

function AklimeMod_PvPChatBlock.Init()
    if IsEnabled() then
        RegisterEvents()
    end
end