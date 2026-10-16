<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';

const props = defineProps({
  page: { type: String, required: true },
});

const route = useRoute();
const source = computed(
  () => `/api/v1/accounts/${route.params.accountId}/food2c/template-app/${props.page}`
);
</script>

<template>
  <iframe
    :key="source"
    :src="source"
    :title="page === 'report' ? 'Relatório Food2C' : 'Nova conversa Food2C'"
    class="w-full h-full border-0 bg-n-surface-1"
  />
</template>
