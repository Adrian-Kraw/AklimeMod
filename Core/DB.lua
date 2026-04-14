-- Core/DB.lua
-- Hinweis: Colorizer-DB wird von ColorizerCore.lua:InitDB() befuellt.
-- Hier nur die restlichen Addon-Einstellungen.

AklimeModDB = AklimeModDB or {}

local function def(t, k, v)
    if t[k] == nil then t[k] = v end
end

function AklimeMod_InitDB()
    local db = AklimeModDB
    def(db, "minimapAngle", 220)

    db.autoRepair = db.autoRepair or {}
    def(db.autoRepair, "enabled",  false)
    def(db.autoRepair, "useGuild", true)
    def(db.autoRepair, "useGold",  true)

    db.eliteFrame = db.eliteFrame or {}
    def(db.eliteFrame, "enabled", false)

    db.rareFrame = db.rareFrame or {}
    def(db.rareFrame, "enabled", false)

    db.raidFrameCenter = db.raidFrameCenter or {}
    def(db.raidFrameCenter, "enabled", true)
    def(db.raidFrameCenter, "offsetX",  0)

    db.chatInteraction = db.chatInteraction or {}
    def(db.chatInteraction, "copyPaste",  false)
    def(db.chatInteraction, "clickLinks", false)
    def(db.chatInteraction, "btnLocked",  false)

    db.dungeonEye = db.dungeonEye or {}
    def(db.dungeonEye, "enabled", false)
    def(db.dungeonEye, "locked",  false)

    db.reloadUI = db.reloadUI or {}
    def(db.reloadUI, "enabled", false)

    db.easyDelete = db.easyDelete or {}
    def(db.easyDelete, "skipDelete",  false)
    def(db.easyDelete, "skipConfirm", false)

    -- Colorizer: wird von AklimeMod_Colorizer:InitDB() befuellt (ColorizerCore.lua)
    db.colorizer = db.colorizer or {}
end