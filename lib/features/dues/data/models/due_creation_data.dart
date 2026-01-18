class DueCreationData {
  final String? title;
  final String? description;
  final String? imageUrl;
  final double? amount;
  final String? frequency;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? automaticDeduction;
  final bool? automaticReminder;
  final String? communityId;

  DueCreationData({
    this.title,
    this.description,
    this.imageUrl,
    this.amount,
    this.frequency,
    this.startDate,
    this.endDate,
    this.automaticDeduction,
    this.automaticReminder,
    this.communityId,
  });

  DueCreationData copyWith({
    String? title,
    String? description,
    String? imageUrl,
    double? amount,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool? automaticDeduction,
    bool? automaticReminder,
    String? communityId,
  }) {
    return DueCreationData(
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      automaticDeduction: automaticDeduction ?? this.automaticDeduction,
      automaticReminder: automaticReminder ?? this.automaticReminder,
      communityId: communityId ?? this.communityId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'amount': amount,
      'frequency': frequency,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'automaticDeduction': automaticDeduction,
      'automaticReminder': automaticReminder,
      'communityId': communityId,
    };
  }

  factory DueCreationData.fromJson(Map<String, dynamic> json) {
    return DueCreationData(
      title: json['title'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      amount: json['amount']?.toDouble(),
      frequency: json['frequency'],
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      automaticDeduction: json['automaticDeduction'],
      automaticReminder: json['automaticReminder'],
      communityId: json['communityId'],
    );
  }
}
