# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2024-01-09
### Added
- Button counter feature for Vivacious Vivification buff
- Continuous cooldown tracking for buff timer
- Visual countdown display on action buttons
- Modular counter system with configurable parameters
- Synchronized counter with actual buff duration
- Optimized font display with clean outline
- Centered bottom positioning for counter text

## [1.0.2] - 2024-01-09
### Added
- Debug state persistence between sessions
- New `/vgd status` command for comprehensive addon state information
- Improved debug command feedback messages

### Changed
- Standardized message formatting
- Enhanced debug command structure
- Updated documentation for debug features

## [1.0.1] - 2024-01-09
### Changed
- Updated to use `IsPlayerSpell` for more reliable talent detection
- Improved specialization change handling
- Enhanced frame strata management following Blizzard best practices

### Fixed
- Talent detection reliability across specialization changes
- Glow effect persistence when changing specializations
- Button tracking during talent and specialization updates

## [1.0.0] - 2024-12-20
### Added
- Initial release: WoW addon for Monks providing actionbar visual feedback of Vivacious Vivification to maximize use
- Blizzard-style glow animation system
- Customizable animation settings in constants.lua
- Dynamic border sizing and positioning
- Configurable color and offset options

### Changed
- Optimized glow effect for stability
- Improved animation smoothness

### Fixed
- Border sizing issues
- Mouseover stability
- Animation consistency