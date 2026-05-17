-- Modules/QoL/Mailbox.lua
-- Adressbuch neben dem Postfach-Schreibfenster.
-- Klick auf Kontakt setzt den Empfänger automatisch.
-- Letzte Empfänger-Option merkt sich den letzten Empfänger pro Session.

local ROW_H        = 22
local FRAME_W      = 235
local ROW_AREA_TOP = -78   -- Pixelabstand (negativ) vom Frame-Top bis Zeilenbeginn
local ROW_AREA_BOT = 8     -- Abstand vom Frame-Boden bis letzte Zeile
local MAX_ROWS     = 25    -- obere Grenze; tatsächliche Anzahl wird per Höhe berechnet

-- ============================================================
-- DB-Zugriff
-- ============================================================
local function GetDB()
    if AklimeModDB and AklimeModDB.mailbox then return AklimeModDB.mailbox end
    return {}
end

-- ============================================================
-- Hilfsfunktionen
-- ============================================================
local function GetClassColor(class)
    local tbl = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS or {}
    local c = tbl[class]
    if c then return c.r or 1, c.g or 1, c.b or 1 end
    return 1, 1, 1
end

local function NormalizeRealm(realm)
    if type(realm) ~= "string" then return "" end
    return realm:gsub("[%s%-']", ""):lower()
end

local function BuildRecipient(name, realm)
    if not name or name == "" then return "" end
    local myRealm = select(2, UnitFullName("player")) or GetRealmName() or ""
    if realm == "" or NormalizeRealm(realm) == NormalizeRealm(myRealm) then
        return name
    end
    return name .. "-" .. realm
end

-- ============================================================
-- Modul
-- ============================================================
local M = {}
AklimeMod_Mailbox = M

M.searchText = ""
M.sortKey    = "name"
M.sortAsc    = true
M.filtered   = {}
M.rows       = {}
M.offset     = 0
M.frame      = nil
M.scrollBar  = nil

-- ============================================================
-- Filterung und Sortierung
-- ============================================================
local function BuildFiltered()
    local contacts = GetDB().contacts or {}
    local needle   = M.searchText:lower()

    local myName, myRealm = UnitFullName("player")
    myRealm = NormalizeRealm(myRealm or GetRealmName() or "")

    wipe(M.filtered)
    for key, rec in pairs(contacts) do
        local name  = rec.name  or key
        local realm = rec.realm or ""
        -- Eigenen Char nicht anzeigen
        if not (name:lower() == (myName or ""):lower() and NormalizeRealm(realm) == myRealm) then
            local match = needle == ""
                or name:lower():find(needle, 1, true)
                or (realm ~= "" and realm:lower():find(needle, 1, true))
            if match then
                local r, g, b = GetClassColor(rec.class)
                table.insert(M.filtered, {
                    key         = key,
                    name        = name,
                    realm       = realm,
                    nameColored = ("|cff%02x%02x%02x%s|r"):format(r*255, g*255, b*255, name),
                })
            end
        end
    end

    table.sort(M.filtered, function(a, b)
        local av, bv
        if M.sortKey == "realm" then
            av, bv = a.realm:lower(), b.realm:lower()
            if av == bv then av, bv = a.name:lower(), b.name:lower() end
        else
            av, bv = a.name:lower(), b.name:lower()
            if av == bv then av, bv = a.realm:lower(), b.realm:lower() end
        end
        if M.sortAsc then return av < bv else return av > bv end
    end)
end

-- ============================================================
-- Zeilen aktualisieren
-- ============================================================
local function CalcVisibleRows()
    if not M.frame then return 0 end
    local h = M.frame:GetHeight()
    return math.max(0, math.floor((h - math.abs(ROW_AREA_TOP) - ROW_AREA_BOT) / ROW_H))
end

