local addonName, ViviGlow = ...

local DefaultGlow = {}

function DefaultGlow:UpdateVivifyGlow(button, shouldGlow)
    -- Remove any existing glow first
    ActionButton_HideOverlayGlow(button)
    
    if shouldGlow then
        ActionButton_ShowOverlayGlow(button)
        -- Protect the overlay from mouseover interference
        if button.overlay then
            -- Store the original frame level if we haven't already
            if not button.overlay.originalFrameLevel then
                button.overlay.originalFrameLevel = button.overlay:GetFrameLevel()
            end
            -- Set to a higher frame level
            button.overlay:SetFrameLevel(100)
        end
    else
        -- Restore original frame level if it exists
        if button.overlay and button.overlay.originalFrameLevel then
            button.overlay:SetFrameLevel(button.overlay.originalFrameLevel)
        end
        ActionButton_HideOverlayGlow(button)
    end
end

ViviGlow.DefaultGlow = DefaultGlow 