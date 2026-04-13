-- Modules/Interface/Colorizer.lua
-- Alle Färb-Skins aus FrameColor, portiert
-- Reset: SetDesaturation(0) + SetVertexColor(1,1,1,1) = Blizzard-Default

local Colorizer = {}
AklimeMod_Colorizer = Colorizer

-- ============================================================
-- Hilfsfunktionen
-- ============================================================
-- Einfärben: desaturation=1, custom color
local function Tint(tex, r, g, b, a)
    if not tex then return end
    tex:SetDesaturation(1)
    tex:SetVertexColor(r, g, b, a or 1)
end
local function TintAll(list, r, g, b, a)
    for _, tex in pairs(list) do Tint(tex, r, g, b, a) end
end

-- Reset: desaturation=0, weiß = Blizzard-Original
local function Reset(tex)
    if not tex then return end
    tex:SetDesaturation(0)
    tex:SetVertexColor(1, 1, 1, 1)
end
local function ResetAll(list)
    for _, tex in pairs(list) do Reset(tex) end
end

Colorizer.skins = {}
Colorizer.groupOrder = {}

local function S(key, label, group, applyFn, removeFn)
    Colorizer.skins[key] = { label=label, group=group, Apply=applyFn, Remove=removeFn }
end

local function c(key)
    local d = AklimeModDB.colorizer[key]
    return d.r, d.g, d.b, d.a
end

-- ============================================================
-- UNIT FRAMES
-- ============================================================
S("playerFrame", "Spieler-Frame", "Unit Frames",
    function()
        local r,g,b,a = c("playerFrame")
        TintAll({
            PlayerFrame.PlayerFrameContainer.FrameTexture,
            PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture,
            PlayerFrame.PlayerFrameContainer.VehicleFrameTexture,
            _G["PlayerFrameGroupIndicatorLeft"],
            _G["PlayerFrameGroupIndicatorMiddle"],
            _G["PlayerFrameGroupIndicatorRight"],
        }, r,g,b,a)
        local ci = PlayerFrame.PlayerFrameContent
            and PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual
            and PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerPortraitCornerIcon
        Tint(ci, r,g,b,a)
        Tint(PlayerCastingBarFrame and PlayerCastingBarFrame.Border, r,g,b,a)
        Tint(PlayerCastingBarFrame and PlayerCastingBarFrame.Background, r,g,b,a)
    end,
    function()
        ResetAll({
            PlayerFrame.PlayerFrameContainer.FrameTexture,
            PlayerFrame.PlayerFrameContainer.AlternatePowerFrameTexture,
            PlayerFrame.PlayerFrameContainer.VehicleFrameTexture,
            _G["PlayerFrameGroupIndicatorLeft"],
            _G["PlayerFrameGroupIndicatorMiddle"],
            _G["PlayerFrameGroupIndicatorRight"],
        })
        local ci = PlayerFrame.PlayerFrameContent
            and PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual
            and PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerPortraitCornerIcon
        Reset(ci)
        Reset(PlayerCastingBarFrame and PlayerCastingBarFrame.Border)
        Reset(PlayerCastingBarFrame and PlayerCastingBarFrame.Background)
    end
)

S("targetFrame", "Ziel-Frame", "Unit Frames",
    function()
        local r,g,b,a = c("targetFrame")
        Tint(TargetFrame.TargetFrameContainer.FrameTexture, r,g,b,a)
        Tint(TargetFrameSpellBar and TargetFrameSpellBar.Border, r,g,b,a)
        Tint(TargetFrameSpellBar and TargetFrameSpellBar.Background, r,g,b,a)
    end,
    function()
        Reset(TargetFrame.TargetFrameContainer.FrameTexture)
        Reset(TargetFrameSpellBar and TargetFrameSpellBar.Border)
        Reset(TargetFrameSpellBar and TargetFrameSpellBar.Background)
    end
)

