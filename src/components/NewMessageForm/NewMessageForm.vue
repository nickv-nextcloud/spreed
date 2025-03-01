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
	<div class="wrapper"
		:class="{'wrapper--chatScrolledToBottom': isChatScrolledToBottom}">
		<!--native file picker, hidden -->
		<input id="file-upload"
			ref="fileUploadInput"
			multiple
			type="file"
			tabindex="-1"
			aria-hidden="true"
			class="hidden-visually"
			@change="handleFileInput">
		<div class="new-message">
			<form class="new-message-form"
				@submit.prevent>
				<!-- Attachments menu -->
				<div v-if="showAttachmentsMenu"
					class="new-message-form__upload-menu">
					<NcActions ref="attachmentsMenu"
						:container="container"
						:boundaries-element="containerElement"
						:disabled="disabled"
						:aria-label="t('spreed', 'Share files to the conversation')"
						:aria-haspopup="true">
						<template #icon>
							<Paperclip :size="16" />
						</template>

						<NcActionButton v-if="canUploadFiles"
							:close-after-click="true"
							@click.prevent="clickImportInput">
							<template #icon>
								<Upload :size="20" />
							</template>
							{{ t('spreed', 'Upload from device') }}
						</NcActionButton>
						<NcActionButton v-if="canShareFiles"
							:close-after-click="true"
							@click.prevent="handleFileShare">
							<template #icon>
								<Folder :size="20" />
							</template>
							{{ shareFromNextcloudLabel }}
						</NcActionButton>
						<template v-if="canShareFiles">
							<NcActionButton v-for="(provider, i) in fileTemplateOptions"
								:key="i"
								:close-after-click="true"
								:icon="provider.iconClass"
								@click.prevent="showTextFileDialog = i">
								{{ provider.label }}
							</NcActionButton>
						</template>
						<NcActionButton v-if="canCreatePoll"
							:close-after-click="true"
							@click.prevent="toggleSimplePollsEditor(true)">
							<template #icon>
								<Poll :size="20" />
							</template>
							{{ t('spreed', 'Create new poll') }}
						</NcActionButton>
					</NcActions>
				</div>
				<!-- Input area -->
				<div class="new-message-form__input">
					<div class="new-message-form__emoji-picker">
						<NcEmojiPicker v-if="!disabled"
							:container="container"
							:close-on-select="false"
							@select="addEmoji">
							<NcButton :disabled="disabled"
								:aria-label="t('spreed', 'Add emoji')"
								type="tertiary-no-background"
								:aria-haspopup="true">
								<template #icon>
									<EmoticonOutline :size="16" />
								</template>
							</NcButton>
						</NcEmojiPicker>
						<!-- Disabled emoji picker placeholder button -->
						<NcButton v-else
							type="tertiary"
							:aria-label="t('spreed', 'Add emoji')"
							:disabled="true">
							<template #icon>
								<EmoticonOutline :size="16" />
							</template>
						</NcButton>
					</div>
					<div v-if="messageToBeReplied" class="new-message-form__quote">
						<Quote :is-new-message-form-quote="true"
							:parent-id="messageToBeReplied.id"
							v-bind="messageToBeReplied" />
					</div>
					<AdvancedInput ref="advancedInput"
						v-model="text"
						:token="token"
						:active-input="!disabled"
						:placeholder-text="placeholderText"
						:aria-label="placeholderText"
						@update:contentEditable="contentEditableToParsed"
						@submit="handleSubmit({ silent: false })"
						@files-pasted="handlePastedFiles" />
				</div>

				<AudioRecorder v-if="!hasText && canUploadFiles"
					:disabled="disabled"
					@recording="handleRecording"
					@audio-file="handleAudioFile" />
				<!-- Send buttons -->
				<template v-else>
					<NcActions v-if="!broadcast"
						:force-menu="true">
						<!-- Silent send -->
						<NcActionButton :close-after-click="true"
							icon="icon-upload"
							:title="t('spreed', 'Send without notification')"
							@click.prevent="handleSubmit({ silent: true })">
							{{ silentSendInfo }}
							<BellOff slot="icon"
								:size="16" />
						</NcActionButton>
					</NcActions>
					<!-- Send -->
					<NcButton :disabled="disabled"
						type="tertiary"
						native-type="submit"
						:title="t('spreed', 'Send message')"
						:aria-label="t('spreed', 'Send message')"
						@click.prevent="handleSubmit({ silent: false })">
						<template #icon>
							<Send :size="16" />
						</template>
					</NcButton>
				</template>
			</form>
		</div>

		<SimplePollsEditor v-if="showSimplePollsEditor"
			:token="token"
			@close="toggleSimplePollsEditor(false)" />

		<!-- Text file creation dialog -->
		<NcModal v-if="showTextFileDialog !== false"
			size="normal"
			:container="$store.getters.getMainContainerSelector()"
			class="templates-picker"
			@close="dismissTextFileCreation">
			<div class="new-text-file">
				<h2>
					{{ t('spreed', 'Create and share a new file') }}
				</h2>
				<form class="new-text-file__form templates-picker__form"
					:style="style"
					@submit.prevent="handleCreateTextFile">
					<NcTextField id="new-file-form-name"
						ref="textFileTitleInput"
						:error="!!newFileError"
						:helper-text="newFileError"
						:label="t('spreed', 'Name of the new file')"
						:placeholder="textFileTitle"
						:value.sync="textFileTitle" />

					<template v-if="fileTemplate.templates.length">
						<ul class="templates-picker__list">
							<TemplatePreview v-bind="emptyTemplate"
								:checked="checked === emptyTemplate.fileid"
								@check="onCheck" />

							<TemplatePreview v-for="template in fileTemplate.templates"
								:key="template.fileid"
								v-bind="template"
								:checked="checked === template.fileid"
								:ratio="fileTemplate.ratio"
								@check="onCheck" />
						</ul>
					</template>

					<div class="new-text-file__buttons">
						<NcButton type="tertiary"
							@click="dismissTextFileCreation">
							{{ t('spreed', 'Close') }}
						</NcButton>
						<NcButton type="primary"
							@click="handleCreateTextFile">
							{{ t('spreed', 'Create file') }}
						</NcButton>
					</div>
				</form>
			</div>
		</NcModal>
	</div>
