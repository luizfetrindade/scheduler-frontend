import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/services/bloc/services_bloc.dart';
import 'package:scheduler_frontend/features/services/bloc/services_state.dart';
import 'package:scheduler_frontend/features/services/data/service_model.dart';
import 'package:scheduler_frontend/features/services/presentation/widgets/service_form_sheet.dart';

class WizardServicesStep extends StatelessWidget {
  const WizardServicesStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (context, state) {
        final services = state is ServicesLoaded
            ? state.services
            : <ServiceModel>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (services.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'Nenhum serviço cadastrado ainda.',
                  style: AppTypography.bodySm.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Expanded(
                child: ListView(
                  children: services
                      .map(
                        (s) => ListTile(
                          title: Text(s.name),
                          subtitle: s.price != null
                              ? Text('R\$ ${s.price!.toStringAsFixed(2)}')
                              : null,
                        ),
                      )
                      .toList(),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            BaseButton(
              label: '+ Adicionar serviço',
              variant: BaseButtonVariant.secondary,
              onPressed: () => _openForm(context),
            ),
          ],
        );
      },
    );
  }

  void _openForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<ServicesBloc>()),
          BlocProvider.value(value: context.read<BusinessBloc>()),
        ],
        child: const ServiceFormSheet(initial: null),
      ),
    );
  }
}
