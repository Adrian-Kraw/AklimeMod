-- UI/Categories.lua

local RSV = function() return AklimeMod_RightScrollView end
local LSV = function() return AklimeMod_LeftScrollView  end

local function newDP() return CreateTreeDataProvider() end

-- ============================================================
-- Shared Helfer
-- ============================================================
local function addModule(dp, name, getEnabled, setEnabled)
    local node = dp:Insert({
        Template   = "AklimeMod_ModuleHeaderTemplate",
        name       = name,
        getEnabled = getEnabled,
        setEnabled = setEnabled,
    })
    node:SetCollapsed(true)
    return node
end

local function addToggle(node, name, getVal, setVal)
    node:Insert({
        Template = "AklimeMod_ToggleTemplate",
        name     = name,
        getVal   = getVal,
        setVal   = setVal,
    })
end

local function addInfo(node, text)
    node:Insert({
        Template = "AklimeMod_InfoTextTemplate",
        text     = text,
    })
end

local function addAction(node, label, onClick)
    node:Insert({
        Template = "AklimeMod_ActionButtonTemplate",
        label    = label,
        onClick  = onClick,
    })
end

-- ============================================================
-- Custom Panel (Dashboard)
-- ============================================================
local dashboardPanel     = nil
local currentCustomPanel = nil

local function HideCustomPanel()
    if currentCustomPanel then currentCustomPanel:Hide(); currentCustomPanel = nil end
end

local function ShowCustomPanel(panel)
    HideCustomPanel()
    local ri = AklimeModFrame.rightInset
    if ri and ri.scrollBox then ri.scrollBox:Hide() end
    if ri and ri.scrollBar then ri.scrollBar:Hide() end
    panel:Show()
    currentCustomPanel = panel
end

local function ShowScrollView()
    HideCustomPanel()
    local ri = AklimeModFrame.rightInset
    if ri and ri.scrollBox then ri.scrollBox:Show() end
    if ri and ri.scrollBar then ri.scrollBar:Show() end
end

-- ============================================================
-- Right Factory fuer QoL / allgemeine Module
-- (Interface / Colorizer hat eigene Factory in ColorizerUI.lua)
-- ============================================================
local reloadBtns = nil

local function actionInitializer(frame, node)
    local data = node:GetData()
    if data.label == "RELOAD_BUTTONS" then
        if not reloadBtns then
            local lbl1 = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            lbl1:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -8); lbl1:SetText("Reload:")
            local b1 = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
            b1:SetSize(80, 26); b1:SetPoint("LEFT", lbl1, "RIGHT", 10, 0); b1:SetText("/rl")
            b1:SetScript("OnClick", function() if AklimeModDB.reloadUI.enabled then ReloadUI() end end)
            local lbl2 = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            lbl2:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -42); lbl2:SetText("Neuladen:")
            local b2 = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
            b2:SetSize(80, 26); b2:SetPoint("LEFT", lbl2, "RIGHT", 10, 0); b2:SetText("/nl")
            b2:SetScript("OnClick", function() if AklimeModDB.reloadUI.enabled then ReloadUI() end end)
            reloadBtns = { b1, b2 }
        end
        return
    end
    if frame.label then
        frame.label:SetText(data.label or "")
        frame.label:SetTextColor(1, 0.25, 0.25, 1)
    end
    frame:SetScript("OnClick", function() if data.onClick then data.onClick() end end)
    frame:SetScript("OnEnter", function() if frame.label then frame.label:SetTextColor(1, 0.5, 0.5, 1) end end)
    frame:SetScript("OnLeave", function() if frame.label then frame.label:SetTextColor(1, 0.25, 0.25, 1) end end)
end

local function moduleHeaderInitializer(button, node)
    local data = node:GetData()
    if not data or type(data.getEnabled) ~= "function" then return end

    if button.name then button.name:SetText(data.name or "") end

    local function isEnabled() return data.getEnabled() end

    local function updateVisuals()
        local enabled = isEnabled()
        local collapsed = node:IsCollapsed()
        if not enabled then
            if not collapsed then node:SetCollapsed(true) end
            if button.Right          then button.Right:SetAlpha(0.25) end
            if button.HighlightRight then button.HighlightRight:SetAlpha(0) end
        else
            local atlas = collapsed and "Options_ListExpand_Right" or "Options_ListExpand_Right_Expanded"
            if button.Right          then button.Right:SetAtlas(atlas, TextureKitConstants.UseAtlasSize); button.Right:SetAlpha(1) end
            if button.HighlightRight then button.HighlightRight:SetAtlas(atlas, TextureKitConstants.UseAtlasSize); button.HighlightRight:SetAlpha(1) end
        end
    end

    if not button.enableButton then return end
    button.enableButton:SetChecked(isEnabled())
    updateVisuals()

    button:SetScript("PreClick", function(self, mouseButton)
        if not node:GetData() or type(node:GetData().getEnabled) ~= "function" then return end
        if (mouseButton == "LeftButton" or mouseButton == nil) and not isEnabled() then
            node:SetCollapsed(true)
        end
    end)

    button:SetScript("OnClick", function(self, mouseButton)
        if not node:GetData() or type(node:GetData().getEnabled) ~= "function" then return end
        if not isEnabled() then
            node:SetCollapsed(true)
            updateVisuals()
            return
        end
        node:ToggleCollapsed()
        updateVisuals()
    end)

    button.enableButton:SetScript("OnClick", function(self)
        data.setEnabled(self:GetChecked())
        updateVisuals()
    end)
end

local function toggleInitializer(button, node)
    local data = node:GetData()
    if button.name then button.name:SetText(data.name or "") end
    local disabled = data.isDisabled and data.isDisabled()
    button.toggle:SetChecked(data.getVal())
    if disabled then
        button.toggle:Disable()
        button.toggle:SetAlpha(0.35)
        if button.name then button.name:SetTextColor(0.4, 0.4, 0.4, 1) end
    else
        button.toggle:Enable()
        button.toggle:SetAlpha(1.0)
        if button.name then button.name:SetTextColor(1, 0.82, 0, 1) end
    end
    button.toggle:SetScript("OnClick", function(self)
        if data.isDisabled and data.isDisabled() then
            self:SetChecked(not self:GetChecked()); return
        end
        data.setVal(self:GetChecked())
    end)
    button:SetScript("OnClick", function(self, mouseButton)
        -- Nichts tun — Toggle regelt sich selbst
    end)
end

local function ColorToHex(r, g, b)
    local function byte(v)
        v = tonumber(v) or 0
        if v < 0 then v = 0 elseif v > 1 then v = 1 end
        return math.floor(v * 255 + 0.5)
    end
    return string.format("#%02X%02X%02X", byte(r), byte(g), byte(b))
end

