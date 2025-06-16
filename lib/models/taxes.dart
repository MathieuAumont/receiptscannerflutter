class Taxes {
  final double tps;
  final double tvq;

  Taxes({
    required this.tps,
    required this.tvq,
  });

  factory Taxes.fromJson(Map<String, dynamic> json) {
    return Taxes(
      tps: (json['tps'] as num).toDouble(),
      tvq: (json['tvq'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tps': tps,
      'tvq': tvq,
    };
  }
} 