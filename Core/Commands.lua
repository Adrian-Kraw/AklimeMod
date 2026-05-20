-- Core/Commands.lua
-- Zentrale Registry aller /akm Slash-Commands.
-- Dashboard und /akm help nutzen diese Liste als einzige Quelle.

AklimeMod_Commands = {
    { cmd = "/akm",          desc = "Addon öffnen / schließen"                    },
    { cmd = "/akm help",     desc = "Alle Befehle im Chat anzeigen"               },
    { cmd = "/akm todo",     desc = "ToDo-Liste öffnen / schließen"               },
    { cmd = "/akm ignore",   desc = "Erweiterte Ignore-Liste öffnen / schließen"   },
    { cmd = "/akm played",  desc = "Gespielte Zeit aller Chars anzeigen"           },
    { cmd = "/akmana",       desc = "Mana-Warnung Status anzeigen"      },
    { cmd = "/akmana test",  desc = "Mana-Warnung Testnachricht senden"  },
}

-- /akm help — gibt alle Befehle im Chat aus
local function PrintHelp()
    print("|cFFFFD100AklimeMod Befehle:|r")
    for _, e in ipairs(AklimeMod_Commands) do
        print("|cFF00CCFF" .. e.cmd .. "|r - " .. e.desc)
    end
end

-- Hook auf den bestehenden /akm Slash-Handler
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, _, arg1)
    if arg1 ~= "AklimeMod" then return end

    local origSlash = SlashCmdList["AKLIMEMOD"]
    SlashCmdList["AKLIMEMOD"] = function(input)
        local cmd = strtrim(input or ""):lower()
        if cmd == "help" then
            PrintHelp()
        elseif cmd == "todo" then
            if AklimeMod_TodoList then AklimeMod_TodoList:Toggle() end
        elseif cmd == "ignore" then
            if AklimeMod_ExtendedIgnore then AklimeMod_ExtendedIgnore:ToggleWindow() end
        elseif cmd == "played" then
            if AklimeMod_PlayedTime then AklimeMod_PlayedTime:Print() end
        elseif origSlash then
            origSlash(input)
        end
    end
end)