<!--
  - @copyright Copyright (c) 2019 Marco Ambrosini <marcoambrosini@icloud.com>
  -
  - @author Marco Ambrosini <marcoambrosini@icloud.com>
  -
  - @license GNU AGPL version 3 or any later version
  -
  - This program is free software: you can redistribute it and/or modify
  - it under the terms of the GNU Affero General Public License as
  - published by the Free Software Foundation, either version 3 of the
  - License, or (at your option) any later version.
  -
  - This program is distributed in the hope that it will be useful,
  - but WITHOUT ANY WARRANTY; without even the implied warranty of
  - MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  - GNU Affero General Public License for more details.
  -
  - You should have received a copy of the GNU Affero General Public License
  - along with this program. If not, see <http://www.gnu.org/licenses/>.
-->

<template>
	<div>
		<NcButton v-if="showStartCallButton"
			id="call_button"
			v-tooltip="{
				placement: 'auto',
				trigger: 'hover',
				content: startCallToolTip,
				autoHide: false,
				html: true
			}"
			:disabled="startCallButtonDisabled || loading || blockCalls"
			:type="startCallButtonType"
			@click="handleClick">
			<template #icon>
				<VideoIcon :size="20" />
			</template>
			{{ startCallLabel }}
		</NcButton>
		<NcButton v-else-if="showLeaveCallButton && !canEndForAll"
			id="call_button"
			type="error"
			:disabled="loading"
			@click="leaveCall(false)">
			<template #icon>
				<VideoOff :size="20" />
			</template>
			{{ leaveCallLabel }}
		</NcButton>
		<NcActions v-else-if="showLeaveCallButton && canEndForAll"
			:disabled="loading"
			:menu-title="leaveCallCombinedLabel"
			type="error">
			<template #icon>
				<VideoOff :size="20" />
			</template>
			<NcActionButton @click="leaveCall(false)">
				<template #icon>
					<VideoOff :size="20" />
				</template>
				{{ leaveCallLabel }}
			</NcActionButton>
			<NcActionButton @click="leaveCall(true)">
				<template #icon>
					<VideoOff :size="20" />
				</template>
				{{ t('spreed', 'End meeting for all') }}
			</NcActionButton>
		</NcActions>
	</div>
</template>

<script>
import { CALL, CONVERSATION, PARTICIPANT } from '../../constants.js'
import browserCheck from '../../mixins/browserCheck.js'
import isInCall from '../../mixins/isInCall.js'
import isInLobby from '../../mixins/isInLobby.js'
import participant from '../../mixins/participant.js'
import Tooltip from '@nextcloud/vue/dist/Directives/Tooltip.js'
import { emit } from '@nextcloud/event-bus'
import { loadState } from '@nextcloud/initial-state'
import BrowserStorage from '../../services/BrowserStorage.js'
import NcActions from '@nextcloud/vue/dist/Components/NcActions.js'
import NcActionButton from '@nextcloud/vue/dist/Components/NcActionButton.js'
import VideoIcon from 'vue-material-design-icons/Video.vue'
import VideoOff from 'vue-material-design-icons/VideoOff.vue'
import NcButton from '@nextcloud/vue/dist/Components/NcButton.js'

