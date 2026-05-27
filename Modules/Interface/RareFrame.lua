-- Modules/Interface/RareFrame.lua
-- Ergänzt seltene Gegner im TargetFrame mit Silberdrachen
-- Stern bleibt drunter, Drachen wird oben drüber gelegt
--
-- Exakte Werte aus ElitePlayerFrame (Mainline/Frame.xml + Core.lua):
--   Atlas: UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver
--   Frame anchort RIGHT an TargetFrame.TargetFrameContainer.FrameTexture
--   Portrait anchort RIGHT an TargetFrame.TargetFrameContainer.TargetPortrait
--   Offset: Frame x=9,y=0 / Portrait x=20,y=13
--   flipHorizontally auf dem TargetFrame = NICHT gespiegelt (normaler TexCoord 0,1,0,1)
--   (ElitePlayerFrame spiegelt NUR den PlayerFrame weil der links sitzt)

local FRAME_OX    =  9
local FRAME_OY    =  0
local PORTRAIT_OX = 20
local PORTRAIT_OY = 13

local ATLAS_SILVER = "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver"

local rareContainer  = nil
local rareFrameTex   = nil
local rarePortTex    = nil

local function BuildRareFrames()
    if rareContainer then return end

    local tf = _G["TargetFrame"]
    if not tf then return end

    local tfContainer = tf["TargetFrameContainer"] or _G["TargetFrameContainer"]
    if not tfContainer then return end

    local refFrameTex = tfContainer["FrameTexture"] or _G["TargetFrameContainerFrameTexture"]
    local refPortrait = tfContainer["TargetPortrait"] or _G["TargetPortrait"]

    rareContainer = CreateFrame("Frame", "AklimeModRareContainer", tf)
    rareContainer:SetAllPoints(tf)
    rareContainer:Hide()

    -- Frame-Textur: BACKGROUND, anchor RIGHT an TargetFrame FrameTexture
    rareFrameTex = rareContainer:CreateTexture(nil, "BACKGROUND", nil, 1)
    rareFrameTex:Hide()
    if refFrameTex then
        rareFrameTex:SetPoint("RIGHT", refFrameTex, "RIGHT", FRAME_OX, FRAME_OY)
    end

    -- Portrait-Textur: ARTWORK, anchor RIGHT an TargetPortrait
    rarePortTex = rareContainer:CreateTexture(nil, "ARTWORK", nil, 2)
    rarePortTex:Hide()
    if refPortrait then
        rarePortTex:SetPoint("RIGHT", refPortrait, "RIGHT", PORTRAIT_OX, PORTRAIT_OY)
    end
end

local function ApplyAtlas(tex, atlas)
    if not tex then return end
    local info = C_Texture.GetAtlasInfo(atlas)
    if info then tex:SetSize(info.width, info.height) end
    tex:SetAtlas(atlas, false)
    -- TargetFrame sitzt rechts → NICHT spiegeln (0,1,0,1 = normal)
    tex:SetTexCoord(0, 1, 0, 1)
    tex:Show()
end

function AklimeMod_UpdateRareFrame()
    if not AklimeModDB or not AklimeModDB.rareFrame.enabled then
        if rareContainer then rareContainer:Hide() end
        return
    end

    local class = UnitExists("target") and UnitClassification("target")
    -- Nur bei "rare" anzeigen — "rareelite" hat schon den goldenen Drachen von Blizzard
    if class == "rare" then
        BuildRareFrames()
        if not rareContainer then return end
        ApplyAtlas(rareFrameTex,  ATLAS_SILVER)
        ApplyAtlas(rarePortTex,   ATLAS_SILVER)
        rareContainer:Show()
    else
        if rareContainer then rareContainer:Hide() end
    end
end
