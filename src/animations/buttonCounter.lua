local addonName, ViviGlow = ...

-- Initialize the counter system
ViviGlow.ButtonCounter = {}
local ButtonCounter = ViviGlow.ButtonCounter

-- Constants for positioning
local POSITION = {
    VERTICAL = {
        TOP = "TOP",
        CENTER = "CENTER",
        BOTTOM = "BOTTOM"
    },
    HORIZONTAL = {
        LEFT = "LEFT",
        CENTER = "CENTER",
        RIGHT = "RIGHT"
    }
}

-- Default settings
local defaults = {
    duration = 10,
    countDown = true,
    verticalAlign = POSITION.VERTICAL.CENTER,
    horizontalAlign = POSITION.HORIZONTAL.CENTER,
    fontSizePercent = 0.6,  -- 60% of button height
    color = {r = 1, g = 1, b = 1, a = 1}
}

-- Create custom font object using Blizzard's recommended method
local COUNTER_FONT_NAME = "ViviGlowCounterFont"
local counterFont = CreateFont(COUNTER_FONT_NAME)
counterFont:SetFontObject(GameFontNormalLarge) -- Inherit from Blizzard base font
counterFont:SetJustifyH("CENTER")
counterFont:SetJustifyV("MIDDLE")
counterFont:SetTextColor(1, 1, 1, 1)  -- White text

-- Helper function to update font size using Blizzard's scaling
local UpdateFontSize
UpdateFontSize = function(text, button, fontSizePercent)
    if not text or not button then return end
    
    local height = button:GetHeight()
    if not height then return end
    
    -- Use Blizzard's UI scale for consistent sizing
    local uiScale = UIParent:GetEffectiveScale()
    local fontSize = math.floor((height * 0.3) / uiScale)
    
    -- Use Blizzard's standard font with thinner outline
    text:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
end

-- Helper function to create or get counter frame
local function GetCounterFrame(button)
    if not button.viviCounter then
        local frame = CreateFrame("Frame", nil, button)
        if not frame then return nil end

        frame:SetFrameStrata("MEDIUM")
        frame:SetFrameLevel(button:GetFrameLevel() + 15)
        frame:SetSize(button:GetWidth() * 0.6, button:GetHeight() * 0.6)
        frame:SetPoint("CENTER", button, "CENTER")

        -- Create text using Blizzard's standard font
        local text = frame:CreateFontString(nil, "OVERLAY")
        text:ClearAllPoints()
        text:SetPoint("BOTTOM", button, "BOTTOM", 0, 5)
        
        -- Apply Blizzard's standard font settings with thinner outline
        text:SetFontObject(counterFont)
        UpdateFontSize(text, button)
        
        frame.text = text
        button.viviCounter = frame
    end
    return button.viviCounter
end

-- Helper function to position counter text
local function PositionText(text, button, vAlign, hAlign)
    -- Clear any existing points
    text:ClearAllPoints()
    
    -- Simple centered positioning if both alignments are center
    if vAlign == POSITION.VERTICAL.CENTER and hAlign == POSITION.HORIZONTAL.CENTER then
        text:SetPoint("CENTER")
        return
    end
    
    -- Calculate offset multipliers
    local yMult = {
        [POSITION.VERTICAL.TOP] = 0.2,
        [POSITION.VERTICAL.CENTER] = 0,
        [POSITION.VERTICAL.BOTTOM] = -0.2
    }
    
    local xMult = {
        [POSITION.HORIZONTAL.LEFT] = -0.2,
        [POSITION.HORIZONTAL.CENTER] = 0,
        [POSITION.HORIZONTAL.RIGHT] = 0.2
    }
    
    -- Calculate pixel offsets based on button size
    local xOffset = (xMult[hAlign] or 0) * button:GetWidth()
    local yOffset = (yMult[vAlign] or 0) * button:GetHeight()
    
    -- Set point using standard anchor points
    text:SetPoint("CENTER", button, "CENTER", xOffset, yOffset)
end

-- Format time display
local function FormatTime(timeValue)
    return string.format("%d", math.ceil(timeValue))  -- Round up to nearest integer
end

-- Main function to start counter with proper initialization checks
function ButtonCounter:StartCounter(button, options)
    if not button then
        ViviGlow:Debug("ERROR: No button provided to StartCounter")
        return
    end

    -- Ensure proper initialization
    if not IsLoggedIn() or InCombatLockdown() then
        C_Timer.After(0.1, function() 
            self:StartCounter(button, options)
        end)
        return
    end

    -- Safe options handling
    options = options or {}
    options.duration = tonumber(options.duration) or defaults.duration
    options.continueCounting = options.continueCounting or false
    options.spellID = tonumber(options.spellID)

    local counterFrame = GetCounterFrame(button)
    if not counterFrame then
        ViviGlow:Debug("ERROR: Failed to get/create counter frame")
        return
    end

    -- Initialize time tracking with safety checks
    local startTime = GetTime()
    local endTime = startTime + options.duration

    -- Update function with improved error handling and current API
    local function UpdateCounter()
        if not counterFrame or not counterFrame.text then return end
        
        local currentTime = GetTime()
        local remaining = endTime - currentTime

        if remaining <= 0 then
            counterFrame.text:SetText("0")
            
            if options.continueCounting and options.spellID then
                -- Use current Dragonflight API for spell cooldown
                local start, duration = C_Spell.GetSpellCooldown(options.spellID)
                if start and duration and start > 0 and duration > 0 then
                    endTime = start + duration
                else
                    self:StopCounter(button)
                    return
                end
            else
                -- Stop counting if not configured to continue
                C_Timer.After(0.5, function()
                    if counterFrame and counterFrame.text then
                        counterFrame.text:SetText("")
                        self:StopCounter(button)
                    end
                end)
                return
            end
        else
            -- Display remaining time
            counterFrame.text:SetText(FormatTime(remaining))
        end
    end

    -- Clean up existing timer before starting new one
    self:StopCounter(button)
    
    -- Start new timer with error handling
    counterFrame.ticker = C_Timer.NewTicker(0.1, function()
        if not button:IsVisible() then
            self:StopCounter(button)
            return
        end
        UpdateCounter()
    end)
    
    counterFrame:Show()
    UpdateCounter() -- Initial update
end

-- Stop counter function with improved cleanup
function ButtonCounter:StopCounter(button)
    if not button then return end
    
    if button.viviCounter then
        if button.viviCounter.ticker then
            button.viviCounter.ticker:Cancel()
            button.viviCounter.ticker = nil
        end
        if button.viviCounter.text then
            button.viviCounter.text:SetText("")
        end
    end
end

-- Clean up function with additional safety
function ButtonCounter:CleanUp(button)
    if not button then return end
    
    self:StopCounter(button)
    if button.viviCounter then
        button.viviCounter:Hide()
        button.viviCounter.text:SetText("")
    end
end 