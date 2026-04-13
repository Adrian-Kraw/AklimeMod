-- UI/Categories.lua

local RSV = function() return AklimeMod_RightScrollView end
local LSV = function() return AklimeMod_LeftScrollView  end

local function newDP() return CreateTreeDataProvider() end

local function setFactory()
    RSV():SetElementFactory(AklimeMod_RightFactory, function() end)
end

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
-- Custom Panel (Dashboard etc.)
-- ============================================================
local dashboardPanel    = nil
local currentCustomPanel = nil

local function HideCustomPanel()
    if currentCustomPanel then
        currentCustomPanel:Hide()
        currentCustomPanel = nil
    end
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
-- Right Factory — erweitert um Info und Action
-- ============================================================
local function infoInitializer(frame, node)
    local data = node:GetData()
    if frame.info then frame.info:SetText(data.text or "") end
end

local reloadBtns = nil  -- persistent damit wir nicht doppelt erstellen

local function actionInitializer(frame, node)
    local data = node:GetData()

    if data.label == "RELOAD_BUTTONS" then
        -- Zwei echte WoW-Buttons nebeneinander erstellen
        if not reloadBtns then
            -- Zeile 1: "Reload:" Label + /rl Button (oben im Frame)
            local lbl1 = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            lbl1:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -8)
            lbl1:SetText("Reload:")

            local b1 = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
            b1:SetSize(80, 26)
            b1:SetPoint("LEFT", lbl1, "RIGHT", 10, 0)
            b1:SetText("/rl")
            b1:SetScript("OnClick", function()
                if AklimeModDB.reloadUI.enabled then ReloadUI() end
            end)

            -- Zeile 2: "Neuladen:" Label + /nl Button (darunter)
            local lbl2 = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            lbl2:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -42)
            lbl2:SetText("Neuladen:")

            local b2 = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
            b2:SetSize(80, 26)
            b2:SetPoint("LEFT", lbl2, "RIGHT", 10, 0)
            b2:SetText("/nl")
            b2:SetScript("OnClick", function()
                if AklimeModDB.reloadUI.enabled then ReloadUI() end
            end)

            reloadBtns = { b1, b2 }
        end
        return
    end

    if frame.label then
        frame.label:SetText(data.label or "")
        frame.label:SetTextColor(1, 0.25, 0.25, 1)
    end
    frame:SetScript("OnClick", function()
        if data.onClick then data.onClick() end
    end)
    frame:SetScript("OnEnter", function()
        if frame.label then frame.label:SetTextColor(1, 0.5, 0.5, 1) end
    end)
    frame:SetScript("OnLeave", function()
        if frame.label then frame.label:SetTextColor(1, 0.25, 0.25, 1) end
    end)
end

