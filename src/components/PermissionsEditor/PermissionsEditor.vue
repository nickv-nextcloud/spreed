<!--
  - @copyright Copyright (c) 2021 Marco Ambrosini <marcoambrosini@icloud.com>
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
	<NcModal size="small"
		:container="$store.getters.getMainContainerSelector()"
		v-on="$listeners">
		<div class="wrapper">
			<template v-if="!loading">
				<!-- eslint-disable-next-line vue/no-v-html -->
				<p class="title" v-html="modalTitle" />
				<form @submit.prevent="handleSubmitPermissions">
					<NcCheckboxRadioSwitch ref="callStart"
						:checked.sync="callStart"
						class="checkbox">
						{{ t('spreed', 'Start a call') }}
					</NcCheckboxRadioSwitch>
					<NcCheckboxRadioSwitch ref="lobbyIgnore"
						:checked.sync="lobbyIgnore"
						class="checkbox">
						{{ t('spreed', 'Skip the lobby') }}
					</NcCheckboxRadioSwitch>
					<NcCheckboxRadioSwitch ref="chatMessagesAndReactions"
						:checked.sync="chatMessagesAndReactions"
						class="checkbox">
						{{ t('spreed', 'Can post messages and reactions') }}
					</NcCheckboxRadioSwitch>
					<NcCheckboxRadioSwitch ref="publishAudio"
						:checked.sync="publishAudio"
						class="checkbox">
						{{ t('spreed', 'Enable the microphone') }}
					</NcCheckboxRadioSwitch>
					<NcCheckboxRadioSwitch ref="publishVideo"
						:checked.sync="publishVideo"
						class="checkbox">
						{{ t('spreed', 'Enable the camera') }}
					</NcCheckboxRadioSwitch>
					<NcCheckboxRadioSwitch ref="publishScreen"
						:checked.sync="publishScreen"
						class="checkbox">
						{{ t('spreed', 'Share the screen') }}
					</NcCheckboxRadioSwitch>
					<NcButton ref="submit"
						native-type="submit"
						class="button-update-permission"
						type="primary"
						:disabled="submitButtonDisabled">
						{{ t('spreed', 'Update permissions') }}
					</NcButton>
				</form>
			</template>
			<div v-if="loading" class="loading-screen">
				<span class="icon-loading" />
				<p>{{ t('spreed', 'Updating permissions') }}</p>
			</div>
		</div>
	</NcModal>
</template>

<script>
import NcCheckboxRadioSwitch from '@nextcloud/vue/dist/Components/NcCheckboxRadioSwitch.js'
import { PARTICIPANT } from '../../constants.js'
import NcModal from '@nextcloud/vue/dist/Components/NcModal.js'
import NcButton from '@nextcloud/vue/dist/Components/NcButton.js'
import { loadState } from '@nextcloud/initial-state'

const PERMISSIONS = PARTICIPANT.PERMISSIONS

