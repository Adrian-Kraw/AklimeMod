-- UI/MainWindow.lua — Hauptfenster, Insets, Initializer

-- ============================================================
-- Main Window
-- ============================================================
local frame = AklimeModFrame

_G["AklimeModFrameTitleText"]:SetText("Aklime Mod Tools")
AklimeModFramePortrait:SetTexture("Interface\\AddOns\\AklimeModTools\\Assets\\icon")

frame:SetFrameStrata("DIALOG")
frame:SetMovable(true)
frame:SetResizable(true)
frame:SetResizeBounds(700, 400)
table.insert(UISpecialFrames, frame:GetName())

frame.TitleContainer:SetScript("OnMouseDown", function()
    frame:StartMoving(); frame:SetAlpha(0.9)
end)
frame.TitleContainer:SetScript("OnMouseUp", function()
    frame:StopMovingOrSizing(); frame:SetAlpha(1)
end)

frame.resizeHandle = CreateFrame("Button", nil, frame)
frame.resizeHandle:SetPoint("BOTTOMRIGHT", -1, 1)
frame.resizeHandle:SetSize(26, 26)
frame.resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
frame.resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
frame.resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
frame.resizeHandle:SetScript("OnMouseDown", function(_, b)
    if b == "LeftButton" then frame:StartSizing("BOTTOMRIGHT") end
end)
frame.resizeHandle:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)

-- ============================================================
-- Left Inset (Kategorie-Liste)
-- ============================================================
frame.leftInset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
frame.leftInset:SetPoint("TOPLEFT", 25, -60)
frame.leftInset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 250, 35)

frame.leftInset.scrollBox = CreateFrame("Frame", nil, frame.leftInset, "WowScrollBoxList")
frame.leftInset.scrollBox:SetPoint("TOPLEFT",     frame.leftInset, "TOPLEFT",     4, -4)
frame.leftInset.scrollBox:SetPoint("BOTTOMRIGHT", frame.leftInset, "BOTTOMRIGHT", -4, 4)

frame.leftInset.scrollBar = CreateFrame("EventFrame", nil, frame.leftInset, "MinimalScrollBar")
frame.leftInset.scrollBar:SetPoint("TOPLEFT",    frame.leftInset, "TOPRIGHT",    7, 0)
frame.leftInset.scrollBar:SetPoint("BOTTOMLEFT", frame.leftInset, "BOTTOMRIGHT", 7, 0)
frame.leftInset.scrollBar:Hide()

AklimeMod_LeftScrollView = CreateScrollBoxListLinearView()
AklimeMod_LeftScrollView:SetPadding(10, 10, 10, 10, 4)
ScrollUtil.InitScrollBoxListWithScrollBar(
    frame.leftInset.scrollBox,
    frame.leftInset.scrollBar,
    AklimeMod_LeftScrollView
)

-- ============================================================
-- Suchleiste (oben rechts im Fenster)
-- ============================================================
local searchBox = CreateFrame("EditBox", "AklimeModSearchBox", frame, "SearchBoxTemplate")
searchBox:SetSize(220, 26)
searchBox:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -30)
searchBox:SetAutoFocus(false)
searchBox:SetMaxLetters(64)

-- Placeholder-Text
local function updateSearchPlaceholder()
    if searchBox:GetText() == "" then
        searchBox.Instructions:Show()
    else
        searchBox.Instructions:Hide()
    end
end
searchBox:HookScript("OnTextChanged", updateSearchPlaceholder)
searchBox:HookScript("OnEditFocusGained", function() searchBox.Instructions:Hide() end)
searchBox:HookScript("OnEditFocusLost", updateSearchPlaceholder)

if searchBox.Instructions then
    searchBox.Instructions:SetText(AklimeModL and AklimeModL["search_placeholder"] or "Search...")
end

-- Globale Referenz damit Categories.lua zugreifen kann
AklimeModSearchBox = searchBox

