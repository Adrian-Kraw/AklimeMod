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

    db.savedInstances = db.savedInstances or {}
    db.savedInstances.chars      = db.savedInstances.chars      or {}
    db.savedInstances.raids      = db.savedInstances.raids      or {}
    db.savedInstances.currencies = db.savedInstances.currencies or {}
    db.savedInstances.raidExps   = db.savedInstances.raidExps   or {}

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

    db.minimapHider = db.minimapHider or {}
    def(db.minimapHider, "enabled", false)
    def(db.minimapHider, "tracking", false)
    def(db.minimapHider, "zoneInfo", false)
    def(db.minimapHider, "clock", false)
    def(db.minimapHider, "calendar", false)
    def(db.minimapHider, "mail", false)
    def(db.minimapHider, "addonCompartment", false)

    db.mouseEffects = db.mouseEffects or {}
    def(db.mouseEffects, "enabled", false)
    def(db.mouseEffects, "trail", false)
    def(db.mouseEffects, "classColor", true)
    db.mouseEffects.customColor = db.mouseEffects.customColor or { r = 1, g = 0.82, b = 0, a = 0.9 }
    def(db.mouseEffects, "trailClassColor", true)
    db.mouseEffects.customTrailColor = db.mouseEffects.customTrailColor or { r = 1, g = 0.82, b = 0, a = 0.85 }
    def(db.mouseEffects, "hideDot",  false)
    def(db.mouseEffects, "hideRing", false)
    def(db.mouseEffects, "onlyCombat", false)
    def(db.mouseEffects, "onlyRightClick", false)
    def(db.mouseEffects, "trailOnlyCombat", false)
    def(db.mouseEffects, "size", 76)
    def(db.mouseEffects, "trailPreset", "medium")

    db.merchant = db.merchant or {}
    def(db.merchant, "enabled", false)

    db.chatLearnFilter = db.chatLearnFilter or {}
    def(db.chatLearnFilter, "enabled", false)

    db.chatIcons = db.chatIcons or {}
    def(db.chatIcons, "enabled",    false)
    def(db.chatIcons, "itemLevel",  false)
    def(db.chatIcons, "showSlot",   false)

    db.chatFade = db.chatFade or {}
    def(db.chatFade, "enabled",      false)
    def(db.chatFade, "timeVisible",  30)
    def(db.chatFade, "fadeDuration", 3)

    db.friendsListDecor = db.friendsListDecor or {}
    def(db.friendsListDecor, "enabled",      false)
    def(db.friendsListDecor, "showLocation", true)
    def(db.friendsListDecor, "hideOwnRealm", true)

    db.pvpChatBlock = db.pvpChatBlock or {}
    def(db.pvpChatBlock, "enabled", false)

    db.pvpNameplateColor = db.pvpNameplateColor or {}
    def(db.pvpNameplateColor, "enabled", false)

    db.savedInstances = db.savedInstances or {}
    db.savedInstances.chars = db.savedInstances.chars or {}

    db.questTracker = db.questTracker or {}
    def(db.questTracker, "showQuestCount",      false)
    def(db.questTracker, "questCountOffsetX",   0)
    def(db.questTracker, "questCountOffsetY",   0)
    def(db.questTracker, "minimizeButtonOnly",  false)
    def(db.questTracker, "minimizeButtonAnchor","TOPRIGHT")
    def(db.questTracker, "rememberState",       false)
    -- questTracker.collapsed: kein Default, wird beim ersten Zustandswechsel gesetzt

    db.blockRequests = db.blockRequests or {}
    def(db.blockRequests, "blockDuels",      false)
    def(db.blockRequests, "blockPetBattles", false)

    db.questAutomation = db.questAutomation or {}
    def(db.questAutomation, "enabled",        false)
    def(db.questAutomation, "modifier",       "NONE")
    def(db.questAutomation, "ignoreDailies",  false)
    def(db.questAutomation, "ignoreTrivial",  false)
    def(db.questAutomation, "ignoreWarband",  false)
    def(db.questAutomation, "wowheadLink",    false)
    db.questAutomation.ignoredNPCs = db.questAutomation.ignoredNPCs or {}

    db.heroismTracker = db.heroismTracker or {}
    def(db.heroismTracker, "enabled",  false)
    def(db.heroismTracker, "locked",   false)
    def(db.heroismTracker, "fontSizeSlider", 20)

    db.deathSound = db.deathSound or {}
    def(db.deathSound, "enabled", false)

    db.talentReminder = db.talentReminder or {}
    def(db.talentReminder, "enabled", false)

    db.summons = db.summons or {}
    def(db.summons, "enabled", false)

    db.chatHistory = db.chatHistory or {}
    def(db.chatHistory, "enabled",     false)
    def(db.chatHistory, "maxMessages", 100)
    db.chatHistory.messages = db.chatHistory.messages or {}

    db.groupInvites = db.groupInvites or {}
    def(db.groupInvites, "block",             false)
    def(db.groupInvites, "blockExceptGuild",  false)
    def(db.groupInvites, "blockExceptFriend", false)
    def(db.groupInvites, "autoAccept",        false)
    def(db.groupInvites, "guildOnly",         false)
    def(db.groupInvites, "friendOnly",        false)

    db.mailbox = db.mailbox or {}
    def(db.mailbox, "enabled",                false)
    def(db.mailbox, "rememberLastRecipient",  false)
    db.mailbox.contacts = db.mailbox.contacts or {}

    db.todoList = db.todoList or {}
    db.todoList.items = db.todoList.items or {}

    -- Colorizer: wird von AklimeMod_Colorizer:InitDB() befuellt (ColorizerCore.lua)
    db.colorizer = db.colorizer or {}
end