S("targetOfTarget", "Ziel des Ziels", "Unit Frames",
    function()
        local r,g,b,a = c("targetOfTarget")
        Tint(TargetFrameToT and TargetFrameToT.FrameTexture, r,g,b,a)
    end,
    function() Reset(TargetFrameToT and TargetFrameToT.FrameTexture) end
)

S("focusFrame", "Fokus-Frame", "Unit Frames",
    function()
        local r,g,b,a = c("focusFrame")
        Tint(FocusFrame and FocusFrame.TargetFrameContainer and FocusFrame.TargetFrameContainer.FrameTexture, r,g,b,a)
        Tint(FocusFrameSpellBar and FocusFrameSpellBar.Border, r,g,b,a)
        Tint(FocusFrameSpellBar and FocusFrameSpellBar.Background, r,g,b,a)
    end,
    function()
        Reset(FocusFrame and FocusFrame.TargetFrameContainer and FocusFrame.TargetFrameContainer.FrameTexture)
        Reset(FocusFrameSpellBar and FocusFrameSpellBar.Border)
        Reset(FocusFrameSpellBar and FocusFrameSpellBar.Background)
    end
)

S("petFrame", "Begleiter-Frame", "Unit Frames",
    function()
        local r,g,b,a = c("petFrame")
        Tint(PetFrame and PetFrame.TargetFrameContainer and PetFrame.TargetFrameContainer.FrameTexture, r,g,b,a)
    end,
    function() Reset(PetFrame and PetFrame.TargetFrameContainer and PetFrame.TargetFrameContainer.FrameTexture) end
)

S("partyFrames", "Gruppen-Frames", "Unit Frames",
    function()
        local r,g,b,a = c("partyFrames")
        for i=1,4 do
            local f = _G["CompactPartyFrameMember"..i]
            if f and f.TargetFrameContainer then Tint(f.TargetFrameContainer.FrameTexture, r,g,b,a) end
        end
    end,
    function()
        for i=1,4 do
            local f = _G["CompactPartyFrameMember"..i]
            if f and f.TargetFrameContainer then Reset(f.TargetFrameContainer.FrameTexture) end
        end
    end
)

S("bossFrames", "Boss-Frames", "Unit Frames",
    function()
        local r,g,b,a = c("bossFrames")
        for i=1,5 do
            local f = _G["Boss"..i.."TargetFrame"]
            if f then Tint(f.TargetFrameContainer.FrameTexture, r,g,b,a) end
        end
    end,
    function()
        for i=1,5 do
            local f = _G["Boss"..i.."TargetFrame"]
            if f then Reset(f.TargetFrameContainer.FrameTexture) end
        end
    end
)

-- ============================================================
-- HUD
-- ============================================================
S("minimap", "Minimap", "HUD",
    function()
        local r,g,b,a = c("minimap")
        Tint(_G["MinimapCompassTexture"], r,g,b,a)
    end,
    function() Reset(_G["MinimapCompassTexture"]) end
)

S("chatFrame", "Chat-Fenster", "HUD",
    function()
        local r,g,b,a = c("chatFrame")
        for i=1,NUM_CHAT_WINDOWS do
            local n = "ChatFrame"..i
            TintAll({ _G[n.."EditBoxLeft"], _G[n.."EditBoxMid"], _G[n.."EditBoxRight"] }, r,g,b,a)
            -- Background: Blizzard nutzt Alpha-Kontrolle via FCF_SetWindowAlpha, nur RGB ändern
            local bg = _G[n.."Background"]
            if bg then
                bg:SetDesaturation(1)
                bg:SetVertexColor(r, g, b, bg:GetAlpha())
            end
        end
    end,
    function()
        -- Chat: Reset auf {1,1,1,1} desaturation=0 = Blizzard-Default
        -- FCF_SetWindowColor stellt danach den Originalzustand wieder her
        for i=1,NUM_CHAT_WINDOWS do
            local n = "ChatFrame"..i
            ResetAll({ _G[n.."EditBoxLeft"], _G[n.."EditBoxMid"], _G[n.."EditBoxRight"] })
            local bg = _G[n.."Background"]
            if bg then
                bg:SetDesaturation(0)
                bg:SetVertexColor(1, 1, 1, bg:GetAlpha())
            end
        end
    end
)