local function UpdateRows()
    if not M.frame or not M.frame:IsShown() then return end
    local visible = CalcVisibleRows()
    local total   = #M.filtered

    for i, row in ipairs(M.rows) do
        if i <= visible then
            local idx = i + M.offset
            if M.filtered[idx] then
                local rec = M.filtered[idx]
                row.nameText:SetText(rec.nameColored)
                row.realmText:SetText(rec.realm)
                row.key    = rec.key
                row.rname  = rec.name
                row.rrealm = rec.realm
                row:Show()
            else
                row:Hide()
            end
        else
            row:Hide()
        end
    end

    if M.scrollUp and M.scrollDown then
        local maxOff = math.max(0, total - visible)
        if maxOff > 0 then
            M.scrollUp:Show();   M.scrollDown:Show()
            M.scrollUp:SetEnabled(M.offset > 0)
            M.scrollDown:SetEnabled(M.offset < maxOff)
        else
            M.scrollUp:Hide();   M.scrollDown:Hide()
        end
    end
end

-- ============================================================
-- Frame-Aufbau (lazy)
-- ============================================================
local function EnsureFrame()
    if M.frame then return end

    local f = CreateFrame("Frame", "AklimeMod_MailboxFrame", UIParent, "BackdropTemplate")
    f:SetWidth(FRAME_W)
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetBackdrop({
        bgFile   = "Interface/ChatFrame/ChatFrameBackground",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0.06, 0.06, 0.06, 0.95)
    f:SetBackdropBorderColor(0.55, 0.45, 0.15, 1)
    f:Hide()

    -- Titel
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -8)
    title:SetText("Adressbuch")

    -- Suche
    local sLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sLabel:SetPoint("TOPLEFT", 8, -30)
    sLabel:SetText("Suche:")

    local sBox = CreateFrame("EditBox", nil, f, "SearchBoxTemplate")
    sBox:SetPoint("TOPLEFT", 50, -28)
    sBox:SetPoint("TOPRIGHT", -8, -28)
    sBox:SetHeight(20)
    sBox:SetAutoFocus(false)
    sBox:SetScript("OnTextChanged", function(self)
        M.searchText = self:GetText()
        BuildFiltered()
        M.offset = 0
        UpdateRows()
    end)
    sBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    M.searchBox = sBox

    -- Spaltenheader
    local function MakeHeader(label, sortKey, left, width)
        local btn = CreateFrame("Button", nil, f)
        btn:SetPoint("TOPLEFT", left, -52)
        btn:SetSize(width, 22)
        btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.label:SetPoint("LEFT", 0, 0)
        btn.label:SetText(label)
        btn.sortKey = sortKey
        btn:SetScript("OnClick", function(self)
            if M.sortKey == self.sortKey then
                M.sortAsc = not M.sortAsc
            else
                M.sortKey = self.sortKey
                M.sortAsc = true
            end
            BuildFiltered()
            M.offset = 0
            UpdateRows()
        end)
        btn:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight", "ADD")
        return btn
    end
    M.nameHeader  = MakeHeader("Name",  "name",  6,   140)
    M.realmHeader = MakeHeader("Realm", "realm", 148, 80)

    -- Trennlinie
    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT",  f, "TOPLEFT",  4, -75)
    line:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -75)
    line:SetColorTexture(0.4, 0.4, 0.4, 0.8)

    -- Scroll: Pfeil-Buttons (kein Template, kein SecureScrollBar)
    local function MakeArrowBtn(isUp)
        local btn = CreateFrame("Button", nil, f)
        btn:SetSize(16, 16)
        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetTexture("Interface/Buttons/UI-ScrollBar-ScrollUpButton-Up")
        if not isUp then
            tex:SetTexCoord(0, 1, 1, 0)  -- vertikal spiegeln fuer unten
        end
        tex:SetAllPoints()
        btn:SetNormalTexture(tex)
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetTexture("Interface/Buttons/UI-ScrollBar-ScrollUpButton-Highlight")
        if not isUp then hl:SetTexCoord(0, 1, 1, 0) end
        hl:SetAllPoints()
        btn:SetHighlightTexture(hl)
        return btn
    end

    local upBtn   = MakeArrowBtn(true)
    local downBtn = MakeArrowBtn(false)
    upBtn:SetPoint("TOPRIGHT",    f, "TOPRIGHT", -3, ROW_AREA_TOP)
    downBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, ROW_AREA_BOT)
    upBtn:SetScript("OnClick", function()
        if M.offset > 0 then
            M.offset = M.offset - 1
            UpdateRows()
        end
    end)
    downBtn:SetScript("OnClick", function()
        local maxOff = math.max(0, #M.filtered - CalcVisibleRows())
        if M.offset < maxOff then
            M.offset = M.offset + 1
            UpdateRows()
        end
    end)
    upBtn:Hide();  downBtn:Hide()
    M.scrollUp   = upBtn
    M.scrollDown = downBtn

    -- Mausrad
    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function(_, delta)
        local maxOff = math.max(0, #M.filtered - CalcVisibleRows())
        M.offset = math.max(0, math.min(maxOff, M.offset - delta))
        UpdateRows()
    end)

    -- Zeilen vorerstellen
    for i = 1, MAX_ROWS do
        local row = CreateFrame("Button", nil, f)
        row:SetHeight(ROW_H)
        row:SetPoint("TOPLEFT",  f, "TOPLEFT",  6,  ROW_AREA_TOP - (i - 1) * ROW_H)
        row:SetPoint("TOPRIGHT", f, "TOPRIGHT", -22, ROW_AREA_TOP - (i - 1) * ROW_H)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight", "ADD")

        row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.nameText:SetPoint("LEFT", 0, 0)
        row.nameText:SetWidth(130)
        row.nameText:SetJustifyH("LEFT")
        row.nameText:SetWordWrap(false)

        row.realmText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.realmText:SetPoint("LEFT", 134, 0)
        row.realmText:SetWidth(78)
        row.realmText:SetJustifyH("LEFT")
        row.realmText:SetWordWrap(false)
        row.realmText:SetTextColor(0.65, 0.65, 0.65, 1)

        row:SetScript("OnClick", function(self, mouseButton)
            if mouseButton == "RightButton" then
                if not self.key then return end
                local key = self.key
                MenuUtil.CreateContextMenu(self, function(_, root)
                    root:CreateTitle(key)
                    root:CreateButton("Entfernen", function()
                        local db = GetDB()
                        if db.contacts then
                            db.contacts[key] = nil
                            BuildFiltered()
                            M.offset = 0
                            UpdateRows()
                        end
                    end)
                end)
                return
            end
            if SendMailNameEditBox and self.key then
                SendMailNameEditBox:SetText(BuildRecipient(self.rname, self.rrealm))
                SendMailNameEditBox:HighlightText(0, 0)
                SendMailNameEditBox:ClearFocus()
            end
        end)

        row:Hide()
        M.rows[i] = row
    end

    M.frame = f
end

-- ============================================================
-- Sichtbarkeit
-- ============================================================
function M:UpdateVisibility()
    if not self.frame then return end
    local db = GetDB()
    if not db.enabled
        or not MailFrame or not MailFrame:IsShown()
        or not SendMailFrame or not SendMailFrame:IsShown()
    then
        self.frame:Hide()
        return
    end

    self.frame:SetHeight(MailFrame:GetHeight() or 430)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 4, 0)

    BuildFiltered()
    M.offset = 0
    UpdateRows()
    self.frame:Show()
