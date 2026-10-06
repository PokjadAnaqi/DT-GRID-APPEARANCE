<script setup lang="ts">
import { useAppearanceStore } from '@/stores/appearance'
import FaIcon from '@/components/shared/FaIcon.vue'
import { icons } from '@/config/icons'

const store = useAppearanceStore()

const emit = defineEmits<{
  'confirm-save': []
  'confirm-exit': []
}>()
</script>

<template>
  <div class="dt-creator-actionbar-inner flex items-center gap-2 px-4 py-3 shrink-0 w-full" :style="{ background: 'var(--theme-bg-panel)', borderTop: '1px solid var(--theme-border-base)' }">
    <button
      v-if="store.config.enableExit"
      class="flex-1 h-10 flex items-center justify-center gap-1.5 rounded text-zinc-300 hover:text-white text-[12px] font-bold uppercase tracking-wider"
      style="background: #222222; transition: background-color 0.15s, color 0.15s;"
      @mouseenter="($event.currentTarget as HTMLElement).style.background = '#2a2a2a'"
      @mouseleave="($event.currentTarget as HTMLElement).style.background = '#222222'"
      @click="emit('confirm-exit')">
      <FaIcon :icon="icons.actions.exit" :size="13" />
      <span>{{ store.t('menu.exit') }}</span>
    </button>
    <button
      class="flex-1 h-10 flex items-center justify-center gap-1.5 rounded text-white text-[12px] font-bold uppercase tracking-wider"
      :class="{ 'opacity-50 cursor-not-allowed': !store.appearance?.model }"
      style="background: rgba(var(--theme-accent-rgb), 0.18); border: 1px solid var(--theme-accent-border); box-shadow: inset 0 -1px 0 rgba(var(--theme-accent-rgb), 0.35); transition: background-color 0.15s, border-color 0.15s;"
      @mouseenter="($event.currentTarget as HTMLElement).style.background = 'rgba(var(--theme-accent-rgb), 0.28)'"
      @mouseleave="($event.currentTarget as HTMLElement).style.background = 'rgba(var(--theme-accent-rgb), 0.18)'"
      @click="store.appearance?.model ? emit('confirm-save') : undefined">
      <FaIcon :icon="icons.actions.save" :size="13" />
      <span>{{ store.t('menu.save') }}</span>
    </button>
  </div>
</template>
