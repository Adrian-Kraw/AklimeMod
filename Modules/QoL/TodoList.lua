-- Modules/QoL/TodoList.lua
-- Persistente ToDo-Liste. Aufruf: /akm todo
-- Gespeichert in AklimeModDB.todoList.items = { "Text1", "Text2", ... }

local M = {}
AklimeMod_TodoList = M

local FRAME_W = 260
local FRAME_H = 340
local ITEM_H  = 24
local PAD     = 10
local MAX     = 50

local mainFrame, listContent, scrollFrame, editBox, emptyLabel
local itemRows = {}

-- ============================================================
-- DB
-- ============================================================

local function GetDB()
    if AklimeModDB and AklimeModDB.todoList then return AklimeModDB.todoList end
    return {}
end

local function GetItems()
    local db = GetDB()
    db.items = db.items or {}
    return db.items
end

-- ============================================================
-- Liste
-- ============================================================

local function RefreshList()
    for _, row in ipairs(itemRows) do row:Hide() end
    itemRows = {}

    local items  = GetItems()
    local rowW   = FRAME_W - PAD * 2 - 20  -- 20 Scrollbar

    for i, text in ipairs(items) do
        local row = CreateFrame("Frame", nil, listContent)
        row:SetSize(rowW, ITEM_H)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ITEM_H)

        local cb = CreateFrame("Button", nil, row)
        cb:SetSize(16, 16)
        cb:SetPoint("LEFT", 2, 0)
        cb:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
        cb:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
        local idx = i
        cb:SetScript("OnClick", function()
            table.remove(GetItems(), idx)
            RefreshList()
        end)

        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        lbl:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetWordWrap(false)
        lbl:SetText(text)

        table.insert(itemRows, row)
    end

    listContent:SetHeight(math.max(#items * ITEM_H, 1))
    if emptyLabel then emptyLabel:SetShown(#items == 0) end
end

-- ============================================================
-- Frame
-- ============================================================

local function BuildFrame()
    if mainFrame then return end

    mainFrame = CreateFrame("Frame", "AklimeModTodoFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(FRAME_W, FRAME_H)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local cx, cy = self:GetCenter()
        local db = GetDB()
        db.x, db.y = cx, cy
    end)
    mainFrame:SetFrameStrata("DIALOG")
    mainFrame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 24,
        insets   = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    mainFrame:Hide()

    tinsert(UISpecialFrames, "AklimeModTodoFrame")

    -- Titel
    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -14)
    title:SetText("ToDo")

    -- Schliessen
    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() mainFrame:Hide() end)

    -- ScrollFrame
    scrollFrame = CreateFrame("ScrollFrame", "AklimeModTodoScroll", mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     PAD,        -38)
    scrollFrame:SetPoint("BOTTOMRIGHT", -PAD - 16,   44)

    listContent = CreateFrame("Frame", nil, scrollFrame)
    listContent:SetWidth(FRAME_W - PAD * 2 - 20)
    listContent:SetHeight(1)
    scrollFrame:SetScrollChild(listContent)

    emptyLabel = listContent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyLabel:SetPoint("TOP", 0, -20)
    emptyLabel:SetText("Keine Eintraege")
    emptyLabel:Hide()

    -- EditBox-Rahmen
    local editBg = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    editBg:SetHeight(26)
    editBg:SetPoint("BOTTOMLEFT",  PAD,  PAD + 16)
    editBg:SetPoint("BOTTOMRIGHT", -PAD, PAD + 16)
    editBg:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    editBg:SetBackdropColor(0, 0, 0, 0.6)
    editBg:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

    editBox = CreateFrame("EditBox", nil, editBg)
    editBox:SetPoint("TOPLEFT",     5, -4)
    editBox:SetPoint("BOTTOMRIGHT", -5,  4)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontNormal)
    editBox:SetMaxLetters(200)
    editBox:SetScript("OnEnterPressed", function(self)
        local text = strtrim(self:GetText() or "")
        if text ~= "" then
            local items = GetItems()
            if #items < MAX then
                table.insert(items, text)
                RefreshList()
                scrollFrame:SetVerticalScroll(scrollFrame:GetVerticalScrollRange())
            end
        end
        self:SetText("")
        self:ClearFocus()
    end)
    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)

    -- Hinweis
    local hint = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOM", 0, PAD)
    hint:SetText("Enter = Hinzufuegen    |    Haken = Erledigt")

    -- Gespeicherte Position wiederherstellen
    local db = GetDB()
    if db.x and db.y then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", db.x, db.y)
    end
end

-- ============================================================
-- API
-- ============================================================

function M:Toggle()
    BuildFrame()
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        RefreshList()
        mainFrame:Show()
    end
end
