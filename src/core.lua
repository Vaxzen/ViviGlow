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
local lastTalentState = false  -- Track talent state changes
local lastBuffState = false  -- Track buff state changes

-- Define standardized messages
local MESSAGES = {
    ADDON_LOAD = "|cFF40D19EViviGlow|r v%s loaded",
    CLASS_WRONG = "|cFFFF0000ViviGlow:|r This addon is for Monks only",
    TALENT_MISSING = "|cFFFFFF00ViviGlow:|r Vivacious Vivification not selected - ViviGlow deactivated",
    TALENT_ACTIVE = "|cFF40D19EViviGlow:|r Active - Vivacious Vivification detected",
    BUTTON_MISSING = "|cFFFFFF00ViviGlow:|r Vivify not found on action bars - Add Vivify spell to enable glow effect",
    DEBUG_ON = "|cFF40D19EViviGlow Debug:|r Enabled",
    DEBUG_OFF = "|cFF40D19EViviGlow Debug:|r Disabled"
}

-- Initialize saved variables
local function InitializeSavedVars()
    ViviGlowDB = ViviGlowDB or { debug = false }
    VIVIGLOW.DEBUG = ViviGlowDB.debug
end

-- Debug command registration (keeping existing implementation)
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
        -- Clean up all glow effects and counters when talent is not active
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
    
    local shouldGlow = self:HasVivaBuff()
    
    -- Get precise buff timing for counter
    local auraData = C_UnitAuras.GetPlayerAuraBySpellID(VIVIGLOW.SPELLS.VIVACIOUS_BUFF)
    local remainingTime = auraData and math.floor(auraData.expirationTime - GetTime()) or 0
    
    for _, button in ipairs(vivifyButtons) do
        -- Update glow effect
        self.BlizzardGlow:UpdateVivifyGlow(button, shouldGlow)
        
        -- Update counter with precise buff timing
        if shouldGlow and (not button.viviCounter or remainingTime >= 9) then
            self.ButtonCounter:StartCounter(button, {
                duration = remainingTime,
                countDown = true,
                continueCounting = true,  -- Enable continuous counting
                spellID = VIVIGLOW.SPELLS.VIVACIOUS_BUFF  -- Pass spell ID for cooldown tracking
            })
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
 