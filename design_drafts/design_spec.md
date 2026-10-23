# Loqta UI Design Specification

## Project
Loqta is a Syrian marketplace mobile application for buying, selling, and donating used items.

## Reference Source
All screen screenshots inside `design_drafts/screens/` are approved visual references from the Google Stitch project:

https://stitch.withgoogle.com/projects/10110978228001762910

Reproduce each screen as closely as possible to its corresponding screenshot.

## Brand Colors
- Primary green: #048444
- Primary text: #1E293B
- Cyan accent: #00BBD7
- Secondary green: #3A9F48

Use other colors only when they are visibly present in the approved screenshot or required for accessible error and disabled states.

## Typography
- Font family: Inter
- Match font sizes, weights, line heights, and letter spacing to the reference screenshots.
- Do not substitute a different font intentionally.

## Logo
Use the official Loqta logo supplied in `design_drafts/assets/loqta_logo.png`.
Do not redraw, recolor, or replace it with a generic icon.

## Implementation
- Flutter and Dart.
- Clean Architecture.
- BLoC only for application state.
- Existing Supabase authentication and project structure must be preserved.
- Build native Flutter widgets, not screenshots used as backgrounds.
- Reuse components only when their appearance and behavior are genuinely shared.
- Do not invent additional screens, UI elements, or product features.
- Do not modify project files while performing the initial design inspection.

## Privacy and Product Restrictions
- No GPS, maps, or distance indicators.
- No phone-based authentication.
- No payment system or delivery tracking.
- Never display an exact pickup address publicly.
- Public listings show only governorate and area.

## Screenshot Inspection
For each screenshot, record:
1. Exact visible text.
2. Main layout and element hierarchy.
3. Background and surface colors.
4. Typography and text alignment.
5. Button and input dimensions and shapes.
6. Icons, images, and logo usage.
7. Spacing, margins, and padding.
8. Any details that cannot be determined confidently.

Clearly distinguish observed details from estimates. Do not invent missing visual information.