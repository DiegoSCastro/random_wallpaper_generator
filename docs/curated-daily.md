# Curated Daily Wallpaper (DEFERRED — post-MVP)

> Status: documented but not implemented. Revisit after first 1k installs.

## Concept

A "wallpaper of the day" curated by the app team, served from the cloud. Every user sees the same wallpaper on the same day. Creates a community conversation ("what's your wallpaper today?") and a daily open reason via push notification.

## Why deferred

- Requires backend (Cloudflare Worker + R2, ~$5/mo) — operational cost
- Requires push notification infrastructure (FCM free)
- Requires social/community angle to justify the dev cost
- MVP must prove the *core* loop first (infinite generation, apply, save)

## Implementation when ready

1. Cloudflare Worker with cron trigger at 00:00 UTC
2. Worker generates 1 PNG (1440x3200) using one of the dynamical systems + curated seed
3. PNG stored in R2 bucket at `daily/YYYY-MM-DD.png`
4. App on open checks `https://<worker>/today.json` for the date + URL
5. If newer than local cache, downloads and offers to apply
6. Push notification at 08:00 local: "Today's wallpaper is ready ✨"
7. Pro tier gets: (a) the curated daily, (b) access to past 365 days archive

## Cost estimate

- Worker free tier: 100k req/day (we use 1k-10k)
- R2 storage: 365 PNGs * 500KB = ~180MB, free tier covers 10GB
- Total: **$0/mo** at MVP scale, **$1-5/mo** at 100k MAU

## Open questions for Diego (when we get here)

- Push timing: 08:00 local? Configurable per user?
- Archive access: 30 / 90 / 365 days for Pro?
- Notification copy: "Daily wallpaper" vs "Strange day #N" branding?

## Alternative (simpler)

If backend is too much, we can fake "curated daily" by having the app *deterministically* compute the same wallpaper on the same date using a date-seeded generator (no server, no network). 80% of the community effect with 0% of the backend. Worth doing instead if Cloudflare Worker setup is too much friction.
