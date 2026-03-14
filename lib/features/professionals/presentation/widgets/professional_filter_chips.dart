import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_bloc.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_event.dart';
import 'package:scheduler_frontend/features/appointments/bloc/schedule_state.dart';
import 'package:scheduler_frontend/features/professionals/data/professional_model.dart';

class ProfessionalFilterChips extends StatelessWidget {
  final List<ProfessionalModel> professionals;

  const ProfessionalFilterChips({super.key, required this.professionals});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        final activeFilter = state is ScheduleLoaded
            ? state.activeProfessionalFilter
            : null;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: const Text('Todos'),
                  selected: activeFilter == null,
                  onSelected: (_) => context
                      .read<ScheduleBloc>()
                      .add(const ScheduleFilterByProfessional(null)),
                ),
              ),
              ...professionals.map(
                (prof) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(prof.name),
                    selected: activeFilter == prof.id,
                    onSelected: (_) => context
                        .read<ScheduleBloc>()
                        .add(ScheduleFilterByProfessional(prof.id)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
