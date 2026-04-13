-- AklimeMod.lua — Entry Point

-- ============================================================
-- Minimap Button
-- ============================================================
local minimapBtn = CreateFrame("Button", "AklimeModMinimapBtn", Minimap)
minimapBtn:SetSize(40, 40)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFixedFrameStrata(true)
minimapBtn:SetFrameLevel(8)
minimapBtn:SetFixedFrameLevel(true)
minimapBtn:RegisterForClicks("AnyUp")
minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:SetHighlightTexture(136477)

local btnOverlay = minimapBtn:CreateTexture(nil, "OVERLAY")
btnOverlay:SetSize(70, 70); btnOverlay:SetTexture(136430)
btnOverlay:SetPoint("TOPLEFT", minimapBtn, "TOPLEFT")

local btnBg = minimapBtn:CreateTexture(nil, "BACKGROUND")
btnBg:SetSize(33, 33); btnBg:SetTexture(136467)
btnBg:SetPoint("CENTER", minimapBtn, "CENTER")

local btnIcon = minimapBtn:CreateTexture(nil, "ARTWORK")
btnIcon:SetSize(28, 28)
btnIcon:SetPoint("CENTER", minimapBtn, "CENTER")
btnIcon:SetTexture("Interface\\AddOns\\AklimeMod\\Assets\\icon")

local function UpdateMinimapPos()
    local angle = math.rad(AklimeModDB.minimapAngle)
    local w = (Minimap:GetWidth()  / 2) + 5
    local h = (Minimap:GetHeight() / 2) + 5
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * w, math.sin(angle) * h)
end

minimapBtn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local scale  = Minimap:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        cx, cy = cx / scale, cy / scale
        AklimeModDB.minimapAngle = math.deg(math.atan2(cy - my, cx - mx))
        UpdateMinimapPos()
    end)
end)
minimapBtn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
minimapBtn:SetScript("OnClick", function(_, b)
    if b == "LeftButton" then AklimeMod_OpenSettings() end
end)
minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("AklimeMod")
    GameTooltip:AddLine("Klick: Einstellungen", 0.7, 0.7, 0.7)
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
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event, arg1)

    if event == "ADDON_LOADED" and arg1 == "AklimeMod" then
        AklimeMod_InitDB()
        -- Colorizer-DB nach den Skins befuellen (Skins sind bereits geladen)
        if AklimeMod_Colorizer then
            AklimeMod_Colorizer:Init()
        end
        UpdateMinimapPos()
        AklimeMod_BuildLeftPanel()
        AklimeMod_InitSearch()
        if AklimeModDB.reloadUI and AklimeModDB.reloadUI.enabled then
            SLASH_AKM_RL1, SLASH_AKM_RL2 = "/rl", "/nl"
            SlashCmdList["AKM_RL"] = function() ReloadUI() end
        end

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