</template>

<script>
import AdvancedInput from './AdvancedInput/AdvancedInput.vue'
import { getFilePickerBuilder, showError } from '@nextcloud/dialogs'
import { getCapabilities } from '@nextcloud/capabilities'
import Quote from '../Quote.vue'
import NcButton from '@nextcloud/vue/dist/Components/NcButton.js'
import NcActions from '@nextcloud/vue/dist/Components/NcActions.js'
import NcActionButton from '@nextcloud/vue/dist/Components/NcActionButton.js'
import NcEmojiPicker from '@nextcloud/vue/dist/Components/NcEmojiPicker.js'
import { EventBus } from '../../services/EventBus.js'
import { shareFile, createTextFile } from '../../services/filesSharingServices.js'
import { CONVERSATION, PARTICIPANT } from '../../constants.js'
import Paperclip from 'vue-material-design-icons/Paperclip.vue'
import EmoticonOutline from 'vue-material-design-icons/EmoticonOutline.vue'
import Send from 'vue-material-design-icons/Send.vue'
import BellOff from 'vue-material-design-icons/BellOff.vue'
import AudioRecorder from './AudioRecorder/AudioRecorder.vue'
import SimplePollsEditor from './SimplePollsEditor/SimplePollsEditor.vue'
import Poll from 'vue-material-design-icons/Poll.vue'
import NcModal from '@nextcloud/vue/dist/Components/NcModal.js'
import Folder from 'vue-material-design-icons/Folder.vue'
import Upload from 'vue-material-design-icons/Upload.vue'
import NcTextField from '@nextcloud/vue/dist/Components/NcTextField.js'
import TemplatePreview from './TemplatePreview.vue'

const picker = getFilePickerBuilder(t('spreed', 'File to share'))
	.setMultiSelect(false)
	.setModal(true)
	.setType(1)
	.allowDirectories()
	.build()

const border = 2
const margin = 8
const width = margin * 20

