import 'package:json_annotation/json_annotation.dart';

part 'booking_client_info.g.dart';

/// The `client` object nested inside GET /v1/staff/bookings/[id] — a
/// slice of the customer's record scoped to what the barber's working
/// screen needs (contact info, visit count, and their visible
/// preferences). Distinct from any customer-module client model: this is
/// staff-facing data reached only through the staff auth flow.
@JsonSerializable()
class BookingClientInfo {
  final String name;
  final String phone;
  final int totalVisits;

  /// `clients.customer_notes` — preferences, visible to the barber (and
  /// any other staff who open this booking). Not private: see
  /// BookingDetailModel.staffNotes for the barber-only counterpart.
  final String? customerNotes;

  const BookingClientInfo({
    required this.name,
    required this.phone,
    required this.totalVisits,
    required this.customerNotes,
  });

  factory BookingClientInfo.fromJson(Map<String, dynamic> json) =>
      _$BookingClientInfoFromJson(json);

  Map<String, dynamic> toJson() => _$BookingClientInfoToJson(this);

  BookingClientInfo copyWith({String? customerNotes}) {
    return BookingClientInfo(
      name: name,
      phone: phone,
      totalVisits: totalVisits,
      customerNotes: customerNotes ?? this.customerNotes,
    );
  }
}
