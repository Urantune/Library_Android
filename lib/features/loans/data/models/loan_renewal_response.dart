class LoanRenewalResponseDTO {
  const LoanRenewalResponseDTO({
    required this.id,
    required this.loanId,
    required this.requestedBy,
    required this.status,
    this.requestedAt,
    this.previousDueAt,
    this.newDueAt,
    this.approvedBy,
    this.decisionAt,
    this.reason,
  });

  final String id;
  final String loanId;
  final String requestedBy;
  final String status;
  final DateTime? requestedAt;
  final DateTime? previousDueAt;
  final DateTime? newDueAt;
  final String? approvedBy;
  final DateTime? decisionAt;
  final String? reason;

  factory LoanRenewalResponseDTO.fromJson(Map<String, dynamic> json) {
    return LoanRenewalResponseDTO(
      id: (json['id'] ?? '').toString(),
      loanId: (json['loanId'] ?? '').toString(),
      requestedBy: (json['requestedBy'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      requestedAt: _parseDate(json['requestedAt']),
      previousDueAt: _parseDate(json['previousDueAt']),
      newDueAt: _parseDate(json['newDueAt']),
      approvedBy: json['approvedBy']?.toString(),
      decisionAt: _parseDate(json['decisionAt']),
      reason: json['reason']?.toString(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    return DateTime.tryParse(value.toString());
  }
}
