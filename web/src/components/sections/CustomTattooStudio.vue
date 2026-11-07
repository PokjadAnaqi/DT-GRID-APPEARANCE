<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { fetchNui } from '@/utils/nui'
import { useAppearanceStore } from '@/stores/appearance'
import type { TattooItem, TattooZone } from '@/types'

type TattooKind = 'image' | 'text'
type TattooZoneOption = { value: TattooZone; label: string }
type SavedTattoo = {
  id: number
  kind: TattooKind
  label: string
  thumbnail: string
  zone: TattooZone
  renderStatus: 'pending' | 'ready'
  paid: boolean
}
type LibraryResponse = {
  ok: boolean
  reason?: string
  library?: SavedTattoo[]
  price?: number
  purchaseEnabled?: boolean
  maxDesigns?: number
}
type PurchaseResponse = { ok: boolean; reason?: string; id?: number; price?: number }
type ReadyResponse = { ok: boolean; reason?: string; tattoo?: TattooItem }

const zones: TattooZoneOption[] = [
  { value: 'ZONE_TORSO', label: 'Torso / Back' },
  { value: 'ZONE_HEAD', label: 'Head / Neck' },
  { value: 'ZONE_LEFT_ARM', label: 'Left Arm' },
  { value: 'ZONE_RIGHT_ARM', label: 'Right Arm' },
  { value: 'ZONE_LEFT_LEG', label: 'Left Leg' },
  { value: 'ZONE_RIGHT_LEG', label: 'Right Leg' },
]
const fonts = ['Space Grotesk', 'Impact', 'Georgia', 'Courier New', 'Arial']
const store = useAppearanceStore()
const view = ref<'editor' | 'library'>('editor')
const kind = ref<TattooKind>('text')
const name = ref('Custom Tattoo')
const lettering = ref('SURVIVOR')
const imageUrl = ref('')
const artwork = ref('')
const thumbnail = ref('')
const message = ref('')
const error = ref('')
const loading = ref(false)
const saving = ref(false)
const confirmPurchase = ref(false)
const confirmActivationId = ref<number | null>(null)
const library = ref<SavedTattoo[]>([])
const purchaseEnabled = ref(false)
const price = ref(300)
const maxDesigns = ref(20)
const imageInput = ref<HTMLInputElement | null>(null)

const editor = reactive({
  zone: 'ZONE_TORSO' as TattooZone,
  x: 0.5,
  y: 0.5,
  scale: 0.32,
  rotation: 0,
  opacity: 0.9,
  font: 'Space Grotesk',
  fontSize: 64,
  color: '#171717'
})

const previewStyle = computed(() => ({
  left: `${editor.x * 100}%`,
  top: `${editor.y * 100}%`,
  width: `${editor.scale * 100}%`,
  opacity: editor.opacity,
  transform: `translate(-50%, -50%) rotate(${editor.rotation}deg)`,
}))

function resetAlerts() {
  confirmPurchase.value = false
  error.value = ''
  message.value = ''
}

function setMode(next: TattooKind) {
  resetAlerts()
  kind.value = next
  artwork.value = ''
  thumbnail.value = ''
  if (next === 'text') renderText()
}

function makeCanvas(size: number): HTMLCanvasElement {
  const canvas = document.createElement('canvas')
  canvas.width = size
  canvas.height = size
  return canvas
}

function makeThumb(source: HTMLCanvasElement): string {
  const thumb = makeCanvas(112)
  const ctx = thumb.getContext('2d')
  if (!ctx) throw new Error('Canvas rendering unavailable')
  ctx.clearRect(0, 0, 112, 112)
  ctx.drawImage(source, 0, 0, 112, 112)
  return thumb.toDataURL('image/png')
}

function acceptCanvas(canvas: HTMLCanvasElement) {
  const image = canvas.toDataURL('image/png')
  if (image.length > 360000) throw new Error('Image is too complex; try a smaller, simpler PNG')
  artwork.value = image
  thumbnail.value = makeThumb(canvas)
  if (thumbnail.value.length > 40000) throw new Error('Preview image is too large')
}

