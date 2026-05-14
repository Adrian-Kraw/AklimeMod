-- AklimeMod.lua — Entry Point

local RADIUS = 99
local menuOpen = false
local menuButtons = {}

-- ============================================================
-- Minimap Button
-- ============================================================
local minimapBtn = CreateFrame("Button", "AklimeModMinimapBtn", Minimap)
minimapBtn:SetSize(36, 36)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFixedFrameStrata(true)
minimapBtn:SetFrameLevel(8)
minimapBtn:SetFixedFrameLevel(true)
minimapBtn:RegisterForClicks("AnyUp")
minimapBtn:RegisterForDrag("LeftButton")

local btnIcon = minimapBtn:CreateTexture(nil, "ARTWORK")
btnIcon:SetSize(30, 30)
btnIcon:SetPoint("CENTER", minimapBtn, "CENTER", 0, 0)
btnIcon:SetTexture("Interface\\AddOns\\AklimeMod\\Assets\\icon")

local mask = minimapBtn:CreateMaskTexture()
mask:SetAllPoints(btnIcon)
mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask",
    "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
btnIcon:AddMaskTexture(mask)

local btnRing = minimapBtn:CreateTexture(nil, "OVERLAY")
btnRing:SetSize(36, 36)
btnRing:SetPoint("CENTER", minimapBtn, "CENTER", 0, 0)
btnRing:SetAtlas("talents-node-choiceflyout-circle-yellow")

local function UpdateMinimapPos()
    local angle = math.rad(AklimeModDB.minimapAngle or -139.6)
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(angle) * RADIUS,
        math.sin(angle) * RADIUS)
end

-- Spread-Tabelle einmalig definiert, von beiden Stellen genutzt
local SPREADS   = { -24, -8, 8, 24 }
local OUTER_R   = 135

local function ApplyMenuPositions(angle)
    for i, mb in ipairs(menuButtons) do
        local a = angle + math.rad(SPREADS[i])
        mb:ClearAllPoints()
        mb:SetPoint("CENTER", Minimap, "CENTER",
            math.cos(a) * OUTER_R,
            math.sin(a) * OUTER_R)
    end
end

minimapBtn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local scale  = Minimap:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        cx, cy = cx / scale, cy / scale
        AklimeModDB.minimapAngle = math.deg(math.atan2(cy - my, cx - mx))
        UpdateMinimapPos()
        if menuOpen then
            ApplyMenuPositions(math.rad(AklimeModDB.minimapAngle))
        end
    end)
end)
minimapBtn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

-- ============================================================
-- Radialmenü
-- ============================================================
local MENU_ITEMS = {
    {   -- oben: PvP Chat Block
        icon    = "Interface\\Icons\\achievement_pvp_a_14",
        tooltip = "PvP Chat blockieren",
        onClick = function()
            if not AklimeMod_PvPChatBlock then return end
            local now = AklimeMod_PvPChatBlock.Toggle()
            if now then
                print("|cFFFFD100AklimeMod:|r |cFF00FF00Chatblockade aktiviert|r")
            else
                print("|cFFFFD100AklimeMod:|r |cFFFF4444Chatblockade deaktiviert|r")
            end
        end,
    },
    {   -- oben-mitte: Vault
        icon    = "Interface\\Icons\\inv_cape_special_treasure_c_01",
        tooltip = "Wöchentliche Schatzkammer",
        onClick = function()
            C_AddOns.LoadAddOn("Blizzard_WeeklyRewards")
            if WeeklyRewardsFrame:IsShown() then WeeklyRewardsFrame:Hide()
            else WeeklyRewardsFrame:Show() end
            -- ESC soll das Fenster schließen
            if not tContains(UISpecialFrames, "WeeklyRewardsFrame") then
                tinsert(UISpecialFrames, "WeeklyRewardsFrame")
            end
        end,
    },
    {   -- unten-mitte: Instances
        icon    = "Interface\\GossipFrame\\DailyActiveQuestIcon",
        tooltip = "Charakter-Tracker",
        onClick = function() AklimeMod_CT_Toggle() end,
    },
    {   -- unten: Settings
        icon    = "Interface\\Icons\\trade_engineering",
        tooltip = "AklimeMod Einstellungen",
        onClick = function() AklimeMod_OpenSettings() end,
    },
}