end

-- ============================================================
-- Eigene Charakter zu Kontakten hinzufügen
-- ============================================================
local function AddSelf()
    local db = GetDB()
    db.contacts = db.contacts or {}
    local name  = UnitName("player")
    local realm = GetRealmName() or ""
    if not name or name == "" then return end
    local class = select(2, UnitClass("player")) or "PRIEST"
    local r, g, b = GetClassColor(class)
    local key = name .. "-" .. realm
    db.contacts[key] = db.contacts[key] or {}
    db.contacts[key].name  = name
    db.contacts[key].realm = realm
    db.contacts[key].class = class
    db.contacts[key].color = { r = r, g = g, b = b }
end

-- ============================================================
-- Empfänger beim Absenden merken und als Kontakt speichern
-- ============================================================
local lastRecipient = nil
local sendHooked    = false

local function CaptureAndSaveRecipient()
    if not SendMailNameEditBox then return end
    local text = SendMailNameEditBox:GetText()
    if not text or text == "" then return end
    lastRecipient = text

    -- Als Kontakt ohne Klasse speichern (weiß)
    local db = GetDB()
    if not db.enabled then return end
    db.contacts = db.contacts or {}
    local name, realm = text:match("^([^%-]+)%-(.+)$")
    if not name then name = text; realm = "" end
    local key = name .. "-" .. (realm or "")
    if not db.contacts[key] then
        -- Sicherheitsgrenze: max 500 Kontakte
        local count = 0
        for _ in pairs(db.contacts) do count = count + 1 end
        if count >= 500 then return end
        db.contacts[key] = { name = name, realm = realm or "", class = nil }
    end