export default {

	name: 'NewMessageForm',

	components: {
		AdvancedInput,
		Quote,
		NcActions,
		NcActionButton,
		NcButton,
		Paperclip,
		NcEmojiPicker,
		EmoticonOutline,
		Send,
		AudioRecorder,
		BellOff,
		SimplePollsEditor,
		Poll,
		NcModal,
		Folder,
		Upload,
		TemplatePreview,
		NcTextField,
	},

	props: {
		isChatScrolledToBottom: {
			type: Boolean,
			default: true,
		},

		/**
		 * The current conversation token or the breakout room token.
		 */
		token: {
			type: String,
			required: true,
		},

		/**
		 * When this component is used to send message to a breakout room we
		 * adapt the layout and remove some functionality.
		 */
		breakoutRoom: {
			type: Boolean,
			default: false,
		},

		/**
		 * Broadcast messages to all breakout rooms of a given conversation.
		 */
		broadcast: {
			type: Boolean,
			default: false,
		},
	},

	data() {
		return {
			text: '',
			parsedText: '',
			conversationIsFirstInList: false,
			// True when the audiorecorder component is recording
			isRecordingAudio: false,
			showSimplePollsEditor: false,
			showTextFileDialog: false,
			textFileTitle: t('spreed', 'New file'),
			newFileError: '',

			// Check empty template by default
			checked: -1,
		}
	},

	computed: {
		conversation() {
			return this.$store.getters.conversation(this.token) || {
				readOnly: CONVERSATION.STATE.READ_WRITE,
			}
		},

		isReadOnly() {
			return this.conversation.readOnly === CONVERSATION.STATE.READ_ONLY
		},

		noChatPermission() {
			return (this.conversation.permissions & PARTICIPANT.PERMISSIONS.CHAT) === 0
		},

		disabled() {
			return this.isReadOnly || this.noChatPermission || this.isReadOnly || !this.currentConversationIsJoined || this.isRecordingAudio
		},

		placeholderText() {
			if (this.isReadOnly) {
				return t('spreed', 'This conversation has been locked')
			} else if (this.noChatPermission) {
				return t('spreed', 'No permission to post messages in this conversation')
			} else if (!this.currentConversationIsJoined) {
				return t('spreed', 'Joining conversation …')
			} else {
				return t('spreed', 'Write message, @ to mention someone …')
			}
		},

		messageToBeReplied() {
			return this.$store.getters.getMessageToBeReplied(this.token)
		},

		currentUserIsGuest() {
			return this.$store.getters.getUserId() === null
		},

		canShareFiles() {
			return !this.currentUserIsGuest
		},

		canUploadFiles() {
			const allowed = getCapabilities()?.spreed?.config?.attachments?.allowed
			return allowed
				&& this.attachmentFolderFreeSpace !== 0
				&& this.canShareFiles
		},

		canCreatePoll() {
			return !this.isOneToOne && !this.noChatPermission
		},

		attachmentFolderFreeSpace() {
			return this.$store.getters.getAttachmentFolderFreeSpace()
		},

		currentConversationIsJoined() {
			return this.$store.getters.currentConversationIsJoined
		},

		hasText() {
			return this.parsedText !== ''
		},

		container() {
			return this.$store.getters.getMainContainerSelector()
		},

		containerElement() {
			return document.querySelector(this.container)
		},

		isOneToOne() {
			return this.conversation.type === CONVERSATION.TYPE.ONE_TO_ONE
				|| this.conversation.type === CONVERSATION.TYPE.ONE_TO_ONE_FORMER
		},

		silentSendInfo() {
			if (this.isOneToOne) {
				return t('spreed', 'The participant will not be notified about this message')
			} else {
				return t('spreed', 'The participants will not be notified about this message')
			}
		},

		shareFromNextcloudLabel() {
			return t('spreed', 'Share from {nextcloud}', { nextcloud: OC.theme.productName })
		},

		fileTemplateOptions() {
			return this.$store.getters.getFileTemplates()
		},

		fileTemplate() {
			return this.fileTemplateOptions[this.showTextFileDialog]
		},

		emptyTemplate() {
			return {
				basename: t('files', 'Blank'),
				fileid: -1,
				filename: t('files', 'Blank'),
				hasPreview: false,
				mime: this.fileTemplate?.mimetypes[0] || this.fileTemplate?.mimetypes,
			}
		},

		selectedTemplate() {
			return this.fileTemplate.templates.find(template => template.fileid === this.checked)
		},

		style() {
			return {
				'--margin': margin + 'px',
				'--width': width + 'px',
				'--border': border + 'px',
				'--fullwidth': width + 2 * margin + 2 * border + 'px',
				'--height': this.fileTemplate.ratio ? Math.round(width / this.fileTemplate.ratio) + 'px' : null,
			}
		},

		showAttachmentsMenu() {
			return (this.canUploadFiles || this.canShareFiles) && !this.broadcast
		},
	},

	watch: {
		currentConversationIsJoined() {
			this.$refs.advancedInput.focusInput()
		},

		text(newValue) {
			this.$store.dispatch('setCurrentMessageInput', { token: this.token, text: newValue })
		},

		token(token) {
			if (token) {
				this.text = this.$store.getters.currentMessageInput(token) || ''
			} else {
				this.text = ''
			}
		},

		showTextFileDialog(newValue) {
			if (newValue !== false) {
				const fileTemplate = this.fileTemplateOptions[newValue]
				this.textFileTitle = fileTemplate.label + fileTemplate.extension
				this.$nextTick(() => {
					this.focusTextDialogInput()
				})
			}
		},
	},

	mounted() {
		EventBus.$on('upload-start', this.handleUploadStart)
		EventBus.$on('retry-message', this.handleRetryMessage)
		this.text = this.$store.getters.currentMessageInput(this.token) || ''
		// this.startRecording()

		if (!this.$store.getters.areFileTemplatesInitialised) {
			this.$store.dispatch('getFileTemplates')
		}
	},

	beforeDestroy() {
		EventBus.$off('upload-start', this.handleUploadStart)
		EventBus.$off('retry-message', this.handleRetryMessage)
	},

	methods: {
		handleUploadStart() {
			// refocus on upload start as the user might want to type again
			// while the upload is running
			this.$refs.advancedInput.focusInput()
		},

		contentEditableToParsed(contentEditable) {
			const mentions = contentEditable.querySelectorAll('span[data-at-embedded]')
			mentions.forEach(mention => {
				// FIXME Adding a space after the mention should be improved to
				// do it or not based on the next element instead of always
				// adding it.
				mention.replaceWith(' @' + mention.firstElementChild.attributes['data-mention-id'].value + ' ')
			})

			this.parsedText = this.rawToParsed(contentEditable.innerHTML)
		},
		/**
		 * Returns a parsed version of the given raw text of the content
		 * editable div.
		 *
		 * The given raw text contains a plain text representation of HTML
		 * content (like "first&nbsp;line<br>second&nbsp;line"). The returned
		 * parsed text replaces the (known) HTML content with the format
		 * expected by the server (like "first line\nsecond line").
		 *
		 * The parsed text is also trimmed.
		 *
		 * @param {string} text the raw text
		 * @return {string} the parsed text
		 */
		rawToParsed(text) {
			text = text.replace(/<br>/g, '\n')
			text = text.replace(/<div>/g, '\n')
			text = text.replace(/<\/div>/g, '')
			text = text.replace(/&nbsp;/g, ' ')

			// Since we used innerHTML to get the content of the div.contenteditable
			// it is escaped. With this little trick from https://stackoverflow.com/a/7394787
			// We unescape the code again, so if you write `<strong>` we can display
			// it again instead of `&lt;strong&gt;`
			const temp = document.createElement('textarea')
			temp.innerHTML = text
			text = temp.value

			// Although the text is fully trimmed, at the very least the last
			// "\n" occurrence should be always removed, as browsers add a
			// "<br>" element as soon as some rich text is written in a content
			// editable div (for example, if a new line is added the div content
			// will be "<br><br>").
			return text.trim()
		},

		/**
		 * Sends the new message
		 *
		 * @param {object} options the submit options
		 */
		async handleSubmit(options) {
			if (OC.debug && this.parsedText.startsWith('/spam ')) {
				const pattern = /^\/spam (\d+) messages$/i
				const match = pattern.exec(this.parsedText)
				// Escape HTML
				if (match) {
					await this.handleSubmitSpam(match[1])
					return
				}
			}

			if (this.parsedText !== '') {
				const temporaryMessage = await this.$store.dispatch('createTemporaryMessage', { text: this.parsedText, token: this.token })
				// FIXME: move "addTemporaryMessage" into "postNewMessage" as it's a pre-requisite anyway ?
				if (!this.broadcast) {
					await this.$store.dispatch('addTemporaryMessage', temporaryMessage)
				}
				this.text = ''
				this.parsedText = ''

				if (!this.breakoutRoom) {
					// Scrolls the message list to the last added message
					EventBus.$emit('smooth-scroll-chat-to-bottom')
				}

				// Also remove the message to be replied for this conversation
				await this.$store.dispatch('removeMessageToBeReplied', this.token)

				this.breakoutRoom
					? await this.broadcastMessage(temporaryMessage, options)
					: await this.postMessage(temporaryMessage, options)
			}
		},

		// Post message to conversation
		async postMessage(temporaryMessage, options) {
			try {
				await this.$store.dispatch('postNewMessage', { temporaryMessage, options })
				this.$emit('sent')
			} catch {
				this.$emit('failure')
			}
		},

		// Broadcast message to all breakout rooms
		async broadcastMessage(temporaryMessage, options) {
			try {
				await this.$store.dispatch('broadcastMessageToBreakoutRoomsAction', { temporaryMessage, options })
				this.$emit('sent')
			} catch {
				this.$emit('failure')
			}
		},

		async handleSubmitSpam(numberOfMessages) {
			console.debug('Sending ' + numberOfMessages + ' lorem ipsum messages')
			for (let i = 0; i < numberOfMessages; i++) {
				const randomNumber = parseInt(Math.random() * 500, 10)
				console.debug('[' + i + '/' + numberOfMessages + '] Sleeping ' + randomNumber + 'ms')
				await this.sleep(randomNumber)

				const loremIpsum = 'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.\n\nDuis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.'
				this.parsedText = loremIpsum.slice(0, 25 + randomNumber)
				await this.handleSubmit()
			}
		},

		sleep(ms) {
			return new Promise(resolve => setTimeout(resolve, ms))
		},

		handleRetryMessage(temporaryMessageId) {
			if (this.parsedText === '') {
				const temporaryMessage = this.$store.getters.message(this.token, temporaryMessageId)
				if (temporaryMessage) {
					this.text = temporaryMessage.message || this.text
					this.parsedText = temporaryMessage.message || this.parsedText

					// Restore the parent/quote message
					if (temporaryMessage.parent) {
						const temporaryParent = this.$store.getters.message(this.token, temporaryMessage.parent)

						this.$store.dispatch('addMessageToBeReplied', {
							id: temporaryParent.id,
							actorId: temporaryParent.actorId,
							actorType: temporaryParent.actorType,
							actorDisplayName: temporaryParent.actorDisplayName,
							timestamp: temporaryParent.timestamp,
							systemMessage: temporaryParent.systemMessage,
							messageType: temporaryParent.messageType,
							message: temporaryParent.message,
							messageParameters: temporaryParent.messageParameters,
							token: temporaryParent.token,
							previousMessageId: temporaryParent.previousMessageId,
						})
					}

					this.$store.dispatch('removeTemporaryMessageFromStore', temporaryMessage)
				}
			}
		},

		async handleFileShare() {
			picker.pick()
				.then(async (path) => {
					console.debug(`path ${path} selected for sharing`)
					if (!path.startsWith('/')) {
						throw new Error(t('files', 'Invalid path selected'))
					}
					await shareFile(path, this.token)
					this.$refs.advancedInput.focusInput()
				})

			// FIXME Remove this hack once it is possible to set the parent
			// element of the file picker.
			// By default the file picker is a sibling of the fullscreen
			// element, so it is not visible when in fullscreen mode. It is not
			// possible to specify the parent nor to know when the file picker
			// was actually opened, so for the time being it is reparented if
			// needed shortly after calling it.
			setTimeout(() => {
				if (this.$store.getters.isFullscreen()) {
					document.getElementById('content-vue').appendChild(document.querySelector('.oc-dialog'))
				}
			}, 1000)
		},

		/**
		 * Clicks the hidden file input when clicking the correspondent NcActionButton,
		 * thus opening the file-picker
		 */
		clickImportInput() {
			this.$refs.fileUploadInput.click()
		},

		handleFileInput(event) {
			const files = Object.values(event.target.files)

			this.handleFiles(files)

			// Clear input to ensure that the change event will be emitted if
			// the same file is picked again.
			event.target.value = ''
		},

		/**
		 * Handles files pasting event
		 *
		 * @param {File[] | FileList} files pasted files list
		 */
		async handlePastedFiles(files) {
			await this.handleFiles(files, true)
		},

		/**
		 * Handles file upload
		 *
		 * @param {File[] | FileList} files pasted files list
		 * @param {boolean} rename whether to rename the files
		 * @param {boolean} isVoiceMessage indicates whether the file is a vooicemessage
		 */
		async handleFiles(files, rename = false, isVoiceMessage) {
			// Create a unique id for the upload operation
			const uploadId = new Date().getTime()
			// Uploads and shares the files
			await this.$store.dispatch('initialiseUpload', { files, token: this.token, uploadId, rename, isVoiceMessage })
		},

		/**
		 * Add selected emoji to text input area
		 *
		 * The emoji will be added at the current caret position, and any text
		 * currently selected will be replaced by the emoji. If the input area
		 * does not have the focus there will be no caret or selection; in that
		 * case the emoji will be added at the end.
		 *
		 * @param {string} emoji Emoji object
		 */
		addEmoji(emoji) {
			const selection = document.getSelection()

			const contentEditable = this.$refs.advancedInput.$refs.contentEditable

			// There is no select, or current selection does not start in the
			// content editable element, so just append the emoji at the end.
			if (!contentEditable.isSameNode(selection.anchorNode) && !contentEditable.contains(selection.anchorNode)) {
				// Browsers add a "<br>" element as soon as some rich text is
				// written in a content editable div (for example, if a new line
				// is added the div content will be "<br><br>"), so the emoji
				// has to be added before the last "<br>" (if any).
				if (this.text.endsWith('<br>')) {
					this.text = this.text.slice(0, this.text.lastIndexOf('<br>')) + emoji + '<br>'
				} else {
					this.text += emoji
				}

				return
			}

			// Although due to legacy reasons the API allows several ranges the
			// specification requires the selection to always have a single
			// range.
			// https://developer.mozilla.org/en-US/docs/Web/API/Selection#Multiple_ranges_in_a_selection
			const range = selection.getRangeAt(0)

			// Deleting the contents also collapses the range to the start.
			range.deleteContents()

			const emojiTextNode = document.createTextNode(emoji)
			range.insertNode(emojiTextNode)

			this.text = contentEditable.innerHTML

			range.setStartAfter(emojiTextNode)
		},

		handleAudioFile(payload) {
			this.handleFiles([payload], false, true)
		},

		handleRecording(payload) {
			this.isRecordingAudio = payload
		},

		toggleSimplePollsEditor(value) {
			this.showSimplePollsEditor = value
		},

		/**
		 * Manages the radio template picker change
		 *
		 * @param {number} fileid the selected template file id
		 */
		onCheck(fileid) {
			this.checked = fileid
		},

		// Create text file and share it to a conversation
		async handleCreateTextFile() {
			this.newFileError = ''
			let filePath = this.$store.getters.getAttachmentFolder() + '/' + this.textFileTitle.replace('/', '')

			if (!filePath.endsWith(this.fileTemplate.extension)) {
				filePath += this.fileTemplate.extension
			}

			let fileData
			try {
				const response = await createTextFile(
					filePath,
					this.selectedTemplate?.filename,
					this.selectedTemplate?.templateType,
				)
				fileData = response.data.ocs.data
			} catch (error) {
				console.error('Error while creating file', error)
				if (error?.response?.data?.ocs?.meta?.message) {
					showError(error.response.data.ocs.meta.message)
					this.newFileError = error.response.data.ocs.meta.message
				} else {
					showError(t('spreed', 'Error while creating file'))
				}
				return
			}

			await shareFile(filePath, this.token, '', '')

			// The Viewer expects a file to be set in the sidebar if the sidebar
			// is open.
			if (this.$store.getters.getSidebarStatus) {
				OCA.Files.Sidebar.state.file = filePath
			}

			OCA.Viewer.open({
				// Viewer expects an internal absolute path starting with "/".
				path: filePath,
				list: [
					fileData,
				],
			})

			// FIXME Remove this hack once it is possible to set the parent
			// element of the viewer.
			// By default the viewer is a sibling of the fullscreen element, so
			// it is not visible when in fullscreen mode. It is not possible to
			// specify the parent nor to know when the viewer was actually
			// opened, so for the time being it is reparented if needed shortly
			// after calling it.
			setTimeout(() => {
				if (this.$store.getters.isFullscreen()) {
					document.getElementById('content-vue').appendChild(document.getElementById('viewer'))
				}
			}, 1000)

			this.dismissTextFileCreation()
		},

		dismissTextFileCreation() {
			this.showTextFileDialog = false
			this.textFileTitle = t('spreed', 'New file')
			this.newFileError = ''
		},

		// Focus and select the text within the input field
		focusTextDialogInput() {
			// this.$refs.textFileTitleInput.$refs.inputField.$refs.input.focus()
			this.$refs.textFileTitleInput.$refs.inputField.$refs.input.select()

		},
	},
}
</script>

