local addonName, ViviGlow = ...

-- Create our main frame and register essential events
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
frame:RegisterEvent("UNIT_AURA")

-- Cache frequently used values
local hasInitialized = false
local vivifyButtons = {}
local isTracking = false
local hasTalent = false
local lastTalentState = false
local lastBuffState = false
local addonEnabled = VIVIGLOW.ENABLED
local glowEnabled = VIVIGLOW.GLOW_ENABLED
local counterEnabled = VIVIGLOW.COUNTER_ENABLED

-- Define standardized messages
local MESSAGES = {
    ADDON_LOAD = "|cFF40D19EViviGlow|r v%s loaded",
    CLASS_WRONG = "|cFFFF0000ViviGlow:|r This addon is for Monks only",
    TALENT_MISSING = "|cFFFFFF00ViviGlow:|r Vivacious Vivification not selected - ViviGlow deactivated",
    TALENT_ACTIVE = "|cFF40D19EViviGlow:|r Active - Vivacious Vivification detected",
    BUTTON_MISSING = "|cFFFFFF00ViviGlow:|r Vivify not found on action bars - Add Vivify spell to enable glow effect",
    DEBUG_ON = "|cFF40D19EViviGlow Debug:|r Enabled",
    DEBUG_OFF = "|cFF40D19EViviGlow Debug:|r Disabled",
    GLOW_ENABLED = "|cFF40D19EViviGlow:|r Glow effect enabled",
    GLOW_DISABLED = "|cFF40D19EViviGlow:|r Glow effect disabled",
    COUNTER_ENABLED = "|cFF40D19EViviGlow:|r Counter display enabled",
    COUNTER_DISABLED = "|cFF40D19EViviGlow:|r Counter display disabled"
}

-- Add color constants using Blizzard's standard colors
local COLORS = {
    MONK = RAID_CLASS_COLORS["MONK"] or CreateColor(0.0, 1.0, 0.59),  -- Fallback monk color
    ENABLED = CreateColor(0.0, 1.0, 0.0),  -- Green
    DISABLED = CreateColor(1.0, 0.0, 0.0),  -- Red
}

-- Helper function to colorize text
local function ColorText(text, color)
    return color:WrapTextInColorCode(text)
end

-- Initialize saved variables
local function InitializeSavedVars()
    -- Initialize saved variables if they don't exist
    ViviGlowDB = ViviGlowDB or {
        debug = false,  -- Default debug state
        enabled = VIVIGLOW.ENABLED,
        glowEnabled = VIVIGLOW.GLOW_ENABLED,
        counterEnabled = VIVIGLOW.COUNTER_ENABLED
    }
    
    -- Update constants from saved variables
    VIVIGLOW.DEBUG = ViviGlowDB.debug
end

