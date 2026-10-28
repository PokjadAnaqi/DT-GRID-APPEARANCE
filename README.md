# DT Grid Appearance

Character customization and clothing integration for DELTA HORIZON, based on illenium-appearance. Includes the appearance editor, clothing shops, outfits, framework adapters and compiled NUI assets.

## Runtime resource name

Install this resource as `illenium-appearance`. Existing exports, framework events and DT Grid Inventory integrations use that name.

## Requirements and setup

Use ox_lib, oxmysql, DT Grid Inventory and your configured supported framework. Start inventory before appearance. Preserve server-specific settings in `shared/config.lua` and apply the SQL files required by your framework.

DTlib and DELTAsec are distributed separately. Check their current releases, including beta releases, when preparing an update. Integration targets are recorded in fxmanifest metadata; changelogs belong in GitHub Releases.

## Clothing persistence

Confirmed clothing-shop changes synchronize with inventory equipment and the persistent Clothing Holder. Equipment wear/unequip changes save the resulting appearance without entering the shop-purchase reconciliation path again.

After a full appearance is applied to the actual player ped, the resource emits `illenium-appearance:client:appearanceApplied`. Inventory then restores equipped clothing, including when a skin is loaded onto an unchanged ped handle. Logout invalidates pending skin loads and reverse-save callbacks.

Keep existing ZSX multicharacter permit/HUD workers. No clothing purchase or skin-save calls need to be added to those workers for this integration.

## Configuration

`shared/config.lua` controls shops, framework integration and DT Grid clothing synchronization. Earpieces configured as appearance-only props remain outside physical clothing items. Keep item metadata and the paired inventory clothing slot definitions intact when merging settings.

## Installation

Download the full release asset, back up the resource/database, merge your configuration, replace the `illenium-appearance` folder and reconnect test players. The full asset contains compiled UI and editable UI source; it excludes node_modules and nested ZIP archives.

## Development

The editable Vue interface is in `web/src`; the runtime loads `web/dist`. Install dependencies and run the build script from `web/package.json` when changing UI source.

Validate character creation, paid clothing, outfits, reconnect, character swap and reloadskin in your actual FiveM environment. Preserve framework authorization and payment handling.

## License

See LICENSE and retain original illenium-appearance attribution.
