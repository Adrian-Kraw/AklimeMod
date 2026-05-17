-- Modules/QoL/Merchant.lua
-- Zeigt 20 Gegenstände pro Händler-Seite statt 10 (2 Spalten à 10).

local ITEMS_PER_PAGE_EXPANDED = 20
local ORIGINAL_ITEMS_PER_PAGE = _G.MERCHANT_ITEMS_PER_PAGE or 10

local function GetDB()
    if AklimeModDB and AklimeModDB.merchant then return AklimeModDB.merchant end
    return { enabled = false }
end

-- ============================================================
-- Cache-Helfer
-- ============================================================

local cache = {}

local function SaveFrame(key, frame)
    if not frame or not frame.GetNumPoints then return end
    local points = {}
    for i = 1, frame:GetNumPoints() do
        local point, relTo, relPoint, x, y = frame:GetPoint(i)
        points[#points + 1] = { point, relTo, relPoint, x, y }
    end
    cache[key] = {
        width  = frame.GetWidth  and frame:GetWidth()  or nil,
        height = frame.GetHeight and frame:GetHeight() or nil,
        points = points,
    }
end

local function RestoreFrame(key, frame)
    local data = cache[key]
    if not data or not frame then return end
    frame:ClearAllPoints()
    for _, p in ipairs(data.points) do
        frame:SetPoint(p[1], p[2], p[3], p[4], p[5])
    end
    if data.width  and frame.SetWidth  then frame:SetWidth(data.width)   end
    if data.height and frame.SetHeight then frame:SetHeight(data.height) end
end

local function CacheAll()
    SaveFrame("merchantFrame",          MerchantFrame)
    SaveFrame("prevPageButton",         MerchantPrevPageButton)
    SaveFrame("pageText",               MerchantPageText)
    SaveFrame("nextPageButton",         MerchantNextPageButton)
    SaveFrame("buyBackItem",            _G.MerchantBuyBackItem)
    SaveFrame("moneyBg",                _G.MerchantMoneyBg)
    SaveFrame("extraCurrencyInset",     _G.MerchantExtraCurrencyInset)
    SaveFrame("extraCurrencyBg",        _G.MerchantExtraCurrencyBg)
    for i = 1, 4 do
        local btn = _G["MerchantToken" .. i]
        if btn then SaveFrame("token" .. i, btn) end
    end
end

local function RestoreAll()
    RestoreFrame("merchantFrame",      MerchantFrame)
    RestoreFrame("prevPageButton",     MerchantPrevPageButton)
    RestoreFrame("pageText",           MerchantPageText)
    RestoreFrame("nextPageButton",     MerchantNextPageButton)
    RestoreFrame("buyBackItem",        _G.MerchantBuyBackItem)
    RestoreFrame("moneyBg",            _G.MerchantMoneyBg)
    RestoreFrame("extraCurrencyInset", _G.MerchantExtraCurrencyInset)
    RestoreFrame("extraCurrencyBg",    _G.MerchantExtraCurrencyBg)
    for i = 1, 4 do
        local btn = _G["MerchantToken" .. i]
        if btn then RestoreFrame("token" .. i, btn) end
    end
    cache = {}
end

-- ============================================================
-- Layout-Funktionen
-- ============================================================

local M = {}
AklimeMod_Merchant = M

M.enabled = false
M.hooked  = false

local function RebuildMerchantFrame()
    if not MerchantFrame then return end
    MerchantFrame:SetWidth(696)
    for i = 1, MERCHANT_ITEMS_PER_PAGE do
        if not _G["MerchantItem" .. i] then
            CreateFrame("Frame", "MerchantItem" .. i, MerchantFrame, "MerchantItemTemplate")
        end
    end
end

local function UpdateSlotPositions()
    if not M.enabled or not MerchantFrame then return end
    local vertSpacing  = -16
    local horizSpacing = 12
    local perColumn    = ORIGINAL_ITEMS_PER_PAGE

    for i = 1, MERCHANT_ITEMS_PER_PAGE do
        local slot = _G["MerchantItem" .. i]
        if slot then
            slot:Show()
            if (i % perColumn) == 1 then
                if i == 1 then
                    slot:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", 24, -70)
                else
                    slot:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - (perColumn - 1))], "TOPRIGHT", 12, 0)
                end
            elseif (i % 2) == 1 then
                slot:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - 2)], "BOTTOMLEFT", 0, vertSpacing)
            else
                slot:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - 1)], "TOPRIGHT", horizSpacing, 0)
            end
        end
    end

    local numItems = securecall("GetMerchantNumItems")
    if numItems and numItems <= MERCHANT_ITEMS_PER_PAGE then
        if MerchantPageText       then MerchantPageText:Show() end
        if MerchantPrevPageButton then MerchantPrevPageButton:Show(); MerchantPrevPageButton:Disable() end
        if MerchantNextPageButton then MerchantNextPageButton:Show(); MerchantNextPageButton:Disable() end
    end
end

local function UpdateBuyBackSlotPositions()
    if not M.enabled or not MerchantFrame then return end
    local vertSpacing  = -30
    local horizSpacing = 50

    for i = 1, MERCHANT_ITEMS_PER_PAGE do
        local slot = _G["MerchantItem" .. i]
        if slot then
            if i > BUYBACK_ITEMS_PER_PAGE then
                slot:Hide()
            else
                if i == 1 then
                    slot:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", 64, -105)
                elseif (i % 3) == 1 then
                    slot:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - 3)], "BOTTOMLEFT", 0, vertSpacing)
                else
                    slot:SetPoint("TOPLEFT", _G["MerchantItem" .. (i - 1)], "TOPRIGHT", horizSpacing, 0)
                end
            end
        end
    end
