-- Core/DB.lua

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
    -- style = nil bedeutet: nichts ausgewählt, kein Frame anzeigen

    db.rareFrame = db.rareFrame or {}
    def(db.rareFrame, "enabled", false)

    db.reloadUI = db.reloadUI or {}
    def(db.reloadUI, "enabled", false)

    db.easyDelete = db.easyDelete or {}
    def(db.easyDelete, "skipDelete",  false)
    def(db.easyDelete, "skipConfirm", false)
    -- Colorizer
    db.colorizer = db.colorizer or {}
    local colorDefs = {
        playerFrame = { r=0.28, g=0.28, b=0.28, a=1 },
        targetFrame = { r=0.28, g=0.28, b=0.28, a=1 },
        targetFrameToT = { r=0.28, g=0.28, b=0.28, a=1 },
        focusFrame = { r=0.28, g=0.28, b=0.28, a=1 },
        petFrame = { r=0.28, g=0.28, b=0.28, a=1 },
        partyFrame = { r=0.28, g=0.28, b=0.28, a=1 },
        bossFrames = { r=0.28, g=0.28, b=0.28, a=1 },
        minimap = { r=0.28, g=0.28, b=0.28, a=1 },
        objectiveTracker = { r=0.28, g=0.28, b=0.28, a=1 },
        chatFrame = { r=0.2, g=0.2, b=0.2, a=1 },
        mirrorTimer = { r=0.28, g=0.28, b=0.28, a=1 },
        statusBar = { r=0.28, g=0.28, b=0.28, a=1 },
        spellFlyout = { r=0.28, g=0.28, b=0.28, a=1 },
        microCharacter = { r=0.28, g=0.28, b=0.28, a=1 },
        microSpellbook = { r=0.28, g=0.28, b=0.28, a=1 },
        microTalents = { r=0.28, g=0.28, b=0.28, a=1 },
        microAchieve = { r=0.28, g=0.28, b=0.28, a=1 },
        microQuest = { r=0.28, g=0.28, b=0.28, a=1 },
        microGuild = { r=0.28, g=0.28, b=0.28, a=1 },
        microLFD = { r=0.28, g=0.28, b=0.28, a=1 },
        microCollect = { r=0.28, g=0.28, b=0.28, a=1 },
        microEJ = { r=0.28, g=0.28, b=0.28, a=1 },
        microStore = { r=0.28, g=0.28, b=0.28, a=1 },
        microMenu = { r=0.28, g=0.28, b=0.28, a=1 },
        microHousing = { r=0.28, g=0.28, b=0.28, a=1 },
        microProfession = { r=0.28, g=0.28, b=0.28, a=1 },
        actionBar1 = { r=0.22, g=0.22, b=0.22, a=1 },
        actionBar2 = { r=0.22, g=0.22, b=0.22, a=1 },
        actionBar3 = { r=0.22, g=0.22, b=0.22, a=1 },
        actionBar4 = { r=0.22, g=0.22, b=0.22, a=1 },
        actionBar5 = { r=0.22, g=0.22, b=0.22, a=1 },
        petBar = { r=0.22, g=0.22, b=0.22, a=1 },
        stanceBar = { r=0.22, g=0.22, b=0.22, a=1 },
        winCharacter = { r=0.28, g=0.28, b=0.28, a=1 },
        winSpellbook = { r=0.28, g=0.28, b=0.28, a=1 },
        winBags = { r=0.28, g=0.28, b=0.28, a=1 },
        winBank = { r=0.28, g=0.28, b=0.28, a=1 },
        winFriends = { r=0.28, g=0.28, b=0.28, a=1 },
        winQuest = { r=0.28, g=0.28, b=0.28, a=1 },
        winLoot = { r=0.28, g=0.28, b=0.28, a=1 },
        winMail = { r=0.28, g=0.28, b=0.28, a=1 },
        winMerchant = { r=0.28, g=0.28, b=0.28, a=1 },
        winAH = { r=0.28, g=0.28, b=0.28, a=1 },
        winMap = { r=0.28, g=0.28, b=0.28, a=1 },
        winAchieve = { r=0.28, g=0.28, b=0.28, a=1 },
        winCollections = { r=0.28, g=0.28, b=0.28, a=1 },
        winEJ = { r=0.28, g=0.28, b=0.28, a=1 },
        winGuild = { r=0.28, g=0.28, b=0.28, a=1 },
        winInspect = { r=0.28, g=0.28, b=0.28, a=1 },
        winDressup = { r=0.28, g=0.28, b=0.28, a=1 },
        winTransmog = { r=0.28, g=0.28, b=0.28, a=1 },
        winPVE = { r=0.28, g=0.28, b=0.28, a=1 },
        winSettings = { r=0.28, g=0.28, b=0.28, a=1 },
        winGameMenu = { r=0.28, g=0.28, b=0.28, a=1 },
        winCalendar = { r=0.28, g=0.28, b=0.28, a=1 },
        winChannel = { r=0.28, g=0.28, b=0.28, a=1 },
        winMacro = { r=0.28, g=0.28, b=0.28, a=1 },
        winHousing = { r=0.28, g=0.28, b=0.28, a=1 },
    }
    for key, defaults in pairs(colorDefs) do
        db.colorizer[key] = db.colorizer[key] or {}
        def(db.colorizer[key], "enabled", false)
        def(db.colorizer[key], "r", defaults.r)
        def(db.colorizer[key], "g", defaults.g)
        def(db.colorizer[key], "b", defaults.b)
        def(db.colorizer[key], "a", defaults.a)
    end
end