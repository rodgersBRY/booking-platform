/// The `client` object nested inside GET /v1/staff/bookings/[id] — a
/// slice of the customer's record scoped to what the barber's working
/// screen needs (contact info, visit count, and their visible
/// preferences). Distinct from any customer-module client model: this is
/// staff-facing data reached only through the staff auth flow.
class BookingClientInfo {
  final String name;
  final String phone;
  final int totalVisits;

  /// `clients.customer_notes` — preferences, visible to the barber (and
  /// any other staff who open this booking). Not private: see
  /// BookingDetailModel.staffNotes for the barber-only counterpart.
  final String? customerNotes;

  BookingClientInfo({
    required this.name,
    required this.phone,
    required this.totalVisits,
    required this.customerNotes,
  });

  factory BookingClientInfo.fromJson(Map<String, dynamic> json) {
    return BookingClientInfo(
      name: json['name'] as String,
      phone: json['phone'] as String,
      totalVisits: json['totalVisits'] as int,
      customerNotes: json['customerNotes'] as String?,
    );
  }

  BookingClientInfo copyWith({String? customerNotes}) {
    return BookingClientInfo(
      name: name,
      phone: phone,
      totalVisits: totalVisits,
      customerNotes: customerNotes ?? this.customerNotes,
    );
  }
}
