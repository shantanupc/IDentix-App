class QRData {
  final String userId;
  final int timestamp;
  final String dynamicHash;

  QRData({
    required this.userId,
    required this.timestamp,
    required this.dynamicHash,
  });

  factory QRData.fromJson(Map<String, dynamic> json) {
    return QRData(
      userId: json['user_id']?.toString() ?? '',
      timestamp: json['timestamp'] is int
          ? json['timestamp']
          : int.tryParse(json['timestamp']?.toString() ?? '0') ?? 0,
      dynamicHash: json['dynamic_hash']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'timestamp': timestamp,
      'dynamic_hash': dynamicHash,
    };
  }

  bool get isValid {
    return userId.isNotEmpty && timestamp > 0 && dynamicHash.isNotEmpty;
  }
}

class QRGenerationState {
  final String qrData;
  final int timestamp;
  final int generation;

  QRGenerationState({
    required this.qrData,
    required this.timestamp,
    required this.generation,
  });
}