function renderText() {
  if (kind.value !== 'text') return
  resetAlerts()
  const canvas = makeCanvas(384)
  const ctx = canvas.getContext('2d')
  if (!ctx) { error.value = 'Canvas rendering unavailable'; return }
  const value = lettering.value.trim().slice(0, 80) || ' '
  const lines = value.split('\n').slice(0, 2)
  const maxWidth = 352
  let textSize = editor.fontSize
  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'
  ctx.fillStyle = editor.color
  do {
    ctx.font = `700 ${textSize}px "${editor.font}"`
    if (lines.every((line) => ctx.measureText(line).width <= maxWidth)) break
    textSize -= 2
  } while (textSize > 16)
  lines.forEach((line, index) => {
    const y = 192 + (index - (lines.length - 1) / 2) * textSize * 1.17
    ctx.fillText(line, 192, y, maxWidth)
  })
  try { acceptCanvas(canvas) } catch (failure) { error.value = String(failure) }
}

function loadImage(source: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.onload = () => resolve(img)
    img.onerror = () => reject(new Error('Could not decode image'))
    img.src = source
  })
}

async function importBlob(blob: Blob) {
  if (blob.size > 2097152) throw new Error('Maximum original image size is 2 MB')
  const url = URL.createObjectURL(blob)
  try {
    const picture = await loadImage(url)
    if (!picture.naturalWidth || !picture.naturalHeight) throw new Error('Invalid image dimensions')
    const sizes = [384, 320, 256, 192]
    for (const size of sizes) {
      const canvas = makeCanvas(size)
      const ctx = canvas.getContext('2d')
      if (!ctx) throw new Error('Canvas rendering unavailable')
      const scale = Math.min((size - 16) / picture.naturalWidth, (size - 16) / picture.naturalHeight)
      const width = picture.naturalWidth * scale
      const height = picture.naturalHeight * scale
      ctx.drawImage(picture, (size - width) / 2, (size - height) / 2, width, height)
      try {
        acceptCanvas(canvas)
        return
      } catch {
        // Retry at a lower resolution before giving up.
      }
    }
    throw new Error('Could not compress PNG to the server payload limit')
  } finally {
    URL.revokeObjectURL(url)
  }
}

async function onChooseImage(event: Event) {
  resetAlerts()
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return
  if (file.type !== 'image/png') {
    error.value = 'Local files must be PNG'
    return
  }
  loading.value = true
  try { await importBlob(file) }
  catch (failure) { error.value = String(failure) }
  finally { loading.value = false; input.value = '' }
}

async function loadUrl() {
  resetAlerts()
  if (!/^https:\/\//i.test(imageUrl.value)) {
    error.value = 'Only direct HTTPS image URLs are supported'
    return
  }
  loading.value = true
  try {
    // Client-side only. No server-side fetching of arbitrary URLs (SSRF protection).
    const response = await fetch(imageUrl.value, { mode: 'cors', credentials: 'omit' })
    if (!response.ok) throw new Error('Image host returned an error')
    const data = await response.blob()
    if (!data.type.startsWith('image/')) throw new Error('URL is not an image')
    await importBlob(data)
  } catch {
    error.value = 'Image unavailable. The host must allow CORS and serve a direct image file.'
  } finally { loading.value = false }
}

async function refreshLibrary() {
  loading.value = true
  try {
    const result = await fetchNui<LibraryResponse>('dtgrid_tattoos_get_library')
    if (!result?.ok) throw new Error(result?.reason || 'Library unavailable')
    library.value = result.library ?? []
    price.value = result.price ?? 300
    purchaseEnabled.value = result.purchaseEnabled === true
    maxDesigns.value = result.maxDesigns ?? 20
  } catch (failure) {
    error.value = String(failure)
  } finally { loading.value = false }
}

