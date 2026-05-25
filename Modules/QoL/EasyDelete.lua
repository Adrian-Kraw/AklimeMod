-- Modules/QoL/EasyDelete.lua
-- Kombiniert aus EasyDelete-Addon + EnhanceQoL:
--
-- Fall 1: DELETE_ITEM_CONFIRM (normale Items)
--   → EditBox verstecken, Bestätigen-Button direkt freischalten
--
-- Fall 2: DELETE_GOOD_ITEM / DELETE_GOOD_QUEST_ITEM (wertvolle Items)
--   → "BESTÄTIGEN" automatisch in EditBox eintragen (aus EnhanceQoL)
--   → So muss man den Text nicht mehr eintippen

local isSetup    = false
local linkDisplay = nil

-- Setup: FontString über dem EditBox des Löschen-Popups
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

-- Fall 1: normale Items — EditBox verstecken, Button freischalten
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

-- Bestätigungstext je nach Popup-Typ.
-- Gibt nil zurück wenn der Typ nicht bekannt ist.
local function GetConfirmText(which)
    if which == "DELETE_GOOD_ITEM"
    or which == "DELETE_GOOD_QUEST_ITEM"
    or which == "DESTROY_ITEM"
    or which == "CONFIRM_DESTROY_ITEM"
    then
        return DELETE_ITEM_CONFIRM_STRING
    end
    if which == "UNLEARN_SKILL" then
        -- CONFIRM_UNLEARN_PROFESSION existiert in manchen WoW-Versionen als Global
        return CONFIRM_UNLEARN_PROFESSION or DELETE_ITEM_CONFIRM_STRING
    end
    return nil
end

-- Fall 2: Bestätigungstext automatisch eintragen
local function HookConfirmDialogs()
    for i = 1, 4 do
        local popup = _G["StaticPopup" .. i]
        if popup then
            hooksecurefunc(popup, "Show", function(self)
                local db = AklimeModDB and AklimeModDB.easyDelete
                if not db or db.skipConfirm ~= true then return end
                if not self then return end
                local text = GetConfirmText(self.which)
                if not text then return end
                local editBox = self.editBox or (self.GetEditBox and self:GetEditBox())
                if editBox then
                    editBox:SetText(text)
                    editBox:ClearFocus()
                    editBox:SetAutoFocus(false)
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