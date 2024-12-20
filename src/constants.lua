VIVIGLOW = {
    -- Spell IDs
    SPELLS = {
        VIVACIOUS_VIVIFICATION = 388812,  -- Talent ID
        VIVACIOUS_BUFF = 392883,         -- Buff ID that makes Vivify instant
        VIVIFY = 116670,                 -- Vivify spell ID
    },
    
    -- Class info
    REQUIRED_CLASS = "MONK",
    REQUIRED_SPEC = 2,  -- Mistweaver spec ID
    
    -- Debug settings
    DEBUG = true,
    
    -- Animation settings
    ANIMATION = {
        SCALE = {
            MIN = 0.9,
            MAX = 1.1
        },
        ALPHA = {
            MIN = 0.7,
            MAX = 1.0
        },
        DURATION = 0.75,  -- Total duration for one complete pulse
        COLOR = {
            r = 0.098,  -- RGB: 25
            g = 0.969,  -- RGB: 247
            b = 0.808   -- RGB: 206
        },
        OFFSET = {
            x = 1,  -- 1px right
            y = 1   -- 1px up
        }
    }
} 