function AklimeMod_RightFactory(factory, node)
    local data = node:GetData()
    local t = data.Template

    if t == "AklimeMod_SeparatorTemplate" then
        factory(t, function(frame, nd)
            local d = nd:GetData()
            if frame.label then
                frame.label:SetText(d.label or "")
                if d.sublabel then
                    -- Untergruppen-Label: kleiner, grau
                    frame.label:SetFont(GameFontHighlightSmall:GetFont())
                    frame.label:SetTextColor(0.65, 0.65, 0.65, 1)
                else
                    -- Haupt-Trennstrich: Überschriftgröße, gold
                    frame.label:SetFont(GameFontNormalLarge:GetFont())
                    frame.label:SetTextColor(1, 0.82, 0, 1)
                end
            end
        end)

    elseif t == "AklimeMod_ColorModuleTemplate" then
        factory(t, function(button, nd)
            local d = nd:GetData()
            if button.name then button.name:SetText(d.name or "") end
            button.enableButton:SetChecked(d.getEnabled())

            -- Swatch-Farbe setzen
            local r, g, b, a = d.getColor()
            if button.colorBtn and button.colorBtn.swatch then
                button.colorBtn.swatch:SetVertexColor(r, g, b, 1)
            end

            -- Enable-Toggle
            button.enableButton:SetScript("OnClick", function(self)
                d.setEnabled(self:GetChecked())
            end)

            -- Reset-Button: setzt auf Default-Farbe zurück
            if button.resetBtn then
                button.resetBtn:SetScript("OnClick", function()
                    local def = AklimeMod_Colorizer.defaults[d.key] or { r=0.28, g=0.28, b=0.28, a=1 }
                    d.setColor(def.r, def.g, def.b, def.a)
                    button.colorBtn.swatch:SetVertexColor(def.r, def.g, def.b, 1)
                end)
                button.resetBtn:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(button.resetBtn, "ANCHOR_TOP")
                    GameTooltip:AddLine("Standard wiederherstellen", 1,1,1)
                    GameTooltip:Show()
                end)
                button.resetBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end

            -- Klick auf Swatch öffnet WoW ColorPicker
            button.colorBtn:SetScript("OnClick", function()
                local r2, g2, b2, a2 = d.getColor()
                local function onChange()
                    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                    local na = ColorPickerFrame:GetColorAlpha()
                    d.setColor(nr, ng, nb, na)
                    button.colorBtn.swatch:SetVertexColor(nr, ng, nb, 1)
                end
                ColorPickerFrame:Hide()
                ColorPickerFrame:SetupColorPickerAndShow({
                    swatchFunc  = onChange,
                    opacityFunc = onChange,
                    cancelFunc  = function()
                        d.setColor(r2, g2, b2, a2)
                        button.colorBtn.swatch:SetVertexColor(r2, g2, b2, 1)
                    end,
                    hasOpacity = true,
                    opacity    = a2,
                    r = r2, g = g2, b = b2,
                })
            end)

            local function updateArrow()
                local atlas = nd:IsCollapsed()
                    and "Options_ListExpand_Right"
                    or  "Options_ListExpand_Right_Expanded"
                if button.Right         then button.Right:SetAtlas(atlas, TextureKitConstants.UseAtlasSize) end
                if button.HighlightRight then button.HighlightRight:SetAtlas(atlas, TextureKitConstants.UseAtlasSize) end
            end
            updateArrow()
            button:SetScript("OnClick", function() nd:ToggleCollapsed(); updateArrow() end)
        end)

    elseif t == "AklimeMod_ToggleTemplate" then
        factory(t, function(btn, nd)
            local d = nd:GetData()
            if btn.name then btn.name:SetText(d.name or "") end
            btn.toggle:SetChecked(d.getVal())
            btn.toggle:SetScript("OnClick", function(self) d.setVal(self:GetChecked()) end)
        end)
    elseif t == "AklimeMod_InfoTextTemplate" then
        factory(t, infoInitializer)
    elseif t == "AklimeMod_ActionButtonTemplate" then
        factory(t, actionInitializer)
    else
        -- ModuleHeaderTemplate
        factory(t, function(button, nd)
            local d = nd:GetData()
            if button.name then button.name:SetText(d.name or "") end
            button.enableButton:SetChecked(d.getEnabled())
            local function updateArrow()
                local atlas = nd:IsCollapsed()
                    and "Options_ListExpand_Right"
                    or  "Options_ListExpand_Right_Expanded"
                if button.Right         then button.Right:SetAtlas(atlas, TextureKitConstants.UseAtlasSize) end
                if button.HighlightRight then button.HighlightRight:SetAtlas(atlas, TextureKitConstants.UseAtlasSize) end
            end
            updateArrow()
            button:SetScript("OnClick", function() nd:ToggleCollapsed(); updateArrow() end)
            button.enableButton:SetScript("OnClick", function(self)
                d.setEnabled(self:GetChecked()); updateArrow()
            end)
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

    local cmds = {
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
    currentBuildFn = nil  -- Dashboard hat keine Suche
    if _G["AklimeModSearchBox"] then _G["AklimeModSearchBox"]:SetText("") end
    AklimeMod_SetRightHeader("Dashboard")
    ShowScrollView()
    setFactory()
    RSV():SetDataProvider(newDP())
    local ri = AklimeModFrame.rightInset
    ShowCustomPanel(GetOrCreateDashboard(ri))
end

-- ============================================================
-- Suche
-- ============================================================
local currentBuildFn = nil  -- merkt sich welche Kategorie gerade offen ist

local function ApplySearch(text)
    if not currentBuildFn then return end
    currentBuildFn(text)
end

-- SearchBox-Callback registrieren (nach ADDON_LOADED gesetzt)
function AklimeMod_InitSearch()
    local sb = _G["AklimeModSearchBox"]
    if not sb then return end
    sb:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            ApplySearch(self:GetText():lower())
        end
    end)
    sb:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
        ApplySearch("")
    end)
end

