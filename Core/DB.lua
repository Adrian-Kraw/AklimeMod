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

    db.manaWarning = db.manaWarning or {}
    def(db.manaWarning, "enabled", false)

    db.autoSellJunk = db.autoSellJunk or {}
    def(db.autoSellJunk, "enabled", false)

    db.leaveServiceChannel = db.leaveServiceChannel or {}
    def(db.leaveServiceChannel, "enabled", true)

    db.mapCoords = db.mapCoords or {}
    def(db.mapCoords, "enabled", false)  -- Default: an

    db.drinkReminder = db.drinkReminder or {}
    def(db.drinkReminder, "enabled",           false)
    def(db.drinkReminder, "intervalMinutes",   60)
    def(db.drinkReminder, "disableInInstance", true)

    db.clock24h = db.clock24h or {}
    def(db.clock24h, "enabled", false)

    db.preyPercent = db.preyPercent or {}
    def(db.preyPercent, "enabled", false)
    def(db.preyPercent, "x", 0)
    def(db.preyPercent, "y", 120)

    db.pvpChatBlock = db.pvpChatBlock or {}
    def(db.pvpChatBlock, "enabled", false)

    db.hideMacroNames = db.hideMacroNames or {}
    def(db.hideMacroNames, "enabled", false)

    db.damageMeterCollapseDown = db.damageMeterCollapseDown or {}
    def(db.damageMeterCollapseDown, "enabled", false)
    db.damageMeterCollapseDown.windows = db.damageMeterCollapseDown.windows or {}

    db.minimapCollector = db.minimapCollector or {}
    def(db.minimapCollector, "enabled",     false)
    def(db.minimapCollector, "includeOwn",  false)
    def(db.minimapCollector, "angle",       143)
    def(db.minimapCollector, "locked",      false)

    -- Colorizer: wird von AklimeMod_Colorizer:InitDB() befuellt (ColorizerCore.lua)
    db.colorizer = db.colorizer or {}
end