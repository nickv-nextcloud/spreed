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
	<div class="top-bar" :class="{ 'in-call': isInCall }">
		<ConversationIcon :key="conversation.token"
			class="conversation-icon"
			:offline="isPeerOffline"
			:item="conversation"
			:hide-favorite="false"
			:hide-call="false" />
		<!-- conversation header -->
		<a role="button"
			class="conversation-header"
			@click="openConversationSettings">
			<div class="conversation-header__text"
				:class="{'conversation-header__text--offline': isPeerOffline}">
				<p class="title">
					{{ conversation.displayName }}
				</p>
				<p v-if="showUserStatusAsDescription"
					class="description">
					{{ statusMessage }}
				</p>
				<template v-if="!isInCall && conversation.description">
					<p v-tooltip.bottom="{
							content: renderedDescription,
							delay: { show: 500, hide: 500 },
							autoHide: false,
							html: true,
						}"
						class="description">
						{{ conversation.description }}
					</p>
				</template>
			</div>
		</a>

		<!-- Call time -->
		<CallTime v-if="isInCall"
			:start="conversation.callStartTime" />

		<!-- Local media controls -->
		<LocalMediaControls v-if="isInCall"
			class="local-media-controls"
			:token="token"
			:model="localMediaModel"
			:show-actions="!isSidebar"
			:screen-sharing-button-hidden="isSidebar"
			:local-call-participant-model="localCallParticipantModel" />

		<!-- TopBar menu -->
		<TopBarMenu :token="token"
			:show-actions="!isSidebar"
			:is-sidebar="isSidebar"
			:model="localMediaModel" />

		<CallButton class="top-bar__button" />

		<template v-if="showOpenSidebarButton">
			<!-- sidebar toggle -->
			<NcButton v-if="!isInCall"
				class="top-bar__button"
				close-after-click="true"
				type="tertiary"
				@click="openSidebar">
				<template #icon>
					<MenuIcon :size="20" />
				</template>
			</NcButton>

			<!-- chat button -->
			<div v-if="isInCall"
				class="chat-button">
				<NcActions class="top-bar__button"
					close-after-click="true"
					:container="container">
					<NcActionButton key="openSideBarButtonMessageText"
						@click="openSidebar('chat')">
						<template #icon>
							<MessageText :size="20"
								fill-color="#ffffff" />
						</template>
					</NcActionButton>
				</NcActions>
				<NcCounterBubble v-if="!isSidebar && isInCall && unreadMessagesCounter > 0"
					class="chat-button__unread-messages-counter"
					:highlighted="hasUnreadMentions">
					{{ unreadMessagesCounter }}
				</NcCounterBubble>
			</div>

			<!-- participants button -->
			<NcButton v-if="isInCall && !isOneToOneConversation"
				class="top-bar__button"
				close-after-click="true"
				type="tertiary"
				@click="openSidebar('participants')">
				<template #icon>
					<AccountMultiple :size="20"
						fill-color="#ffffff" />
				</template>
				{{ participantsInCall }}
			</NcButton>
		</template>
	</div>
</template>

<script>
import { showMessage } from '@nextcloud/dialogs'
import NcActionButton from '@nextcloud/vue/dist/Components/NcActionButton.js'
import NcActions from '@nextcloud/vue/dist/Components/NcActions.js'
import NcCounterBubble from '@nextcloud/vue/dist/Components/NcCounterBubble.js'
import CallButton from './CallButton.vue'
import BrowserStorage from '../../services/BrowserStorage.js'
import AccountMultiple from 'vue-material-design-icons/AccountMultiple.vue'
import MessageText from 'vue-material-design-icons/MessageText.vue'
import { CONVERSATION } from '../../constants.js'
import { generateUrl } from '@nextcloud/router'
import { localCallParticipantModel, localMediaModel } from '../../utils/webrtc/index.js'
import { emit } from '@nextcloud/event-bus'
import ConversationIcon from '../ConversationIcon.vue'
import Tooltip from '@nextcloud/vue/dist/Directives/Tooltip.js'
import richEditor from '@nextcloud/vue/dist/Mixins/richEditor.js'
import userStatus from '../../mixins/userStatus.js'
import LocalMediaControls from '../CallView/shared/LocalMediaControls.vue'
import getParticipants from '../../mixins/getParticipants.js'
import TopBarMenu from './TopBarMenu.vue'
import NcButton from '@nextcloud/vue/dist/Components/NcButton.js'
import CallTime from './CallTime.vue'
import MenuIcon from 'vue-material-design-icons/Menu.vue'