S("objectiveTracker", "Aufgaben-Tracker", "HUD",
    function()
        local r,g,b,a = c("objectiveTracker")
        for _, f in pairs({ ObjectiveTrackerFrame, QuestObjectiveTracker, WorldQuestObjectiveTracker,
            BonusObjectiveTracker, ScenarioObjectiveTracker, AchievementObjectiveTracker,
            CampaignQuestObjectiveTracker, AdventureObjectiveTracker,
            MonthlyActivitiesObjectiveTracker, ProfessionsRecipeTracker }) do
            if f and f.Header and f.Header.Background then Tint(f.Header.Background, r,g,b,a) end
        end
    end,
    function()
        for _, f in pairs({ ObjectiveTrackerFrame, QuestObjectiveTracker, WorldQuestObjectiveTracker,
            BonusObjectiveTracker, ScenarioObjectiveTracker, AchievementObjectiveTracker,
            CampaignQuestObjectiveTracker, AdventureObjectiveTracker,
            MonthlyActivitiesObjectiveTracker, ProfessionsRecipeTracker }) do
            if f and f.Header and f.Header.Background then Reset(f.Header.Background) end
        end
    end
)

S("buffs", "Buff-Rahmen", "HUD",
    function()
        local r,g,b,a = c("buffs")
        if BuffFrame and BuffFrame.AuraContainer then
            for _, w in pairs({ BuffFrame.AuraContainer:GetChildren() }) do
                if w.Icon then Tint(w.Icon, r,g,b,a) end
            end
        end
    end,
    function()
        if BuffFrame and BuffFrame.AuraContainer then
            for _, w in pairs({ BuffFrame.AuraContainer:GetChildren() }) do
                if w.Icon then Reset(w.Icon) end
            end
        end
    end
)

S("statusBars", "Statusleisten", "HUD",
    function()
        local r,g,b,a = c("statusBars")
        Tint(MainStatusTrackingBarContainer and MainStatusTrackingBarContainer.BarFrameTexture, r,g,b,a)
        Tint(SecondaryStatusTrackingBarContainer and SecondaryStatusTrackingBarContainer.BarFrameTexture, r,g,b,a)
    end,
    function()
        Reset(MainStatusTrackingBarContainer and MainStatusTrackingBarContainer.BarFrameTexture)
        Reset(SecondaryStatusTrackingBarContainer and SecondaryStatusTrackingBarContainer.BarFrameTexture)
    end
)

S("mirrorTimers", "Spiegel-Timer", "HUD",
    function()
        local r,g,b,a = c("mirrorTimers")
        if MirrorTimerContainer then
            for _, child in pairs({ MirrorTimerContainer:GetChildren() }) do Tint(child.Border, r,g,b,a) end
        end
    end,
    function()
        if MirrorTimerContainer then
            for _, child in pairs({ MirrorTimerContainer:GetChildren() }) do Reset(child.Border) end
        end
    end
)

S("tooltips", "Tooltips", "HUD",
    function()
        local r,g,b,a = c("tooltips")
        for _, tt in pairs({ GameTooltip, ShoppingTooltip1, ShoppingTooltip2, ItemRefTooltip }) do
            if tt and tt.NineSlice then Tint(tt.NineSlice, r,g,b,a) end
        end
    end,
    function()
        for _, tt in pairs({ GameTooltip, ShoppingTooltip1, ShoppingTooltip2, ItemRefTooltip }) do
            if tt and tt.NineSlice then Reset(tt.NineSlice) end
        end
    end
)

