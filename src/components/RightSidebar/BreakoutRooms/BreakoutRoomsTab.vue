<!--
  - @copyright Copyright (c) 2022 Marco Ambrosini <marcoambrosini@icloud.com>
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
	<div class="breakout-rooms">
		<!-- Series of buttons at the top of the tab, these affect all
		 breakout rooms -->
		<div class="breakout-rooms__actions">
			<div class="breakout-rooms__actions-group">
				<template>
					<NcButton v-if="breakoutRoomsNotStarted"
						:title="t('spreed', 'Start breakout rooms')"
						:aria-label="t('spreed', 'Start breakout rooms')"
						type="tertiary"
						:disabled="!isInCall"
						@click="startBreakoutRooms">
						<template #icon>
							<Play :size="20" />
						</template>
					</NcButton>
					<NcButton v-else
						:title="t('spreed', 'Stop breakout rooms')"
						:aria-label="t('spreed', 'Stop breakout rooms')"
						type="tertiary"
						@click="stopBreakoutRooms">
						<template #icon>
							<StopIcon :size="20" />
						</template>
					</NcButton>
					<NcButton :title="t('spreed', 'Send message to breakout rooms')"
						:aria-label="t('spreed', 'Send message to breakout rooms')"
						type="tertiary"
						@click="openSendMessageDialog">
						<template #icon>
							<Message :size="18" />
						</template>
					</NcButton>
				</template>
			</div>
			<div class="breakout-rooms__actions-group">
				<!-- Configuration button -->
				<NcButton :type="breakoutRoomsConfigured ? 'tertiary' : 'secondary'"
					:title="configurationButtonTitle"
					:aria-label="configurationButtonTitle"
					@click="openBreakoutRoomsEditor">
					<template #icon>
						<Reload :size="20" />
					</template>
				</NcButton>
				<NcButton v-if="breakoutRoomsConfigured"
					:title="t('spreed', 'Delete breakout rooms')"
					:aria-label="t('spreed', 'Delete breakout rooms')"
					type="tertiary"
					@click="deleteBreakoutRooms">
					<template #icon>
						<Delete :size="20" />
					</template>
				</NcButton>
			</div>
		</div>

		<template v-if="breakoutRoomsConfigured">
			<!-- Breakout rooms list -->
			<BreakoutRoomsList v-if="breakoutRooms" :breakout-rooms="breakoutRooms" />

			<!-- Breakout rooms editor -->
			<BreakoutRoomsEditor v-if="showBreakoutRoomsEditor"
				:token="token"
				@close="showBreakoutRoomsEditor = false" />

			<!-- Send message dialog -->
			<SendMessageDialog v-if="sendMessageDialogOpened"
				:token="token"
				:broadcast="true"
				@close="closeSendMessageDialog" />
		</template>
	</div>
</template>

<script>
// Components
import NcButton from '@nextcloud/vue/dist/Components/NcButton.js'
import BreakoutRoomsEditor from '../../BreakoutRoomsEditor/BreakoutRoomsEditor.vue'
import SendMessageDialog from '../../BreakoutRoomsEditor/SendMessageDialog.vue'
import BreakoutRoomsList from '../../BreakoutRoomsEditor/BreakoutRoomsList.vue'

// Icons
import Delete from 'vue-material-design-icons/Delete.vue'
import Play from 'vue-material-design-icons/Play.vue'
import StopIcon from 'vue-material-design-icons/Stop.vue'
import Reload from 'vue-material-design-icons/Reload.vue'
import Message from 'vue-material-design-icons/Message.vue'

// Constants
import { CONVERSATION } from '../../../constants.js'

// Mixins
import isInCall from '../../../mixins/isInCall.js'