export default {
	name: 'TopBar',

	directives: {
		Tooltip,
	},

	components: {
		NcActionButton,
		NcActions,
		NcCounterBubble,
		CallButton,
		AccountMultiple,
		MessageText,
		ConversationIcon,
		LocalMediaControls,
		TopBarMenu,
		NcButton,
		CallTime,
		MenuIcon,
	},

	mixins: [
		richEditor,
		userStatus,
		getParticipants,
	],

	props: {
		isInCall: {
			type: Boolean,
			required: true,
		},

		/**
		 * In the sidebar the conversation settings are hidden
		 */
		isSidebar: {
			type: Boolean,
			default: false,
		},
	},

	data: () => {
		return {
			unreadNotificationHandle: null,
			localCallParticipantModel,
			localMediaModel,
		}
	},

	computed: {
		container() {
			return this.$store.getters.getMainContainerSelector()
		},

		showOpenSidebarButton() {
			return !this.$store.getters.getSidebarStatus
		},

		isOneToOneConversation() {
			return this.conversation.type === CONVERSATION.TYPE.ONE_TO_ONE
		},

		token() {
			return this.$store.getters.getToken()
		},

		conversation() {
			return this.$store.getters.conversation(this.token) || this.$store.getters.dummyConversation
		},

		showUserStatusAsDescription() {
			return this.isOneToOneConversation && this.statusMessage
		},

		statusMessage() {
			return this.getStatusMessage(this.conversation)
		},

		unreadMessagesCounter() {
			return this.conversation.unreadMessages
		},
		hasUnreadMentions() {
			return this.conversation.unreadMention
		},

		linkToConversation() {
			if (this.token !== '') {
				return window.location.protocol + '//' + window.location.host + generateUrl('/call/' + this.token)
			} else {
				return ''
			}
		},

		renderedDescription() {
			return this.renderContent(this.conversation.description)
		},

		/**
		 * Current actor id
		 */
		actorId() {
			return this.$store.getters.getActorId()
		},

		/**
		 * Online status of the peer in one to one conversation.
		 */
		isPeerOffline() {
			// Only compute this in on to one conversations
			if (!this.isOneToOneConversation) {
				return undefined
			}

			// Get the 1 to 1 peer
			let peer
			const participants = this.$store.getters.participantsList(this.token)
			for (const participant of participants) {
				if (participant.actorId !== this.actorId) {
					peer = participant
				}
			}

			if (peer) {
				return !peer.sessionIds.length
			} else return false
		},

		participantsInCall() {
			return this.$store.getters.participantsInCall(this.token) ? this.$store.getters.participantsInCall(this.token) : ''
		},
	},

	watch: {
		unreadMessagesCounter(newValue, oldValue) {
			if (!this.isInCall || !this.showOpenSidebarButton) {
				return
			}

			// new messages arrived
			if (newValue > 0 && oldValue === 0 && !this.hasUnreadMentions) {
				this.notifyUnreadMessages(t('spreed', 'You have new unread messages in the chat.'))
			}
		},

		hasUnreadMentions(newValue, oldValue) {
			if (!this.isInCall || !this.showOpenSidebarButton) {
				return
			}

			if (newValue) {
				this.notifyUnreadMessages(t('spreed', 'You have been mentioned in the chat.'))
			}
		},

		isInCall(newValue) {
			if (!newValue) {
				// discard notification if the call ends
				this.notifyUnreadMessages(null)
			}
		},

		// Starts and stops the getParticipantsMixin logic
		isOneToOneConversation(newValue) {
			if (newValue) {
				this.initialiseGetParticipantsMixin()
			} else {
				this.stopGetParticipantsMixin()
			}
		},
	},

	mounted() {
		document.body.classList.add('has-topbar')
		document.addEventListener('fullscreenchange', this.fullScreenChanged, false)
		document.addEventListener('mozfullscreenchange', this.fullScreenChanged, false)
		document.addEventListener('MSFullscreenChange', this.fullScreenChanged, false)
		document.addEventListener('webkitfullscreenchange', this.fullScreenChanged, false)
	},

	beforeDestroy() {
		this.notifyUnreadMessages(null)
		document.removeEventListener('fullscreenchange', this.fullScreenChanged, false)
		document.removeEventListener('mozfullscreenchange', this.fullScreenChanged, false)
		document.removeEventListener('MSFullscreenChange', this.fullScreenChanged, false)
		document.removeEventListener('webkitfullscreenchange', this.fullScreenChanged, false)
		document.body.classList.remove('has-topbar')
	},

	methods: {
		notifyUnreadMessages(message) {
			if (this.unreadNotificationHandle) {
				this.unreadNotificationHandle.hideToast()
				this.unreadNotificationHandle = null
			}
			if (message) {
				this.unreadNotificationHandle = showMessage(message)
			}
		},

		openSidebar(activeTab) {
			if (typeof activeTab === 'string') {
				emit('spreed:select-active-sidebar-tab', activeTab)
			}
			this.$store.dispatch('showSidebar')
			BrowserStorage.setItem('sidebarOpen', 'true')
		},

		openConversationSettings() {
			emit('show-conversation-settings', { token: this.token })
		},

		// TODO: implement real method
		stopRecording() {
			console.debug('stop recordiiing')
		},
	},
}
</script>