export default {
	name: 'CallButton',

	directives: {
		Tooltip,
	},

	components: {
		NcActions,
		NcActionButton,
		VideoIcon,
		VideoOff,
		NcButton,
	},

	mixins: [
		browserCheck,
		isInCall,
		isInLobby,
		participant,
	],

	props: {
		/**
		 * Skips the device checker dialog and joins or starts the call
		 * upon clicking the button
		 */
		forceJoinCall: {
			type: Boolean,
			default: false,
		},

		/**
		 * Whether the call should trigger a notifications and sound
		 * for other participants or not
		 */
		silentCall: {
			type: Boolean,
			default: false,
		},
	},

	data() {
		return {
			loading: false,
			callEnabled: false,
		}
	},

	computed: {
		token() {
			return this.$store.getters.getToken()
		},
		isNextcloudTalkHashDirty() {
			return this.$store.getters.isNextcloudTalkHashDirty
		},

		conversation() {
			return this.$store.getters.conversation(this.token) || this.$store.getters.dummyConversation
		},

		isRecording() {
			return this.conversation.callRecording !== CALL.RECORDING.OFF
		},

		participantType() {
			return this.conversation.participantType
		},

		canEndForAll() {
			return ((this.conversation.callPermissions !== PARTICIPANT.PERMISSIONS.DEFAULT
					&& (this.conversation.callPermissions & PARTICIPANT.PERMISSIONS.CALL_START) === 0)
				|| (this.conversation.defaultPermissions !== PARTICIPANT.PERMISSIONS.DEFAULT
					&& (this.conversation.defaultPermissions & PARTICIPANT.PERMISSIONS.CALL_START) === 0))
			 && (this.participantType === PARTICIPANT.TYPE.OWNER
				|| this.participantType === PARTICIPANT.TYPE.MODERATOR
				|| this.participantType === PARTICIPANT.TYPE.GUEST_MODERATOR)
		},

		hasCall() {
			return this.conversation.hasCall || this.conversation.hasCallOverwrittenByChat
		},

		startCallButtonDisabled() {
			return (!this.conversation.canStartCall
					&& !this.hasCall)
				|| this.isInLobby
				|| this.conversation.readOnly
				|| this.isNextcloudTalkHashDirty
				|| !this.currentConversationIsJoined
		},

		leaveCallLabel() {
			return t('spreed', 'Leave call')
		},

		leaveCallCombinedLabel() {
			return this.leaveCallLabel + ' ▼'
		},

		startCallLabel() {
			if (this.hasCall && !this.isInLobby) {
				return t('spreed', 'Join call')
			}

			return this.silentCall ? t('spreed', 'Start call silently') : t('spreed', 'Start call')
		},

		startCallToolTip() {
			if (this.isNextcloudTalkHashDirty) {
				return t('spreed', 'Nextcloud Talk was updated, you need to reload the page before you can start or join a call.')
			}

			if (this.callButtonTooltipText) {
				return this.callButtonTooltipText
			}

			if (!this.conversation.canStartCall && !this.hasCall) {
				return t('spreed', 'You will be able to join the call only after a moderator starts it.')
			}

			return ''
		},

		startCallButtonType() {
			if (!this.isInLobby) {
				if (!this.hasCall) {
					return 'primary'
				} else {
					return 'success'
				}
			}
			return ''
		},

		showStartCallButton() {
			return this.callEnabled
				&& this.conversation.readOnly === CONVERSATION.STATE.READ_WRITE
				&& !this.isInCall
		},

		showLeaveCallButton() {
			return this.conversation.readOnly === CONVERSATION.STATE.READ_WRITE
				&& this.isInCall
		},

		currentConversationIsJoined() {
			return this.$store.getters.currentConversationIsJoined
		},
	},

	mounted() {
		this.callEnabled = loadState('spreed', 'call_enabled')
	},

	methods: {
		isParticipantTypeModerator(participantType) {
			return [PARTICIPANT.TYPE.OWNER, PARTICIPANT.TYPE.MODERATOR, PARTICIPANT.TYPE.GUEST_MODERATOR].indexOf(participantType) !== -1
		},

		/**
		 * Starts or joins a call
		 */
		async joinCall() {
			let flags = PARTICIPANT.CALL_FLAG.IN_CALL
			if (this.conversation.permissions & PARTICIPANT.PERMISSIONS.PUBLISH_AUDIO) {
				flags |= PARTICIPANT.CALL_FLAG.WITH_AUDIO
			}
			if (this.conversation.permissions & PARTICIPANT.PERMISSIONS.PUBLISH_VIDEO) {
				flags |= PARTICIPANT.CALL_FLAG.WITH_VIDEO
			}

			console.info('Joining call')
			this.loading = true
			// Close navigation
			emit('toggle-navigation', {
				open: false,
			})
			await this.$store.dispatch('joinCall', {
				token: this.token,
				participantIdentifier: this.$store.getters.getParticipantIdentifier(),
				flags,
				silent: this.hasCall ? true : this.silentCall,
			})
			this.loading = false
		},

		async leaveCall(endMeetingForAll = false) {
			if (endMeetingForAll) {
				console.info('End meeting for everyone')
			} else {
				console.info('Leaving call')
			}

			// Remove selected participant
			this.$store.dispatch('selectedVideoPeerId', null)
			this.loading = true

			// Open navigation
			emit('toggle-navigation', {
				open: true,
			})
			await this.$store.dispatch('leaveCall', {
				token: this.token,
				participantIdentifier: this.$store.getters.getParticipantIdentifier(),
				all: endMeetingForAll,
			})
			this.loading = false
		},

		handleClick() {
			const shouldShowDeviceCheckerScreen = (BrowserStorage.getItem('showDeviceChecker' + this.token) === null
				|| BrowserStorage.getItem('showDeviceChecker' + this.token) === 'true') && !this.forceJoinCall
			console.debug(shouldShowDeviceCheckerScreen)
			if ((this.isRecording && !this.forceJoinCall) || shouldShowDeviceCheckerScreen) {
				emit('talk:device-checker:show')
			} else {
				emit('talk:device-checker:hide')
				this.joinCall()
			}
		},
	},
}
</script>

<style lang="scss" scoped>
#call_button {
	margin: 0 auto;
}
</style>
