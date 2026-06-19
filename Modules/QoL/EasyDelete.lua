-- Modules/QoL/EasyDelete.lua
-- Streamlines the item delete-confirmation popups:
--
-- Case 1: DELETE_ITEM_CONFIRM (normal items)
--   Hide the edit box and enable the confirm button directly
--
-- Case 2: DELETE_GOOD_ITEM / DELETE_GOOD_QUEST_ITEM (valuable items)
--   Fill the required confirm text into the edit box automatically
--   so it no longer has to be typed by hand

local isSetup    = false
local linkDisplay = nil

-- Setup: FontString above the edit box of the delete popup
local function Setup()
    if isSetup then return end
    isSetup = true

    local popup = _G["StaticPopup1"]
    if not popup then return end

    linkDisplay = popup:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    linkDisplay:SetPoint("CENTER", _G["StaticPopup1EditBox"])
    linkDisplay:Hide()

    popup:HookScript("OnHide", function()
        if linkDisplay then linkDisplay:Hide() end
    end)
end

-- Case 1: normal items. Hide the edit box, enable the button
local function HandleDeleteConfirm()
    local db = AklimeModDB and AklimeModDB.easyDelete
    if not db or db.skipDelete ~= true then return end
    local editBox = _G["StaticPopup1EditBox"]
    local btn1    = _G["StaticPopup1Button1"]
    if editBox and editBox:IsShown() then
        editBox:Hide()
        if btn1 then btn1:Enable() end
        local _, _, link = GetCursorInfo()
        if linkDisplay and link then
            linkDisplay:SetText(link)
            linkDisplay:Show()
        end
    end
end

-- Confirmation text for valuable item deletions.
local function GetConfirmText(which)
    if which == "DELETE_GOOD_ITEM"
    or which == "DELETE_GOOD_QUEST_ITEM"
    or which == "DESTROY_ITEM"
    or which == "CONFIRM_DESTROY_ITEM"
    then
        return DELETE_ITEM_CONFIRM_STRING
    end
    return nil
end

-- Helper: set text in the edit box and remove focus
local function FillEditBox(self, text)
    local editBox = self.editBox or (self.GetEditBox and self:GetEditBox())
    if editBox then
        editBox:SetText(text)
        editBox:ClearFocus()
        editBox:SetAutoFocus(false)
    end
end

-- Helper: hide the edit box and enable the OK button
local function BypassEditBox(self)
    C_Timer.After(0, function()
        local editBox = self.editBox or (self.GetEditBox and self:GetEditBox())
        local btn1    = self.button1
        if editBox and editBox:IsShown() then
            editBox:Hide()
            if btn1 then btn1:Enable() end
        end
    end)
end

-- Cases 2-4: intercept popups and automate text entry
local function HookConfirmDialogs()
    for i = 1, 4 do
        local popup = _G["StaticPopup" .. i]
        if popup then
            hooksecurefunc(popup, "Show", function(self)
                local db = AklimeModDB and AklimeModDB.easyDelete
                if not db or not self then return end
                local which = self.which

                -- Confirm: delete valuable items
                if db.skipConfirm then
                    local text = GetConfirmText(which)
                    if text then FillEditBox(self, text); return end
                end

                -- Unlearn: forget a profession or skill
                if db.skipUnlearn and which == "UNLEARN_SKILL" then
                    local text = CONFIRM_UNLEARN_PROFESSION or DELETE_ITEM_CONFIRM_STRING
                    FillEditBox(self, text)
                    return
                end

                -- Understood: all other popups with text entry
                if db.skipUnderstood then
                    local info = StaticPopupDialogs and StaticPopupDialogs[which]
                    if info and info.hasEditBox
                    and not GetConfirmText(which) and which ~= "UNLEARN_SKILL" then
                        BypassEditBox(self)
                    end
                end
            end)
        end
    end
end

local easyDeleteFrame = CreateFrame("Frame")
easyDeleteFrame:RegisterEvent("ADDON_LOADED")
easyDeleteFrame:RegisterEvent("DELETE_ITEM_CONFIRM")
easyDeleteFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "AklimeModTools" then
        Setup()
        HookConfirmDialogs()
    elseif event == "DELETE_ITEM_CONFIRM" then
        HandleDeleteConfirm()
    end
end)