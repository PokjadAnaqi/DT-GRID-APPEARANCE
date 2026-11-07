# DT GRID APPEARANCE — Streamed tattoo pack integration (Beta 4 development)

A custom tattoo is only visible on a real FiveM ped after a valid ped decoration pack
(.ytd textures + PedDecorationCollection XML) is **built, installed and loaded**.
This feature supports GTAX-generated packs and packs built in Atelier or another compatible editor.
Nothing from third-party projects is copied into DT GRID APPEARANCE.

## Requirements

- The Beta 4 appearance development branch
- GTA freemode male/female tattoo pack built and installed as its own resource
- server console or ACE `dtgrid.tattoos.admin`
- GTA asset download/reconnect after the resource is installed
- For GTAX pack building: Node 20+, a private GTAX API key, and network access
- The GTAX API is an **external service**. Artwork is sent to it only when an administrator runs the CLI.
  No API key is stored in NUI, the FiveM resource or GitHub.

## Workflow

1. In the Tattoo Studio UI, create an image/text draft and save it in the library (free test draft).
2. From the server console: `dtgridtattoo:export 12`.
   This creates `tattoo_exports/tattoo_12.json` within this resource.
3. Position the tattoo **on the actual 3D freemode ped** in a tattoo authoring tool.
   The Beta 3 X/Y guide is **not** GTA UV placement! Do not use the sliders as UV coordinates.
   For GTAX, use its editor or API's `pick` endpoint to obtain verified per-sex placement files.
4. Option A: use Atelier to build a streamable tattoo pack offline. Respect its noncommercial license.
   Option B: generate a GTAX pack with the included *original* Node CLI:
   ```bash
   GTAX_API_KEY=YOUR_PRIVATE_KEY node tools/build-custom-tattoo.mjs \
     --source tattoo_exports/tattoo_12.json \
     --male tools/tattoo-placement.sample.json \
     --female tools/tattoo-placement.sample.json \
     --output tattoo_exports/tattoo_12.zip
   ```
   Sample placement is a format example **only**, not validated for your desired location.
   Use distinct male and female positions where required.
5. Inspect the ZIP, extract the full tattoo pack into FiveM resources.
   Its fxmanifest must register `PED_OVERLAY_FILE`; its stream folder must contain the YTD(s).
6. Add an explicit collection-to-resource mapping in `shared/custom_tattoos.lua`:
   ```lua
   StreamedCollections = {
       ['your_collection_overlays'] = 'your_tattoo_resource'
   },
   ```
7. Restart the server, ensure the tattoo resource starts *before* `illenium-appearance`,
   and reconnect clients so the new texture is downloaded.
8. Read the generated collection and the exact male/female `nameHash` fields from the pack.
   Register (server console or authorized admin):
   ```
   dtgridtattoo:register 12 your_collection_overlays YOUR_HASH_M YOUR_HASH_F
   ```
9. Relaunch tattoo studio. A mapped approved draft can be tested on the ped for free while
   `PurchaseEnabled = false`. Appearance Save persists the tattoo like the standard catalog.

## Limitations and security

- **NOT LIVE:** no hot-loading newly generated YTDs while connected.
- No automatic server-side execution or installation of external ZIPs.
- `PurchaseEnabled = false` is the safe default; no 300 DTC is deducted in this development build.
- Pack existence and client texture download are not guaranteed by the DB status; verify live in FiveM.
- Use private keys only; the CLI never forwards player identifiers.
- The stored image export contains the player's artwork; do not publicly publish tattoo_exports.
- Existing GTA tattoo catalog and clothing item synchronization are unchanged.
- For in-game admin usage: `add_ace group.admin dtgrid.tattoos.admin allow` in permissions.cfg.

Sources:
- https://github.com/gtax-dev/gtav-tattoo-editor (GPL reference; API contract only)
- https://github.com/grandTheftAtelier/atelier (PolyForm Noncommercial; external authoring tool)
- https://docs.fivem.net/docs/game-references/data-files/