<style lang="scss" scoped>

@import '../../assets/variables';

.top-bar {
	right: 12px; /* needed so we can still use the scrollbar */
	display: flex;
	z-index: 10;
	justify-content: flex-end;
	padding: 8px;
	background-color: var(--color-main-background);
	border-bottom: 1px solid var(--color-border);

	.talk-sidebar-callview & {
		margin-right: $clickable-area;
	}

	&.in-call {
		right: 0;
		border: none;
		position: absolute;
		top: 0;
		left:0;
		background-color: transparent;
		display: flex;
		flex-wrap: wrap;
		& * {
			color: #fff;
		}

		:deep(.action-item--open .action-item__menutoggle),
		:deep(.action-item__menutoggle:hover),
		:deep(.action-item--single:hover),
		:deep(.buttons-bar button:hover) {
			background-color: rgba(0, 0, 0, 0.2);
		}
	}

	&__button {
		margin: 0 2px;
		align-self: center;
		display: flex;
		align-items: center;
		white-space: nowrap;
		.icon {
			margin-right: 4px !important;
		}

		&__force-white {
			color: white;
		}
	}

	.chat-button {
		position: relative;
		&__unread-messages-counter {
			position: absolute;
			top: 24px;
			right: 2px;
			pointer-events: none;
		}
	}
}

.conversation-icon {
	margin-left: 48px;
}

.conversation-header {
	position: relative;
	display: flex;
	overflow-x: hidden;
	overflow-y: clip;
	white-space: nowrap;
	width: 0;
	flex-grow: 1;
	cursor: pointer;
	&__text {
		display: flex;
		flex-direction:column;
		flex-grow: 1;
		margin-left: 8px;
		justify-content: center;
		width: 100%;
		overflow: hidden;
		height: $clickable-area;
		&--offline {
			color: var(--color-text-maxcontrast);
		}
	}
	.title {
		font-weight: bold;
		overflow: hidden;
		text-overflow: ellipsis;
	}
	.description {
		overflow: hidden;
		text-overflow: ellipsis;
		max-width: fit-content;
		color: var(--color-text-lighter);
	}
}
</style>