-- Debug command registration (keeping existing implementation)
SLASH_VIVIGLOWDEBUG1 = '/vgd'
SLASH_VIVIGLOWDEBUG2 = '/viviglowdebug'
SlashCmdList["VIVIGLOWDEBUG"] = function(msg)
    local command = msg:lower()
    
    if command == "" then
        -- Show comprehensive status in the new format
        print(string.format("%s Debug Mode: %s (on / off)",
            ColorText("ViviGlow v" .. (VIVIGLOW.VERSION or "1.0.0"), COLORS.MONK),
            ColorText(VIVIGLOW.DEBUG and "Enabled" or "Disabled", 
                     VIVIGLOW.DEBUG and COLORS.ENABLED or COLORS.DISABLED)))
        
        print(string.format("%s %s",
            ColorText("/vgd talent:", COLORS.MONK),
            ColorText(hasTalent and "Active" or "Not Selected",
                     hasTalent and COLORS.ENABLED or COLORS.DISABLED)))
        
        print(string.format("%s %s",
            ColorText("/vgd tracking:", COLORS.MONK),
            ColorText(isTracking and "Active" or "Inactive",
                     isTracking and COLORS.ENABLED or COLORS.DISABLED)))
        
        print(string.format("%s %d",
            ColorText("/vgd buttons:", COLORS.MONK),
            #vivifyButtons))
        
        return
    end
    
    if command == "on" or command == "off" then
        VIVIGLOW.DEBUG = command == "on"
        ViviGlowDB.debug = VIVIGLOW.DEBUG
        print(VIVIGLOW.DEBUG and MESSAGES.DEBUG_ON or MESSAGES.DEBUG_OFF)
    end
end

-- Helper function to check talent and update status
function ViviGlow:CheckTalentStatus()
    local newTalentState = IsPlayerSpell(VIVIGLOW.SPELLS.VIVACIOUS_VIVIFICATION)
    
    -- Only show messages if talent state has changed
    if newTalentState ~= lastTalentState then
        if newTalentState then
            print(MESSAGES.TALENT_ACTIVE)
            self:Debug("Talent activated")
        else
            print(MESSAGES.TALENT_MISSING)
            self:Debug("Talent deactivated")
        end
        lastTalentState = newTalentState
    end
    
    return newTalentState
end

-- Core initialization function following program flow
function ViviGlow:Init()
    if hasInitialized then return end
    
    InitializeSavedVars()
    
    self:Debug("=== Initialization Start ===")
    
    -- Step 1: Load confirmation
    print(string.format(MESSAGES.ADDON_LOAD, "1.0.0"))
    
    -- Step 2: Class check
    local _, className = UnitClass("player")
    if className ~= VIVIGLOW.REQUIRED_CLASS then
        print(MESSAGES.CLASS_WRONG)
        self:Debug("Wrong class detected - disabling addon")
        return
    end
    
    -- Register remaining events only if class check passes
    frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    
    hasInitialized = true
    self:Debug("Initialization complete - proceeding to talent check")
    
    -- Initial talent and button check
    self:CheckTalentAndInitialize()
end

-- Consolidated talent and button initialization
function ViviGlow:CheckTalentAndInitialize()
    -- Step 3: Talent check
    hasTalent = self:CheckTalentStatus()
    
    if not hasTalent then
        isTracking = false
        self:UpdateVivifyGlow() -- Clean up any existing glows
        return
    end
    
    -- Step 4: Button check
    self:CacheVivifyButtons()
    
    if #vivifyButtons == 0 then
        print(MESSAGES.BUTTON_MISSING)
        self:Debug("No Vivify buttons found")
        return
    end
    
    -- Step 5: Begin tracking
    isTracking = true
    self:UpdateVivifyGlow()
end

-- Track only Vivify casts when we have the talent
function ViviGlow:UNIT_SPELLCAST_SUCCEEDED(unit, _, spellID)
    if unit == "player" and spellID == VIVIGLOW.SPELLS.VIVIFY and hasTalent then
        self:Debug("Vivify cast - Watching for next buff cycle")
        -- We don't need to track time, just wait for next UNIT_AURA
    end
end

-- Function to find all Vivify buttons
function ViviGlow:CacheVivifyButtons()
    -- Clear existing buttons and their glows
    for _, button in ipairs(vivifyButtons) do
        if button.viviGlow then
            button.viviGlow.animGroup:Stop()
            button.viviGlow:Hide()
            button.viviGlow = nil
        end
    end
    wipe(vivifyButtons)
    
    -- Scan all action bars using Blizzard's action bar API
    for i = 1, 180 do
        local buttonTypes = {
            ["ActionButton"] = _G["ActionButton"..i],
            ["MultiBarBottomLeft"] = _G["MultiBarBottomLeftButton"..i],
            ["MultiBarBottomRight"] = _G["MultiBarBottomRightButton"..i],
            ["MultiBarRight"] = _G["MultiBarRightButton"..i],
            ["MultiBarLeft"] = _G["MultiBarLeftButton"..i]
        }
        
        for _, button in pairs(buttonTypes) do
            if button then
                local actionType, id = GetActionInfo(button.action or 0)
                if actionType == "spell" and id == VIVIGLOW.SPELLS.VIVIFY then
                    table.insert(vivifyButtons, button)
                end
            end
        end
    end
end

-- Add debug function
function ViviGlow:Debug(message)
    if VIVIGLOW.DEBUG then
        print("|cFF40D19EViviGlow:|r", message)
    end
end

-- Updated HasVivaBuff function with state tracking
function ViviGlow:HasVivaBuff()
    -- Use C_UnitAuras for modern API usage
    local auraData = C_UnitAuras.GetPlayerAuraBySpellID(VIVIGLOW.SPELLS.VIVACIOUS_BUFF)
    local currentBuffState = auraData ~= nil
    
    -- Only debug message on state change
    if currentBuffState ~= lastBuffState then
        if currentBuffState then
            self:Debug("Vivacious buff gained - Starting glow and counter")
        else
            self:Debug("Vivacious buff lost - Stopping glow and counter")
        end
        lastBuffState = currentBuffState
    end
    
    return currentBuffState
end

-- Function to update glow on all cached Vivify buttons
function ViviGlow:UpdateVivifyGlow()
    if not hasTalent then
        -- Clean up effects if talent not active
        for _, button in ipairs(vivifyButtons) do
            if button.viviGlow then
                button.viviGlow.animGroup:Stop()
                button.viviGlow:Hide()
                button.viviGlow = nil
            end
            self.ButtonCounter:CleanUp(button)
        end
        return
    end
    
    -- Use AuraUtil for more reliable aura detection
    local auraInfo = C_UnitAuras.GetPlayerAuraBySpellID(VIVIGLOW.SPELLS.VIVACIOUS_BUFF)
    local shouldGlow = auraInfo ~= nil
    
    for _, button in ipairs(vivifyButtons) do
        -- Update glow effect (keeps original behavior)
        self.BlizzardGlow:UpdateVivifyGlow(button, shouldGlow)
        
        -- Update counter when enabled
        if counterEnabled then
            if shouldGlow then
                -- Sync with actual buff duration
                local remainingTime = auraInfo.expirationTime - GetTime()
                self.ButtonCounter:StartCounter(button, {
                    duration = remainingTime,
                    countDown = true,
                    continueCounting = true,
                    spellID = VIVIGLOW.SPELLS.VIVACIOUS_BUFF,
                    timeStamp = auraInfo.expirationTime
                })
            elseif not button.viviCounter or button.viviCounter.value == 0 then
                -- Start new 9-second countdown when inactive
                self.ButtonCounter:StartCounter(button, {
                    duration = 9,
                    countDown = true,
                    continueCounting = true,
                    spellID = VIVIGLOW.SPELLS.VIVACIOUS_BUFF
                })
            end
        elseif not counterEnabled and button.viviCounter then
            self.ButtonCounter:CleanUp(button)
        end
    end
end

-- Event handler with improved flow
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        ViviGlow:Init()
    elseif hasInitialized then
        if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
            ViviGlow:CheckTalentAndInitialize()
        elseif isTracking then
            if event == "UNIT_AURA" then
                local unit = ...
                if unit == "player" then
                    ViviGlow:UpdateVivifyGlow()
                end
            elseif event == "ACTIONBAR_SLOT_CHANGED" then
                ViviGlow:CacheVivifyButtons()
                ViviGlow:UpdateVivifyGlow()
            end
        end
    end
end)

local function HandleVivifyButton(button)
    if not button then return end
    
    -- When buff is detected
    local function OnAuraChanged(unit)
        if unit ~= "player" then return end
        
        local name, _, _, _, _, _, _, _, _, spellID = 
            AuraUtil.FindAuraByName(VIVIGLOW.SPELLS.VIVACIOUS_BUFF, "player")
            
        if name then
            -- Start glow effect
            ViviGlow.BlizzardGlow:StartGlow(button)
            -- Start counter with default settings (10 seconds, countdown)
            ViviGlow.ButtonCounter:StartCounter(button, {
                duration = 10,  -- Matches buff duration
                countDown = true,
                verticalAlign = "CENTER",
                horizontalAlign = "CENTER",
                fontSizePercent = 0.6,
                color = { r = 1, g = 1, b = 1, a = 1 }
            })
        else
            -- Stop both glow and counter
            ViviGlow.BlizzardGlow:StopGlow(button)
            ViviGlow.ButtonCounter:StopCounter(button)
        end
    end
    
    -- Register for aura changes
    local frame = CreateFrame("Frame")
    frame:RegisterUnitEvent("UNIT_AURA", "player")
    frame:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_AURA" then
            OnAuraChanged(unit)
        end
    end)
