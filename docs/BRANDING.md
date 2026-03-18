# SixtyFour — Branding & Design System

![Design Overview](design-full.png)

## Color Palette

| Name        | Hex       | Usage                              |
|-------------|-----------|-------------------------------------|
| Void        | `#060607` | Deepest background                  |
| Surface 1   | `#0D0D0F` | Tab bar base                        |
| Surface 2   | `#131316` | Page background                     |
| Surface 3   | `#1A1A1F` | Cards, tiles                        |
| Surface 4   | `#222228` | Stepper buttons, secondary elements |
| Surface 5   | `#2B2B33` | Progress bar track                  |
| Surface 6   | `#35353F` | Sparkline inactive bars             |
| Ivory       | `#ECE8DF` | Primary text                        |
| Ivory 2     | `#9E9A91` | Secondary text, headings            |
| Ivory 3     | `#555049` | Tertiary text, labels               |
| Amber       | `#F5A623` | Primary accent, rings, highlights   |
| Amber 2     | `#C97D10` | Gradient end, secondary amber       |
| Green       | `#2ECC71` | Success, solved, accuracy ring      |
| Red         | `#E74C3C` | Error, failed, failed ring          |
| Blue        | `#5B9CF6` | Info accent                         |
| Border      | `#FFFFFF` @ 6% | Card/tile borders                |
| Border Amber| `#F5A623` @ 28% | Amber-tinted borders (streak badge) |

## Typography

- **App title**: System 27pt bold, kerning 3 — "SIXTY" (ivory) + "FOUR" (amber)
- **Hero rating**: System 48pt bold, kerning 1
- **Section headers**: System 9pt monospaced, kerning 2, amber
- **Card labels**: System 12pt medium, ivory
- **Stat values**: System 29pt bold (dashboard tiles), 20pt bold (widget)
- **Stat labels**: System 8-9pt monospaced, kerning 1.3, ivory 3
- **Monospaced accents**: Used throughout for data, counts, ratings

## Iconography

- **System icons**: SF Symbols — `target`, `checkmark.circle`, `xmark.circle`, `flame`, `bell`, `person`, `arrow.clockwise`, `chess.pawn.fill`
- **Knight silhouette**: Custom SVG in widget assets, rendered as template image at low opacity (7-8% white) for background decoration
- **App icon**: Chess knight silhouette with "64" — amber 6 on dark background, white 4

## Widget Design

### Small Widget
- Single activity ring (amber), 78pt, lineWidth 7
- Center: remaining count (38pt bold amber) + "LEFT" label (9pt amber @ 70%)
- Footer: solved/target count + rating with arrow
- Knight silhouette centered at 8% white opacity
- Background: Surface 2 (`#131316`)

### Medium Widget
- Three concentric activity rings:
  - Outer (120pt): Target progress — amber
  - Middle (98pt): Accuracy — green
  - Inner (78pt): Failed ratio — red
- Center of rings: rating (22pt bold) + "RATING" label
- Right side: stat rows (LEFT/PASSED/FAILED) with colored dots, 20pt bold values
- Header: "SIXTYFOUR" in amber @ 75%
- Footer: "+N today" delta in green
- Knight silhouette right-aligned at 7% white opacity

## App Screens

### Onboarding
- Centered layout, app title at top
- Chess.com username input field
- "CONNECT" button in amber
- "No password required" note with lock icon

### Dashboard
- App bar: title + refresh button + avatar (initials in amber gradient circle)
- Hero card: puzzle rating with sparkline bars, amber glow, knight watermark
- Three stat tiles: LEFT (amber), PASSED (green), FAILED (red) with glow effects
- Progress bar: amber gradient fill with shadow
- Streak badge: flame icon in amber capsule

### History
- 30-day daily breakdown
- Each row: date, solved (green), failed (red), accuracy %, rating
- Summary tiles for period totals

### Settings
- Sections: Account, Daily Target, Notifications
- Stepper with typeable number input (1-999)
- Toggle for daily reminder (7 PM)
- Sign out button in red

## Tab Bar

- Glass effect: `.ultraThinMaterial` + dark overlay (Surface 1 @ 60%)
- Top edge: white hairline at 8% opacity
- Icons: `house` / `clock` / `gearshape` — amber when active, ivory 3 when inactive
- Extends to bottom safe area