async function saveTattoo() {
  error.value = ''
  message.value = ''
  if (saving.value) return
  if (!artwork.value || !thumbnail.value) {
    error.value = 'Add an image or text before saving.'
    return
  }
  if (purchaseEnabled.value && !confirmPurchase.value) {
    confirmPurchase.value = true
    message.value = `Press Save again to confirm the ${price.value} DTC charge.`
    return
  }
  confirmPurchase.value = false
  saving.value = true
  try {
    const result = await fetchNui<PurchaseResponse>('dtgrid_tattoos_purchase', {
      kind: kind.value,
      label: name.value,
      image: artwork.value.split(',')[1],
      thumbnail: thumbnail.value.split(',')[1],
      transform: { ...editor, text: kind.value === 'text' ? lettering.value : '' }
    })
    if (!result?.ok) throw new Error(result?.reason || 'Purchase was not completed')
    message.value = result.price ? `Design #${result.id} saved for ${result.price} DTC. Ped overlay: pending.` : `Test draft #${result.id} saved. No DTC deducted.`
    await refreshLibrary()
  } catch (failure) { error.value = String(failure) }
  finally { saving.value = false }
}

async function applySaved(item: SavedTattoo) {
  resetAlerts()
  if (item.renderStatus !== 'ready') {
    error.value = 'This design needs a streamed ped overlay before it can be worn.'
    return
  }
  try {
    const response = await fetchNui<ReadyResponse>('dtgrid_tattoos_ready', { id: item.id })
    if (!response?.ok || !response.tattoo) throw new Error(response?.reason || 'Tattoo unavailable')
    const newTattoo = response.tattoo
    const original = store.appearance?.tattoos
    if (!original) throw new Error('Character appearance not loaded')
    const zone = item.zone
    const all = { ...original } as Record<TattooZone, TattooItem[]>
    const tattoos = [...(all[zone] || [])]
    const existing = tattoos.some((tattoo) => tattoo.collection === newTattoo.collection
      && tattoo.hashMale === newTattoo.hashMale && tattoo.hashFemale === newTattoo.hashFemale)
    if (!existing) tattoos.push(newTattoo)
    all[zone] = tattoos
    store.updateTattoos(all)
    message.value = 'Tattoo preview applied. Press the main appearance Save button to persist.'
  } catch (failure) { error.value = String(failure) }
}

watch([lettering, () => editor.font, () => editor.fontSize, () => editor.color], renderText)
onMounted(() => { renderText(); refreshLibrary() })
</script>