end

local function RestoreRecipient()
    local db = GetDB()
    if not db.rememberLastRecipient then return end
    if not SendMailNameEditBox then return end
    if lastRecipient and lastRecipient ~= "" then
        SendMailNameEditBox:SetText(lastRecipient)
        SendMailNameEditBox:HighlightText(0, 0)
    end
end

local function HookSendMail()
    if sendHooked then return end
    if type(SendMailFrame_SendMail) ~= "function" then return end
    if type(SendMailFrame_Reset)    ~= "function" then return end
    hooksecurefunc("SendMailFrame_SendMail", CaptureAndSaveRecipient)
    hooksecurefunc("SendMailFrame_Reset",    RestoreRecipient)
    sendHooked = true
end

-- ============================================================
-- Tab-Hook + MailFrame-Hide-Hook
-- ============================================================
local tabHooked     = false
local mailHideHooked = false

local function HookMailFrameHide()
    if mailHideHooked then return end
    if not MailFrame then return end
    MailFrame:HookScript("OnHide", function()
        if M.frame then M.frame:Hide() end
    end)
    mailHideHooked = true
end

local function HookMailTabs()
    if tabHooked then return end
    if type(MailFrameTab_OnClick) ~= "function" then return end
    hooksecurefunc("MailFrameTab_OnClick", function()
        if M.frame then M:UpdateVisibility() end
    end)
    tabHooked = true
end

-- ============================================================
-- API
-- ============================================================
function M:IsEnabled()
    return GetDB().enabled == true
end

function M:IsRememberLastRecipient()
    return GetDB().rememberLastRecipient == true
end

function M:SetEnabled(v)
    GetDB().enabled = v and true or false
    if v then
        AddSelf()
        EnsureFrame()
        HookMailTabs()
        HookMailFrameHide()
        self:UpdateVisibility()
    else
        if self.frame then self.frame:Hide() end
    end
end

function M:SetRememberLastRecipient(v)
    GetDB().rememberLastRecipient = v and true or false
    if not v then lastRecipient = nil end
end

function M:ClearContacts()
    local db = GetDB()
    db.contacts = {}
    wipe(M.filtered)
    M.offset = 0
    UpdateRows()
end

-- ============================================================
-- Event-Handling
-- ============================================================
local mailEventFrame = CreateFrame("Frame")
mailEventFrame:RegisterEvent("MAIL_SHOW")
mailEventFrame:RegisterEvent("MAIL_CLOSED")
mailEventFrame:RegisterEvent("ADDON_LOADED")
mailEventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_MailFrame" then HookSendMail() end
        return
    end
    if event == "MAIL_SHOW" then
        HookSendMail()
        HookMailFrameHide()
        HookMailTabs()
        EnsureFrame()
        RunNextFrame(function()
            if MailFrame and MailFrame:IsShown() then
                M:UpdateVisibility()
            end
        end)
    elseif event == "MAIL_CLOSED" then
        lastRecipient = nil
        if M.frame then M.frame:Hide() end
    end
end)

-- ============================================================
-- Init
-- ============================================================
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self)
    local db = GetDB()
    if db.enabled then
        AddSelf()
        EnsureFrame()
        HookMailTabs()
        HookMailFrameHide()
    end
    self:UnregisterEvent("PLAYER_LOGIN")
end)
