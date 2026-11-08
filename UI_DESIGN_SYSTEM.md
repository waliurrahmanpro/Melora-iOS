# Melora — Premium AMOLED Dark Design System

---

## 1. Design Philosophy

Melora employs a **pure pitch black (#000000) AMOLED aesthetic** engineered for modern OLED and Super Retina XDR displays on iPhone. 

Key visual principles:
1. **True Pitch Black (#000000):** Every main background pixel is completely off, saving battery and creating infinite contrast.
2. **Elevated Charcoal Surfaces:** Cards, list rows, and modal sheets use layered dark charcoals (`#121212` and `#1C1C1E`) with subtle 1px border lines (`#27272A`).
3. **Restrained Accentuation:** A single vibrant accent color—Melora Electric Violet (`#8B5CF6`)—is used strategically for active playback controls, active tab indicators, and scrubbers.
4. **Zero Visual Clutter:** No gratuitous neon gradients, glassy blurs that obscure readability, or decorative fake buttons. Every element serves an audible or functional purpose.
5. **Touch Accessibility:** Every interactive button adheres to Apple's Human Interface Guidelines with a minimum 44×44 pt touch target and VoiceOver accessibility labels.

---

## 2. Color Palette ([`MeloraColors.swift`](file:///e:/Downloads/app/MeloraUI/Sources/MeloraUI/DesignSystem/MeloraColors.swift))

| Name | Hex / RGB | Usage |
| :--- | :--- | :--- |
| `amoledBlack` | `#000000` | Fullscreen background surface |
| `darkCard` | `#121212` | Base card and list row background |
| `cardElevated` | `#1C1C1E` | Floating mini player, modal sheets, pill backgrounds |
| `cardBorder` | `#27272A` | 1 pt subtle structural borders |
| `accent` | `#8B5CF6` | Primary active accent (sliders, active icons, play button) |
| `accentSubtle` | `#8B5CF6 (18%)` | Badges, lossless codec tags |
| `textPrimary` | `#FFFFFF` | High-contrast track titles, headers |
| `textSecondary`| `#A1A1AA` | Artist names, album titles, secondary captions |
| `textTertiary` | `#71717A` | Elapsed time indicators, dot dividers, timestamps |
| `spotifyGreen` | `#1DB954` | Official Spotify connection state indicator |
| `success` | `#10B981` | Successful import confirmations |
| `danger` | `#EF4444` | Track deletion, destructive alerts, favorites heart |

---

## 3. Typography Scale ([`MeloraTypography.swift`](file:///e:/Downloads/app/MeloraUI/Sources/MeloraUI/DesignSystem/MeloraTypography.swift))

| Style | Specs | Usage |
| :--- | :--- | :--- |
| `heroTitle` | 28 pt, Bold, Rounded | Now Playing track title, Home greeting |
| `screenTitle` | 22 pt, Bold | Large navigation bar titles |
| `sectionHeader` | 18 pt, Semibold | Dashboard section headers ("Recently Added") |
| `itemTitle` | 16 pt, Semibold | Card titles, playlist names |
| `bodyBold` | 15 pt, Semibold | Track list row primary title |
| `bodyRegular` | 15 pt, Regular | Settings items, descriptions |
| `caption` | 13 pt, Regular | Artist subtitles, durations, file sizes |
| `captionMedium` | 13 pt, Medium | Pill badges, sort menus |
| `badge` | 11 pt, Bold, Rounded | Lossless audio format tags (FLAC, ALAC, WAV) |
| `timeIndicator` | 12 pt, Medium, Monospaced | Scrubber timestamps ("2:45 / 4:12") |

---

## 4. Spacing & Dimensions ([`MeloraSpacing.swift`](file:///e:/Downloads/app/MeloraUI/Sources/MeloraUI/DesignSystem/MeloraSpacing.swift))

```
xs (4pt)   sm (8pt)   md (12pt)   lg (16pt)   xl (20pt)   xxl (24pt)   xxxl (32pt)   huge (48pt)
```

- **Corner Radii:**
  - `radiusSmall` (8 pt): Mini player thumbnails, format badges.
  - `radiusMedium` (12 pt): List row artwork, search input field.
  - `radiusCard` (16 pt): Standard cards, mini player bar.
  - `radiusLarge` (20 pt): Hero Now Playing artwork cover.
  - `radiusPill` (999 pt): Category selector chips, play buttons.
- **Touch Target:** Minimum 44×44 pt touch target enforced across all icon buttons.

---

## 5. Reusable Components ([`MeloraComponents.swift`](file:///e:/Downloads/app/MeloraUI/Sources/MeloraUI/DesignSystem/MeloraComponents.swift))

- **`MeloraArtworkImage`**: Square container with corner radii, supporting both local sandboxed artwork files and remote Spotify preview images, with graceful music note fallback.
- **`MeloraFormatBadge`**: Pill tag indicating codec (`FLAC`, `ALAC`, `MP3`, `WAV`, `AAC`) with accent tint for lossless formats.
- **`MeloraIconButton`**: Accessible button with custom icon, color, minimum touch target, and VoiceOver labels.
- **`MeloraTrackRow`**: High-performance row for songs with artwork, title, artist, format badge, duration, and tap-to-play gesture.
- **`MeloraEmptyState`**: Centered iconography, title, explanation, and action button.