-- ============================================================
-- Interface
-- ============================================================
local function BuildInterfaceContent(filter)
    AklimeMod_SetRightHeader("Frames")
    ShowScrollView()
    setFactory()
    local dp = newDP()

    local eliteNode = addModule(dp, "Elite Frame",
        function() return AklimeModDB.eliteFrame.enabled end,
        function(v)
            AklimeModDB.eliteFrame.enabled = v
            if v and AklimeModDB.eliteFrame.style then AklimeMod_ApplyEliteFrame()
            else AklimeMod_RemoveEliteFrame() end
        end
    )
    -- Radio-Gruppe: nur einer kann aktiv sein
    local eliteStyles = {
        { key="silver",     label="Silberner Drachen"              },
        { key="silverWing", label="Silberner Drachen mit Flügeln"  },
        { key="gold",       label="Goldener Drachen"               },
        { key="goldWing",   label="Goldener Drachen mit Flügeln"   },
    }
    for _, s in ipairs(eliteStyles) do
        local key = s.key
        addToggle(eliteNode, s.label,
            function() return AklimeModDB.eliteFrame.style == key end,
            function(v)
                if v then
                    AklimeModDB.eliteFrame.style = key
                    if AklimeModDB.eliteFrame.enabled then AklimeMod_ApplyEliteFrame(key) end
                else
                    AklimeModDB.eliteFrame.style = nil
                    AklimeMod_RemoveEliteFrame()
                end
                -- ScrollView neu rendern damit alle Checkboxen den korrekten Zustand zeigen
                eliteNode:SetCollapsed(true)
                eliteNode:SetCollapsed(false)
            end
        )
    end

    local rareNode = addModule(dp, "Seltene Gegner",
        function() return AklimeModDB.rareFrame.enabled end,
        function(v)
            AklimeModDB.rareFrame.enabled = v
            AklimeMod_UpdateRareFrame()
        end
    )
    addToggle(rareNode, "Stern durch Silbernen Drachen ergänzen",
        function() return AklimeModDB.rareFrame.enabled end,
        function(v)
            AklimeModDB.rareFrame.enabled = v
            AklimeMod_UpdateRareFrame()
        end
    )

    -- ── Trennstrich + Kategorie "Anpassung" ──────────────────────────
    dp:Insert({
        Template = "AklimeMod_SeparatorTemplate",
        label    = "Anpassung",
    })

    -- Alle Gruppen aus Colorizer.groupOrder
    if AklimeMod_Colorizer then
        for _, group in ipairs(AklimeMod_Colorizer.groupOrder) do
            -- Filter: zeige Gruppe nur wenn mind. ein Eintrag passt
            local groupHasMatch = false
            if filter and filter ~= "" then
                for _, key in ipairs(group.keys) do
                    local skin = AklimeMod_Colorizer.skins[key]
                    if skin and skin.label:lower():find(filter, 1, true) then
                        groupHasMatch = true; break
                    end
                end
                -- Auch Gruppen-Label selbst prüfen
                if not groupHasMatch and group.label:lower():find(filter, 1, true) then
                    groupHasMatch = true
                end
            else
                groupHasMatch = true
            end

            if groupHasMatch then
                dp:Insert({
                    Template = "AklimeMod_SeparatorTemplate",
                    label    = group.label,
                    sublabel = true,
                })
            end
            for _, key in ipairs(group.keys) do
                local skin = AklimeMod_Colorizer.skins[key]
                -- Filter anwenden
                local matches = true
                if filter and filter ~= "" then
                    matches = skin and (
                        skin.label:lower():find(filter, 1, true) or
                        group.label:lower():find(filter, 1, true)
                    )
                end
                if skin and matches then
                    local k = key
                    dp:Insert({
                        Template   = "AklimeMod_ColorModuleTemplate",
                        key        = k,
                        name       = skin.label,
                        getEnabled = function()
                            return AklimeModDB.colorizer[k] and AklimeModDB.colorizer[k].enabled
                        end,
                        setEnabled = function(v)
                            if not AklimeModDB.colorizer[k] then return end
                            AklimeModDB.colorizer[k].enabled = v
                            local s = AklimeMod_Colorizer.skins[k]
                            if s then
                                if v then pcall(function() s:Apply() end)
                                else      pcall(function() s:Remove() end) end
                            end
                        end,
                        getColor = function()
                            local d = AklimeModDB.colorizer[k]
                            if not d then return 0.28,0.28,0.28,1 end
                            return d.r, d.g, d.b, d.a
                        end,
                        setColor = function(r, g, b, a)
                            local d = AklimeModDB.colorizer[k]
                            if not d then return end
                            d.r, d.g, d.b, d.a = r, g, b, a
                            if d.enabled then
                                local s = AklimeMod_Colorizer.skins[k]
                                if s then pcall(function() s:Apply() end) end
                            end
                        end,
                    })
                end
            end -- keys loop
        end -- groups loop
    end

    -- currentBuildFn merken für Suche
    currentBuildFn = BuildInterfaceContent

    RSV():SetDataProvider(dp)
