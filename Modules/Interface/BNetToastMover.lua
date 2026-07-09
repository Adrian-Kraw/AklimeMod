-- Modules/Interface/BNetToastMover.lua
-- Repositions Blizzard's "friend came online" Battle.net toast (BNToastFrame).
-- Blizzard positions it itself through the AlertFrame auto-anchor system, so
-- we hooksecurefunc its SetPoint and correct the position immediately after
-- (next frame tick, C_Timer.After(0, ...)) instead of replacing SetPoint
-- outright, which stopped the toast from showing at all (it likely relies
-- on its own SetPoint completing normally for internal bookkeeping).
-- Until a custom position exists, we passively record where Blizzard puts
-- it natively, so the preview always starts exactly there.

local PROXY_WIDTH  = 300
local PROXY_HEIGHT = 64

local function GetDB()
    if AklimeModDB and AklimeModDB.bnetToastMover then return AklimeModDB.bnetToastMover end
    return {}
end

local proxy  = nil
local hooked = false

local function SnapRealFrame()
    local db = GetDB()
    if not (db.enabled and db.x and db.y) then return end
    local toast = _G.BNToastFrame
    if not toast then return end
    local scale = toast:GetEffectiveScale()
    toast._akmMoving = true
    toast:ClearAllPoints()
    toast:SetPoint("CENTER", UIParent, "BOTTOMLEFT", db.x / scale, db.y / scale)
    C_Timer.After(0, function() toast._akmMoving = nil end)
end

local function EnsureHook()
    if hooked then return end
    local toast = _G.BNToastFrame
    if not toast then return end
    hooked = true

    hooksecurefunc(toast, "SetPoint", function(self)
        if self._akmMoving then return end
        local db = GetDB()
        if db.enabled and db.x and db.y then
            C_Timer.After(0, SnapRealFrame)
            return
        end
        -- No custom position yet: passively record where Blizzard puts it
        -- natively, used as the preview's starting point.
        local cx, cy = self:GetCenter()
        if cx and cy then
            local scale = self:GetEffectiveScale()
            db.naturalX = cx * scale
            db.naturalY = cy * scale
        end
    end)
end

local function SavePosition()
    local db = GetDB()
    local x, y = proxy:GetCenter()
    local scale = proxy:GetEffectiveScale()
    db.x = x * scale
    db.y = y * scale
end

-- Preview always starts at Blizzard's own natural position (if known),
-- not at a previously saved custom position, so it can be dragged from
-- the real starting point every time.
local function ApplyProxyPosition()
    local db = GetDB()
    proxy:ClearAllPoints()
    local x, y = db.naturalX or db.x, db.naturalY or db.y
    if x and y then
        local scale = proxy:GetEffectiveScale()
        proxy:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    else
        proxy:SetPoint("CENTER", UIParent, "CENTER", 0, 250)
    end
end

local function BuildProxy()
    if proxy then return end

    proxy = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    proxy:SetSize(PROXY_WIDTH, PROXY_HEIGHT)
    proxy:SetFrameStrata("DIALOG")
    proxy:SetMovable(true)
    proxy:SetClampedToScreen(true)
    proxy:Hide()

    proxy:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    proxy:SetBackdropColor(0.1, 0.5, 0.9, 0.35)
    proxy:SetBackdropBorderColor(0.3, 0.7, 1, 1)

    local label = proxy:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("CENTER")
    label:SetText(AklimeModL and AklimeModL["mod_bnet_toast_mover"] or "Appearing BNet Contacts")

    proxy:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not GetDB().locked then
            self:StartMoving()
        end
    end)
    proxy:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
        SavePosition()
        SnapRealFrame()
    end)
end

-- ============================================================
-- API
-- ============================================================
AklimeMod_BNetToastMover = {}

function AklimeMod_BNetToastMover:IsEnabled()
    return GetDB().enabled == true
end

function AklimeMod_BNetToastMover:SetEnabled(v)
    local db = GetDB()
    db.enabled = v and true or false
    if db.enabled then
        EnsureHook()
        SnapRealFrame()
    end
end

-- nil and true count as locked. Only explicit false = unlocked.
function AklimeMod_BNetToastMover:IsLocked()
    return GetDB().locked ~= false
end

function AklimeMod_BNetToastMover:SetLocked(v)
    local db = GetDB()
    db.locked = v ~= false
    if proxy then proxy:EnableMouse(not db.locked) end
end

function AklimeMod_BNetToastMover:ShowPreview()
    EnsureHook()
    BuildProxy()
    ApplyProxyPosition()
    proxy:EnableMouse(not self:IsLocked())
    proxy:Show()
end

function AklimeMod_BNetToastMover:HidePreview()
    if proxy then proxy:Hide() end
end

-- ============================================================
-- Events
-- ============================================================
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    if GetDB().enabled then
        EnsureHook()
        SnapRealFrame()
    end
end)
