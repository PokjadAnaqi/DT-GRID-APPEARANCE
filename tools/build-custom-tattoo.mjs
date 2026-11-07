#!/usr/bin/env node
// Standalone, original GTAX Tattoo API integration. Does not bundle GTAX or Atelier code.
// Runs only on the administrator's computer or trusted server. Never expose the API key in NUI.
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { dirname, basename } from 'node:path';

const API_URL = 'https://gtax.dev/api/public/ped-tattoo/build';
const allowedZones = new Set([
  'ZONE_HEAD', 'ZONE_TORSO', 'ZONE_LEFT_ARM',
  'ZONE_RIGHT_ARM', 'ZONE_LEFT_LEG', 'ZONE_RIGHT_LEG',
]);

function option(name) {
  const index = process.argv.indexOf(name);
  return index !== -1 ? process.argv[index + 1] : undefined;
}

function checkPlacement(data, sex) {
  if (!data || !allowedZones.has(data.zone)) throw Error(`${sex}: invalid zone`);
  for (const [name, value] of [
    ['uvPos.x', data.uvPos?.x], ['uvPos.y', data.uvPos?.y],
    ['scale.x', data.scale?.x], ['scale.y', data.scale?.y],
    ['rotation', data.rotation],
  ]) {
    if (!Number.isFinite(value)) throw Error(`${sex}: invalid ${name}`);
  }
  if (data.uvPos.x < 0 || data.uvPos.x > 1 || data.uvPos.y < 0 || data.uvPos.y > 1) {
    throw Error(`${sex}: UV coordinates must be normalized`);
  }
  if (data.scale.x <= 0 || data.scale.y <= 0) throw Error(`${sex}: scale must be positive`);
  return {
    enabled: true,
    zone: data.zone,
    uvPos: { x: data.uvPos.x, y: data.uvPos.y },
    scale: { x: data.scale.x, y: data.scale.y },
    rotation: data.rotation,
    flipX: data.flipX === true,
    flipY: data.flipY === true,
  };
}

async function main() {
  const sourceFile = option('--source');
  const maleFile = option('--male');
  const femaleFile = option('--female');
  const outputFile = option('--output');
  const apiKey = process.env.GTAX_API_KEY;

  if (!sourceFile || !outputFile || (!maleFile && !femaleFile)) {
    throw Error('Usage: node tools/build-custom-tattoo.mjs --source tattoo_exports/tattoo_12.json --male male.json --female female.json --output tattoo_12.zip');
  }
  if (!apiKey) throw Error('Set GTAX_API_KEY privately on the machine running this tool.');

  const source = JSON.parse(await readFile(sourceFile, 'utf8'));
  if (!Number.isSafeInteger(source.id) || source.id < 1) throw Error('Invalid tattoo export ID');
  if (typeof source.pngBase64 !== 'string' || source.pngBase64.length > 400000) {
    throw Error('Invalid or oversized tattoo PNG');
  }
  const png = Buffer.from(source.pngBase64, 'base64');
  if (!png.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) {
    throw Error('Invalid PNG signature');
  }
  const addonName = `dtgrid_tattoo_${source.id}`;
  const form = new FormData();
  form.append('image', new Blob([png], { type: 'image/png' }), `${addonName}.png`);
  form.append('addonName', addonName);
  form.append('format', 'fivem');
  form.append('textureSize', '512');
  if (maleFile) form.append('male', JSON.stringify(checkPlacement(
    JSON.parse(await readFile(maleFile, 'utf8')), 'male')));
  if (femaleFile) form.append('female', JSON.stringify(checkPlacement(
    JSON.parse(await readFile(femaleFile, 'utf8')), 'female')));

  const response = await fetch(API_URL, {
    method: 'POST',
    headers: { authorization: `Bearer ${apiKey}` },
    body: form,
    signal: AbortSignal.timeout(120000),
  });

  if (!response.ok) {
    const error = (await response.text()).slice(0, 1000);
    throw Error(`GTAX build rejected (${response.status}): ${error}`);
  }
  const mime = response.headers.get('content-type') || '';
  if (!/zip|octet-stream/i.test(mime)) {
    throw Error(`Unexpected GTAX package content-type: ${mime}`);
  }
  const archive = Buffer.from(await response.arrayBuffer());
  if (archive.length > 30 * 1024 * 1024 || archive.length < 100) {
    throw Error('Unexpected package size');
  }
  if (archive.subarray(0, 2).toString('utf8') !== 'PK') {
    throw Error('Response is not a ZIP archive');
  }
  await mkdir(dirname(outputFile), { recursive: true });
  await writeFile(outputFile, archive);
  console.log(`Tattoo #${source.id}: saved ${basename(outputFile)} (${archive.length} bytes)`);
  console.log('Inspect generated pack metadata/overlay hashes, then install and restart the FiveM server.');
  console.log('Only then register the tattoo using dtgridtattoo:register; reconnect to test.');
}

main().catch((error) => {
  console.error('[DT GRID APPEARANCE]', error.message);
  process.exitCode = 1;
});
