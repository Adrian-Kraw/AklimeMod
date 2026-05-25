-- Modules/Interface/MinimapElementHider.lua

local Hider = {}
local hooked = {}
local managedFrames = {}

local ELEMENTS = {
    tracking = {
        "MiniMapTracking",
        "MiniMapTrackingButton",
        "MiniMapTrackingFrame",
        "MinimapCluster.Tracking",
        "MinimapCluster.Tracking.Button",
        "MinimapCluster.TrackingFrame",
        "MinimapCluster.TrackingButton",
    },
    zoneInfo = {
        "MinimapZoneTextButton", "MinimapZoneText",
    },
    clock = {
        "TimeManagerClockButton",
    },
    calendar = {
        "GameTimeFrame",
    },
    mail = {
        "MiniMapMailFrame",
    },
    addonCompartment = {
        "AddonCompartmentFrame", "AddonCompartmentFrameButton",
    },
}

local function ResolveFrame(path)
    if not path or path == "" then return nil end
    local current = _G
    for part in path:gmatch("[^%.]+") do
        current = current and current[part]
    end
    return current
end

local function DB()
    AklimeModDB.minimapHider = AklimeModDB.minimapHider or {}
    return AklimeModDB.minimapHider
end

local function IsElementHidden(key)
    local db = DB()
    return db.enabled and db[key] == true
end

local function IsHousing()
    local inInst, instType = IsInInstance()

    -- Bekannte Housing-Instanztypen je nach WoW-Build
    if inInst and (instType == "neighborhood" or instType == "interior" or instType == "home") then
        return true
    end

    -- TWW Housing kann Instanztypen verwenden, die kein regulaerer Content sind.
    -- Bekannte Content-Typen ausschliessen, alles andere als Housing behandeln.
    if inInst then
        local contentTypes = { party = true, raid = true, pvp = true, arena = true, scenario = true }
        if not contentTypes[instType] then
            return true
        end
    end

    -- TWW Housing-Innenbereich: oft als Micro-Karte dargestellt (kein IsInInstance).
    if C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID then
            local info = C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
            if info and info.mapType == Enum.UIMapType.Micro then
                return true
            end
        end
    end

    return false
end

-- Debug: /akmmapinfo (im Housing-Bereich eingeben)
SLASH_AKMMAPINFO1 = "/akmmapinfo"
SlashCmdList["AKMMAPINFO"] = function()
    local inInst, instType = IsInInstance()
    print("|cFFFFD100AklimeMod:|r IsInInstance=" .. tostring(inInst) .. " type=" .. tostring(instType))
    if C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        print("|cFFFFD100AklimeMod:|r mapID=" .. tostring(mapID))
        if mapID then
            local info = C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
            if info then
                print("|cFFFFD100AklimeMod:|r mapType=" .. tostring(info.mapType) .. " name=" .. tostring(info.name))
            end
        end
    end
    print("|cFFFFD100AklimeMod:|r IsHousing=" .. tostring(IsHousing()))
end

local function ApplyFrame(frame, hide)
    if not frame then return end
    if hide then
        frame:Hide()
    else
        if frame.SetShown then
            frame:SetShown(true)
            return
        end
        frame:Show()
    end
end

local function RememberFrame(key, frame)
    if not key or not frame then return end
    managedFrames[key] = managedFrames[key] or {}
    managedFrames[key][frame] = true
end

local function HookFrame(frame)
    if not frame or hooked[frame] then return end
    if not frame.HookScript then return end
    hooked[frame] = true
    frame:HookScript("OnShow", function(self)
        -- Housing-Bearbeitungsmodus: Blizzard positioniert Minimap-Elemente neu.
        -- Hier nichts ausblenden, sonst verschiebt sich die Minimap.
        if IsHousing() then return end
        for elementKey, names in pairs(ELEMENTS) do
            for _, frameName in ipairs(names) do
                if ResolveFrame(frameName) == self and IsElementHidden(elementKey) then
                    self:Hide()
                    return
                end
            end
        end
        local name = self.GetName and self:GetName()
        if name and name:lower():find("tracking", 1, true) and managedFrames.tracking and managedFrames.tracking[self] and IsElementHidden("tracking") then
            self:Hide()
        end
    end)
end

local function ScanMinimapTrackingFrames()
    local found = {}
    local function scan(parent, depth)
        if not parent or depth > 4 then return end
        local children = { parent:GetChildren() }
        for _, child in ipairs(children) do
            local name = child.GetName and child:GetName()
            if name and name:lower():find("tracking", 1, true) then
                found[#found + 1] = child
            end
            scan(child, depth + 1)
        end
    end
    scan(Minimap, 1)
    scan(_G.MinimapCluster, 1)
    return found
end

local function ApplyManagedFrames(key, hide)
    if not managedFrames[key] then return end
    for frame in pairs(managedFrames[key]) do
        ApplyFrame(frame, hide)
    end
end

local function ApplyElement(key)
    if IsHousing() then return end
    local hide = IsElementHidden(key)
    for _, name in ipairs(ELEMENTS[key] or {}) do
        local frame = ResolveFrame(name)
        RememberFrame(key, frame)
        ApplyFrame(frame, hide)
        HookFrame(frame)
    end
    if key == "tracking" then
        for _, frame in ipairs(ScanMinimapTrackingFrames()) do
            RememberFrame(key, frame)
            ApplyFrame(frame, hide)
            HookFrame(frame)
        end
    end
    ApplyManagedFrames(key, hide)
end

function Hider.Apply()
    if IsHousing() then
        -- Housing: alle verwalteten Elemente wieder einblenden.
        -- Blizzard benoetigt sie fuer die Interior-Karte und den Bearbeitungsmodus.
        for key in pairs(ELEMENTS) do
            for _, name in ipairs(ELEMENTS[key] or {}) do
                ApplyFrame(ResolveFrame(name), false)
            end
            ApplyManagedFrames(key, false)
        end
        return
    end
    for key in pairs(ELEMENTS) do
        ApplyElement(key)
    end
end

function Hider.IsEnabled()
    return DB().enabled == true
end

function Hider.SetEnabled(v)
    DB().enabled = v and true or false
    Hider.Apply()
end

function Hider.Get(key)
    return DB()[key] == true
end

function Hider.Set(key, v)
    DB()[key] = v and true or false
    ApplyElement(key)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("MINIMAP_UPDATE_TRACKING")
frame:RegisterEvent("SPELLS_CHANGED")
frame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName ~= "Blizzard_TimeManager" and addonName ~= "Blizzard_Calendar" then return end
    C_Timer.After(0.2, Hider.Apply)
    C_Timer.After(1.0, Hider.Apply)
end)

AklimeMod_MinimapElementHider = Hider
