<script setup lang="ts">
import { useAppearanceStore } from '@/stores/appearance'

const store = useAppearanceStore()

const getShopTitle = (shopType?: string) => {
  if (!shopType) return store.t('menu.title')
  switch(shopType.toLowerCase()) {
    case 'ponsonbys': return 'Ponsonbys'
    case 'binco': return 'Binco'
    case 'suburban': return 'Suburban'
    case 'barber': return store.t('menu.barberShopTitle')
    case 'tattoo': return store.t('menu.tattooShopTitle')
    case 'wardrobe': return store.t('outfits.save.menuTitle')
    default: return store.t('menu.title')
  }
}

function getTitleStyle() {
  return {
    color: '#e7e9e5',
    webkitTextFillColor: '#e7e9e5',
    background: 'none',
    textShadow: '0 2px 14px rgba(0,0,0,0.64)'
  }
}
</script>

<template>
  <div class="dt-apocalypse-header border-b border-theme-border shrink-0 flex flex-col relative">
    <div class="dt-apocalypse-brandrow">
      <div class="dt-apocalypse-brand">
        <img class="dt-apocalypse-logo" src="/delta-horizon-logo.png" alt="Delta Horizon" />
        <span>DELTA HORIZON // APPEARANCE TERMINAL</span>
      </div>
      <span class="dt-apocalypse-index">02 · CUSTOMIZATION</span>
    </div>

    <h1
      class="dt-apocalypse-header-title font-display font-bold uppercase"
      :style="getTitleStyle()"
    >
      {{ getShopTitle(store.config?.shopType) }}
    </h1>
    <div class="dt-apocalypse-header-subtitle">IDENTITY · CLOTHING · FIELD CONFIGURATION</div>
  </div>
</template>
