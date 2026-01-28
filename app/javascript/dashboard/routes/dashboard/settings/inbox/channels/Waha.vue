<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import wahaChannelAPI from '../../../../../api/channel/wahaChannel';

const shouldBeUrl = (value = '') =>
  value ? value.startsWith('http') : false;

export default {
  components: {
    PageHeader,
    NextButton,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      channelName: '',
      phoneNumber: '',
      wahaApiUrl: '',
      wahaApiKey: '',
      sessionName: 'default',
      webhookUrl: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    channelName: { required },
    phoneNumber: { required },
    wahaApiUrl: { required, shouldBeUrl },
    wahaApiKey: { required },
    sessionName: { required },
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const response = await wahaChannelAPI.create({
          name: this.channelName?.trim(),
          phone_number: this.phoneNumber?.trim(),
          waha_api_url: this.wahaApiUrl?.trim(),
          waha_api_key: this.wahaApiKey?.trim(),
          session_name: this.sessionName?.trim() || 'default',
        });

        // Store webhook URL for display
        this.webhookUrl = response.data.webhook_url;

        // Show success message with webhook URL
        useAlert(
          this.$t('INBOX_MGMT.ADD.WAHA_CHANNEL.API.SUCCESS_MESSAGE', {
            webhookUrl: this.webhookUrl,
          })
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: response.data.inbox.id,
          },
        });
      } catch (error) {
        const errorMessage =
          error?.response?.data?.error ||
          this.$t('INBOX_MGMT.ADD.WAHA_CHANNEL.API.ERROR_MESSAGE');
        useAlert(errorMessage);
      }
    },
  },
};
</script>

<template>
  <div class="h-full w-full p-6 col-span-6">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.WAHA_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.WAHA_CHANNEL.DESC')"
    />
    <form
      class="flex flex-wrap flex-col mx-0"
      @submit.prevent="createChannel()"
    >
      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.channelName.$error }">
          {{ $t('INBOX_MGMT.ADD.WAHA_CHANNEL.CHANNEL_NAME.LABEL') }}
          <input
            v-model="channelName"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.WAHA_CHANNEL.CHANNEL_NAME.PLACEHOLDER')
            "
            @blur="v$.channelName.$touch"
          />
          <span v-if="v$.channelName.$error" class="message">{{
            $t('INBOX_MGMT.ADD.WAHA_CHANNEL.CHANNEL_NAME.ERROR')
          }}</span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.phoneNumber.$error }">
          {{ $t('INBOX_MGMT.ADD.WAHA_CHANNEL.PHONE_NUMBER.LABEL') }}
          <input
            v-model="phoneNumber"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.WAHA_CHANNEL.PHONE_NUMBER.PLACEHOLDER')
            "
            @blur="v$.phoneNumber.$touch"
          />
          <span v-if="v$.phoneNumber.$error" class="message">{{
            $t('INBOX_MGMT.ADD.WAHA_CHANNEL.PHONE_NUMBER.ERROR')
          }}</span>
        </label>
        <p class="help-text">
          {{ $t('INBOX_MGMT.ADD.WAHA_CHANNEL.PHONE_NUMBER.SUBTITLE') }}
        </p>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.wahaApiUrl.$error }">
          {{ $t('INBOX_MGMT.ADD.WAHA_CHANNEL.WAHA_API_URL.LABEL') }}
          <input
            v-model="wahaApiUrl"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.WAHA_CHANNEL.WAHA_API_URL.PLACEHOLDER')
            "
            @blur="v$.wahaApiUrl.$touch"
          />
          <span v-if="v$.wahaApiUrl.$error" class="message">{{
            $t('INBOX_MGMT.ADD.WAHA_CHANNEL.WAHA_API_URL.ERROR')
          }}</span>
        </label>
        <p class="help-text">
          {{ $t('INBOX_MGMT.ADD.WAHA_CHANNEL.WAHA_API_URL.SUBTITLE') }}
        </p>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.wahaApiKey.$error }">
          {{ $t('INBOX_MGMT.ADD.WAHA_CHANNEL.WAHA_API_KEY.LABEL') }}
          <input
            v-model="wahaApiKey"
            type="password"
            :placeholder="
              $t('INBOX_MGMT.ADD.WAHA_CHANNEL.WAHA_API_KEY.PLACEHOLDER')
            "
            @blur="v$.wahaApiKey.$touch"
          />
          <span v-if="v$.wahaApiKey.$error" class="message">{{
            $t('INBOX_MGMT.ADD.WAHA_CHANNEL.WAHA_API_KEY.ERROR')
          }}</span>
        </label>
        <p class="help-text">
          {{ $t('INBOX_MGMT.ADD.WAHA_CHANNEL.WAHA_API_KEY.SUBTITLE') }}
        </p>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.sessionName.$error }">
          {{ $t('INBOX_MGMT.ADD.WAHA_CHANNEL.SESSION_NAME.LABEL') }}
          <input
            v-model="sessionName"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.WAHA_CHANNEL.SESSION_NAME.PLACEHOLDER')
            "
            @blur="v$.sessionName.$touch"
          />
        </label>
        <p class="help-text">
          {{ $t('INBOX_MGMT.ADD.WAHA_CHANNEL.SESSION_NAME.SUBTITLE') }}
        </p>
      </div>

      <div class="w-full mt-4">
        <NextButton
          :is-loading="uiFlags.isCreating"
          type="submit"
          solid
          blue
          :label="$t('INBOX_MGMT.ADD.WAHA_CHANNEL.SUBMIT_BUTTON')"
        />
      </div>

      <div v-if="webhookUrl" class="w-full mt-4 p-4 bg-slate-25 dark:bg-slate-900 rounded-md">
        <p class="text-sm font-medium text-slate-800 dark:text-slate-100 mb-2">
          {{ $t('INBOX_MGMT.ADD.WAHA_CHANNEL.WEBHOOK_URL.LABEL') }}
        </p>
        <code class="text-xs text-slate-600 dark:text-slate-300 break-all">
          {{ webhookUrl }}
        </code>
      </div>
    </form>
  </div>
</template>