local function CreateMenuButton(item)
    local btn = CreateFrame("Button", nil, Minimap, "BackdropTemplate")
    btn:SetSize(30, 30)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(9)
    btn:Hide()

    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10, insets={left=2,right=2,top=2,bottom=2},
    })
    btn:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    btn:SetBackdropBorderColor(0.8, 0.65, 0.1, 1)

    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT",     btn, "TOPLEFT",      3, -3)
    tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -3,  3)
    tex:SetTexture(item.icon)

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hl:SetAlpha(0.3)

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, 0.82, 0, 1)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(item.tooltip, 1, 0.82, 0, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.8, 0.65, 0.1, 1)
        GameTooltip:Hide()
    end)
    btn:SetScript("OnClick", function()
        for _, mb in ipairs(menuButtons) do mb:Hide() end
        menuOpen = false
        item.onClick()
    end)

    return btn
end

local function PositionMenuButtons()
    ApplyMenuPositions(math.rad(AklimeModDB.minimapAngle or -139.6))
end

local function ToggleMenu()
    menuOpen = not menuOpen
    if menuOpen then
        PositionMenuButtons()
        for _, mb in ipairs(menuButtons) do mb:Show() end
    else
        for _, mb in ipairs(menuButtons) do mb:Hide() end
    end
end

minimapBtn:SetScript("OnClick", function(_, b)
    if b == "LeftButton" then ToggleMenu() end
end)

minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("AklimeMod", 1, 0.82, 0, 1)
    GameTooltip:AddLine("Klick: Menü öffnen/schließen", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Drag: Position ändern", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
minimapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- ============================================================
-- Slash Commands
-- ============================================================
SLASH_AKLIMEMOD1, SLASH_AKLIMEMOD2 = "/akm", "/aklimemod"
SlashCmdList["AKLIMEMOD"] = function() AklimeMod_OpenSettings() end

-- ============================================================
-- Events
-- ============================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event, arg1)

    if event == "ADDON_LOADED" and arg1 == "AklimeMod" then
        AklimeMod_InitDB()
        if AklimeMod_Colorizer then AklimeMod_Colorizer:Init() end
        UpdateMinimapPos()
        AklimeMod_BuildLeftPanel()
        AklimeMod_InitSearch()
        if AklimeModDB.reloadUI and AklimeModDB.reloadUI.enabled then
            SLASH_AKM_RL1, SLASH_AKM_RL2 = "/rl", "/nl"
            SlashCmdList["AKM_RL"] = function() ReloadUI() end
        end
        for _, item in ipairs(MENU_ITEMS) do
            table.insert(menuButtons, CreateMenuButton(item))
        end

    elseif event == "PLAYER_LOGIN" then
        -- SavedVariables sind jetzt garantiert geladen
        if AklimeMod_PreyPercent then AklimeMod_PreyPercent.Init() end
        if AklimeMod_PvPChatBlock then AklimeMod_PvPChatBlock.Init() end
        if AklimeMod_PvPNameplateColor then AklimeMod_PvPNameplateColor.Init() end

    elseif event == "PLAYER_TARGET_CHANGED" then
        AklimeMod_UpdateRareFrame()

    elseif event == "PLAYER_ENTERING_WORLD" then
        if AklimeModDB and AklimeModDB.eliteFrame and AklimeModDB.eliteFrame.enabled then
            C_Timer.After(0.5, function()
                AklimeMod_ApplyEliteFrame(AklimeModDB.eliteFrame.style)
            end)
        end
    end
end)