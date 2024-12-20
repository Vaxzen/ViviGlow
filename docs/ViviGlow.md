# ViviGlow - WoW Addon Documentation

## Overview
ViviGlow is a WoW addon for Monks providing actionbar visual feedback of Vivacious Vivification to maximize use.

## Current Features

### Core Functionality
- Monitors Vivacious Vivification buff state
- Applies glow effect to Vivify buttons when proc is active
- Automatically detects Mistweaver spec and talent selection

### Animation System
- Custom Blizzard-style border glow
- Smooth pulse animation with configurable:
  - Scale range (MIN/MAX)
  - Alpha range (MIN/MAX)
  - Duration
  - Position offset
- Turquoise color theme
- Stable mouseover behavior
- Dynamic border sizing (15px Blizzard standard)

## Specifications

### Addon Details
- **Name**: ViviGlow
- **Version**: @project-version@
- **WoW Interface Version**: 110007
- **Dependencies**: None

### Requirements
- **Class**: Monk
- **Specialization**: Mistweaver
- **Talent**: Vivacious Vivification

### Spell Details
```lua
Vivacious Vivification (Spell ID: 388812)
Type: Passive Talent
Description: Your Renewing Mist has a chance to make your next Vivify free 
            and heal for 20% more.
```

## Project Structure

### Directory Layout
```
ViviGlow/
├── src/
│   ├── animations/
│   │   ├── blizzardGlow.lua  - Current primary animation system
│   │   ├── defaultGlow.lua   - Blizzard's default glow implementation
│   │   └── customGlow.lua    - Custom animation system (archived)
│   ├── constants.lua         - Configuration and spell IDs
│   └── core.lua             - Main addon functionality
├── docs/
│   ├── images/             - Documentation images
│   ├── ViviGlow.md        - Technical documentation
│   ├── CHANGELOG.md       - Version history and changes
│   ├── CONTRIBUTING.md    - Contribution guidelines (to be created)
│   ├── LICENSE.md         - License information (to be created)
│   └── API.md             - API documentation (to be created)
├── .gitignore
├── README.md              - Quick start and basic info
└── ViviGlow.toc
```

### Documentation Structure
1. **README.md** (root)
   - Quick start guide
   - Basic feature overview
   - Installation instructions
   - Basic configuration

2. **ViviGlow.md** (docs/)
   - Detailed technical documentation
   - Implementation details
   - System architecture
   - Development guidelines

3. **CHANGELOG.md** (docs/)
   - Version history
   - Detailed changes
   - Migration guides

4. **Additional Documentation** (docs/)
   - API.md - Interface documentation
   - CONTRIBUTING.md - Contribution guidelines
   - LICENSE.md - License information

### Animation Systems
The addon includes three different glow implementations:
1. **BlizzardGlow** - Current primary system
   - Custom implementation based on Blizzard's style
   - Optimized for stability and performance
   - Fully configurable animations

2. **DefaultGlow** - Blizzard's native system
   - Uses ActionButton_ShowOverlayGlow
   - Preserved for reference and fallback
   - Minimal customization options

3. **CustomGlow** - Archived system
   - Original custom implementation
   - Preserved for future reference
   - Full animation control

## Implementation Details

### Constants
Current animation settings in constants.lua:
```lua
ANIMATION = {
    SCALE = {
        MIN = 0.9,
        MAX = 1.1
    },
    ALPHA = {
        MIN = 0.7,
        MAX = 1.0
    },
    DURATION = 0.75,
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

SPELLS = {
    VIVACIOUS_VIVIFICATION = 388812,
    VIVACIOUS_BUFF = 392883,
    VIVIFY = 116670
}
```

### Core Systems

#### 1. Initialization System
- Class verification
- Talent verification
- Event registration
- Frame creation

#### 2. Event Management
- `PLAYER_LOGIN` - Initial setup
- `PLAYER_TALENT_UPDATE` - Talent verification
- `UNIT_AURA` - Buff tracking
- `SPELL_UPDATE_COOLDOWN` - Button state updates

#### 3. Buff Detection System
- Monitor Vivacious Vivification proc state
- Track buff duration
- Handle buff removal

#### 4. Visual Feedback System
- Locate Vivify action button
- Manage glow effect states
- Handle visual updates

## Error Handling

### Validation Checks
1. **Class Validation**
   - Verify Monk class on load
   - Disable functionality for non-Monks

2. **Talent Validation**
   - Check Vivacious Vivification talent selection
   - Monitor talent changes

3. **Runtime Protection**
   - Nil checks for spell IDs
   - Button existence verification
   - Event registration validation

## Performance Considerations

### Optimization Strategies
1. **Event Management**
   - Register events only when needed
   - Unregister inactive events
   - Implement event throttling

2. **Memory Usage**
   - Local variable usage
   - Table recycling
   - Minimal global namespace impact

3. **Processing Efficiency**
   - Cache frequently accessed data
   - Minimize redundant calculations
   - Batch visual updates

## Testing Protocol

### Functional Testing
1. **Basic Operations**
   - Addon initialization
   - Event registration
   - Buff detection accuracy
   - Visual feedback timing

2. **State Changes**
   - Talent changes
   - Spec swapping
   - UI reloading
   - Combat transitions

### Edge Cases
1. **Error Conditions**
   - Invalid spell IDs
   - Missing buttons
   - Talent respec
   - Load order conflicts

2. **Environmental Factors**
   - Instance transitions
   - Loading screen handling
   - Combat lockouts
   - UI scale changes

## ToDo List

### Features
- [x] Implement basic glow effect
- [x] Add custom animation system
- [x] Add color customization
- [x] Add position offset support
- [x] Implement stable mouseover behavior
- [ ] Add in-game configuration panel
- [ ] Save user preferences between sessions
- [ ] Add color presets
- [ ] Add multiple animation style options
- [ ] Support for different button types (ElvUI, Bartender, etc.)

### Technical Improvements
- [x] Implement Blizzard-style glow system
- [x] Fix border sizing issues
- [x] Optimize animation performance
- [x] Implement proper frame level handling
- [ ] Add performance monitoring
- [ ] Add comprehensive error handling
- [ ] Add debug logging system
- [ ] Add addon compatibility checks

### Documentation
- [x] Create basic README
- [x] Document current features
- [x] Create CHANGELOG
- [x] Document animation settings
- [x] Create technical documentation
- [ ] Add installation images
- [ ] Create configuration guide
- [ ] Document API for potential extensions
- [ ] Add contributing guidelines

### Testing
- [x] Test basic functionality
- [x] Test mouseover behavior
- [x] Test animation system
- [ ] Create test suite
- [ ] Add compatibility testing for popular UI addons
- [ ] Add performance benchmarks
- [ ] Document testing procedures

## Contributing

Currently in initial development. Contribution guidelines coming soon.

## References
- [WoW API Documentation](https://wowpedia.fandom.com/wiki/World_of_Warcraft_API)
- [Vivacious Vivification Spell Data](https://www.wowhead.com/spell=388812/vivacious-vivification)

## Version History

See [docs/CHANGELOG.md](CHANGELOG.md) for version history and changes.
