# DT GRID APPEARANCE — BETA 1

> **v1.0.0-beta.1** — fresh DT GRID APPEARANCE release, using the DT GRID integration 1.0.5.94 sync-fix build and illenium-appearance v5.7.0.
>
> A complete UI/UX redesign of [illenium-appearance](https://github.com/iLLeniumStudios/illenium-appearance).  
> Drop-in replacement — no export changes, no migration needed.

---

## Preview

Preview assets are included in `web/dist` and `web/public`.

---

## What's New

### ⭐ Favorites System
Bookmark any model and filter your list to only what you love. No more scrolling through hundreds of items.

### ⚡ Pre-load System
Hit the pre-load button and the system cycles through every model automatically — zero manual work, buttery smooth browsing after.

### 💡 Lighting Studio
A fully featured in-game lighting panel. Point a light at your character and control every parameter — angle, intensity, color, range.

### 👕 Wardrobe System
Save outfits, switch between them live, and save new ones — all without closing the menu. Your wardrobe, your workflow.

### 📷 Smart Zone Camera
Click Head, Torso, Legs, or Feet — the camera snaps to that zone with freecam + zoom. Inspect every detail exactly how you want.

### 🎨 Adaptive Shop Theme
The UI theme changes automatically based on Shopping Type — every store feels different, every interaction feels intentional.

---

## Installation

1. Remove your existing `illenium-appearance` folder
2. Clone or download this repository
3. Rename the folder to `illenium-appearance`
4. Add `ensure illenium-appearance` to your `server.cfg`
5. Done — all existing exports and events work as before

```
git clone https://github.com/PokjadAnaqi/DT-GRID-APPEARANCE illenium-appearance
```

---

## Dependencies

This DT GRID build requires `ox_inventory`, `oxmysql` and `ox_lib`. The configured framework must also be started. `lation_ui` support is configured through `shared/config.lua`.

Framework support:

- [ox_lib](https://github.com/overextended/ox_lib)
- [qb-core](https://github.com/qbcore-framework/qb-core) *(qb-core servers)*
- [es_extended](https://github.com/esx-framework/esx-legacy) *(ESX servers)*

---

## Credits

- Original script: [fivem-appearance](https://github.com/pedr0fontoura/fivem-appearance) by pedr0fontoura
- Built upon: [illenium-appearance](https://github.com/iLLeniumStudios/illenium-appearance) by iLLeniumStudios *(MIT License)*
- Redesigned & extended by: **Galaxis**

---

## License

MIT — see [LICENSE](LICENSE) for details.

## DT GRID 1.0.5.94 sync fix

- Synchronizes clothing shop purchases, saved outfits and character creation with DT Grid clothing items.
- Retries transient inventory readiness/equip failures and silences intermediate failure notifications.
- Preserves appearance-only ignored props and saves appearance when inventory clothing changes.
- Includes the current Delta UI, compiled NUI assets and editable Vue source.
- Keeps `fx_version 'cerulean'`, release version `1.0.0-beta.1`, upstream version `v5.7.0` and DT integration version `1.0.5.94`.

Install the resource as `illenium-appearance`; keep your server configuration and database backups before replacing an existing installation. The bundled `web/dist` is ready to use.
