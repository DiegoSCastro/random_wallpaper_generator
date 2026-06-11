# Product Decision Memo — Random Wallpaper Generator

**Author:** Hermes Agent (with Diego)
**Date:** 2026-06-10
**Status:** MVP approved. Build underway.

## Product

Android app that generates infinite procedural wallpapers from dynamical systems (Lorenz, Clifford, Hopalong, Aizawa, Rossler). User taps "Generate" → sees a fresh mathematical pattern in <500ms → can save to gallery or apply as lock/home wallpaper.

## Target user

Android user 18-35 who likes:
- Minimalist or mathematical aesthetics
- Tinkering with parameters (parameters visible: σ, ρ, β for Lorenz)
- Sharing visually unique content on Instagram / X

## Positioning

- **vs Tapet** (4.0★, 1M+ downloads): Tapet has a huge catalog of generic patterns. We are *intentionally small + mathematical* — the user knows exactly what generated their wallpaper.
- **vs Zedge / Walli / Backdrops** (4.5-4.7★): They sell photos. We sell math.
- **vs AI wallpaper apps** (Realtime, Imagine): They cost $$$. We are offline + free.

## Monetization (post-MVP)

- **Free tier**: AdMob banner on home, interstitial every 5 "Apply". 5 systems (Lorenz, Clifford, Hopalong, Aizawa, Rossler). 1080p export.
- **Pro tier** (R$ 14.90/mo, R$ 79.90/yr via RevenueCat): No ads, +10 systems, 4K export, palette customization, batch export.

## Visual identity

- **Liquid glass** neutral: translucent surfaces, soft blur, very low saturation chrome so wallpaper is the hero.
- No emoji in UI.
- Type: system font (San Francisco on iOS, Roboto on Android).
- Accent color: a single neutral that shifts based on currently displayed wallpaper (auto-extracted dominant color).

## Out of scope for MVP

- Curated daily wallpaper (documented in `curated-daily.md`, deferred)
- iOS
- Live wallpaper (Android `WallpaperService`)
- Cloud sync / community gallery
- Account system
- Custom formulas (user-defined)
- Wallpaper packs marketplace

## Success metric

- 1,000 installs in first 30 days post-publish
- 3% Pro conversion at end of month 1
- 4.5+ star rating

## Risk register

| Risk | Likelihood | Mitigation |
|---|---|---|
| Google Play policy rejects "wallpaper" category if app doesn't setWallpaper | Medium | Set home + lock screen from day 1; declare use of `setWallpaper` permission |
| Shaders crash on low-end devices | Medium | Provide "low quality" preset; auto-detect GPU |
| AdMob CTR too low | Low | Interstitial only on Apply, not on Generate |
| Competitor copies the angle | Low | 12-month head start; visual identity is the moat |
