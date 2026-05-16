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
