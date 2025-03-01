Feature: callapi/recording
  Background:
    Given user "participant1" exists
    Given user "participant2" exists

  Scenario: Start and stop video recording
    When the following "spreed" app config is set
      | signaling_dev | yes |
    And user "participant1" creates room "room1" (v4)
      | roomType | 2 |
      | roomName | room1 |
    And user "participant1" joins room "room1" with 200 (v4)
    And user "participant1" joins call "room1" with 200 (v4)
    And user "participant1" starts "video" recording in room "room1" with 200 (v1)
    Then user "participant1" sees the following system messages in room "room1" with 200 (v1)
      | room  | actorType | actorId      | actorDisplayName         | systemMessage        |
      | room1 | users     | participant1 | participant1-displayname | recording_started    |
      | room1 | users     | participant1 | participant1-displayname | call_started         |
      | room1 | users     | participant1 | participant1-displayname | conversation_created |
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 1             |
    When user "participant1" stops recording in room "room1" with 200 (v1)
    Then user "participant1" sees the following system messages in room "room1" with 200 (v1)
      | room  | actorType | actorId      | actorDisplayName         | systemMessage        |
      | room1 | users     | participant1 | participant1-displayname | recording_stopped    |
      | room1 | users     | participant1 | participant1-displayname | recording_started    |
      | room1 | users     | participant1 | participant1-displayname | call_started         |
      | room1 | users     | participant1 | participant1-displayname | conversation_created |
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 0             |

  Scenario: Start and stop audio recording
    When the following "spreed" app config is set
      | signaling_dev | yes |
    And user "participant1" creates room "room1" (v4)
      | roomType | 2 |
      | roomName | room1 |
    And user "participant1" joins room "room1" with 200 (v4)
    And user "participant1" joins call "room1" with 200 (v4)
    And user "participant1" starts "audio" recording in room "room1" with 200 (v1)
    Then user "participant1" sees the following system messages in room "room1" with 200 (v1)
      | room  | actorType | actorId      | actorDisplayName         | systemMessage           |
      | room1 | users     | participant1 | participant1-displayname | audio_recording_started |
      | room1 | users     | participant1 | participant1-displayname | call_started            |
      | room1 | users     | participant1 | participant1-displayname | conversation_created    |
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 2             |
    When user "participant1" stops recording in room "room1" with 200 (v1)
    Then user "participant1" sees the following system messages in room "room1" with 200 (v1)
      | room  | actorType | actorId      | actorDisplayName         | systemMessage           |
      | room1 | users     | participant1 | participant1-displayname | audio_recording_stopped |
      | room1 | users     | participant1 | participant1-displayname | audio_recording_started |
      | room1 | users     | participant1 | participant1-displayname | call_started            |
      | room1 | users     | participant1 | participant1-displayname | conversation_created    |
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 0             |

  Scenario: Get error when start|stop recording and already did this
    Given the following "spreed" app config is set
      | signaling_dev | yes |
    And user "participant1" creates room "room1" (v4)
      | roomType | 2 |
      | roomName | room1 |
    And user "participant1" joins room "room1" with 200 (v4)
    And user "participant1" joins call "room1" with 200 (v4)
    When user "participant1" starts "audio" recording in room "room1" with 200 (v1)
    Then user "participant1" starts "audio" recording in room "room1" with 400 (v1)
    And the response error matches with "recording"
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 2             |
    When user "participant1" stops recording in room "room1" with 200 (v1)
    Then user "participant1" stops recording in room "room1" with 200 (v1)
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 0             |
    When user "participant1" starts "video" recording in room "room1" with 200 (v1)
    Then user "participant1" starts "video" recording in room "room1" with 400 (v1)
    And the response error matches with "recording"
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 1             |
    When user "participant1" stops recording in room "room1" with 200 (v1)
    Then user "participant1" stops recording in room "room1" with 200 (v1)
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 0             |

  Scenario: Get error when try to start recording with invalid status
    When the following "spreed" app config is set
      | signaling_dev | yes |
    And user "participant1" creates room "room1" (v4)
      | roomType | 2 |
      | roomName | room1 |
    And user "participant1" joins room "room1" with 200 (v4)
    And user "participant1" joins call "room1" with 200 (v4)
    Then user "participant1" starts "invalid" recording in room "room1" with 400 (v1)
    And the response error matches with "status"
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 0             |

  Scenario: Manager try without success to start recording when signaling is internal
    When the following "spreed" app config is set
      | signaling_dev | no |
    And user "participant1" creates room "room1" (v4)
      | roomType | 2 |
      | roomName | room1 |
    And user "participant1" joins room "room1" with 200 (v4)
    And user "participant1" joins call "room1" with 200 (v4)
    Then user "participant1" starts "video" recording in room "room1" with 400 (v1)
    And the response error matches with "config"
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 0             |
    And user "participant1" starts "audio" recording in room "room1" with 400 (v1)
    And the response error matches with "config"
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 0             |

  Scenario: Get error when non moderator/owner try to start recording
    Given the following "spreed" app config is set
      | signaling_dev | yes |
    And user "participant1" creates room "room1" (v4)
      | roomType | 2 |
      | roomName | room1 |
    And user "participant1" joins room "room1" with 200 (v4)
    And user "participant1" joins call "room1" with 200 (v4)
    When user "participant1" adds user "participant2" to room "room1" with 200 (v4)
    And user "participant2" joins room "room1" with 200 (v4)
    And user "participant2" joins call "room1" with 200 (v4)
    Then user "participant2" starts "video" recording in room "room1" with 403 (v1)
    And user "participant2" starts "audio" recording in room "room1" with 403 (v1)
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 0             |

  Scenario: Get error when try to start recording and no call started
    Given the following "spreed" app config is set
      | signaling_dev | yes |
    And user "participant1" creates room "room1" (v4)
      | roomType | 2 |
      | roomName | room1 |
    Then user "participant1" starts "video" recording in room "room1" with 400 (v1)
    And the response error matches with "call"
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 0             |
    Then user "participant1" starts "audio" recording in room "room1" with 400 (v1)
    And the response error matches with "call"
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 0             |

  Scenario: Store recording
    Given user "participant1" creates room "room1" (v4)
      | roomType | 2 |
      | roomName | room1 |
    And user "participant1" joins room "room1" with 200 (v4)
    Then user "participant1" store recording file "/img/join_call.ogg" in room "room1" with 200 (v1)
    And user "participant1" has the following notifications
      | app    | object_type | object_id | subject                                        |
      | spreed | chat        | room1     | Recording for the call in room1 was uploaded.  |
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 0             |

  Scenario: Stop recording automatically when end the call
    When the following "spreed" app config is set
      | signaling_dev | yes |
    And user "participant1" creates room "room1" (v4)
      | roomType | 2 |
      | roomName | room1 |
    And user "participant1" joins room "room1" with 200 (v4)
    And user "participant1" joins call "room1" with 200 (v4)
    And user "participant1" starts "audio" recording in room "room1" with 200 (v1)
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 2             |
    Then user "participant1" ends call "room1" with 200 (v4)
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 0             |

  Scenario: Stop recording automatically when the last participant go out
    When the following "spreed" app config is set
      | signaling_dev | yes |
    And user "participant1" creates room "room1" (v4)
      | roomType | 2 |
      | roomName | room1 |
    And user "participant1" joins room "room1" with 200 (v4)
    And user "participant1" joins call "room1" with 200 (v4)
    And user "participant1" starts "audio" recording in room "room1" with 200 (v1)
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 2             |
    Then user "participant1" leaves room "room1" with 200 (v4)
    And user "participant1" is participant of the following unordered rooms (v4)
      | type | name  | callRecording |
      | 2    | room1 | 0             |
