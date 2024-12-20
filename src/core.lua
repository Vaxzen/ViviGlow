local addonName, ViviGlow = ...

-- Create our main frame and register for events
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

-- Cache frequently used values
local hasInitialized = false
local vivifyButtons = {}
local isTracking = false
local hasTalent = false
local lastBuffStatus = nil  -- Track previous buff state

-- Add debug function
function ViviGlow:Debug(message)
    if VIVIGLOW.DEBUG then
        print("|cFF40D19EViviGlow:|r", message)
    end
end

-- Helper function to check if talent is selected
function ViviGlow:HasVivaciousTalent()
    self:Debug("=== Talent Check Start ===")
    
    -- Try multiple detection methods
    local methods = {
        ["IsSpellKnown"] = function() return IsSpellKnown(VIVIGLOW.SPELLS.VIVACIOUS_VIVIFICATION) end,
        ["FindSpellOverrideByID"] = function() return FindSpellOverrideByID(VIVIGLOW.SPELLS.VIVACIOUS_VIVIFICATION) ~= nil end,
        ["IsPlayerSpell"] = function() return IsPlayerSpell(VIVIGLOW.SPELLS.VIVACIOUS_VIVIFICATION) end
    }
    
    for methodName, checkFunction in pairs(methods) do
        local result = checkFunction()
        self:Debug(methodName .. " result: " .. tostring(result))
        if result then
            hasTalent = true
            break
        end
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
    wipe(vivifyButtons)
    local buttonCount = 0
    
    self:Debug("=== Scanning Action Bars for Vivify ===")
    
    for i = 1, 180 do
        local buttonTypes = {
            ["ActionButton"] = _G["ActionButton"..i],
            ["MultiBarBottomLeft"] = _G["MultiBarBottomLeftButton"..i],
            ["MultiBarBottomRight"] = _G["MultiBarBottomRightButton"..i],
            ["MultiBarRight"] = _G["MultiBarRightButton"..i],
            ["MultiBarLeft"] = _G["MultiBarLeftButton"..i]
        }
        
        for buttonType, button in pairs(buttonTypes) do
            if button then
                local actionType, id = GetActionInfo(button.action)
                
                -- Only debug when we find Vivify
                if actionType == "spell" and id == VIVIGLOW.SPELLS.VIVIFY then
                    table.insert(vivifyButtons, button)
                    buttonCount = buttonCount + 1
                    self:Debug(string.format("Found Vivify on %s%d", buttonType, i))
                end
            end
        end
    end
    
    -- Single summary message at the end
    if buttonCount > 0 then
        self:Debug(string.format("Found %d Vivify button%s", 
            buttonCount, buttonCount > 1 and "s" or ""))
    else
        self:Debug("No Vivify buttons found")
    end
end

function ViviGlow:Init()
    if hasInitialized then return end
    
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
    if not hasTalent then return end
    
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
        if event == "UNIT_AURA" and hasTalent then
            local unit = ...
            if unit == "player" then
                -- Only update if it's a player aura
                ViviGlow:UpdateVivifyGlow()
            end
        elseif event == "PLAYER_TALENT_UPDATE" then
            hasTalent = ViviGlow:HasVivaciousTalent()
            lastBuffStatus = nil  -- Reset buff tracking on talent changes
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            ViviGlow:UNIT_SPELLCAST_SUCCEEDED(...)
        end
    end
end)
 