local function mouseColorInitializer(button, node)
    if not AklimeMod_MouseEffects then return end
    local data = node:GetData()
    local isTrail = data.mouseTrailColor == true
    local label = isTrail and "Spurfarbe" or "Ringfarbe"
    local classKey = isTrail and "trailClassColor" or "classColor"
    local getColor = isTrail and AklimeMod_MouseEffects.GetTrailColor or AklimeMod_MouseEffects.GetCustomColor
    local setColor = isTrail and AklimeMod_MouseEffects.SetTrailColor or AklimeMod_MouseEffects.SetCustomColor

    local function refresh()
        local r, g, b = getColor()
        local hex = ColorToHex(r, g, b)
        if button.name then button.name:SetText(label .. "  |cFFAAAAAA" .. hex .. "|r") end
        if button.colorPicker and button.colorPicker.swatch then
            button.colorPicker.swatch:SetAtlas(nil)
            button.colorPicker.swatch:SetColorTexture(r, g, b, 1)
        end
        if button.followClassColor then
            button.followClassColor:SetChecked(AklimeMod_MouseEffects.Get(classKey))
        end
    end

    refresh()

    if button.followClassColor then
        button.followClassColor:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("Klassenfarbe verwenden", 1, 1, 1)
            GameTooltip:Show()
        end)
        button.followClassColor:SetScript("OnLeave", function() GameTooltip:Hide() end)
        button.followClassColor:SetScript("OnClick", function(self)
            AklimeMod_MouseEffects.Set(classKey, self:GetChecked())
            refresh()
        end)
    end

    if button.colorPicker then
        button.colorPicker:SetScript("OnEnter", function(self)
            local r, g, b = getColor()
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("Farbe waehlen", 1, 1, 1)
            GameTooltip:AddLine(ColorToHex(r, g, b), 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        button.colorPicker:SetScript("OnLeave", function() GameTooltip:Hide() end)
        button.colorPicker:SetScript("OnClick", function()
            local oldR, oldG, oldB, oldA = getColor()
            local function onChange()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                local a = ColorPickerFrame.GetColorAlpha and ColorPickerFrame:GetColorAlpha() or oldA
                setColor(r, g, b, a)
                refresh()
            end
            ColorPickerFrame:Hide()
            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc = onChange,
                opacityFunc = onChange,
                cancelFunc = function()
                    setColor(oldR, oldG, oldB, oldA)
                    refresh()
                end,
                hasOpacity = true,
                opacity = oldA or 0.9,
                r = oldR, g = oldG, b = oldB,
            })
        end)
    end
end

-- Standard-Factory fuer QoL und andere Kategorien
function AklimeMod_RightFactory(factory, node)
    local d = node:GetData()
    local t = d.Template
    if t == "AklimeMod_ModuleHeaderTemplate" then
        factory(t, moduleHeaderInitializer)
    elseif t == "AklimeMod_ToggleTemplate" and d.name then
        -- normaler Toggle (QoL etc.) — hat .name statt .toggleLabel
        factory(t, toggleInitializer)
    elseif t == "AklimeMod_SubColorTemplate" and (d.mouseRingColor or d.mouseTrailColor) then
        factory(t, mouseColorInitializer)
    elseif t == "AklimeMod_InfoTextTemplate" then
        factory(t, function(frame, nd)
            local data = nd:GetData()
            local text = data.text
            if type(text) == "function" then text = text() end
            if frame.info then frame.info:SetText(text or "") end
        end)
    elseif t == "AklimeMod_ActionButtonTemplate" then
        factory(t, actionInitializer)
    elseif t == "AklimeMod_SeparatorTemplate" then
        factory(t, function(frame, nd)
            local data = nd:GetData()
            if frame.label then
                frame.label:SetText(data.label or "")
                if data.centered then
                    frame.label:SetFont(GameFontNormalLarge:GetFont())
                    frame.label:SetTextColor(1, 0.82, 0, 1)
                    frame.label:SetJustifyH("CENTER")
                    frame.label:ClearAllPoints()
                    frame.label:SetPoint("LEFT",  frame, "LEFT",  0, 0)
                    frame.label:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
                else
                    frame.label:SetFont(GameFontNormalLarge:GetFont())
                    frame.label:SetTextColor(1, 0.82, 0, 1)
                    frame.label:SetJustifyH("LEFT")
                    frame.label:ClearAllPoints()
                    frame.label:SetPoint("LEFT", frame, "LEFT", 8, 0)
                end
            end
        end)
    end
end

-- ============================================================
-- Dashboard
-- ============================================================
local function GetOrCreateDashboard(parent)
    if dashboardPanel then return dashboardPanel end
    dashboardPanel = CreateFrame("Frame", nil, parent)
    dashboardPanel:SetAllPoints(parent)
    dashboardPanel:Hide()

    local function Label(text, offsetY, font, r, g, b)
        local fs = dashboardPanel:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
        fs:SetPoint("TOPLEFT", dashboardPanel, "TOPLEFT", 20, offsetY)
        fs:SetTextColor(r or 0.9, g or 0.9, b or 0.9, 1)
        fs:SetText(text)
        return fs
    end
    local function Separator(offsetY)
        local line = dashboardPanel:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("TOPLEFT",  dashboardPanel, "TOPLEFT",  16, offsetY)
        line:SetPoint("TOPRIGHT", dashboardPanel, "TOPRIGHT", -16, offsetY)
        line:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    end

    local y = -40
    Label("|cFFFFD100Kontakt|r", y, "GameFontNormalLarge"); y = y - 28
    Separator(y); y = y - 18
    Label("|cFF00CCFFGithub:|r  github.com/aklime/aklimemod", y); y = y - 22
    Label("|cFF00CCFFIngame:|r  Yodabär-Blackmoore", y); y = y - 30
    Separator(y); y = y - 18
    Label("|cFFFFD100Befehle|r", y, "GameFontNormalLarge"); y = y - 28
    Separator(y); y = y - 18
    local cmds = AklimeMod_Commands or {
        { cmd="/akm",      desc="Addon öffnen / schließen" },
        { cmd="/akm help", desc="Alle Befehle im Chat anzeigen" },
    }
    for _, e in ipairs(cmds) do
        local row = dashboardPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row:SetPoint("TOPLEFT", dashboardPanel, "TOPLEFT", 20, y)
        row:SetText("|cFF00CCFF" .. e.cmd .. "|r   —   " .. e.desc)
        y = y - 22
    end
    return dashboardPanel
end

local function BuildDashboardContent()
    currentBuildFn = nil
    if _G["AklimeModSearchBox"] then _G["AklimeModSearchBox"]:SetText("") end
    AklimeMod_SetRightHeader("Dashboard")
    ShowScrollView()
    RSV():SetElementFactory(AklimeMod_RightFactory, function() end)
    RSV():SetDataProvider(newDP())

    -- Dashboard Panel immer neu aufbauen damit Commands-Liste aktuell ist
    if dashboardPanel then dashboardPanel:Hide(); dashboardPanel = nil end
    ShowCustomPanel(GetOrCreateDashboard(AklimeModFrame.rightInset))
end

-- ============================================================
-- Suche
-- ============================================================
local currentBuildFn = nil

