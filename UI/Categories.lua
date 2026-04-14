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
    if button.name then button.name:SetText(data.name or "") end
    button.enableButton:SetChecked(data.getEnabled())
    local function updateArrow()
        local atlas = node:IsCollapsed() and "Options_ListExpand_Right" or "Options_ListExpand_Right_Expanded"
        if button.Right         then button.Right:SetAtlas(atlas, TextureKitConstants.UseAtlasSize) end
        if button.HighlightRight then button.HighlightRight:SetAtlas(atlas, TextureKitConstants.UseAtlasSize) end
    end
    updateArrow()
    button:SetScript("OnClick", function() node:ToggleCollapsed(); updateArrow() end)
    button.enableButton:SetScript("OnClick", function(self) data.setEnabled(self:GetChecked()); updateArrow() end)
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
    elseif t == "AklimeMod_InfoTextTemplate" then
        factory(t, function(frame, nd)
            if frame.info then frame.info:SetText(nd:GetData().text or "") end
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
    for _, e in ipairs({
        { cmd="/akm",      desc="Addon öffnen / schließen" },
        { cmd="/akm help", desc="Alle Befehle im Chat anzeigen" },
        { cmd="/akm todo", desc="Todo-Liste öffnen (kommt bald)" },
    }) do
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

    -- Colorizer-Nodes direkt in dp3 einfügen
    local function insertColorizerNodes(targetDP, searchFilter)
        local C = AklimeMod_Colorizer

        targetDP:Insert({
            Template = "AklimeMod_SeparatorTemplate",
            label    = "Farbliche Anpassungen",
            centered = true,
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

    RSV():SetDataProvider(dp)
end

local function BuildEmpty(header)
    currentBuildFn = nil
    if _G["AklimeModSearchBox"] then _G["AklimeModSearchBox"]:SetText("") end
    AklimeMod_SetRightHeader(header)
    ShowScrollView()
    RSV():SetElementFactory(AklimeMod_RightFactory, function() end)
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
    if data.order == 1 then SetSelected(button); data.callback() end
end

LSV():SetElementInitializer("AklimeMod_CategoryButtonTemplate", LeftInitializer)

function AklimeMod_BuildLeftPanel()
    local dp = CreateDataProvider()
    for _, cat in ipairs(categories) do dp:Insert(cat) end
    LSV():SetDataProvider(dp)
end