<template>
  <section class="api69-tattoo-studio">
    <header class="api69-tattoo-head">
      <div>
        <span class="api69-eyebrow">PERSONAL INK SYSTEM</span>
        <h2>Custom Tattoo Studio</h2>
      </div>
      <span class="api69-price">{{ price }} DTC</span>
    </header>

    <div class="api69-segment">
      <button :class="{ selected: view === 'editor' }" @click="view = 'editor'">Create Design</button>
      <button :class="{ selected: view === 'library' }" @click="view = 'library'; refreshLibrary()">My Library ({{ library.length }})</button>
    </div>

    <div v-if="view === 'editor'" class="api69-editor">
      <div class="api69-segment api69-types">
        <button :class="{ selected: kind === 'text' }" @click="setMode('text')">Text Tattoo</button>
        <button :class="{ selected: kind === 'image' }" @click="setMode('image')">Image / PNG</button>
      </div>

      <label class="api69-field-label" for="api69-tattoo-label">DESIGN NAME</label>
      <input id="api69-tattoo-label" v-model="name" maxlength="64" placeholder="My custom tattoo" class="api69-input" />

      <template v-if="kind === 'text'">
        <label class="api69-field-label" for="api69-tattoo-text">TATTOO TEXT</label>
        <input id="api69-tattoo-text" v-model="lettering" maxlength="80" class="api69-input" />
        <div class="api69-grid-two">
          <label>FONT
            <select v-model="editor.font" class="api69-input">
              <option v-for="font in fonts" :key="font">{{ font }}</option>
            </select>
          </label>
          <label>INK COLOR
            <input v-model="editor.color" type="color" class="api69-input api69-color" />
          </label>
        </div>
        <label class="api69-slider">TEXT SIZE <span>{{ editor.fontSize }} px</span>
          <input v-model.number="editor.fontSize" type="range" min="16" max="128" step="2" />
        </label>
      </template>

      <template v-else>
        <input ref="imageInput" class="api69-hidden-file" type="file" accept="image/png" @change="onChooseImage" />
        <button class="api69-action-muted" @click="imageInput?.click()">Choose Local PNG (max 2 MB)</button>
        <label class="api69-field-label" for="api69-tattoo-url">OR DIRECT IMAGE URL</label>
        <div class="api69-inline">
          <input id="api69-tattoo-url" v-model="imageUrl" type="url" placeholder="https://.../tattoo.png" class="api69-input" />
          <button class="api69-action-muted" :disabled="loading" @click="loadUrl">Load</button>
        </div>
      </template>

      <label class="api69-field-label">BODY PLACEMENT (DESIGN PREVIEW)</label>
      <select v-model="editor.zone" class="api69-input">
        <option v-for="zone in zones" :key="zone.value" :value="zone.value">{{ zone.label }}</option>
      </select>
      <div class="api69-preview">
        <div class="api69-preview-body">
          <div v-if="artwork" class="api69-preview-ink" :style="previewStyle">
            <img :src="artwork" alt="Custom tattoo artwork" draggable="false" />
          </div>
          <span v-else class="api69-preview-placeholder">NO ARTWORK</span>
        </div>
        <small>2D placement guide only — not a GTA ped render</small>
      </div>

      <div class="api69-editor-sliders">
        <label class="api69-slider">POSITION X <span>{{ Math.round(editor.x * 100) }}%</span>
          <input v-model.number="editor.x" type="range" min="0" max="1" step="0.01" />
        </label>
        <label class="api69-slider">POSITION Y <span>{{ Math.round(editor.y * 100) }}%</span>
          <input v-model.number="editor.y" type="range" min="0" max="1" step="0.01" />
        </label>
        <label class="api69-slider">SIZE <span>{{ Math.round(editor.scale * 100) }}%</span>
          <input v-model.number="editor.scale" type="range" min="0.06" max="0.85" step="0.01" />
        </label>
        <label class="api69-slider">ROTATION <span>{{ editor.rotation }}°</span>
          <input v-model.number="editor.rotation" type="range" min="0" max="360" step="1" />
        </label>
        <label class="api69-slider">OPACITY <span>{{ Math.round(editor.opacity * 100) }}%</span>
          <input v-model.number="editor.opacity" type="range" min="0.1" max="1" step="0.05" />
        </label>
      </div>
      <button class="api69-action-primary" :disabled="saving || loading || !artwork" @click="saveTattoo">
        {{ saving ? 'Saving…' : confirmPurchase ? `Confirm ${price} DTC` : purchaseEnabled ? `Save to Library — ${price} DTC` : 'Save Test Draft — FREE' }}
      </button>
      <p v-if="!purchaseEnabled" class="api69-caution">Beta test mode: drafts are stored without payment and cannot appear on the ped. Paid saving will be enabled after renderer validation.</p>
    </div>

    <div v-else class="api69-library">
      <div class="api69-library-count">{{ library.length }} / {{ maxDesigns }} CUSTOM DESIGNS</div>
      <div v-if="!library.length" class="api69-empty">No purchased tattoo designs yet.</div>
      <div v-for="item in library" :key="item.id" class="api69-library-row">
        <img :src="item.thumbnail" :alt="item.label" />
        <div class="api69-library-details">
          <strong>{{ item.label }}</strong>
          <small>{{ item.zone.replace('ZONE_', '').replace(/_/g, ' ') }}</small>
          <small>{{ !item.paid ? 'Test draft — unpaid' : item.renderStatus === 'ready' ? 'Streamed overlay ready' : 'Awaiting streamed overlay' }}</small>
        </div>
        <button :disabled="!item.paid || item.renderStatus !== 'ready'" @click="applySaved(item)">Use</button>
      </div>
    </div>

    <p v-if="error" role="alert" class="api69-error">{{ error }}</p>
    <p v-if="message" role="status" class="api69-success">{{ message }}</p>
  </section>
</template>