end

-- ============================================================
-- Quality of Life
-- ============================================================
local function BuildQoLContent()
    currentBuildFn = nil
    if _G["AklimeModSearchBox"] then _G["AklimeModSearchBox"]:SetText("") end
    AklimeMod_SetRightHeader("Quality of Life")
    ShowScrollView()
    setFactory()
    local dp = newDP()

    -- Auto Repair
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

    -- Interface Neuladen
    local reloadNode = addModule(dp, "Interface Neuladen",
        function() return AklimeModDB.reloadUI.enabled end,
        function(v)
            AklimeModDB.reloadUI.enabled = v
            if v then
                SLASH_AKM_RL1, SLASH_AKM_RL2 = "/rl", "/nl"
                SlashCmdList["AKM_RL"] = function() ReloadUI() end
            else
                -- Slash-Commands deregistrieren
                SlashCmdList["AKM_RL"] = nil
                SLASH_AKM_RL1, SLASH_AKM_RL2 = nil, nil
            end
        end
    )
    addInfo(reloadNode,
        "Lädt das Interface komplett neu. Addon-Einstellungen werden gespeichert."
    )
    addAction(reloadNode, "RELOAD_BUTTONS", nil) -- Marker für zwei Buttons nebeneinander

    local deleteNode
    -- Einfaches Bestätigen und Löschen
    -- Haupt-Toggle = true wenn mindestens eine Sub aktiv
    -- Haupt-Toggle an  → beide Sub an
    -- Haupt-Toggle aus → beide Sub aus
    -- Beide Sub aus    → Haupt aus
    local function easyDeleteMainEnabled()
        local db = AklimeModDB.easyDelete
        return db.skipDelete == true or db.skipConfirm == true
    end

    local function refreshDeleteNode()
        deleteNode:SetCollapsed(true)
        deleteNode:SetCollapsed(false)
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
            -- Wenn beide aus → Haupt aus
            if not v and not AklimeModDB.easyDelete.skipConfirm then
                AklimeModDB.easyDelete.skipDelete  = false
                AklimeModDB.easyDelete.skipConfirm = false
            end
            refreshDeleteNode()
        end
    )
    addToggle(deleteNode, "Nicht mehr BESTÄTIGEN schreiben",
        function() return AklimeModDB.easyDelete.skipConfirm == true end,
        function(v)
            AklimeModDB.easyDelete.skipConfirm = v
            -- Wenn beide aus → Haupt aus
            if not v and not AklimeModDB.easyDelete.skipDelete then
                AklimeModDB.easyDelete.skipDelete  = false
                AklimeModDB.easyDelete.skipConfirm = false
            end
            refreshDeleteNode()
        end
    )

    RSV():SetDataProvider(dp)
end

local function BuildEmpty(header)
    currentBuildFn = nil
    if _G["AklimeModSearchBox"] then _G["AklimeModSearchBox"]:SetText("") end
    AklimeMod_SetRightHeader(header)
    ShowScrollView()
    setFactory()
    RSV():SetDataProvider(newDP())
end

-- ============================================================
-- Linke Kategorie-Buttons
-- ============================================================
local categories = {
    { order=1, name="Dashboard",       callback=BuildDashboardContent                   },
    { order=2, name="Interface",       callback=BuildInterfaceContent                   },
    { order=3, name="Quality of Life", callback=BuildQoLContent                         },
    { order=4, name="Collecting",      callback=function() BuildEmpty("Collecting") end },
    { order=5, name="PvP",             callback=function() BuildEmpty("PvP")        end },
    { order=6, name="Profile",         callback=function() BuildEmpty("Profile")    end },
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
    if data.order == 1 then
        SetSelected(button)
        data.callback()
    end
end

LSV():SetElementInitializer("AklimeMod_CategoryButtonTemplate", LeftInitializer)

function AklimeMod_BuildLeftPanel()
    local dp = CreateDataProvider()
    for _, cat in ipairs(categories) do dp:Insert(cat) end
    LSV():SetDataProvider(dp)
end

-- Slash-Befehle werden nur registriert wenn Toggle aktiv (siehe reloadNode setEnabled)