import 'package:scheduler_frontend/features/reports/data/reports_model.dart';

enum AlertSeverity { high, medium, positive }

class ReportAlert {
  final AlertSeverity severity;
  final String message;
  final String detail;
  const ReportAlert({required this.severity, required this.message, required this.detail});
}

List<ReportAlert> buildAlerts(ReportsModel model) {
  final alerts = <ReportAlert>[];
  final appts = model.appointments;
  final rev = model.revenue;
  final clients = model.clients;

  // Alta — cancelamento
  final cancellationDelta = appts.cancellationRate - appts.previousCancellationRate;
  if (appts.cancellationRate > 0.15 || cancellationDelta > 0.03) {
    final pct = (appts.cancellationRate * 100).toStringAsFixed(0);
    alerts.add(ReportAlert(
      severity: AlertSeverity.high,
      message: 'Taxa de cancelamento subiu para $pct%',
      detail: 'Considere ativar confirmações automáticas de agendamento.',
    ));
  }

  // Média — clientes em risco
  if (clients.atRisk.length > 10) {
    alerts.add(ReportAlert(
      severity: AlertSeverity.medium,
      message: '${clients.atRisk.length} clientes sem agendar há mais de 60 dias',
      detail: 'Oportunidade de reativação — veja a lista na aba Clientes.',
    ));
  }

  // Média — ocupação baixa
  if (model.occupancy.occupancyRate < 0.60) {
    final pct = (model.occupancy.occupancyRate * 100).toStringAsFixed(0);
    alerts.add(ReportAlert(
      severity: AlertSeverity.medium,
      message: 'Ocupação abaixo de 60% ($pct%)',
      detail: 'Considere abrir novos horários ou promover serviços.',
    ));
  }

  // Positivo — receita cresceu
  if (rev.previousRealized > 0) {
    final revenueDelta = (rev.realized - rev.previousRealized) / rev.previousRealized;
    if (revenueDelta > 0.10) {
      final pct = (revenueDelta * 100).toStringAsFixed(0);
      alerts.add(ReportAlert(
        severity: AlertSeverity.positive,
        message: 'Receita cresceu $pct% este período',
        detail: 'Ótimo desempenho! Continue investindo nos serviços mais lucrativos.',
      ));
    }
  }

  // Positivo — clientes novos cresceram
  if (clients.previousNewClients > 0) {
    final newDelta = (clients.newClients - clients.previousNewClients) /
        clients.previousNewClients;
    if (newDelta > 0.10) {
      final pct = (newDelta * 100).toStringAsFixed(0);
      alerts.add(ReportAlert(
        severity: AlertSeverity.positive,
        message: '$pct% mais clientes novos que o período anterior',
        detail: 'Seu negócio está em expansão.',
      ));
    }
  }

  // Positivo — serviço top
  if (rev.topServices.isNotEmpty && rev.realized > 0) {
    final top = rev.topServices.first;
    if (top.revenue / rev.realized > 0.30) {
      final pct = ((top.revenue / rev.realized) * 100).toStringAsFixed(0);
      alerts.add(ReportAlert(
        severity: AlertSeverity.positive,
        message: '${top.name} representa $pct% da receita',
        detail: 'Seu serviço mais lucrativo do período.',
      ));
    }
  }

  // Ordenar: high → medium → positive
  alerts.sort((a, b) => a.severity.index.compareTo(b.severity.index));
  return alerts;
}
