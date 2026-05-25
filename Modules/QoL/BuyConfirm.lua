-- Modules/QoL/BuyConfirm.lua
-- Kaufbestätigungsdialoge automatisch annehmen.

local M = {}
AklimeMod_BuyConfirm = M

local function GetDB()
    if AklimeModDB and AklimeModDB.buyConfirm then return AklimeModDB.buyConfirm end
    return {}
end

local AUTO_CONFIRM = {
    CONFIRM_PURCHASE_TOKEN_ITEM         = true,
    CONFIRM_PURCHASE_NONREFUNDABLE_ITEM = true,
}

local function TryAccept(popup, idx, which)
    if not popup:IsShown() or popup.which ~= which then return end

    -- Dialog-OnAccept direkt aufrufen (Blizzard-intern identisch mit Button1-Klick).
    local dialog = StaticPopupDialogs and StaticPopupDialogs[which]
    if dialog and dialog.OnAccept then
        dialog.OnAccept(popup, popup.data, popup.data2)
        StaticPopup_Hide(which)
        return
    end

    -- Fallback: Button1 klicken.
    local btn = popup.button1 or _G["StaticPopup" .. idx .. "Button1"]
    if btn and btn:IsEnabled() then
        btn:Click()
    end
end

local hooked = false
local function Setup()
    if hooked then return end
    hooked = true

    for i = 1, 4 do
        local popup = _G["StaticPopup" .. i]
        if popup then
            local idx = i
            -- HookScript("OnShow") statt hooksecurefunc(popup, "Show", ...).
            -- Feuert auf Widget-Ebene unabhaengig davon wie das Frame sichtbar wird.
            popup:HookScript("OnShow", function(self)
                if not self.which or not AUTO_CONFIRM[self.which] then return end
                if not GetDB().enabled then return end
                local which = self.which

                local elapsed = 0
                local ticker
                ticker = C_Timer.NewTicker(0.1, function()
                    elapsed = elapsed + 0.1
                    if elapsed > 10 then ticker:Cancel(); return end
                    if not popup:IsShown() or popup.which ~= which then ticker:Cancel(); return end

                    local btn = popup.button1 or _G["StaticPopup" .. idx .. "Button1"]
                    if btn and btn:IsEnabled() then
                        ticker:Cancel()
                        TryAccept(popup, idx, which)
                    end
                end)
            end)
        end
    end
end

-- Debug: /akmbuydebug
SLASH_AKMBUYDEBUG1 = "/akmbuydebug"
SlashCmdList["AKMBUYDEBUG"] = function()
    local found = false
    for i = 1, 4 do
        local popup = _G["StaticPopup" .. i]
        if popup and popup:IsShown() then
            found = true
            local btn2 = _G["StaticPopup" .. i .. "Button1"]
            print(string.format("|cFFFFD100AklimeMod:|r StaticPopup%d which=%s data=%s data2=%s",
                i, tostring(popup.which), tostring(popup.data), tostring(popup.data2)))
            if btn2 then
                print(string.format("  button1: enabled=%s shown=%s",
                    tostring(btn2:IsEnabled()), tostring(btn2:IsShown())))
            end
            local dialog = StaticPopupDialogs and StaticPopupDialogs[popup.which]
            print(string.format("  OnAccept=%s", dialog and tostring(dialog.OnAccept) or "kein Dialog"))
        end
    end
    if not found then
        print("|cFFFFD100AklimeMod:|r Kein StaticPopup offen.")
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    Setup()
end)

function M.IsEnabled() return GetDB().enabled == true end
function M.SetEnabled(v) GetDB().enabled = v and true or false end