-- ============================================================
-- Right Inset (Inhalt)
-- ============================================================
frame.rightInset = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
frame.rightInset:SetPoint("TOPRIGHT",   frame,           "TOPRIGHT",   -25, -60)
frame.rightInset:SetPoint("BOTTOMLEFT", frame.leftInset, "BOTTOMRIGHT",  5,   0)

local rightHeader = frame.rightInset:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
rightHeader:SetPoint("TOPLEFT",  frame.rightInset, "TOPLEFT",   12, -10)
rightHeader:SetPoint("TOPRIGHT", frame.rightInset, "TOPRIGHT",  -12, -10)
rightHeader:SetJustifyH("CENTER")

local rightHeaderLine = frame.rightInset:CreateTexture(nil, "ARTWORK")
rightHeaderLine:SetHeight(1)
rightHeaderLine:SetPoint("TOPLEFT",  frame.rightInset, "TOPLEFT",   6, -30)
rightHeaderLine:SetPoint("TOPRIGHT", frame.rightInset, "TOPRIGHT",  -6, -30)
rightHeaderLine:SetColorTexture(0.3, 0.3, 0.3, 0.8)

function AklimeMod_SetRightHeader(text) rightHeader:SetText(text) end

frame.rightInset.scrollBox = CreateFrame("Frame", nil, frame.rightInset, "WowScrollBoxList")
frame.rightInset.scrollBox:SetPoint("TOPLEFT",     frame.rightInset, "TOPLEFT",     4, -36)
frame.rightInset.scrollBox:SetPoint("BOTTOMRIGHT", frame.rightInset, "BOTTOMRIGHT", -4,   4)

frame.rightInset.scrollBar = CreateFrame("EventFrame", nil, frame.rightInset, "MinimalScrollBar")
frame.rightInset.scrollBar:SetPoint("TOPLEFT",    frame.rightInset, "TOPRIGHT",    7, -36)
frame.rightInset.scrollBar:SetPoint("BOTTOMLEFT", frame.rightInset, "BOTTOMRIGHT", 7,    4)
frame.rightInset.scrollBar:SetHideIfUnscrollable(true)

AklimeMod_RightScrollView = CreateScrollBoxListTreeListView()
AklimeMod_RightScrollView:SetPadding(10, 10, 10, 10, 4)
ScrollUtil.InitScrollBoxListWithScrollBar(
    frame.rightInset.scrollBox,
    frame.rightInset.scrollBar,
    AklimeMod_RightScrollView
)

local TEMPLATE_EXTENTS = {
    AklimeMod_ToggleTemplate       = 32,
    AklimeMod_SliderTemplate       = 52,
    AklimeMod_ModuleHeaderTemplate = 32,
    AklimeMod_SkinHeaderTemplate   = 32,
    AklimeMod_InfoTextTemplate     = 24,
    AklimeMod_ActionButtonTemplate = 70,
    AklimeMod_SeparatorTemplate    = 50,
    AklimeMod_SubColorTemplate     = 32,
}

AklimeMod_RightScrollView:SetElementExtentCalculator(function(index, node)
    local data = node:GetData()
    if data and data.extent then return data.extent end
    return (data and data.Template and TEMPLATE_EXTENTS[data.Template]) or 32
end)

-- ============================================================
-- Shared Initializer (wie FrameColor)
-- ============================================================
local function headerInitializer(button, node)
    local data = node:GetData()
    button._refreshCheckbox = function() button.enableButton:SetChecked(data.getEnabled()) end
    button.name:SetText(data.name)
    local function updateArrow()
        local atlas = node:IsCollapsed()
            and "Options_ListExpand_Right"
            or  "Options_ListExpand_Right_Expanded"
        if button.Right         then button.Right:SetAtlas(atlas, TextureKitConstants.UseAtlasSize) end
        if button.HighlightRight then button.HighlightRight:SetAtlas(atlas, TextureKitConstants.UseAtlasSize) end
    end
    updateArrow()
    button:SetScript("OnClick", function() node:ToggleCollapsed(); updateArrow() end)
    button.enableButton:SetScript("OnClick", function(self)
        data.setEnabled(self:GetChecked()); updateArrow()
    end)
    button.enableButton:SetChecked(data.getEnabled())
