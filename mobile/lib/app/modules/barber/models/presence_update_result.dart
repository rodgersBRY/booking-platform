import 'staff_presence.dart';

/// Result of PATCH /v1/staff/presence.
class PresenceUpdateResult {
  final bool success;
  final StaffPresence? presence;
  final String? presenceUpdatedAt;
  final String? errorCode;
  final String? message;

  PresenceUpdateResult.success(this.presence, this.presenceUpdatedAt)
    : success = true,
      errorCode = null,
      message = null;

  PresenceUpdateResult.failure(this.errorCode, this.message)
    : success = false,
      presence = null,
      presenceUpdatedAt = null;
}