end

-- Updated helper function for status display with modern API practices
local function ShowStatus()
    local version = VIVIGLOW.VERSION or "1.0.0"
    
    -- Check if addon is fully functional
    local isActive = hasInitialized and hasTalent and addonEnabled
    
    -- Main status line showing actual functional state
    print(string.format("%s Status: %s",
        ColorText("ViviGlow v" .. version, COLORS.MONK),
        ColorText(isActive and "Enabled" or "Disabled", 
                 isActive and COLORS.ENABLED or COLORS.DISABLED)))
    
    -- Feature status lines with class-colored commands
    print(string.format("%s %s (on / off)",
        ColorText("/vg glow:", COLORS.MONK),
        ColorText(glowEnabled and "Enabled" or "Disabled",
                 glowEnabled and COLORS.ENABLED or COLORS.DISABLED)))
    
    print(string.format("%s %s (on / off)",
        ColorText("/vg counter:", COLORS.MONK),
        ColorText(counterEnabled and "Enabled" or "Disabled",
                 counterEnabled and COLORS.ENABLED or COLORS.DISABLED)))
end

-- Helper function for help display
local function ShowHelp()
    print(MESSAGES.HELP_HEADER)
    for _, helpLine in ipairs(MESSAGES.HELP) do
        print(helpLine)
    end
