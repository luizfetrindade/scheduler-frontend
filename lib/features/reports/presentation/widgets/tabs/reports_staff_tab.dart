import 'package:flutter/material.dart';
import 'package:scheduler_frontend/features/reports/data/reports_model.dart';
import 'package:scheduler_frontend/features/reports/presentation/widgets/staff_performance_list.dart';

class ReportsStaffTab extends StatelessWidget {
  final ReportsModel model;
  const ReportsStaffTab({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: StaffPerformanceList(staff: model.staff),
    );
  }
}