export default {
	name: 'BreakoutRoomsTab',

	components: {
		// Components
		NcButton,
		BreakoutRoomsEditor,
		SendMessageDialog,
		BreakoutRoomsList,

		// Icons
		Delete,
		Play,
		Reload,
		StopIcon,
		Message,
	},

	mixins: [isInCall],

	props: {
		token: {
			type: String,
			required: true,
		},

		conversation: {
			type: Object,
			required: true,
		},
	},

	data() {
		return {
			showBreakoutRoomsEditor: false,
			sendMessageDialogOpened: false,
		}
	},

	computed: {
		breakoutRooms() {
			// Return an empty array until the conversations object is populated
			if (!this.hasBreakoutRooms) {
				return []
			}
			return this.$store.getters.breakoutRoomsReferences(this.token).map(reference => {
				return this.$store.getters.conversation(reference)
			})
		},

		breakoutRoomsReferences() {
			return this.$store.getters.breakoutRoomsReferences(this.token)
		},

		breakoutRoomsConfigured() {
			return this.conversation.breakoutRoomMode !== CONVERSATION.BREAKOUT_ROOM_MODE.NOT_CONFIGURED
		},

		breakoutRoomsNotStarted() {
			return this.conversation.breakoutRoomStatus !== CONVERSATION.BREAKOUT_ROOM_STATUS.STARTED
		},

		configurationButtonTitle() {
			return this.breakoutRoomsConfigured ? t('spreed', 'Re-configure breakout rooms') : t('spreed', 'Configure breakout rooms')
		},

		hasBreakoutRooms() {
			return this.$store.getters.hasBreakoutRooms(this.token)
		},
	},

	mounted() {
		// Get the breakout rooms only if they're not already in the store
		if (!this.hasBreakoutRooms) {
			this.getBreakoutRooms()
		}
	},

	methods: {
		getBreakoutRooms() {
			if (this.breakoutRoomsConfigured) {
				this.$store.dispatch('getBreakoutRoomsAction', {
					token: this.token,
				})
			}
		},

		deleteBreakoutRooms() {
			OC.dialogs.confirmDestructive(
				t('spreed', 'Current breakout rooms and settings will be lost'),
				t('spreed', 'Delete breakout rooms'),
				{
					type: OC.dialogs.YES_NO_BUTTONS,
					confirm: t('spreed', 'Delete breakout rooms'),
					confirmClasses: 'error',
					cancel: t('spreed', 'Cancel'),
				},
				(decision) => {
					if (!decision) {
						return
					}
					this.$store.dispatch('deleteBreakoutRoomsAction', {
						token: this.token,
					})
				}
			)
		},

		openBreakoutRoomsEditor() {
			if (!this.breakoutRoomsConfigured) {
				this.showBreakoutRoomsEditor = true
				return
			}
			OC.dialogs.confirmDestructive(
				t('spreed', 'Current breakout rooms and settings will be lost'),
				t('spreed', 'Re-configure breakout rooms'),
				{
					type: OC.dialogs.YES_NO_BUTTONS,
					confirm: t('spreed', 'Re-configure breakout rooms'),
					confirmClasses: 'primary',
					cancel: t('spreed', 'Cancel'),
				},
				(decision) => {
					if (!decision) {
						return
					}
					this.showBreakoutRoomsEditor = true
				}
			)
		},

		startBreakoutRooms() {
			this.$store.dispatch('startBreakoutRoomsAction', this.token)
		},

		stopBreakoutRooms() {
			this.$store.dispatch('stopBreakoutRoomsAction', this.token)
		},

		openSendMessageDialog() {
			this.sendMessageDialogOpened = true
		},

		closeSendMessageDialog() {
			this.sendMessageDialogOpened = false
		},
	},
}
</script>

<style lang="scss" scoped>

.breakout-rooms {
	&__actions {
		display: flex;
		justify-content: space-between;
		margin-bottom: calc(var(--default-grid-baseline) * 3);
	}

	&__actions-group {
		display: flex;
		gap: var(--default-grid-baseline);

	}

	&__room {
		margin-top: var(--default-grid-baseline);
	}
}

::v-deep .app-navigation-entry__title {
	font-weight: bold !important;
}

// TODO: upstream collapse icon position fix
::v-deep .icon-collapse {
	position: absolute !important;
	left: 0;
}
</style>
