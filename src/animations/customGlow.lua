local addonName, ViviGlow = ...

--[[ ADJUSTABLE SETTINGS ]]--

-- Common animation controls that apply to all animations
local COMMON_CONTROLS = {
    -- Color settings (RGB values from 0 to 1)
    color = {
        r = 0.4,    -- Red component
        g = 1.0,    -- Green component
        b = 1.0     -- Blue component
    },
    
    -- Transparency settings (0 = invisible, 1 = fully visible)
    alpha = {
        min = 0.5,  -- Minimum visibility
        max = 1.0   -- Maximum visibility
    },
    
    -- Timing settings
    duration = 0.3,     -- Base duration of animations
    frequency = 1.0,    -- How often the animation repeats (times per second)
    
    -- Position settings
    padding = {
        horizontal = 0,  -- Distance from left/right of button
        vertical = 0    -- Distance from top/bottom of button
    }
}

-- Add color presets at the top of the file
local COLOR_PRESETS = {
    TURQUOISE = {
        r = 0.098,  -- RGB: 25
        g = 0.969,  -- RGB: 247
        b = 0.808   -- RGB: 206
    },
    GOLD = {
        r = 1.0,    -- RGB: 255
        g = 0.82,   -- RGB: 209
        b = 0.0     -- RGB: 0
    }
}

-- Default settings for each animation type
local ANIMATION_DEFAULTS = {
    -- Common settings for all animations
    frameStrata = "HIGH",
    frameLevelDelta = 10,
    overlayLevel = 5,
    padding = {
        vertical = 0,
        horizontal = 0
    },
    color = COLOR_PRESETS.TURQUOISE,
    alpha = {
        min = 0.7,
        max = 1.0
    },
    
    -- Border animation settings
    BORDER = {
        borderSize = 10
    },
    
    -- Pulse animation settings
    PULSE = {
        scale = {
            min = 1.0,
            max = 1.8
        }
    },
    
    -- Path animation settings
    PATH = {
        pathWidth = 10,
        speed = 1.2,
        fadeRatio = 0.2
    },
    
    -- Blizzard animation settings
    BLIZZARD = {
        borderRatio = 0.15,
        duration = 0.75,
        scale = {
            min = 0.9,
            max = 1.1,
        }
    },
    
    -- Add Proc animation settings
    PROC = {
        duration = {
            inDuration = 0.2,
            loopDuration = 0.8,
            rotationDuration = 3
        },
        scale = {
            outer = 1.5,
            inner = 1.3,
            burst = {
                outer = 1.2,
                inner = 1.4
            }
        },
        alpha = {
            min = 0.8,
            max = 1.0
        },
        color = {
            r = 1.0,
            g = 1.0,
            b = 1.0
        }
    }
}

-- Frame display settings
local FRAME_DEFAULTS = {
    frameStrata = "HIGH",       -- Layer priority (LOW, MEDIUM, HIGH, etc.)
    frameLevelDelta = 10,       -- How many layers above the button
    overlayLevel = 5            -- Changed from 7 to 5 to allow for +1 in sparkle
}

--[[ END ADJUSTABLE SETTINGS ]]--

