-- ChatInteraction.lua
-- C-Button am Chat (verschiebbar, Größe wie Kontakte-Icon)
-- Links klickbar mit eigenem Popup-Fenster

AklimeMod_Defaults = AklimeMod_Defaults or {}
AklimeMod_Defaults.chatInteraction = {
    copyPaste  = false,
    clickLinks = false,
    btnLocked  = false,
    btnX = nil, btnY = nil,
}

local function GetDB()
    if AklimeModDB and AklimeModDB.chatInteraction then return AklimeModDB.chatInteraction end
    return AklimeMod_Defaults.chatInteraction
end

-- ============================================================
-- Chat-Copy Fenster
-- ============================================================
local copyFrame = nil

local function GetOrCreateCopyFrame()
    if copyFrame then return copyFrame end

    local f = CreateFrame("Frame", "AklimeMod_ChatCopyFrame", UIParent, "BackdropTemplate")
    f:SetSize(520, 340)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:Hide()
    tinsert(UISpecialFrames, "AklimeMod_ChatCopyFrame")

    -- Hintergrund: leicht transparent, dunkler Ton
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile=true, tileSize=32, edgeSize=26,
        insets={left=8, right=8, top=8, bottom=8},
    })
    f:SetBackdropColor(0.08, 0.08, 0.08, 0.85)
    f:SetBackdropBorderColor(1, 0.82, 0, 1)

    -- Titelleiste (drag-Bereich)
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetPoint("TOPLEFT"); titleBar:SetPoint("TOPRIGHT"); titleBar:SetHeight(32)
    titleBar:EnableMouse(true)
    titleBar:SetScript("OnMouseDown", function() f:StartMoving() end)
    titleBar:SetScript("OnMouseUp",   function() f:StopMovingOrSizing() end)

    -- Trennlinie unter Titel
    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(1, 0.82, 0, 0.4)
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT",  f, "TOPLEFT",  10, -32)
    divider:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -32)

    -- Titel-Text
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -10)
    title:SetText("|cFFFFD100Chat|r")

    -- Schließen-Button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- ScrollFrame
    local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     f, "TOPLEFT",     12, -38)
    sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 46)
    f.scrollFrame = sf

    -- EditBox
    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true)
    eb:SetMaxLetters(0)
    eb:SetFontObject(ChatFontNormal)
    eb:SetTextColor(0.9, 0.9, 0.9, 1)
    eb:SetAutoFocus(false)
    eb:EnableMouse(true)
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    sf:SetScrollChild(eb)
    f.editBox = eb

    -- Trennlinie über Buttons
    local divider2 = f:CreateTexture(nil, "ARTWORK")
    divider2:SetColorTexture(1, 0.82, 0, 0.4)
    divider2:SetHeight(1)
    divider2:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  10, 42)
    divider2:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 42)

    -- Buttons zentriert unten
    local btnAll = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnAll:SetSize(140, 26)
    btnAll:SetPoint("BOTTOM", f, "BOTTOM", -76, 12)
    btnAll:SetText("Alles auswählen")
    btnAll:SetScript("OnClick", function() eb:SetFocus(); eb:HighlightText() end)

    local btnClose = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnClose:SetSize(110, 26)
    btnClose:SetPoint("BOTTOM", f, "BOTTOM", 76, 12)
    btnClose:SetText("Schließen")
    btnClose:SetScript("OnClick", function() f:Hide() end)

    copyFrame = f
    return f
end

local function CleanChatMessage(msg)
    if type(msg) ~= "string" then return nil end

    local ok, clean = pcall(function()
        return msg:gsub("|c%x%x%x%x%x%x%x%x","")
                  :gsub("|r","")
                  :gsub("|H[^|]+|h%[([^%]]+)%]|h","%1")
                  :gsub("|T[^|]+|t","")
                  :gsub("|4[^;]+;","")
    end)

    if ok then return clean end
    return nil
end

local function OpenChatCopy(chatIdx, url)
    local f = GetOrCreateCopyFrame()
    f.editBox:SetText("")

    if url then
        -- URL-Modus: klein, URL markiert
        f:SetHeight(100)
        f.editBox:SetWidth(f.scrollFrame:GetWidth())
        f.editBox:Insert(url)
        f.editBox:HighlightText()
        f.editBox:SetFocus()
    else
        f:SetHeight(320)
        local cf = _G["ChatFrame"..(chatIdx or 1)]
        if not cf then return end

        -- Breite vor dem Einfuegen setzen, sonst berechnet WoW Zeilenumbrueche
        -- mit der falschen Breite und Klicks landen auf der falschen Zeile.
        f.editBox:SetWidth(f.scrollFrame:GetWidth())

        local maxLines = cf:GetNumMessages() or 0
        local startLine = math.max(1, maxLines - 300)
        local inserted = false
        for i = startLine, maxLines do
            local ok, msg = pcall(cf.GetMessageInfo, cf, i)
            msg = ok and CleanChatMessage(msg) or nil
            if msg and msg ~= "" then
                f.editBox:Insert((inserted and "\n" or "") .. msg)
                inserted = true
            end
        end

        -- Nach unten scrollen, damit die neuesten Nachrichten sichtbar sind.
        -- Einen Frame warten, weil GetVerticalScrollRange erst nach dem Render aktuell ist.
        C_Timer.After(0, function()
            f.scrollFrame:SetVerticalScroll(f.scrollFrame:GetVerticalScrollRange())
        end)
    end
    f:Show()
end

-- ============================================================
-- C-Button: verschiebbar, Größe wie Kontakte-Icon (~32x32)
-- ============================================================
local chatBtn = nil