-- ============================================================
-- MICRO MENU
-- ============================================================
local microButtons = {
    "CharacterMicroButton","PlayerSpellsMicroButton","ProfessionMicroButton",
    "AchievementMicroButton","QuestLogMicroButton","GuildMicroButton",
    "LFDMicroButton","EJMicroButton","CollectionsMicroButton",
    "StoreMicroButton","MainMenuMicroButton","HousingMicroButton",
}
S("microMenu", "Micro-Menü", "Micro Menu",
    function()
        local r,g,b,a = c("microMenu")
        for _, name in ipairs(microButtons) do
            local btn = _G[name]
            if btn then
                Tint(btn:GetNormalTexture(), r,g,b,a)
                Tint(btn:GetHighlightTexture(), r,g,b,a)
                Tint(btn:GetPushedTexture(), r,g,b,a)
            end
        end
    end,
    function()
        for _, name in ipairs(microButtons) do
            local btn = _G[name]
            if btn then
                Reset(btn:GetNormalTexture())
                Reset(btn:GetHighlightTexture())
                Reset(btn:GetPushedTexture())
            end
        end
    end
)

-- ============================================================
-- AKTIONSLEISTEN
-- ============================================================
local barPrefixes = {
    { prefix="ActionButton",              count=12 },
    { prefix="MultiBarBottomLeftButton",  count=12 },
    { prefix="MultiBarBottomRightButton", count=12 },
    { prefix="MultiBarRightButton",       count=12 },
    { prefix="MultiBarLeftButton",        count=12 },
    { prefix="MultiBar5Button",           count=12 },
    { prefix="MultiBar6Button",           count=12 },
    { prefix="MultiBar7Button",           count=12 },
    { prefix="PetActionButton",           count=10 },
    { prefix="StanceButton",              count=10 },
}
S("actionBars", "Aktionsleisten", "Aktionsleisten",
    function()
        local r,g,b,a = c("actionBars")
        for _, bar in ipairs(barPrefixes) do
            for i=1,bar.count do Tint(_G[bar.prefix..i.."NormalTexture"], r,g,b,a) end
        end
        if MainActionBar then
            Tint(MainActionBar.EndCaps and MainActionBar.EndCaps.LeftEndCap, r,g,b,a)
            Tint(MainActionBar.EndCaps and MainActionBar.EndCaps.RightEndCap, r,g,b,a)
            Tint(MainActionBar.BorderArt, r,g,b,a)
        end
    end,
    function()
        for _, bar in ipairs(barPrefixes) do
            for i=1,bar.count do Reset(_G[bar.prefix..i.."NormalTexture"]) end
        end
        if MainActionBar then
            Reset(MainActionBar.EndCaps and MainActionBar.EndCaps.LeftEndCap)
            Reset(MainActionBar.EndCaps and MainActionBar.EndCaps.RightEndCap)
            Reset(MainActionBar.BorderArt)
        end
    end
)

