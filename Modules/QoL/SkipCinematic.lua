-- Modules/QoL/SkipCinematic.lua
-- Cutscenes und Cinematics automatisch überspringen.

local function GetDB()
    if AklimeModDB and AklimeModDB.skipCinematic then return AklimeModDB.skipCinematic end
    return { enabled = false }
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CINEMATIC_START")
eventFrame:RegisterEvent("PLAY_MOVIE")
eventFrame:SetScript("OnEvent", function(_, event)
    if not GetDB().enabled then return end
    if event == "CINEMATIC_START" then
        CancelCinematic()
    elseif event == "PLAY_MOVIE" then
        if MovieFrame and MovieFrame.StopMovie then
            MovieFrame:StopMovie()
        end
    end
end)

AklimeMod_SkipCinematic = {
    IsEnabled  = function() return GetDB().enabled == true end,
    SetEnabled = function(v) GetDB().enabled = v and true or false end,
}