function AklimeMod_InitSearch()
    local sb = _G["AklimeModSearchBox"]
    if not sb then return end
    sb:SetScript("OnTextChanged", function(self, userInput)
        if userInput and currentBuildFn then currentBuildFn(self:GetText():lower()) end
    end)
    sb:SetScript("OnEscapePressed", function(self)
        self:SetText(""); self:ClearFocus()
        if currentBuildFn then currentBuildFn("") end
    end)
end

-- ============================================================
-- Interface-Tab — Elite/Rare + Colorizer-Baum
-- ============================================================
local function BuildInterfaceContent(filter)
    AklimeMod_SetRightHeader("Interface")
    ShowScrollView()
    currentBuildFn = BuildInterfaceContent

    -- Factory auf Colorizer-Factory umschalten
    RSV():SetElementFactory(AklimeMod_ColorizerRightFactory, function() end)

    local dp = CreateTreeDataProvider()

    -- Elite Frame
    local eliteNode = dp:Insert({
        Template   = "AklimeMod_SkinHeaderTemplate",
        skinKey    = "__eliteFrame",  -- pseudo-key
        name       = "Elite Frame",
    })
    eliteNode:SetCollapsed(true)

    -- Wir bauen Elite Frame als normales Modul über Colorizer-Factory —
    -- aber da es kein Colorizer-Skin ist, braucht es einen Wrapper.
    -- Stattdessen: direkt nach dem Colorizer-DP die Elite-Module voranstellen.
    -- Lösung: separater DP mit gemischten Templates.

    -- DataProvider neu aufbauen: Elite + Rare als Module, dann Colorizer
    local dp2 = CreateTreeDataProvider()

    -- Elite Frame (bleibt als normaler Modul-Header mit eigenem Initializer)
    -- Wir nutzen einen Trick: Template ist SkinHeaderTemplate, aber skinKey ist nil
    -- und wir überschreiben den Initializer in der Factory.
    -- Sauberer: wir bauen Elite/Rare als AklimeMod_ModuleHeaderTemplate
    -- und registrieren sie in der ColorizerRightFactory.

    -- Erweiterte Factory (Elite + Rare Support)
    -- Wird direkt hier gesetzt bevor SetDataProvider.

    local function extendedFactory(factory, node)
        local d = node:GetData()
        if d.Template == "AklimeMod_ModuleHeaderTemplate" then
            factory(d.Template, moduleHeaderInitializer)
        elseif d.Template == "AklimeMod_ToggleTemplate" and d.name then
            factory(d.Template, toggleInitializer)
        elseif d.Template == "AklimeMod_SubColorTemplate" and (d.mouseRingColor or d.mouseTrailColor) then
            factory(d.Template, mouseColorInitializer)
        else
            -- Alle Colorizer-Templates
            AklimeMod_ColorizerRightFactory(factory, node)
        end
    end
    RSV():SetElementFactory(extendedFactory, function() end)

    local dp3 = CreateTreeDataProvider()

    -- Elite Frame
    local eliteNode3 = addModule(dp3, "Elite Frame",
        function() return AklimeModDB.eliteFrame.enabled end,
        function(v)
            AklimeModDB.eliteFrame.enabled = v
            if v and AklimeModDB.eliteFrame.style then AklimeMod_ApplyEliteFrame()
            else AklimeMod_RemoveEliteFrame() end
        end
    )
    local eliteStyles = {
        { key="silver",     label="Silberner Drachen"             },
        { key="silverWing", label="Silberner Drachen mit Flügeln" },
        { key="gold",       label="Goldener Drachen"              },
        { key="goldWing",   label="Goldener Drachen mit Flügeln"  },
    }
    for _, s in ipairs(eliteStyles) do
        local key = s.key
        addToggle(eliteNode3, s.label,
            function() return AklimeModDB.eliteFrame.style == key end,
            function(v)
                if v then
                    AklimeModDB.eliteFrame.style = key
                    if AklimeModDB.eliteFrame.enabled then AklimeMod_ApplyEliteFrame(key) end
                else
                    AklimeModDB.eliteFrame.style = nil; AklimeMod_RemoveEliteFrame()
                end
                eliteNode3:SetCollapsed(true); eliteNode3:SetCollapsed(false)
            end
        )
    end

    -- Seltene Gegner
    local rareNode = addModule(dp3, "Seltene Gegner",
        function() return AklimeModDB.rareFrame.enabled end,
        function(v) AklimeModDB.rareFrame.enabled = v; AklimeMod_UpdateRareFrame() end
    )
    addToggle(rareNode, "Stern durch Silbernen Drachen ergänzen",
        function() return AklimeModDB.rareFrame.enabled end,
        function(v) AklimeModDB.rareFrame.enabled = v; AklimeMod_UpdateRareFrame() end
    )

    -- Dungeon Eye
    local dungeonEyeNode = addModule(dp3, "Dungeon Eye",
        function() return AklimeMod_DungeonEye.IsEnabled() end,
        function(v) AklimeMod_DungeonEye.SetEnabled(v) end
    )
    addToggle(dungeonEyeNode, "An Minimap-Rand fixieren",
        function() return AklimeMod_DungeonEye.IsLocked() end,
        function(v) AklimeMod_DungeonEye.SetLocked(v) end
    )
    addInfo(dungeonEyeNode, "Kein Haken = frei per Drag ziehbar.\nHaken = springt an den Minimap-Rand.")

    -- Raid Frame Zentrierung
    local raidCenterNode = addModule(dp3, "Raid Frame Zentrierung",
        function() return AklimeMod_RaidFrameCenter.IsEnabled() end,
        function(v) AklimeMod_RaidFrameCenter.SetEnabled(v) end
    )
    addInfo(raidCenterNode, "Zentriert Raid-Frames dynamisch.\nGruppen werden immer um die Bildschirmmitte angeordnet.\nIm Bearbeitungsmodus inaktiv.")

    local hideMacroNode = addModule(dp3, "Makro-Namen ausblenden",
        function() return AklimeMod_HideMacroNames.IsEnabled() end,
        function(v) AklimeMod_HideMacroNames.SetEnabled(v) end
    )
    addInfo(hideMacroNode, "Versteckt die Makro-Namen auf allen Action Buttons.\nNeu erstellte Makros werden ebenfalls sofort ausgeblendet.")

    local dmCollapseNode = addModule(dp3, "Schadensanzeige: nach unten klappen",
        function() return AklimeMod_DamageMeterCollapseDown.IsEnabled() end,
        function(v) AklimeMod_DamageMeterCollapseDown.SetEnabled(v) end
    )
    addInfo(dmCollapseNode, "Ändert die Klapp-Richtung der Blizzard-Schadensanzeige.\nStandardmäßig klappt sie nach oben — mit diesem Toggle nach unten.")

    if AklimeMod_MinimapCollector then
        local mmCollectorNode = addModule(dp3, "Minimap Button Sammler",
            function()
                if not AklimeMod_MinimapCollector then return false end
                return AklimeMod_MinimapCollector.IsEnabled()
            end,
            function(v)
                if not AklimeMod_MinimapCollector then return end
                AklimeMod_MinimapCollector.SetEnabled(v)
            end
        )
        addInfo(mmCollectorNode, "Versteckt alle Addon-Minimap-Buttons in einem eigenen Button.\nKlick: Buttons aufklappen. Drag: Position ändern — wird automatisch gespeichert.")
        addToggle(mmCollectorNode, "Eigenen AklimeMod-Button einschließen",
            function()
                if not AklimeMod_MinimapCollector then return false end
                return AklimeMod_MinimapCollector.IncludeOwn()
            end,
            function(v)
                if not AklimeMod_MinimapCollector then return end
                AklimeMod_MinimapCollector.SetIncludeOwn(v)
            end
        )
    end

    if AklimeMod_MinimapElementHider then
        local hideNode = addModule(dp3, "Minimap-Elemente ausblenden",
            function() return AklimeMod_MinimapElementHider.IsEnabled() end,
            function(v) AklimeMod_MinimapElementHider.SetEnabled(v) end
        )
        addToggle(hideNode, "Verfolgungssymbol",
            function() return AklimeMod_MinimapElementHider.Get("tracking") end,
            function(v) AklimeMod_MinimapElementHider.Set("tracking", v) end
        )
        addToggle(hideNode, "Zoneninfo",
            function() return AklimeMod_MinimapElementHider.Get("zoneInfo") end,
            function(v) AklimeMod_MinimapElementHider.Set("zoneInfo", v) end
        )
        addToggle(hideNode, "Uhr",
            function() return AklimeMod_MinimapElementHider.Get("clock") end,
            function(v) AklimeMod_MinimapElementHider.Set("clock", v) end
        )
        addToggle(hideNode, "Kalender",
            function() return AklimeMod_MinimapElementHider.Get("calendar") end,
            function(v) AklimeMod_MinimapElementHider.Set("calendar", v) end
        )
        addToggle(hideNode, "Post-Symbol",
            function() return AklimeMod_MinimapElementHider.Get("mail") end,
            function(v) AklimeMod_MinimapElementHider.Set("mail", v) end
        )
        addToggle(hideNode, "Addonfach",
            function() return AklimeMod_MinimapElementHider.Get("addonCompartment") end,
            function(v) AklimeMod_MinimapElementHider.Set("addonCompartment", v) end
        )
    end

    if AklimeMod_MouseEffects then
        local mouseNode = addModule(dp3, "Mausring und Mausspur",
            function() return AklimeMod_MouseEffects.IsEnabled() end,
            function(v) AklimeMod_MouseEffects.SetEnabled(v) end
        )
        addToggle(mouseNode, "Mausspur aktivieren",
            function() return AklimeMod_MouseEffects.Get("trail") end,
            function(v) AklimeMod_MouseEffects.Set("trail", v) end
        )
        addToggle(mouseNode, "Klassenfarbe verwenden",
            function() return AklimeMod_MouseEffects.Get("classColor") end,
            function(v) AklimeMod_MouseEffects.Set("classColor", v) end
        )
        addToggle(mouseNode, "Mausspur in Klassenfarbe",
            function() return AklimeMod_MouseEffects.Get("trailClassColor") end,
            function(v) AklimeMod_MouseEffects.Set("trailClassColor", v) end
        )
        addToggle(mouseNode, "Punkt in der Mitte ausblenden",
            function() return AklimeMod_MouseEffects.Get("hideDot") end,
            function(v) AklimeMod_MouseEffects.Set("hideDot", v) end
        )
        addToggle(mouseNode, "Ring nur im Kampf",
            function() return AklimeMod_MouseEffects.Get("onlyCombat") end,
            function(v) AklimeMod_MouseEffects.Set("onlyCombat", v) end
        )
        addToggle(mouseNode, "Ring nur bei Rechtsklick",
            function() return AklimeMod_MouseEffects.Get("onlyRightClick") end,
            function(v) AklimeMod_MouseEffects.Set("onlyRightClick", v) end
        )
        addToggle(mouseNode, "Mausspur nur im Kampf",
            function() return AklimeMod_MouseEffects.Get("trailOnlyCombat") end,
            function(v) AklimeMod_MouseEffects.Set("trailOnlyCombat", v) end
        )
        addInfo(mouseNode, "Ringgroesse:")
        for _, opt in ipairs({
            { label = "Klein", size = 56 },
            { label = "Mittel", size = 76 },
            { label = "Gross", size = 96 },
            { label = "Sehr gross", size = 120 },
        }) do
            local size = opt.size
            addToggle(mouseNode, opt.label,
                function() return AklimeMod_MouseEffects.GetSize() == size end,
                function(v) if v then AklimeMod_MouseEffects.SetSize(size) end end
            )
        end
        mouseNode:Insert({
            Template = "AklimeMod_SubColorTemplate",
            mouseRingColor = true,
        })
        mouseNode:Insert({
            Template = "AklimeMod_SubColorTemplate",
            mouseTrailColor = true,
        })
        addInfo(mouseNode, "Mausspur-Dichte:")
        for _, opt in ipairs({
            { label = "Niedrig", preset = "low" },
            { label = "Mittel", preset = "medium" },
            { label = "Hoch", preset = "high" },
            { label = "Ultra", preset = "ultra" },
        }) do
            local preset = opt.preset
            addToggle(mouseNode, opt.label,
                function() return AklimeMod_MouseEffects.GetTrailPreset() == preset end,
                function(v) if v then AklimeMod_MouseEffects.SetTrailPreset(preset) end end
            )
        end
    end
    -- Colorizer-Nodes direkt in dp3 einfügen
    local function insertColorizerNodes(targetDP, searchFilter)
        local C = AklimeMod_Colorizer

        targetDP:Insert({
            Template = "AklimeMod_SeparatorTemplate",
            label    = "Farbliche Anpassungen",
            centered = true,
        })

        -- Master-Toggle: alle Skins an/aus
        local function AllEnabled()
            for _, group in ipairs(C.groupOrder) do
                for _, key in ipairs(group.keys) do
                    if not C:IsEnabled(key) then return false end
                end
            end
            return true
        end

        local function SetAll(v)
            for _, group in ipairs(C.groupOrder) do
                for _, key in ipairs(group.keys) do
                    AklimeModDB.colorizer[key] = AklimeModDB.colorizer[key] or {}
                    AklimeModDB.colorizer[key].enabled = v
                    local skin = C.skins[key]
                    if skin then
                        if v then pcall(function() skin:apply() end)
                        else      pcall(function() skin:remove() end) end
                    end
                end
            end
            -- UI neu aufbauen
            if AklimeMod_BuildInterfaceContent then AklimeMod_BuildInterfaceContent() end
        end

        targetDP:Insert({
            Template   = "AklimeMod_ModuleHeaderTemplate",
            name       = "Alle aktivieren / deaktivieren",
            getEnabled = AllEnabled,
            setEnabled = SetAll,
        })

        for _, group in ipairs(C.groupOrder) do
            local groupHasMatch = true
            if searchFilter and searchFilter ~= "" then
                groupHasMatch = false
                if group.label:lower():find(searchFilter, 1, true) then groupHasMatch = true end
                if not groupHasMatch then
                    for _, key in ipairs(group.keys) do
                        local skin = C.skins[key]
                        if skin and skin.label:lower():find(searchFilter, 1, true) then
                            groupHasMatch = true; break
                        end
                    end
                end
            end

            if groupHasMatch then
                targetDP:Insert({
                    Template = "AklimeMod_SeparatorTemplate",
                    label    = group.label,
                    sublabel = true,
                })

                -- Gruppe Master-Toggle
                local grpKeys = group.keys
                local function GroupAllEnabled()
                    for _, key in ipairs(grpKeys) do
                        if not C:IsEnabled(key) then return false end
                    end
                    return true
                end
                local function SetGroup(v)
                    for _, key in ipairs(grpKeys) do
                        AklimeModDB.colorizer[key] = AklimeModDB.colorizer[key] or {}
                        AklimeModDB.colorizer[key].enabled = v
                        local skin = C.skins[key]
                        if skin then
                            if v then pcall(function() skin:apply() end)
                            else      pcall(function() skin:remove() end) end
                        end
                    end
                    if AklimeMod_BuildInterfaceContent then AklimeMod_BuildInterfaceContent() end
                end
                targetDP:Insert({
                    Template   = "AklimeMod_ModuleHeaderTemplate",
                    name       = "Alle " .. group.label .. " an/aus",
                    getEnabled = GroupAllEnabled,
                    setEnabled = SetGroup,
                })

                for _, key in ipairs(group.keys) do
                    local skin = C.skins[key]
                    if skin then
                        local skinMatches = true
                        if searchFilter and searchFilter ~= "" then
                            skinMatches = skin.label:lower():find(searchFilter, 1, true)
                                or group.label:lower():find(searchFilter, 1, true)
                        end
                        if skinMatches then
                            local headerNode = targetDP:Insert({
                                Template = "AklimeMod_SkinHeaderTemplate",
                                skinKey  = key,
                                name     = skin.label,
                            })
                            headerNode:SetCollapsed(true)

                            -- Toggles
                            if skin.toggles then
                                for tk, td in pairs(skin.toggles) do
                                    headerNode:Insert({
                                        Template    = "AklimeMod_ToggleTemplate",
                                        skinKey     = key,
                                        toggleKey   = tk,
                                        toggleLabel = td.label or tk,
                                    })
                                end
                            end

                            -- Farben (sortiert)
                            if skin.colors then
                                local sortedColors = {}
                                for ck, cd in pairs(skin.colors) do
                                    table.insert(sortedColors, { key=ck, def=cd, order=cd.order or 99 })
                                end
                                table.sort(sortedColors, function(a,b) return a.order < b.order end)
                                for _, entry in ipairs(sortedColors) do
                                    headerNode:Insert({
                                        Template   = "AklimeMod_SubColorTemplate",
                                        skinKey    = key,
                                        colorKey   = entry.key,
                                        colorLabel = entry.def.label or entry.key,
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    insertColorizerNodes(dp3, filter)
    RSV():SetDataProvider(dp3)
end
AklimeMod_BuildInterfaceContent = BuildInterfaceContent

-- ============================================================
-- Quality of Life
-- ============================================================
local function BuildQoLContent()
    currentBuildFn = nil
    if _G["AklimeModSearchBox"] then _G["AklimeModSearchBox"]:SetText("") end
    AklimeMod_SetRightHeader("Quality of Life")
    ShowScrollView()
    RSV():SetElementFactory(AklimeMod_RightFactory, function() end)
    local dp = newDP()

    local chatNode = addModule(dp, "Chat Interaktion",
        function()
            return AklimeMod_ChatInteraction.IsCopyPasteEnabled()
                or AklimeMod_ChatInteraction.IsClickLinksEnabled()
        end,
        function(v)
            AklimeMod_ChatInteraction.SetCopyPasteEnabled(v)
            AklimeMod_ChatInteraction.SetClickLinksEnabled(v)
        end
    )
    -- Toggle: Chat kopieren
    chatNode:Insert({
        Template = "AklimeMod_ToggleTemplate",
        name     = "Chat kopieren aktivieren  (\"C\"-Button, verschiebbar)",
        getVal   = function() return AklimeMod_ChatInteraction.IsCopyPasteEnabled() end,
        setVal   = function(v)
            AklimeMod_ChatInteraction.SetCopyPasteEnabled(v)
            -- Neu rendern damit "Fixieren"-Toggle grau/aktiv wird
            chatNode:SetCollapsed(true)
            chatNode:SetCollapsed(false)
        end,
    })
    -- Toggle: Fixieren (ausgegraut wenn copyPaste aus)
    chatNode:Insert({
        Template     = "AklimeMod_ToggleTemplate",
        name         = "C-Button Position fixieren (kein Drag)",
        getVal       = function() return AklimeMod_ChatInteraction.IsBtnLocked() end,
        setVal       = function(v) AklimeMod_ChatInteraction.SetBtnLocked(v) end,
        isDisabled   = function() return not AklimeMod_ChatInteraction.IsCopyPasteEnabled() end,
    })
    -- Toggle: Links klickbar
    chatNode:Insert({
        Template = "AklimeMod_ToggleTemplate",
        name     = "Links klickbar machen",
        getVal   = function() return AklimeMod_ChatInteraction.IsClickLinksEnabled() end,
        setVal   = function(v) AklimeMod_ChatInteraction.SetClickLinksEnabled(v) end,
    })
    addInfo(chatNode, "C-Button: frei verschiebbar per Drag.\nLinks im Chat öffnen ein Kopierfenster.")

    local vaultNode = addModule(dp, "Wöchentliche Schatzkammer",
        function() return true end,
        function(v) end
    )
    addInfo(vaultNode, "Öffnet die wöchentliche Schatzkammer.\nAuch über das Radialmenü am Minimap-Icon erreichbar.")
    addAction(vaultNode, "Schatzkammer öffnen", function()
        C_AddOns.LoadAddOn("Blizzard_WeeklyRewards")
        if WeeklyRewardsFrame:IsShown() then
            WeeklyRewardsFrame:Hide()
        else
            WeeklyRewardsFrame:Show()
        end
    end)

    local repairNode = addModule(dp, "Auto Repair",
        function() return AklimeModDB.autoRepair.enabled end,
        function(v) AklimeModDB.autoRepair.enabled = v end
    )
    addToggle(repairNode, "Gildenbank verwenden (wenn Rechte vorhanden)",
        function() return AklimeModDB.autoRepair.useGuild end,
        function(v) AklimeModDB.autoRepair.useGuild = v end
    )
    addToggle(repairNode, "Eigene Tasche verwenden",
        function() return AklimeModDB.autoRepair.useGold end,
        function(v) AklimeModDB.autoRepair.useGold = v end
    )

    local reloadNode = addModule(dp, "Interface Neuladen",
        function() return AklimeModDB.reloadUI.enabled end,
        function(v)
            AklimeModDB.reloadUI.enabled = v
            if v then
                SLASH_AKM_RL1, SLASH_AKM_RL2 = "/rl", "/nl"
                SlashCmdList["AKM_RL"] = function() ReloadUI() end
            else
                SlashCmdList["AKM_RL"] = nil
                SLASH_AKM_RL1, SLASH_AKM_RL2 = nil, nil
            end
        end
    )
    addInfo(reloadNode, "Lädt das Interface komplett neu.")
    addAction(reloadNode, "RELOAD_BUTTONS", nil)

    local deleteNode
    local function easyDeleteMainEnabled()
        local db = AklimeModDB.easyDelete
        return db.skipDelete == true or db.skipConfirm == true
    end
    local function refreshDeleteNode()
        deleteNode:SetCollapsed(true); deleteNode:SetCollapsed(false)
    end
    deleteNode = addModule(dp, "Einfaches Bestätigen und Löschen",
        easyDeleteMainEnabled,
        function(v)
            AklimeModDB.easyDelete.skipDelete  = v
            AklimeModDB.easyDelete.skipConfirm = v
            refreshDeleteNode()
        end
    )
    addToggle(deleteNode, "Nicht mehr LÖSCHEN schreiben",
        function() return AklimeModDB.easyDelete.skipDelete == true end,
        function(v)
            AklimeModDB.easyDelete.skipDelete = v
            if not v and not AklimeModDB.easyDelete.skipConfirm then
                AklimeModDB.easyDelete.skipDelete = false; AklimeModDB.easyDelete.skipConfirm = false
            end
            refreshDeleteNode()
        end
    )
    addToggle(deleteNode, "Nicht mehr BESTÄTIGEN schreiben",
        function() return AklimeModDB.easyDelete.skipConfirm == true end,
        function(v)
            AklimeModDB.easyDelete.skipConfirm = v
            if not v and not AklimeModDB.easyDelete.skipDelete then
                AklimeModDB.easyDelete.skipDelete = false; AklimeModDB.easyDelete.skipConfirm = false
            end
            refreshDeleteNode()
        end
    )

    local sellJunkNode = addModule(dp, "Graue Items automatisch verkaufen",
        function() return AklimeMod_AutoSellJunk.IsEnabled() end,
        function(v) AklimeMod_AutoSellJunk.SetEnabled(v) end
    )
    addInfo(sellJunkNode, "Verkauft automatisch alle grauen Items wenn du einen Haendler oeffnest.\nNutzt Blizzards eingebauten Verkaufs-Button.")
    local leaveServiceNode = addModule(dp, "Dienste-Channel verlassen",
        function() return AklimeMod_LeaveServiceChannel.IsEnabled() end,
        function(v) AklimeMod_LeaveServiceChannel.SetEnabled(v) end
    )
    addInfo(leaveServiceNode, "Verlaesst automatisch den Dienste-Channel beim Login/Reload.\nDie Kanal-Nummer aendert sich — wird immer per Name gesucht.")

    -- ============================================================
    -- NEU: Jagd % Anzeige
    -- ============================================================
    local preyPctNode = addModule(dp, "Jagd % Anzeige (statt Kristall)",
        function() return AklimeMod_PreyPercent and AklimeMod_PreyPercent.IsEnabled() end,
        function(v)
            if AklimeMod_PreyPercent then AklimeMod_PreyPercent.SetEnabled(v) end
        end
    )
    addInfo(preyPctNode,
        "Versteckt den Blizzard-Kristall bei aktiver Jagd und zeigt\n" ..
        "stattdessen den Fortschritt als % Text an.\n\n" ..
        "Die Farbe wechselt automatisch:\n" ..
        "Rot < 25%  \183  Orange < 50%  \183  Gold < 75%  \183  Gruen >= 75%"
    )

    local manaNode = addModule(dp, "Mana Warnung",
        function() return AklimeMod_ManaWarning.IsEnabled() end,
        function(v) AklimeMod_ManaWarning.SetEnabled(v) end
    )
    addInfo(manaNode,
        "Sendet eine Nachricht im Gruppen- / Instanz-Chat wenn Mana niedrig ist.\n" ..
        "Nur aktiv wenn du in einer Gruppe oder Instanz bist.\n\n" ..
        "Im Kampf: Warnung bei Low Mana (~20%) und Out of Mana.\n" ..
        "Außerhalb Kampf: Nur Out of Mana bei fehlgeschlagenem Spell.\n\n" ..
        "Hinweis: Blizzard sperrt Mana-Werte (Secret Values) in 12.0.\n" ..
        "Schwellwert-Warnungen außerhalb Kampf sind technisch nicht moeglich."
    )

    local clock24hNode = addModule(dp, "24-Stunden-Uhr",
        function() return AklimeMod_Clock24h.IsEnabled() end,
        function(v) AklimeMod_Clock24h.SetEnabled(v) end
    )
    addInfo(clock24hNode, "Setzt die Blizzard-Uhr auf 24-Stunden-Format.\nWird beim Login automatisch aktiviert wenn nicht bereits gesetzt.")

    local mapCoordsNode = addModule(dp, "Karten-Koordinaten",
        function() return AklimeMod_MapCoords.IsEnabled() end,
        function(v) AklimeMod_MapCoords.SetEnabled(v) end
    )
    addInfo(mapCoordsNode, "Zeigt Maus- und Spieler-Koordinaten unten mittig auf der Weltkarte.\nFormat: Maus: X / Y  -  Spieler: X / Y")

    -- ============================================================
    -- Kontakte
    -- ============================================================
    dp:Insert({
        Template = "AklimeMod_SeparatorTemplate",
        label    = "Kontakte",
        centered = false,
    })

    if AklimeMod_ChatIcons then
        local chatIconsNode = addModule(dp, "Item- und Waehrungssymbole im Chat",
            function() return AklimeMod_ChatIcons:IsEnabled() end,
            function(v) AklimeMod_ChatIcons:SetEnabled(v) end
        )
        addInfo(chatIconsNode,
            "Zeigt vor jedem Item-Link das Item-Icon.\n" ..
            "Bei Beute- und Waehrungsnachrichten auch das Waehrungs-Icon."
        )
    end

    if AklimeMod_ChatFade then
        local chatFadeNode = addModule(dp, "Chat verblassen",
            function() return AklimeMod_ChatFade.IsEnabled() end,
            function(v) AklimeMod_ChatFade.SetEnabled(v) end
        )
        addInfo(chatFadeNode, "Sichtbar (Sekunden):")
        for _, opt in ipairs({
            { label = "15 Sekunden",  val = 15  },
            { label = "30 Sekunden",  val = 30  },
            { label = "60 Sekunden",  val = 60  },
            { label = "120 Sekunden", val = 120 },
        }) do
            local v = opt.val
            addToggle(chatFadeNode, opt.label,
                function() return AklimeMod_ChatFade.GetTimeVisible() == v end,
                function(on) if on then AklimeMod_ChatFade.SetTimeVisible(v) end end
            )
        end
        addInfo(chatFadeNode, "Verblassdauer:")
        for _, opt in ipairs({
            { label = "1 Sekunde",  val = 1 },
            { label = "3 Sekunden", val = 3 },
            { label = "5 Sekunden", val = 5 },
        }) do
            local v = opt.val
            addToggle(chatFadeNode, opt.label,
                function() return AklimeMod_ChatFade.GetFadeDuration() == v end,
                function(on) if on then AklimeMod_ChatFade.SetFadeDuration(v) end end
            )
        end
    end

    if AklimeMod_FriendsListDecor then
        local friendsNode = addModule(dp, "Verbesserte Freundesliste",
            function() return AklimeMod_FriendsListDecor:IsEnabled() end,
            function(v) AklimeMod_FriendsListDecor:SetEnabled(v) end
        )
        addToggle(friendsNode, "Zone und Realm anzeigen",
            function() return AklimeMod_FriendsListDecor:Get("showLocation") end,
            function(v) AklimeMod_FriendsListDecor:Set("showLocation", v) end
        )
        addToggle(friendsNode, "Eigenen Realm ausblenden",
            function() return AklimeMod_FriendsListDecor:Get("hideOwnRealm") end,
            function(v) AklimeMod_FriendsListDecor:Set("hideOwnRealm", v) end
        )
        addInfo(friendsNode,
            "Faerbt Freundesnamen in Klassenfarbe.\n" ..
            "Zeigt Level, Zone und Status (AFK/DND/Offline).\n" ..
            "BNet-Freunde: Spiel-Icon und Fraktionsflagge."
        )
    end

    -- ============================================================
    -- Haendler
    -- ============================================================
    dp:Insert({
        Template = "AklimeMod_SeparatorTemplate",
        label    = "Händler",
        centered = false,
    })

    if AklimeMod_Merchant then
        local merchantNode = addModule(dp, "20 Gegenstände pro Seite",
            function() return AklimeMod_Merchant:IsEnabled() end,
            function(v)
                if v then
                    AklimeMod_Merchant:Enable()
                    AklimeModDB.merchant.enabled = true
                else
                    AklimeMod_Merchant:Disable()
                    AklimeModDB.merchant.enabled = false
                end
            end
        )
        addInfo(merchantNode,
            "Zeigt 20 statt 10 Gegenstände pro Händler-Seite.\n" ..
            "Der Händler-Rahmen wird auf zwei Spalten verbreitert.\n" ..
            "Kann jederzeit ohne Neustart deaktiviert werden."
        )
    end

    -- ============================================================
    -- Trennlinie: Gesundheit
    -- ============================================================
    dp:Insert({
        Template = "AklimeMod_SeparatorTemplate",
        label    = "Gesundheit",
        centered = false,
    })

    local drinkNode = addModule(dp, "Trinkerinnerung",
        function() return AklimeMod_DrinkReminder.IsEnabled() end,
        function(v) AklimeMod_DrinkReminder.SetEnabled(v) end
    )
    addInfo(drinkNode,
        "Erinnert dich regelmäßig daran zu trinken und dich zu strecken.\n" ..
        "Erscheint als Ingame-Popup oben mittig. In Instanzen wird die\n" ..
        "Meldung zurückgehalten und kommt wenn du wieder draußen bist."
    )
    addToggle(drinkNode, "Nicht in Instanzen",
        function() return AklimeMod_DrinkReminder.GetDisableInInstance() end,
        function(v) AklimeMod_DrinkReminder.SetDisableInInstance(v) end
    )
    addInfo(drinkNode, "Intervall:")
    local intervals = {
        { label = "30 Minuten", minutes = 30  },
        { label = "1 Stunde",   minutes = 60  },
        { label = "2 Stunden",  minutes = 120 },
    }
    for _, opt in ipairs(intervals) do
        local m = opt.minutes
        addToggle(drinkNode,
            opt.label,
            function() return AklimeMod_DrinkReminder.GetInterval() == m end,
            function(v) if v then AklimeMod_DrinkReminder.SetInterval(m) end end
        )
    end
    addAction(drinkNode, "Jetzt testen", function()
        AklimeMod_DrinkReminder.ShowNow()
    end)

    RSV():SetDataProvider(dp)
end
AklimeMod_BuildQoLContent = BuildQoLContent  -- global fuer Module

-- ============================================================
-- PvP
-- ============================================================
local function BuildPvPContent()
    currentBuildFn = nil
    if _G["AklimeModSearchBox"] then _G["AklimeModSearchBox"]:SetText("") end
    AklimeMod_SetRightHeader("PvP")
    ShowScrollView()
    RSV():SetElementFactory(AklimeMod_RightFactory, function() end)
    local dp = newDP()

    -- ── Namensplaketten-Farben ────────────────────────────────
    local npNode = addModule(dp, "Namensplaketten einfärben",
        function() return AklimeMod_PvPNameplateColor and AklimeMod_PvPNameplateColor.IsEnabled() end,
        function(v)
            if AklimeMod_PvPNameplateColor then AklimeMod_PvPNameplateColor.SetEnabled(v) end
        end
    )
    addInfo(npNode,
        "Färbt Namensplaketten in PvP-Instanzen (Arena & Schlachtfeld):\n" ..
        "|cFF00FF00Grün|r  = eigene Gruppe / Team\n" ..
        "|cFFFF3333Rot|r   = Gegner\n\n" ..
        "Nur aktiv innerhalb einer PvP-Instanz.\n" ..
        "Außerhalb werden die Blizzard-Standardfarben wiederhergestellt."
    )

    -- ── Chat-Block ────────────────────────────────────────────
    dp:Insert({
        Template = "AklimeMod_SeparatorTemplate",
        label    = "Sonstiges",
        centered = false,
    })

    local chatBlockNode = addModule(dp, "Chat im PvP blockieren",
        function() return AklimeMod_PvPChatBlock and AklimeMod_PvPChatBlock.IsEnabled() end,
        function(v)
            if AklimeMod_PvPChatBlock then AklimeMod_PvPChatBlock.SetEnabled(v) end
        end
    )
    addInfo(chatBlockNode,
        "Verhindert das Öffnen der Chat-Eingabe (Enter) in Arenen und\n" ..
        "Schlachtfeldern — verhindert versehentliches Tippen mitten im Kampf."
    )

    RSV():SetDataProvider(dp)
end
AklimeMod_BuildPvPContent = BuildPvPContent

local function BuildEmpty(header)
    currentBuildFn = nil
    if _G["AklimeModSearchBox"] then _G["AklimeModSearchBox"]:SetText("") end
    AklimeMod_SetRightHeader(header)
    ShowScrollView()
    RSV():SetElementFactory(AklimeMod_RightFactory, function() end)
    RSV():SetDataProvider(newDP())
end

-- ============================================================
-- Collecting
-- ============================================================
local function BuildCollectingContent()
    currentBuildFn = nil
    if _G["AklimeModSearchBox"] then _G["AklimeModSearchBox"]:SetText("") end
    AklimeMod_SetRightHeader("Collecting")
    ShowScrollView()
    RSV():SetElementFactory(AklimeMod_RightFactory, function() end)
    local dp = newDP()

    -- ── Charakter-Tracker ─────────────────────────────────────
    dp:Insert({
        Template = "AklimeMod_SeparatorTemplate",
        label    = "Charakter-Tracker",
        centered = false,
    })
    dp:Insert({
        Template = "AklimeMod_InfoTextTemplate",
        text     = "Charaktere im Tracker auswählen: Tracker öffnen → 'Charaktere' Button.",
    })

    -- ── Raids nach Erweiterung ────────────────────────────────
    dp:Insert({
        Template = "AklimeMod_SeparatorTemplate",
        label    = "Schlachtzüge",
        centered = false,
    })

    local EXP_NAMES_SHORT = {
        [0]="Classic", [1]="TBC", [2]="WotLK", [3]="Cata", [4]="MoP",
        [5]="WoD", [6]="Legion", [7]="BfA", [8]="SL", [9]="DF",
        [10]="TWW", [11]="Midnight",
    }

    -- Master-Toggle pro Erweiterung
    local function BuildExpRaidToggles(dpTarget)
        -- Aus eigener DB oder SI
        local dataDB = (AklimeModDB and AklimeModDB.tracker and next(AklimeModDB.tracker.Instances))
            and AklimeModDB.tracker
            or _G.SavedInstancesDB
        if not dataDB or not dataDB.Instances then return end

        local exps = {}
        for _, inst in pairs(dataDB.Instances) do
            if inst.Raid and inst.Expansion then
                local exp = inst.Expansion
                if exp >= 0 and exp <= 11 then
                    exps[exp] = true
                end
            end
        end
        local expList = {}
        for e in pairs(exps) do expList[#expList+1] = e end
        table.sort(expList, function(a,b) return a > b end)

        for _, exp in ipairs(expList) do
            local e = exp
            local label = EXP_NAMES_SHORT[e] or ("Exp "..e)
            dpTarget:Insert({
                Template = "AklimeMod_ToggleTemplate",
                name     = label,
                getVal   = function()
                    local db = AklimeModDB and AklimeModDB.savedInstances
                    return not (db and db.raidExps and db.raidExps[e] == false)
                end,
                setVal   = function(v)
                    local db = AklimeModDB and AklimeModDB.savedInstances
                    if db then
                        db.raidExps = db.raidExps or {}
                        db.raidExps[e] = v and nil or false
                    end
                end,
            })
        end
    end
    BuildExpRaidToggles(dp)

    -- ── Währungen nach Erweiterung ────────────────────────────
    dp:Insert({
        Template = "AklimeMod_SeparatorTemplate",
        label    = "Währungen",
        centered = false,
    })

    local ALL_CURR_EXP = {
        {11,"Midnight"},{10,"The War Within"},{9,"Dragonflight"},
        {8,"Shadowlands"},{7,"Battle for Azeroth"},{6,"Legion"},
        {5,"Warlords"},{4,"Mists"},{3,"Cataclysm"},{2,"WotLK"},
        {1,"TBC"},{0,"Classic"},
    }
    local CURR_BY_EXP = {}
    for _, ce in ipairs({
        {id=3392,exp=11},{id=3373,exp=11},{id=3376,exp=11},{id=3379,exp=11},
        {id=3385,exp=11},{id=3383,exp=11},{id=3319,exp=11},{id=3316,exp=11},
        {id=3377,exp=11},{id=3378,exp=11},{id=3028,exp=11},{id=3310,exp=11},
        {id=3400,exp=11},{id=3341,exp=11},{id=3343,exp=11},{id=3345,exp=11},
        {id=3347,exp=11},
        {id=3056,exp=10},{id=2806,exp=10},{id=2803,exp=10},{id=2807,exp=10},
        {id=2912,exp=10},{id=2914,exp=10},{id=2650,exp=10},
        {id=2245,exp=9},{id=2123,exp=9},{id=2118,exp=9},
        {id=1191,exp=8},{id=1602,exp=8},{id=1792,exp=8},
        {id=1710,exp=7},{id=1718,exp=7},{id=1560,exp=7},
        {id=1754,exp=6},{id=1220,exp=6},
        {id=994,exp=5},{id=823,exp=5},
        {id=738,exp=4},{id=752,exp=4},
        {id=391,exp=3},{id=241,exp=2},
    }) do
        if not CURR_BY_EXP[ce.exp] then CURR_BY_EXP[ce.exp] = {} end
        CURR_BY_EXP[ce.exp][#CURR_BY_EXP[ce.exp]+1] = ce.id
    end

    local function GetCurrNameLocal(id)
        if C_CurrencyInfo then
            local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
            if ok and info and info.name ~= "" then
                local icon = info.iconFileID
                local iconStr = icon and ("|T" .. icon .. ":14:14:0:0|t ") or ""
                return iconStr .. info.name
            end
        end
        return "ID:" .. id
    end

    for _, pair in ipairs(ALL_CURR_EXP) do
        local exp, expLabel = pair[1], pair[2]
        local ids = CURR_BY_EXP[exp]
        if ids then
            -- Exp-Label
            dp:Insert({
                Template = "AklimeMod_InfoTextTemplate",
                text     = "|cFF888888" .. expLabel .. "|r",
            })
            for _, id in ipairs(ids) do
                local cid = id
                dp:Insert({
                    Template = "AklimeMod_ToggleTemplate",
                    name     = GetCurrNameLocal(cid),
                    getVal   = function()
                        local db = AklimeModDB and AklimeModDB.savedInstances
                        return not (db and db.currencies and db.currencies[cid] == false)
                    end,
                    setVal   = function(v)
                        local db = AklimeModDB and AklimeModDB.savedInstances
                        if db then
                            db.currencies = db.currencies or {}
                            db.currencies[cid] = v and nil or false
                        end
                    end,
                })
            end
        end
    end

    RSV():SetDataProvider(dp)
end

-- ============================================================
-- Linke Kategorie-Buttons
-- ============================================================
local categories = {
    { order=1, name="Dashboard",       callback=BuildDashboardContent                        },
    { order=2, name="Interface",       callback=BuildInterfaceContent                        },
    { order=3, name="Quality of Life", callback=BuildQoLContent                              },
    { order=4, name="Collecting",      callback=BuildCollectingContent                       },
    { order=5, name="PvP",             callback=function() AklimeMod_BuildPvPContent() end   },
    { order=6, name="Profile",         callback=function() BuildEmpty("Profile")         end },
}

local function SetSelected(clickedButton)
    LSV():FindFrameByPredicate(function(btn) btn.selectedTexture:Hide() end)
    clickedButton.selectedTexture:Show()
end

local function LeftInitializer(button, data)
    button.name:SetText(data.name)
    button:SetScript("OnClick", function(self)
        if self.selectedTexture:IsShown() then return end
        SetSelected(self)
        data.callback()
    end)
    if data.order == 1 then SetSelected(button); data.callback() end
end

LSV():SetElementInitializer("AklimeMod_CategoryButtonTemplate", LeftInitializer)

function AklimeMod_BuildLeftPanel()
    local dp = CreateDataProvider()
    for _, cat in ipairs(categories) do dp:Insert(cat) end
    LSV():SetDataProvider(dp)
end