-- ============================================================
-- FENSTER
-- ============================================================
S("characterFrame", "Charakter", "Fenster",
    function() local r,g,b,a=c("characterFrame"); Tint(CharacterFrame, r,g,b,a); Tint(CharacterFrameInset and CharacterFrameInset.Bg, r,g,b,a) end,
    function() Reset(CharacterFrame); Reset(CharacterFrameInset and CharacterFrameInset.Bg) end
)
S("bankFrame", "Bank", "Fenster",
    function() local r,g,b,a=c("bankFrame"); Tint(_G["BankFrameBg"], r,g,b,a); Tint(_G["ReagentBankFrameBg"], r,g,b,a) end,
    function() Reset(_G["BankFrameBg"]); Reset(_G["ReagentBankFrameBg"]) end
)
S("bagFrames", "Taschen", "Fenster",
    function()
        local r,g,b,a=c("bagFrames")
        for i=1,13 do
            local f=_G["ContainerFrame"..i]
            if f and f.Bg then
                if f.Bg.TopSection then f.Bg.TopSection:SetVertexColor(r,g,b,a) end
                if f.Bg.BottomEdge then f.Bg.BottomEdge:SetVertexColor(r,g,b,a) end
            end
        end
    end,
    function()
        for i=1,13 do
            local f=_G["ContainerFrame"..i]
            if f and f.Bg then
                if f.Bg.TopSection then f.Bg.TopSection:SetVertexColor(1,1,1,1) end
                if f.Bg.BottomEdge then f.Bg.BottomEdge:SetVertexColor(1,1,1,1) end
            end
        end
    end
)
S("friendsFrame", "Freunde", "Fenster",
    function() local r,g,b,a=c("friendsFrame"); Tint(_G["FriendListFrameBg"], r,g,b,a) end,
    function() Reset(_G["FriendListFrameBg"]) end
)
S("questFrame", "Quest-Fenster", "Fenster",
    function() local r,g,b,a=c("questFrame"); Tint(_G["QuestFrameBg"], r,g,b,a) end,
    function() Reset(_G["QuestFrameBg"]) end
)
S("mailFrame", "Post", "Fenster",
    function() local r,g,b,a=c("mailFrame"); Tint(_G["MailFrameBg"], r,g,b,a); Tint(_G["OpenMailFrameBg"], r,g,b,a) end,
    function() Reset(_G["MailFrameBg"]); Reset(_G["OpenMailFrameBg"]) end
)
S("merchantFrame", "Händler", "Fenster",
    function() local r,g,b,a=c("merchantFrame"); Tint(_G["MerchantFrameBg"], r,g,b,a) end,
    function() Reset(_G["MerchantFrameBg"]) end
)
S("lootFrame", "Beute", "Fenster",
    function() local r,g,b,a=c("lootFrame"); Tint(_G["LootFrameBg"], r,g,b,a) end,
    function() Reset(_G["LootFrameBg"]) end
)
S("tradeFrame", "Handel", "Fenster",
    function() local r,g,b,a=c("tradeFrame"); Tint(_G["TradeBg1"], r,g,b,a); Tint(_G["TradeBg2"], r,g,b,a) end,
    function() Reset(_G["TradeBg1"]); Reset(_G["TradeBg2"]) end
)
S("auctionFrame", "Auktionshaus", "Fenster",
    function() local r,g,b,a=c("auctionFrame"); Tint(_G["AuctionHouseFrameBg"], r,g,b,a) end,
    function() Reset(_G["AuctionHouseFrameBg"]) end
)
S("encounterJournal", "Schlachtzugsjournal", "Fenster",
    function() local r,g,b,a=c("encounterJournal"); if EncounterJournal then Tint(EncounterJournal.Bg, r,g,b,a) end end,
    function() if EncounterJournal then Reset(EncounterJournal.Bg) end end
)
S("collectionsJournal", "Sammlungen", "Fenster",
    function() local r,g,b,a=c("collectionsJournal"); Tint(_G["CollectionsJournalBg"], r,g,b,a) end,
    function() Reset(_G["CollectionsJournalBg"]) end
)
S("gameMenu", "Spielmenü", "Fenster",
    function() local r,g,b,a=c("gameMenu"); Tint(_G["GameMenuFrameBg"], r,g,b,a) end,
    function() Reset(_G["GameMenuFrameBg"]) end
)
S("worldMap", "Weltkarte", "Fenster",
    function() local r,g,b,a=c("worldMap"); if WorldMapFrame and WorldMapFrame.BorderFrame then Tint(WorldMapFrame.BorderFrame.Bg, r,g,b,a) end end,
    function() if WorldMapFrame and WorldMapFrame.BorderFrame then Reset(WorldMapFrame.BorderFrame.Bg) end end
)
S("professions", "Berufe", "Fenster",
    function() local r,g,b,a=c("professions"); Tint(_G["ProfessionsFrameBg"], r,g,b,a) end,
    function() Reset(_G["ProfessionsFrameBg"]) end
)