<style lang="scss" scoped>
@import '../../assets/variables';

.wrapper {
	display: flex;
	justify-content: center;
	padding: 12px 0;
	border-top: 1px solid var(--color-border);
	min-height: 69px;
	&--chatScrolledToBottom {
		border-top: none;
	}
}

.new-message {
	width: 100%;
	display: flex;
	justify-content: center;
	&-form {
		align-items: flex-end;
		display: flex;
		position:relative;
		flex: 0 1 700px;
		margin: 0 4px;
		&__emoji-picker {
			position: absolute;
			left: 5px;
			bottom: 1px;
			z-index: 1;
		}

		&__input {
			flex-grow: 1;
			overflow: hidden;
			position: relative;
			padding: 2px;
		}
		&__quote {
			margin: 0 16px 12px 24px;
			background-color: var(--color-background-hover);
			padding: 8px;
			border-radius: var(--border-radius-large);
		}

		// put a grey round background when popover is opened
		// or hover-focused
		&__icon:hover,
		&__icon:focus,
		&__icon:active {
			opacity: $opacity_full;
			// good looking on dark AND white bg
			background-color: $icon-focus-bg;
		}

	}
}

// Override actions styles TODO: upstream this change
// Targeting two classess for specificity
::v-deep .action-item__menutoggle.action-item__menutoggle--with-icon-slot {
	opacity: 1 !important;
	&:hover,
	&:focus {
		background-color: var(--color-background-hover) !important;
	}
	&:disabled {
		opacity: .5 !important;
	}
}

.new-text-file {
	display: flex;
	justify-content: center;
	align-items: center;
	flex-direction: column;
	gap: 28px;
	padding: 20px;

	&__buttons {
		display: flex;
		gap: 4px;
		justify-content: center;
		margin-top: 20px;
	}

	&__form {
		width: 100%;

		.templates-picker__list {
			margin-top: 20px;
			display: grid;
			grid-gap: calc(var(--margin) * 2);
			grid-auto-columns: 1fr;
			// We want maximum 5 columns. Putting 6 as we don't count the grid gap. So it will always be lower than 6
			max-width: calc(var(--fullwidth) * 6);
			grid-template-columns: repeat(auto-fit, var(--fullwidth));
			// Make sure all rows are the same height
			grid-auto-rows: 1fr;
			// Center the columns set
			justify-content: center;
		}
	}
}
</style>
