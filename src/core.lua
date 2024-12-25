local addonName, ViviGlow = ...

-- Create our main frame and register for events
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

-- Cache frequently used values
local hasInitialized = false
local vivifyButtons = {}
local isTracking = false
local hasTalent = false

-- Define messages first
local MESSAGES = {
    ADDON_LOAD = "|cFF40D19EViviGlow|r v%s loaded",
    CLASS_WRONG = "|cFFFF0000ViviGlow:|r This addon is for Monks only",
    TALENT_MISSING = "|cFFFFFF00ViviGlow:|r Vivacious Vivification not selected - Addon deactivated",
    TALENT_ACTIVE = "|cFF40D19EViviGlow:|r Active - Vivacious Vivification detected",
    BUTTON_MISSING = "|cFFFFFF00ViviGlow:|r Vivify not found on action bars - Add Vivify spell to enable glow effect",
    DEBUG_ON = "|cFF40D19EViviGlow Debug:|r Enabled",
    DEBUG_OFF = "|cFF40D19EViviGlow Debug:|r Disabled"
}

-- Then register slash commands
SLASH_VIVIGLOWDEBUG1 = '/vgd'
SLASH_VIVIGLOWDEBUG2 = '/viviglowdebug'
SlashCmdList["VIVIGLOWDEBUG"] = function(msg)
    local command = msg:lower()
    if command == "on" then
        VIVIGLOW.DEBUG = true
        ViviGlowDB.debug = true
        print(MESSAGES.DEBUG_ON)
    elseif command == "off" then
        VIVIGLOW.DEBUG = false
        ViviGlowDB.debug = false
        print(MESSAGES.DEBUG_OFF)
    elseif command == "status" then
        -- Show comprehensive status
        print("|cFF40D19EViviGlow Status:|r")
        print("- Debug Mode: " .. (VIVIGLOW.DEBUG and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"))
        print("- Talent Status: " .. (hasTalent and "|cFF00FF00Active|r" or "|cFFFF0000Not Selected|r"))
        print("- Tracking Status: " .. (isTracking and "|cFF00FF00Active|r" or "|cFFFF0000Inactive|r"))
        print("- Vivify Buttons Found: " .. #vivifyButtons)
    else
        -- Show usage help
        print("|cFF40D19EViviGlow Debug Commands:|r")
        print("- /vgd on - Enable debug mode")
        print("- /vgd off - Disable debug mode")
        print("- /vgd status - Show current status")
    end
end

-- Add debug function
function ViviGlow:Debug(message)
    if VIVIGLOW.DEBUG then
        print("|cFF40D19EViviGlow:|r", message)
    end
end

-- Helper function to check if talent is selected
function ViviGlow:HasVivaciousTalent()
    self:Debug("=== Talent Check Start ===")
    hasTalent = IsPlayerSpell(VIVIGLOW.SPELLS.VIVACIOUS_VIVIFICATION)
    
    if hasTalent then
        print("|cFF40D19EViviGlow - Active:|r Vivacious Vivification Detected")
        isTracking = true
    else
        print("|cFFFFFF00ViviGlow - Disabled:|r Vivacious Vivification Not Selected")
        isTracking = false
        self:UpdateVivifyGlow()
    end
    
    self:Debug("Final talent status: " .. (hasTalent and "SELECTED" or "NOT SELECTED"))
    self:Debug("=== Talent Check End ===")
    return hasTalent
end

-- Helper function to check for Vivacious Vivification buff
function ViviGlow:HasVivaBuff()
    local buffId = VIVIGLOW.SPELLS.VIVACIOUS_BUFF
    local auras = C_UnitAuras.GetPlayerAuraBySpellID(buffId)
    local hasBuff = auras ~= nil
    
    -- Only debug when buff status changes
    if hasBuff ~= lastBuffStatus then
        self:Debug("Vivacious buff: " .. (hasBuff and "GAINED" or "LOST"))
        lastBuffStatus = hasBuff
    end
    
    return hasBuff
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

-- Initialize saved variables
local function InitializeSavedVars()
    -- Create default settings if they don't exist
    ViviGlowDB = ViviGlowDB or {
        debug = false
    }
    
    -- Initialize debug mode from saved settings
    VIVIGLOW.DEBUG = ViviGlowDB.debug
end

function ViviGlow:Init()
    if hasInitialized then return end
    
    InitializeSavedVars()
    
    -- Startup message with specific color
    print("|cFF40D19EViviGlow|r v1.0.0 loaded")
    self:Debug("Initializing...")
    
    -- Check if player is correct class
    local _, className = UnitClass("player")
    self:Debug("Class check: " .. className)
    
    if className ~= VIVIGLOW.REQUIRED_CLASS then
        print("|cFFFF0000ViviGlow:|r This addon is for Monks only!")
        return
    end
    
    -- Check talent status
    self:Debug("Checking talents...")
    local talentStatus = self:HasVivaciousTalent()
    
    -- Cache Vivify buttons
    self:Debug("Scanning action bars...")
    self:CacheVivifyButtons()
    
    hasInitialized = true
    
    -- Final status message
    if talentStatus then
        print("|cFF40D19EViviGlow:|r Ready - Vivacious Vivification detected")
    else
        print("|cFFFFFF00ViviGlow:|r Waiting - Vivacious Vivification not selected")
    end
end

-- Add at top with other locals
local glowStyle = {
    BLIZZARD = "BLIZZARD",  -- Default gold proc glow
    CUSTOM = "CUSTOM"       -- Our turquoise glow
}

-- Function to update glow on all cached Vivify buttons
function ViviGlow:UpdateVivifyGlow()
    if not hasTalent then
        -- Clean up all glow effects when talent is not active
        for _, button in ipairs(vivifyButtons) do
            if button.viviGlow then
                button.viviGlow.animGroup:Stop()
                button.viviGlow:Hide()
                button.viviGlow = nil
            end
        end
        return
    end
    
    local shouldGlow = self:HasVivaBuff()
    
    for _, button in ipairs(vivifyButtons) do
        self.BlizzardGlow:UpdateVivifyGlow(button, shouldGlow)
    end
end

-- Event handler
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        print("|cFF40D19EViviGlow|r v1.0.0 - Addon Loaded")
    elseif event == "PLAYER_ENTERING_WORLD" then
        ViviGlow:Init()
    elseif hasInitialized then
        if event == "PLAYER_SPECIALIZATION_CHANGED" then
            local unit = ...
            if unit == "player" then
                hasTalent = ViviGlow:HasVivaciousTalent()
                if hasTalent then
                    ViviGlow:CacheVivifyButtons()
                    ViviGlow:UpdateVivifyGlow()
                end
            end
        elseif event == "PLAYER_TALENT_UPDATE" then
            hasTalent = ViviGlow:HasVivaciousTalent()
            if hasTalent then
                ViviGlow:CacheVivifyButtons()
                ViviGlow:UpdateVivifyGlow()
            end
        elseif event == "UNIT_AURA" and hasTalent then
            local unit = ...
            if unit == "player" then
                ViviGlow:UpdateVivifyGlow()
            end
        elseif event == "ACTIONBAR_SLOT_CHANGED" then
            if isTracking then
                ViviGlow:CacheVivifyButtons()
                ViviGlow:UpdateVivifyGlow()
            end
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            ViviGlow:UNIT_SPELLCAST_SUCCEEDED(...)
        end
    end
end)
 