-- ============================================================
-- Gruppen-Reihenfolge
-- ============================================================
Colorizer.groupOrder = {
    { label="Unit Frames",    keys={"playerFrame","targetFrame","targetOfTarget","focusFrame","petFrame","partyFrames","bossFrames"} },
    { label="HUD",            keys={"minimap","chatFrame","objectiveTracker","buffs","statusBars","mirrorTimers","tooltips"} },
    { label="Micro Menu",     keys={"microMenu"} },
    { label="Aktionsleisten", keys={"actionBars"} },
    { label="Fenster",        keys={"characterFrame","bankFrame","bagFrames","friendsFrame","questFrame","mailFrame","merchantFrame","lootFrame","tradeFrame","auctionFrame","encounterJournal","collectionsJournal","gameMenu","worldMap","professions"} },
}

-- ============================================================
-- Default-Farben (für Reset-Button)
-- ============================================================
Colorizer.defaults = {
    playerFrame       = { r=0.28, g=0.28, b=0.28, a=1 },
    targetFrame       = { r=0.28, g=0.28, b=0.28, a=1 },
    targetOfTarget    = { r=0.28, g=0.28, b=0.28, a=1 },
    focusFrame        = { r=0.28, g=0.28, b=0.28, a=1 },
    petFrame          = { r=0.28, g=0.28, b=0.28, a=1 },
    partyFrames       = { r=0.28, g=0.28, b=0.28, a=1 },
    bossFrames        = { r=0.28, g=0.28, b=0.28, a=1 },
    minimap           = { r=0.28, g=0.28, b=0.28, a=1 },
    chatFrame         = { r=0.20, g=0.20, b=0.20, a=1 },
    objectiveTracker  = { r=0.28, g=0.28, b=0.28, a=1 },
    buffs             = { r=0.28, g=0.28, b=0.28, a=1 },
    statusBars        = { r=0.28, g=0.28, b=0.28, a=1 },
    mirrorTimers      = { r=0.28, g=0.28, b=0.28, a=1 },
    tooltips          = { r=0.28, g=0.28, b=0.28, a=1 },
    microMenu         = { r=0.28, g=0.28, b=0.28, a=1 },
    actionBars        = { r=0.22, g=0.22, b=0.22, a=1 },
    characterFrame    = { r=0.28, g=0.28, b=0.28, a=1 },
    bankFrame         = { r=0.28, g=0.28, b=0.28, a=1 },
    bagFrames         = { r=0.28, g=0.28, b=0.28, a=1 },
    friendsFrame      = { r=0.28, g=0.28, b=0.28, a=1 },
    questFrame        = { r=0.28, g=0.28, b=0.28, a=1 },
    mailFrame         = { r=0.28, g=0.28, b=0.28, a=1 },
    merchantFrame     = { r=0.28, g=0.28, b=0.28, a=1 },
    lootFrame         = { r=0.28, g=0.28, b=0.28, a=1 },
    tradeFrame        = { r=0.28, g=0.28, b=0.28, a=1 },
    auctionFrame      = { r=0.28, g=0.28, b=0.28, a=1 },
    encounterJournal  = { r=0.28, g=0.28, b=0.28, a=1 },
    collectionsJournal= { r=0.28, g=0.28, b=0.28, a=1 },
    gameMenu          = { r=0.28, g=0.28, b=0.28, a=1 },
    worldMap          = { r=0.28, g=0.28, b=0.28, a=1 },
    professions       = { r=0.28, g=0.28, b=0.28, a=1 },
}

-- ============================================================
-- Init
-- ============================================================
function Colorizer:Init()
    for key, skin in pairs(self.skins) do
        if AklimeModDB.colorizer[key] and AklimeModDB.colorizer[key].enabled then
            pcall(function() skin:Apply() end)
        end
    end
end