end

local function toggleInitializer(button, node)
    local data = node:GetData()
    button._refreshCheckbox = function() button.toggle:SetChecked(data.getVal()) end
    button.name:SetText(data.name)
    button.toggle:SetScript("OnClick", function(self)
        data.setVal(self:GetChecked())
        -- Zustand immer aus der DB spiegeln: Radio-Optionen lassen sich so
        -- nicht abwaehlen und der Haken zeigt nie einen veralteten Stand.
        self:SetChecked(data.getVal())
    end)
    button.toggle:SetChecked(data.getVal())
end

-- Synchronisiert alle sichtbaren Checkboxen mit ihren Gettern.
-- Jeder Initializer hinterlegt dafuer _refreshCheckbox am Frame.
-- Laeuft synchron und nur ueber die tatsaechlich angezeigten Frames,
-- damit nach einem Radio-Klick nie zwei Haken gleichzeitig stehen
-- und keine recycelten Frames falsche Zustaende bekommen.
-- Erst sammeln, dann ausfuehren: ein Refresh-Callback darf Sektionen
-- zuklappen (Colorizer), was die Frame-Liste der ScrollBox veraendert.
function AklimeMod_RefreshRightToggles()
    local scrollBox = frame.rightInset and frame.rightInset.scrollBox
    if not scrollBox or not scrollBox.ForEachFrame then return end
    local pending = {}
    scrollBox:ForEachFrame(function(button)
        if button._refreshCheckbox then pending[#pending + 1] = button._refreshCheckbox end
    end)
    for _, refresh in ipairs(pending) do refresh() end
end

local function sliderInitializer(frame, node)
    local data = node:GetData()
    if frame.label then frame.label:SetText(data.label or "") end
    local s = frame.slider
    if s then
        -- Alten Callback entfernen bevor Bereich/Wert geaendert werden.
        -- Sonst feuert der recycelte Callback vom vorherigen Node beim
        -- SetMinMaxValues-Clamping und schreibt den falschen Wert in die DB.
        s:SetScript("OnValueChanged", nil)
        s:SetMinMaxValues(data.sliderMin or 0, data.sliderMax or 100)
        s:SetValueStep(data.sliderStep or 1)
        s:SetObeyStepOnDrag(true)
        local cur = data.getVal and data.getVal() or 0
        s:SetValue(cur)
        local actual = math.floor(s:GetValue() + 0.5)
        -- Wenn der gespeicherte Wert ausserhalb des Slider-Bereichs lag, korrigieren.
        if actual ~= cur and data.setVal then data.setVal(actual) end
        if frame.valueText then
            frame.valueText:SetText(data.formatFn and data.formatFn(actual) or tostring(actual))
        end
        s:SetScript("OnValueChanged", function(_, value)
            local v = math.floor(value + 0.5)
            if data.setVal then data.setVal(v) end
            if frame.valueText then
                frame.valueText:SetText(data.formatFn and data.formatFn(v) or tostring(v))
            end
        end)
    end
end
-- Global damit ColorizerUI.lua denselben Initializer nutzen kann
AklimeMod_SliderInitializer = sliderInitializer

function AklimeMod_RightFactory(factory, node)
    local data = node:GetData()
    if data.Template == "AklimeMod_ToggleTemplate" then
        factory(data.Template, toggleInitializer)
    elseif data.Template == "AklimeMod_SliderTemplate" then
        factory(data.Template, sliderInitializer)
    else
        factory(data.Template, headerInitializer)
    end
end

-- ============================================================
-- Open / toggle
-- ============================================================
function AklimeMod_OpenSettings()
    if InCombatLockdown() then return end
    if frame:IsShown() then frame:Hide() else frame:Show() end
end