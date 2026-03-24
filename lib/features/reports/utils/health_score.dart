/// Retorna score de saúde do negócio entre 0 e 100.
///
/// [revenueDelta] deve ser 0.0 quando previousRealized == 0.
/// Caller é responsável por computar: previousRealized > 0
///   ? (realized - previousRealized) / previousRealized
///   : 0.0
double computeHealthScore({
  required double occupancyRate,
  required double revenueDelta,
  required double clientReturnRate,
  required double cancellationRate,
  required double noShowRate,
}) {
  final occupancyScore = occupancyRate.clamp(0.0, 1.0) * 100 * 0.30;
  final revenueScore = ((revenueDelta + 1.0).clamp(0.5, 1.5) / 1.5) * 100 * 0.25;
  final retentionScore = clientReturnRate.clamp(0.0, 1.0) * 100 * 0.25;
  final operationScore =
      (1.0 - (cancellationRate + noShowRate).clamp(0.0, 1.0)) * 100 * 0.20;
  return (occupancyScore + revenueScore + retentionScore + operationScore).clamp(0, 100);
}

String healthScoreLabel(double score) {
  if (score >= 80) return 'Seu negócio está excelente este período';
  if (score >= 60) return 'Seu negócio está bem — há espaço para crescer';
  if (score >= 40) return 'Atenção necessária em algumas áreas';
  return 'Seu negócio precisa de ajustes importantes';
}
