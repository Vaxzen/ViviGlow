local addonName, ViviGlow = ...

local BlizzardGlow = {}

-- Simple settings
local GLOW_SETTINGS = {
    frameStrata = "MEDIUM",
    frameLevelDelta = 1,
    BORDER_SIZE = 15
}

function BlizzardGlow:UpdateVivifyGlow(button, shouldGlow)
    -- Clean up any existing glow on this button
    if button.viviGlow then
        button.viviGlow.animGroup:Stop()
        button.viviGlow:Hide()
        button.viviGlow = nil
    end

    if shouldGlow then
        -- Create the glow frame
        local glow = CreateFrame("Frame", nil, button)
        glow:SetFrameStrata(GLOW_SETTINGS.frameStrata)
        glow:SetFrameLevel(button:GetFrameLevel() + GLOW_SETTINGS.frameLevelDelta)
        glow:SetAllPoints(button)
        
        -- Calculate sizes dynamically based on button dimensions
        local buttonWidth = button:GetWidth()
        local buttonHeight = button:GetHeight()
        local baseSize = math.max(buttonWidth, buttonHeight)
        local totalSize = baseSize + (GLOW_SETTINGS.BORDER_SIZE * 2)
        
        -- Create and setup the glow texture
        local overlay = glow:CreateTexture(nil, "OVERLAY")
        overlay:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        overlay:SetBlendMode("ADD")
        overlay:SetSize(totalSize, totalSize)
        overlay:SetPoint("CENTER")  -- Simplified positioning
        overlay:SetVertexColor(VIVIGLOW.ANIMATION.COLOR.r, 
                             VIVIGLOW.ANIMATION.COLOR.g, 
                             VIVIGLOW.ANIMATION.COLOR.b)
        
        glow.overlay = overlay
        
        -- Create animation group
        local ag = glow:CreateAnimationGroup()
        ag:SetLooping("REPEAT")
        
        -- Scale out animation
        local scaleOut = ag:CreateAnimation("Scale")
        scaleOut:SetScale(VIVIGLOW.ANIMATION.SCALE.MAX, VIVIGLOW.ANIMATION.SCALE.MAX)
        scaleOut:SetDuration(VIVIGLOW.ANIMATION.DURATION / 2)
        scaleOut:SetSmoothing("IN_OUT")
        scaleOut:SetOrder(1)
        
        -- Scale in animation
        local scaleIn = ag:CreateAnimation("Scale")
        scaleIn:SetScale(VIVIGLOW.ANIMATION.SCALE.MIN, VIVIGLOW.ANIMATION.SCALE.MIN)
        scaleIn:SetDuration(VIVIGLOW.ANIMATION.DURATION / 2)
        scaleIn:SetSmoothing("IN_OUT")
        scaleIn:SetOrder(2)
        
        -- Alpha out animation
        local fadeOut = ag:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(VIVIGLOW.ANIMATION.ALPHA.MAX)
        fadeOut:SetToAlpha(VIVIGLOW.ANIMATION.ALPHA.MIN)
        fadeOut:SetDuration(VIVIGLOW.ANIMATION.DURATION / 2)
        fadeOut:SetSmoothing("IN_OUT")
        fadeOut:SetOrder(1)
        
        -- Alpha in animation
        local fadeIn = ag:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(VIVIGLOW.ANIMATION.ALPHA.MIN)
        fadeIn:SetToAlpha(VIVIGLOW.ANIMATION.ALPHA.MAX)
        fadeIn:SetDuration(VIVIGLOW.ANIMATION.DURATION / 2)
        fadeIn:SetSmoothing("IN_OUT")
        fadeIn:SetOrder(2)
        
        -- Setup cleanup on hide
        glow:SetScript("OnHide", function()
            if glow.animGroup then
                glow.animGroup:Stop()
            end
        end)
        
        glow.animGroup = ag
        button.viviGlow = glow
        
        glow:Show()
        ag:Play()
    end
end

ViviGlow.BlizzardGlow = BlizzardGlow 