-- Combined defaults (Don't adjust these directly, modify the settings above)
local GLOW_DEFAULTS = {
    -- Merge common controls
    color = COMMON_CONTROLS.color,
    alpha = COMMON_CONTROLS.alpha,
    padding = COMMON_CONTROLS.padding,
    
    -- Frame settings
    frameStrata = FRAME_DEFAULTS.frameStrata,
    frameLevelDelta = FRAME_DEFAULTS.frameLevelDelta,
    overlayLevel = FRAME_DEFAULTS.overlayLevel,
    
    -- Animation settings
    animation = {
        style = "BORDER",
        duration = COMMON_CONTROLS.duration,
        frequency = COMMON_CONTROLS.frequency,
        settings = {}
    }
}

local ButtonGlow = {}

-- Function to merge settings with defaults based on animation style
function ButtonGlow:MergeSettings(settings)
    settings = settings or {}
    local merged = {}
    
    -- Deep copy of default settings including alpha
    for key, value in pairs(ANIMATION_DEFAULTS) do
        if type(value) == "table" then
            merged[key] = {}
            for subKey, subValue in pairs(value) do
                merged[key][subKey] = subValue
            end
        else
            merged[key] = value
        end
    end
    
    -- Ensure alpha settings exist
    merged.alpha = merged.alpha or { min = 0.7, max = 1.0 }
    
    -- Handle animation style
    settings.animation = settings.animation or {}
    local style = settings.animation.style or "BORDER"
    merged.animation = {
        style = style,
        settings = merged[style] or {}
    }
    
    -- Handle color settings
    if settings.colorPreset then
        merged.color = COLOR_PRESETS[settings.colorPreset] or COLOR_PRESETS.TURQUOISE
    elseif settings.color then
        merged.color = settings.color
    end
    
    return merged
end

-- Helper function to create pulse animation
local function CreatePulseAnimation(glow, settings)
    -- Get animation settings
    local animSettings = settings.animation.settings
    
    -- Create the glow texture
    local texture = glow:CreateTexture(nil, "OVERLAY", nil, settings.overlayLevel)
    texture:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    texture:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
    texture:SetBlendMode("ADD")
    texture:SetVertexColor(settings.color.r, settings.color.g, settings.color.b, settings.alpha.min)
    texture:SetAllPoints(glow)
    glow.pulseTexture = texture
    
    local ag = glow:CreateAnimationGroup()
    ag:SetLooping("REPEAT")
    
    -- Scale animation
    local scaleOut = ag:CreateAnimation("Scale")
    scaleOut:SetScale(animSettings.scale.max, animSettings.scale.max)
    scaleOut:SetDuration(0.5 / settings.animation.frequency)
    scaleOut:SetOrder(1)
    scaleOut:SetSmoothing("IN_OUT")
    scaleOut:SetTarget(texture)
    
    local scaleIn = ag:CreateAnimation("Scale")
    scaleIn:SetScale(animSettings.scale.min, animSettings.scale.min)
    scaleIn:SetDuration(0.5 / settings.animation.frequency)
    scaleIn:SetOrder(2)
    scaleIn:SetSmoothing("IN_OUT")
    scaleIn:SetTarget(texture)
    
    -- Alpha animation
    local fadeOut = ag:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(settings.alpha.min)
    fadeOut:SetToAlpha(settings.alpha.max)
    fadeOut:SetDuration(0.5 / settings.animation.frequency)
    fadeOut:SetOrder(1)
    fadeOut:SetSmoothing("IN_OUT")
    fadeOut:SetTarget(texture)
    
    local fadeIn = ag:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(settings.alpha.max)
    fadeIn:SetToAlpha(settings.alpha.min)
    fadeIn:SetDuration(0.5 / settings.animation.frequency)
    fadeIn:SetOrder(2)
    fadeIn:SetSmoothing("IN_OUT")
    fadeIn:SetTarget(texture)
    
    return ag
end

-- Helper function to create path animation
local function CreatePathAnimation(glow, settings)
    -- Get animation settings
    local animSettings = settings.animation.settings
    
    -- Create single border glow
    local border = glow:CreateTexture(nil, "OVERLAY", nil, settings.overlayLevel)
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")  -- Using default WoW border
    border:SetBlendMode("ADD")
    border:SetVertexColor(settings.color.r, settings.color.g, settings.color.b, settings.alpha.min)
    border:SetAllPoints(glow)
    glow.border = border
    
    -- Create moving glow texture
    local texture = glow:CreateTexture(nil, "OVERLAY", nil, settings.overlayLevel + 1)
    texture:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    texture:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
    texture:SetBlendMode("ADD")
    texture:SetVertexColor(settings.color.r, settings.color.g, settings.color.b, settings.alpha.max)
    texture:SetSize(glow:GetWidth() / 4, glow:GetWidth() / 4)  -- Smaller size to match border
    
    -- Initially position the texture
    texture:SetPoint("CENTER", glow, "TOPLEFT")
    glow.pathTexture = texture
    
    local ag = glow:CreateAnimationGroup()
    ag:SetLooping("REPEAT")
    
    -- Create the path animation
    local path = ag:CreateAnimation("Path")
    path:SetTarget(texture)
    local duration = 1.0 / settings.animation.frequency * animSettings.speed
    path:SetDuration(duration)
    
    -- Define the path points to follow the border closely
    local padding = 2  -- Distance from border
    local points = {
        {x = padding/glow:GetWidth(),      y = padding/glow:GetHeight(),     order = 1},    -- Top-left
        {x = 1-(padding/glow:GetWidth()),  y = padding/glow:GetHeight(),     order = 2},    -- Top-right
        {x = 1-(padding/glow:GetWidth()),  y = 1-(padding/glow:GetHeight()), order = 3},    -- Bottom-right
        {x = padding/glow:GetWidth(),      y = 1-(padding/glow:GetHeight()), order = 4},    -- Bottom-left
        {x = padding/glow:GetWidth(),      y = padding/glow:GetHeight(),     order = 5}     -- Back to start
    }
    
    -- Create path points
    for _, point in ipairs(points) do
        local offset = path:CreateControlPoint()
        local xOffset = point.x * glow:GetWidth()
        local yOffset = -point.y * glow:GetHeight()  -- Negative Y for correct direction
        offset:SetOffset(xOffset, yOffset)
        offset:SetOrder(point.order)
    end
    
    -- Add alpha animation for moving glow
    local fadeIn = ag:CreateAnimation("Alpha")
    fadeIn:SetTarget(texture)
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(settings.alpha.max)
    fadeIn:SetDuration(duration * 0.2)
    fadeIn:SetOrder(1)
    
    local fadeOut = ag:CreateAnimation("Alpha")
    fadeOut:SetTarget(texture)
    fadeOut:SetFromAlpha(settings.alpha.max)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(duration * 0.2)
    fadeOut:SetStartDelay(duration * 0.8)
    fadeOut:SetOrder(1)
    
    return ag
end

-- Helper function to create border animation (placeholder)
local function CreateBorderAnimation(glow, settings)
    -- Border animation implementation will go here
    return glow:CreateAnimationGroup() -- Temporary return
end

-- Add CreateBlizzardAnimation function
local function CreateBlizzardAnimation(glow, settings)
    local animSettings = settings.animation.settings
    local color = settings.color or COLOR_PRESETS.TURQUOISE
    local alpha = settings.alpha or { min = 0.7, max = 1.0 }
    
    -- Create the Blizzard glow overlay
    local overlay = glow:CreateTexture(nil, "OVERLAY", nil, settings.overlayLevel)
    overlay:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    overlay:SetBlendMode("ADD")
    overlay:SetVertexColor(
        color.r,
        color.g,
        color.b,
        alpha.max
    )
    
    -- Calculate sizes dynamically
    local buttonWidth = glow:GetWidth()
    local buttonHeight = glow:GetHeight()
    local baseSize = math.max(buttonWidth, buttonHeight)
    local borderThickness = baseSize * animSettings.borderRatio
    local totalSize = baseSize + (borderThickness * 2)
    
    -- Calculate center offset if button isn't square
    local xOffset = (buttonWidth - buttonHeight) / 2
    local yOffset = (buttonHeight - buttonWidth) / 2
    
    -- Position offset (1px up and right)
    local offsetX = 1
    local offsetY = 1
    
    -- Set up the border with dynamic centering and offset
    overlay:SetSize(totalSize, totalSize)
    overlay:ClearAllPoints()
    if buttonWidth > buttonHeight then
        -- Wide button
        overlay:SetPoint("CENTER", glow, "CENTER", offsetX, yOffset + offsetY)
    elseif buttonHeight > buttonWidth then
        -- Tall button
        overlay:SetPoint("CENTER", glow, "CENTER", xOffset + offsetX, offsetY)
    else
        -- Square button
        overlay:SetPoint("CENTER", glow, "CENTER", offsetX, offsetY)
    end
    
    local ag = glow:CreateAnimationGroup()
    
    -- Scale animation
    local scaleOut = ag:CreateAnimation("Scale")
    scaleOut:SetTarget(overlay)
    scaleOut:SetScale(animSettings.scale.max, animSettings.scale.max)
    scaleOut:SetDuration(animSettings.duration)
    scaleOut:SetOrder(1)
    scaleOut:SetSmoothing("IN_OUT")
    
    local scaleIn = ag:CreateAnimation("Scale")
    scaleIn:SetTarget(overlay)
    scaleIn:SetScale(animSettings.scale.min, animSettings.scale.min)
    scaleIn:SetDuration(animSettings.duration)
    scaleIn:SetOrder(2)
    scaleIn:SetSmoothing("IN_OUT")
    
    -- Alpha animation
    local fadeOut = ag:CreateAnimation("Alpha")
    fadeOut:SetTarget(overlay)
    fadeOut:SetFromAlpha(alpha.max)
    fadeOut:SetToAlpha(alpha.min)
    fadeOut:SetDuration(animSettings.duration)
    fadeOut:SetOrder(1)
    fadeOut:SetSmoothing("IN_OUT")
    
    local fadeIn = ag:CreateAnimation("Alpha")
    fadeIn:SetTarget(overlay)
    fadeIn:SetFromAlpha(alpha.min)
    fadeIn:SetToAlpha(alpha.max)
    fadeIn:SetDuration(animSettings.duration)
    fadeIn:SetOrder(2)
    fadeIn:SetSmoothing("IN_OUT")
    
    ag:SetLooping("REPEAT")
    
    -- Debug output with dynamic calculations
    glow:SetScript("OnShow", function()
        print("Dynamic Blizzard Glow Settings:")
        print("Button size (W x H):", buttonWidth, "x", buttonHeight)
        print("Border ratio:", animSettings.borderRatio)
        print("Border thickness:", borderThickness)
        print("Total size:", totalSize)
        print("Center offsets (X, Y):", xOffset, yOffset)
        overlay:Show()
        overlay:SetAlpha(alpha.max)
        ag:Play()
    end)
    
    return ag
end

-- Add to the top with other animations
local function CreateProcAnimation(glow, settings)
    local animSettings = settings.animation.settings
    local color = settings.color or COLOR_PRESETS.TURQUOISE
    local alpha = settings.alpha or { min = 0.7, max = 1.0 }
    
    -- Calculate sizes
    local buttonWidth = glow:GetWidth()
    local buttonHeight = glow:GetHeight()
    local baseSize = math.max(buttonWidth, buttonHeight)
    
    -- Create the outer glow
    local outerGlow = glow:CreateTexture(nil, "OVERLAY", nil, settings.overlayLevel)
    outerGlow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    outerGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
    outerGlow:SetBlendMode("ADD")
    outerGlow:SetVertexColor(color.r, color.g, color.b, alpha.max)
    outerGlow:SetSize(baseSize * 1.4, baseSize * 1.4)  -- Slightly larger than button
    outerGlow:SetPoint("CENTER", glow, "CENTER")
    
    -- Create the inner sparkle
    local innerSparkle = glow:CreateTexture(nil, "OVERLAY", nil, settings.overlayLevel + 1)
    innerSparkle:SetTexture("Interface\\SpellActivationOverlay\\IconAlertGlow")
    innerSparkle:SetTexCoord(0.53125000, 0.78125000, 0.27734375, 0.52734375)
    innerSparkle:SetBlendMode("ADD")
    innerSparkle:SetVertexColor(color.r, color.g, color.b, alpha.max)
    innerSparkle:SetSize(baseSize * 1.2, baseSize * 1.2)  -- Slightly smaller than outer
    innerSparkle:SetPoint("CENTER", glow, "CENTER")
    
    local ag = glow:CreateAnimationGroup()
    
    -- Outer glow animations
    local outerAlphaIn = ag:CreateAnimation("Alpha")
    outerAlphaIn:SetTarget(outerGlow)
    outerAlphaIn:SetFromAlpha(0)
    outerAlphaIn:SetToAlpha(alpha.max)
    outerAlphaIn:SetDuration(animSettings.duration.inDuration)
    outerAlphaIn:SetOrder(1)
    outerAlphaIn:SetSmoothing("OUT")
    
    local outerScaleIn = ag:CreateAnimation("Scale")
    outerScaleIn:SetTarget(outerGlow)
    outerScaleIn:SetScale(1.2, 1.2)
    outerScaleIn:SetDuration(animSettings.duration.inDuration)
    outerScaleIn:SetOrder(1)
    outerScaleIn:SetSmoothing("OUT")
    
    -- Inner sparkle animations
    local innerRotation = ag:CreateAnimation("Rotation")
    innerRotation:SetTarget(innerSparkle)
    innerRotation:SetDegrees(360)
    innerRotation:SetDuration(animSettings.duration.rotationDuration)
    innerRotation:SetOrder(1)
    
    local innerAlphaIn = ag:CreateAnimation("Alpha")
    innerAlphaIn:SetTarget(innerSparkle)
    innerAlphaIn:SetFromAlpha(0)
    innerAlphaIn:SetToAlpha(alpha.max)
    innerAlphaIn:SetDuration(animSettings.duration.inDuration)
    innerAlphaIn:SetOrder(1)
    innerAlphaIn:SetSmoothing("OUT")
    
    local innerScaleIn = ag:CreateAnimation("Scale")
    innerScaleIn:SetTarget(innerSparkle)
    innerScaleIn:SetScale(1.4, 1.4)
    innerScaleIn:SetDuration(animSettings.duration.inDuration)
    innerScaleIn:SetOrder(1)
    innerScaleIn:SetSmoothing("OUT")
    
    -- Maintain the glow
    local outerAlphaLoop = ag:CreateAnimation("Alpha")
    outerAlphaLoop:SetTarget(outerGlow)
    outerAlphaLoop:SetFromAlpha(alpha.max)
    outerAlphaLoop:SetToAlpha(alpha.min)
    outerAlphaLoop:SetDuration(animSettings.duration.loopDuration)
    outerAlphaLoop:SetOrder(2)
    outerAlphaLoop:SetSmoothing("IN_OUT")
    
    local innerAlphaLoop = ag:CreateAnimation("Alpha")
    innerAlphaLoop:SetTarget(innerSparkle)
    innerAlphaLoop:SetFromAlpha(alpha.max)
    innerAlphaLoop:SetToAlpha(alpha.min)
    innerAlphaLoop:SetDuration(animSettings.duration.loopDuration)
    innerAlphaLoop:SetOrder(2)
    innerAlphaLoop:SetSmoothing("IN_OUT")
    
    ag:SetLooping("REPEAT")
    
    glow:SetScript("OnShow", function()
        outerGlow:Show()
        innerSparkle:Show()
        ag:Play()
    end)
    
    return ag
end

function ButtonGlow:New(button, settings)
    settings = settings or {}
    
    -- Allow color selection in settings
    if settings.colorPreset then
        settings.color = COLOR_PRESETS[settings.colorPreset] or COLOR_PRESETS.TURQUOISE
    end
    
    settings = self:MergeSettings(settings)
    local glow = CreateFrame("Frame", nil, button)
    
    -- Setup frame
    glow:SetFrameStrata(settings.frameStrata)
    glow:SetFrameLevel(button:GetFrameLevel() + settings.frameLevelDelta)
    glow:SetPoint("TOPLEFT", button, "TOPLEFT", -settings.padding.horizontal, settings.padding.vertical)
    glow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", settings.padding.horizontal, -settings.padding.vertical)
    
    -- Create animation based on style
    if settings.animation.style == "PULSE" then
        glow.animGroup = CreatePulseAnimation(glow, settings)
    elseif settings.animation.style == "PATH" then
        glow.animGroup = CreatePathAnimation(glow, settings)
    elseif settings.animation.style == "BLIZZARD" then
        glow.animGroup = CreateBlizzardAnimation(glow, settings)
    elseif settings.animation.style == "PROC" then
        glow.animGroup = CreateProcAnimation(glow, settings)
    else -- BORDER
        glow.animGroup = CreateBorderAnimation(glow, settings)
    end
    
    glow:Hide()
    
    function glow:Start()
        self:Show()
        if self.animGroup then
            print("Start called - Playing animation")
            self.animGroup:Play()
        end
    end
    
    function glow:Stop()
        if self.animGroup then
            print("Stop called - Stopping animation")
            self.animGroup:Stop()
        end
        self:Hide()
    end
    
    return glow
end

ViviGlow.ButtonGlow = ButtonGlow 