end

local function RebuildPageButtonPositions()
    if MerchantPrevPageButton then MerchantPrevPageButton:SetPoint("CENTER", MerchantFrame, "BOTTOM",  36, 55) end
    if MerchantPageText       then MerchantPageText:SetPoint("BOTTOM",       MerchantFrame, "BOTTOM", 166, 50) end
    if MerchantNextPageButton then MerchantNextPageButton:SetPoint("CENTER", MerchantFrame, "BOTTOM", 296, 55) end
end

local function RebuildBuyBackItemPositions()
    local item = _G.MerchantBuyBackItem
    local ref  = _G.MerchantItem10
    if item and ref then item:SetPoint("TOPLEFT", ref, "BOTTOMLEFT", 17, -20) end
end

local function RebuildTokenPositions()
    if not MerchantFrame then return end
    local moneyBg            = _G.MerchantMoneyBg
    local moneyInset         = _G.MerchantMoneyInset
    local extraCurrencyInset = _G.MerchantExtraCurrencyInset
    local extraCurrencyBg    = _G.MerchantExtraCurrencyBg

    if moneyBg then
        moneyBg:SetPoint("TOPRIGHT",   MerchantFrame, "BOTTOMRIGHT", -8,    25)
        moneyBg:SetPoint("BOTTOMLEFT", MerchantFrame, "BOTTOMRIGHT", -169,   6)
    end
    if extraCurrencyInset and moneyInset then
        extraCurrencyInset:ClearAllPoints()
        extraCurrencyInset:SetPoint("TOPLEFT",     moneyInset, "TOPLEFT",    -171, 0)
        extraCurrencyInset:SetPoint("BOTTOMRIGHT", moneyInset, "BOTTOMLEFT",    0, 0)
    end
    if extraCurrencyBg and moneyBg then
        extraCurrencyBg:ClearAllPoints()
        extraCurrencyBg:SetPoint("TOPLEFT",     moneyBg, "TOPLEFT",    -171, 0)
        extraCurrencyBg:SetPoint("BOTTOMRIGHT", moneyBg, "BOTTOMLEFT",   -3, 0)
    end

    local currencies = { GetMerchantCurrencies() }
    MerchantFrame.numCurrencies = #currencies
    for i = 1, MerchantFrame.numCurrencies do
        local btn = _G["MerchantToken" .. i]
        if btn then
            btn:ClearAllPoints()
            if i == 1 then
                btn:SetPoint("BOTTOMRIGHT", -16, 8)
            elseif i == 4 then
                btn:SetPoint("RIGHT", _G["MerchantToken" .. (i - 1)], "LEFT", -15, 0)
            else
                btn:SetPoint("RIGHT", _G["MerchantToken" .. (i - 1)], "LEFT",   0, 0)
            end
        end
    end
end

local function RebuildSellAllJunkButtonPositions()
    if not M.enabled then return end
    if securecall("CanMerchantRepair") then return end
    local sellBtn   = _G.MerchantSellAllJunkButton
    local buyBackIt = _G.MerchantBuyBackItem
    if sellBtn and buyBackIt then sellBtn:SetPoint("RIGHT", buyBackIt, "LEFT", -18, 0) end
end

local function RebuildGuildBankRepairButtonPositions()
    if not M.enabled then return end
    local guildBtn  = _G.MerchantGuildBankRepairButton
    local repairBtn = _G.MerchantRepairAllButton
    if guildBtn and repairBtn then guildBtn:SetPoint("LEFT", repairBtn, "RIGHT", 10, 0) end
end

local function ApplyAll()
    RebuildMerchantFrame()
    RebuildPageButtonPositions()
    RebuildBuyBackItemPositions()
    RebuildTokenPositions()
    RebuildGuildBankRepairButtonPositions()
    if MerchantFrame and MerchantFrame:IsShown() then
        UpdateSlotPositions()
        UpdateBuyBackSlotPositions()
    end
end

-- ============================================================
-- API
-- ============================================================

function M:Enable()
    if self.enabled then return end

    CacheAll()

    self.enabled = true
    _G.MERCHANT_ITEMS_PER_PAGE = ITEMS_PER_PAGE_EXPANDED

    if not self.hooked then
        hooksecurefunc("MerchantFrame_UpdateRepairButtons", RebuildSellAllJunkButtonPositions)
        hooksecurefunc("MerchantFrame_UpdateMerchantInfo", UpdateSlotPositions)
        hooksecurefunc("MerchantFrame_UpdateBuybackInfo",  UpdateBuyBackSlotPositions)
        self.hooked = true
    end

    ApplyAll()
end

function M:Disable()
    if not self.enabled then return end
    self.enabled = false
    _G.MERCHANT_ITEMS_PER_PAGE = ORIGINAL_ITEMS_PER_PAGE

    -- Extra-Slots ausblenden
    for i = ORIGINAL_ITEMS_PER_PAGE + 1, ITEMS_PER_PAGE_EXPANDED do
        local slot = _G["MerchantItem" .. i]
        if slot then slot:Hide() end
    end

    -- Original-Positionen wiederherstellen
    RestoreAll()

    -- Blizzard positioniert Item-Slots 1-10 selbst neu
    if MerchantFrame and MerchantFrame:IsShown() then
        if MerchantFrame_UpdateMerchantInfo then MerchantFrame_UpdateMerchantInfo() end
    end
end

function M:IsEnabled()
    return self.enabled == true
end

-- ============================================================
-- Init
-- ============================================================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("MERCHANT_SHOW")
initFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if GetDB().enabled then M:Enable() end
    elseif event == "MERCHANT_SHOW" then
        if M.enabled then ApplyAll() end
    end
end)