end

-- Main command implementation
SLASH_VIVIGLOW1 = '/vg'
SLASH_VIVIGLOW2 = '/viviglow'
SlashCmdList["VIVIGLOW"] = function(msg)
    local command, arg = strsplit(" ", msg:lower(), 2)
    
    if command == "" or command == "status" then
        ShowStatus()
        return
    end
    
    if command == "glow" then
        if not arg or (arg ~= "on" and arg ~= "off") then
            print("Usage: /vg glow on|off")
            return
        end
        
        glowEnabled = arg == "on"
        VIVIGLOW.GLOW_ENABLED = glowEnabled  -- Update constant
        ViviGlowDB.glowEnabled = glowEnabled  -- Save to persistent storage
        
        if glowEnabled then
            -- Enable glow tracking events
            frame:RegisterEvent("UNIT_AURA")
            print(MESSAGES.GLOW_ENABLED)
        else
            -- Disable glow tracking events and clean up existing glows
            frame:UnregisterEvent("UNIT_AURA")
            -- Clean up any existing glows
            for _, button in ipairs(vivifyButtons) do
                if button.viviGlow then
                    button.viviGlow.animGroup:Stop()
                    button.viviGlow:Hide()
                end
            end
            print(MESSAGES.GLOW_DISABLED)
        end
        
    elseif command == "counter" then
        if not arg or (arg ~= "on" and arg ~= "off") then
            print("Usage: /vg counter on|off")
            return
        end
        
        counterEnabled = arg == "on"
        VIVIGLOW.COUNTER_ENABLED = counterEnabled  -- Update constant
        ViviGlowDB.counterEnabled = counterEnabled  -- Save to persistent storage
        
        if counterEnabled then
            frame:RegisterEvent("UNIT_AURA")
            print(MESSAGES.COUNTER_ENABLED)
            -- Force immediate update
            ViviGlow:UpdateVivifyGlow()
        else
            -- Disable counter tracking events and clean up existing counters
            frame:UnregisterEvent("UNIT_AURA")
            -- Clean up any existing counters
            for _, button in ipairs(vivifyButtons) do
                if button.viviCounter then
                    button.viviCounter:Hide()
                end
            end
            print(MESSAGES.COUNTER_DISABLED)
        end
    end
end
 