export default {
	name: 'PermissionsEditor',

	components: {
		NcCheckboxRadioSwitch,
		NcModal,
		NcButton,
	},

	props: {
		permissions: {
			type: Number,
			default: null,
		},

		/**
		 * The user's displayname. Don't provide this only when modifying the
		 * default conversation's permissions.
		 */
		displayName: {
			type: String,
			default: '',
		},

		/**
		 * The conversation's name. Don't provide this when modifying
		 * participants' permissions.
		 */
		conversationName: {
			type: String,
			default: '',
		},

		/**
		 * Displays the loading state of this component
		 */
		loading: {
			type: Boolean,
			default: false,
		},
	},

	data() {
		return {
			// Permission to start a call
			callStart: false,
			// Permission to bypass the lobby
			lobbyIgnore: false,
			// Permission to post messages and reactions
			chatMessagesAndReactions: false,
			// Permission to enable the microphone
			publishAudio: false,
			// Permission to enable the camera
			publishVideo: false,
			// Permission to start a screenshare
			publishScreen: false,
		}
	},

	computed: {
		modalTitle() {
			if (this.displayName) {
				return t('spreed', 'In this conversation <strong>{user}</strong> can:', {
					user: this.displayName,
				})
			} else if (this.conversationName) {
				return t('spreed', 'Edit default permissions for participants in <strong>{conversationName}</strong>', {
					conversationName: this.conversationName,
				})
			} else throw Error('you need to fill either the conversationName or the displayName props')
		},

		permissionsWithDefault() {
			if (this.permissions !== PERMISSIONS.DEFAULT) {
				return this.permissions
			}

			return loadState(
				'spreed',
				'default_permissions',
				PERMISSIONS.MAX_DEFAULT & ~PERMISSIONS.LOBBY_IGNORE
			)
		},

		/**
		 * The number of the edited permissions during the editing of the form.
		 * We use this to compare it with the actual permissions of the
		 * participant in the store and enable or disable the submit button
		 * accordingly.
		 */
		formPermissions() {
			return (this.callStart ? PERMISSIONS.CALL_START : 0)
			| (this.lobbyIgnore ? PERMISSIONS.LOBBY_IGNORE : 0)
			| (this.chatMessagesAndReactions ? PERMISSIONS.CHAT : 0)
			| (this.publishAudio ? PERMISSIONS.PUBLISH_AUDIO : 0)
			| (this.publishVideo ? PERMISSIONS.PUBLISH_VIDEO : 0)
			| (this.publishScreen ? PERMISSIONS.PUBLISH_SCREEN : 0)
			| PERMISSIONS.CUSTOM
		},

		/**
		 * If the permissions are not changed, the submit button will stay
		 * disabled.
		 */
		submitButtonDisabled() {
			return (!!(this.permissionsWithDefault & PERMISSIONS.CALL_START)) === this.callStart
				&& !!(this.permissionsWithDefault & PERMISSIONS.LOBBY_IGNORE) === this.lobbyIgnore
				&& !!(this.permissionsWithDefault & PERMISSIONS.CHAT) === this.chatMessagesAndReactions
				&& !!(this.permissionsWithDefault & PERMISSIONS.PUBLISH_AUDIO) === this.publishAudio
				&& !!(this.permissionsWithDefault & PERMISSIONS.PUBLISH_VIDEO) === this.publishVideo
				&& !!(this.permissionsWithDefault & PERMISSIONS.PUBLISH_SCREEN) === this.publishScreen
		},
	},

	mounted() {
		this.writePermissionsToComponent(this.permissionsWithDefault)
	},

	methods: {
		/**
		 * Takes the permissions from the store and writes them in the data of
		 * this component.
		 *
		 * @param {number} permissions - the permissions number.
		 */
		writePermissionsToComponent(permissions) {
			permissions & PERMISSIONS.CALL_START ? this.callStart = true : this.callStart = false
			permissions & PERMISSIONS.LOBBY_IGNORE ? this.lobbyIgnore = true : this.lobbyIgnore = false
			permissions & PERMISSIONS.CHAT ? this.chatMessagesAndReactions = true : this.chatMessagesAndReactions = false
			permissions & PERMISSIONS.PUBLISH_AUDIO ? this.publishAudio = true : this.publishAudio = false
			permissions & PERMISSIONS.PUBLISH_VIDEO ? this.publishVideo = true : this.publishVideo = false
			permissions & PERMISSIONS.PUBLISH_SCREEN ? this.publishScreen = true : this.publishScreen = false
		},

		handleSubmitPermissions() {
			this.$emit('submit', this.formPermissions)
		},
	},
}
</script>

<style lang="scss" scoped>
.wrapper {
	padding: 0 24px 24px 24px;
}

.title {
	font-size: 16px;
	margin-bottom: 12px;
	padding-top: 24px;
}

.loading-screen {
	height: 200px;
	text-align: center;
	font-weight: bold;
	display: flex;
	flex-direction: column;
	justify-content: center;

	// Loader
	span {
		margin-bottom: 16px;
	}
}

.button-update-permission {
	margin: 0 auto;
}

</style>