local function CreateChatBtn()
    if chatBtn then return chatBtn end

    local btn = CreateFrame("Button", "AklimeMod_ChatCopyBtn", UIParent, "BackdropTemplate")
    btn:SetSize(32, 32)
    btn:SetFrameStrata("HIGH")
    btn:SetMovable(true)
    btn:SetClampedToScreen(true)
    btn:RegisterForDrag("LeftButton")
    btn:SetToplevel(true)

    -- Position wiederherstellen oder default neben Chat
    local db = GetDB()
    if db.btnX and db.btnY then
        btn:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", db.btnX, db.btnY)
    else
        btn:SetPoint("BOTTOMLEFT", ChatFrame1, "BOTTOMRIGHT", 4, 0)
    end

    -- Aussehen: wie Kontakte-Icon
    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12, insets={left=2,right=2,top=2,bottom=2},
    })
    btn:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
    btn:SetBackdropBorderColor(0.6, 0.5, 0.2, 1)

    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon")
    tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetAllPoints()
    label:SetText("|cFFFFD100C|r")
    tex:Hide()  -- Text statt Textur

    -- Drag
    btn:SetScript("OnDragStart", function(self)
        if not GetDB().copyPaste then return end
        if GetDB().btnLocked then return end
        self:StartMoving()
    end)
    btn:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x = self:GetLeft()
        local y = self:GetBottom()
        GetDB().btnX = x
        GetDB().btnY = y
        -- Neu verankern damit Position gespeichert bleibt
        self:ClearAllPoints()
        self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
    end)

    -- Highlight
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, 0.82, 0, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("|cFFFFD100Chat kopieren|r", 1, 1, 1)
        GameTooltip:AddLine("Klick: Chat-History öffnen", 0.7,0.7,0.7)
        GameTooltip:AddLine("Drag: Button verschieben", 0.7,0.7,0.7)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.6, 0.5, 0.2, 1)
        GameTooltip:Hide()
    end)

    btn:SetScript("OnClick", function()
        if copyFrame and copyFrame:IsShown() then
            copyFrame:Hide()
        else
            -- Welches ChatFrame ist gerade aktiv (sichtbar)?
            local idx = 1
            for i = 1, NUM_CHAT_WINDOWS do
                local cf = _G["ChatFrame"..i]
                if cf and cf:IsShown() then idx = i; break end
            end
            OpenChatCopy(idx)
        end
    end)

    chatBtn = btn
    return btn
end

local function UpdateChatBtn()
    if not chatBtn then return end
    if GetDB().copyPaste then chatBtn:Show() else chatBtn:Hide() end
end

-- ============================================================
-- URL-Erkennung & klickbare Links
-- ============================================================
local URL_PATTERNS = {
    "^(%a[%w+.-]+://%S+)",
    "%f[%S](%a[%w+.-]+://%S+)",
    "^(www%.[-%w_%%]+%.%a%a+%S*)",
    "%f[%S](www%.[-%w_%%]+%.%a%a+%S*)",
    "(%S+@[%w_.-%%]+%.%a%a+)",
}

local function FormatURL(url)
    return "|cff4db8ff|Hurl:"..url.."|h["..url.."]|h|r"
end

local function MakeClickable(_, _, msg, ...)
    if not GetDB().clickLinks then return false, msg, ... end

    local ok, newMsg = pcall(function()
        if type(msg) ~= "string" then return msg end
        for _, p in ipairs(URL_PATTERNS) do
            if msg:find(p) then
                msg = msg:gsub(p, FormatURL("%1"))
            end
        end
        return msg
    end)

    if ok then
        msg = newMsg
    end
    return false, msg, ...
end

-- URL-Klick öffnet das Copy-Fenster mit der URL
local origSetHyperlink = ItemRefTooltip.SetHyperlink
ItemRefTooltip.SetHyperlink = function(self, link, ...)
    if link and link:sub(1,3) == "url" then
        OpenChatCopy(nil, link:sub(5))
    else
        origSetHyperlink(self, link, ...)
    end
end

local CHAT_TYPES = {
    "SAY","YELL","PARTY","PARTY_LEADER","RAID","RAID_LEADER","RAID_WARNING",
    "GUILD","OFFICER","WHISPER","WHISPER_INFORM","CHANNEL","EMOTE","SYSTEM",
    "BN_WHISPER","BN_WHISPER_INFORM","BATTLEGROUND","BATTLEGROUND_LEADER",
}
local filtersOn = false
local function RegisterFilters()
    if filtersOn then return end
    for _, t in ipairs(CHAT_TYPES) do ChatFrame_AddMessageEventFilter("CHAT_MSG_"..t, MakeClickable) end
    filtersOn = true
end
local function UnregisterFilters()
    if not filtersOn then return end
    for _, t in ipairs(CHAT_TYPES) do ChatFrame_RemoveMessageEventFilter("CHAT_MSG_"..t, MakeClickable) end
    filtersOn = false
end

-- ============================================================
-- Init
-- ============================================================
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function()
    -- C-Button erstellen (aber nur zeigen wenn aktiviert)
    CreateChatBtn()
    UpdateChatBtn()
    -- Links
    if GetDB().clickLinks then RegisterFilters() end
end)

-- ============================================================
-- API
-- ============================================================
AklimeMod_ChatInteraction = {
    IsCopyPasteEnabled  = function() return GetDB().copyPaste end,
    SetCopyPasteEnabled = function(v)
        GetDB().copyPaste = v
        CreateChatBtn()
        UpdateChatBtn()
    end,
    IsClickLinksEnabled  = function() return GetDB().clickLinks end,
    SetClickLinksEnabled = function(v)
        GetDB().clickLinks = v
        if v then RegisterFilters() else UnregisterFilters() end
    end,
    IsBtnLocked  = function() return GetDB().btnLocked end,
    SetBtnLocked = function(v) GetDB().btnLocked = v end,
}
