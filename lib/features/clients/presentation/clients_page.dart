import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_bloc.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_event.dart';
import 'package:scheduler_frontend/features/clients/bloc/clients_state.dart';
import 'package:scheduler_frontend/features/clients/data/client_model.dart';
import 'package:scheduler_frontend/features/clients/presentation/widgets/client_card.dart';
import 'package:scheduler_frontend/features/clients/presentation/widgets/client_form_sheet.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ClientModel> _filtered(List<ClientModel> clients) {
    final list = _query.isEmpty
        ? [...clients]
        : clients
            .where((c) {
              final q = _query.toLowerCase();
              return c.name.toLowerCase().contains(q) ||
                  (c.phone?.contains(q) ?? false) ||
                  (c.email?.toLowerCase().contains(q) ?? false);
            })
            .toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// Groups a sorted list by first letter, returning a flat list of entries
  /// (headers + items) ready to be rendered.
  List<_GroupEntry> _grouped(List<ClientModel> clients) {
    final entries = <_GroupEntry>[];
    String? currentLetter;
    for (final c in clients) {
      final letter =
          c.name.isNotEmpty ? c.name[0].toUpperCase() : '#';
      if (letter != currentLetter) {
        currentLetter = letter;
        entries.add(_LetterHeader(letter));
      }
      entries.add(_ClientEntry(c));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: BlocConsumer<ClientsBloc, ClientsState>(
        listener: (context, state) {
          if (state is ClientsError && state.clients.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ClientsLoading) {
            return Center(
              child: CircularProgressIndicator(color: context.appColors.primary),
            );
          }

          final allClients = switch (state) {
            ClientsLoaded(:final clients) => clients,
            ClientsActionInProgress(:final clients) => clients,
            ClientsError(:final clients) => clients,
            _ => <ClientModel>[],
          };

          final clients = _filtered(allClients);

          final businessState = context.read<BusinessBloc>().state;
          final businessId = businessState is BusinessLoaded
              ? businessState.active.id
              : '';

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Clientes',
                        style: AppTypography.headingMd.copyWith(
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      if (allClients.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _CountBadge(count: allClients.length),
                      ],
                      const Spacer(),
                      // TODO: hide for staff role
                      BaseButton(
                        label: 'Novo cliente',
                        prefixIcon: Icons.add,
                        onPressed: () => _openForm(context, initial: null),
                      ),
                    ],
                  ),
                ),

                // ── Search ──────────────────────────────────────────────
                if (allClients.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: _SearchField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),

                Divider(height: 1, color: context.appColors.outline),

                // ── Body ────────────────────────────────────────────────
                Expanded(
                  child: allClients.isEmpty
                      ? _EmptyState(
                          isFirstTime: true,
                          onAdd: () => _openForm(context, initial: null),
                        )
                      : clients.isEmpty
                          ? const _EmptyState(isFirstTime: false)
                          : _buildGroupedList(
                              context, _grouped(clients), businessId),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    List<_GroupEntry> entries,
    String businessId,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: entries.length,
      findChildIndexCallback: (key) {
        if (key is ValueKey<String>) {
          final idx = entries.indexWhere((e) => switch (e) {
                _LetterHeader(:final letter) => key.value == 'header_$letter',
                _ClientEntry(:final client) => key.value == client.id,
              });
          return idx >= 0 ? idx : null;
        }
        return null;
      },
      itemBuilder: (_, i) {
        final entry = entries[i];
        final isLastInGroup = i == entries.length - 1 ||
            entries[i + 1] is _LetterHeader;
        return switch (entry) {
          _LetterHeader(:final letter) => _SectionHeader(
              key: ValueKey('header_$letter'),
              letter: letter,
            ),
          _ClientEntry(:final client) => ClientCard(
              key: ValueKey(client.id),
              client: client,
              businessId: businessId,
              showDivider: !isLastInGroup,
              onEdit: () => _openForm(context, initial: client),
              onDelete: () => _confirmDelete(context, client),
            ),
        };
      },
    );
  }

  void _openForm(BuildContext context, {required ClientModel? initial}) {
    final businessState = context.read<BusinessBloc>().state;
    if (businessState is! BusinessLoaded) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ClientsBloc>(),
        child: ClientFormSheet(
          initial: initial,
          businessId: businessState.active.id,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, ClientModel client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: ctx.appColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    color: AppColors.error.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Excluir cliente',
                    style: AppTypography.labelLarge.copyWith(
                      color: ctx.appColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tem certeza que deseja excluir "${client.name}"? '
                'O vínculo com este negócio será removido, '
                'mas a conta do cliente será preservada.',
                style: AppTypography.bodySm.copyWith(
                  color: ctx.appColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: BaseButton(
                      label: 'Cancelar',
                      variant: BaseButtonVariant.secondary,
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: BaseButton(
                      label: 'Excluir',
                      variant: BaseButtonVariant.destructive,
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final businessState = context.read<BusinessBloc>().state;
      if (businessState is! BusinessLoaded) return;

      context.read<ClientsBloc>().add(ClientDeleteRequested(
            businessId: businessState.active.id,
            clientId: client.id,
          ));
    }
  }
}

// ── Count badge ───────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      color: context.appColors.surfaceHigh,
      child: Text(
        '$count',
        style: AppTypography.caption.copyWith(
          color: context.appColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Search field ──────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          style: AppTypography.bodySm.copyWith(
            color: context.appColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Buscar por nome, telefone ou e-mail…',
            hintStyle: AppTypography.bodySm.copyWith(
              color: context.appColors.textDisabled,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 18,
              color: context.appColors.textSecondary,
            ),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: context.appColors.textSecondary,
                    ),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : null,
            filled: true,
            fillColor: context.appColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: context.appColors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: context.appColors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(
                color: context.appColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isFirstTime;
  final VoidCallback? onAdd;

  const _EmptyState({required this.isFirstTime, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              color: context.appColors.surfaceHigh,
              child: Icon(
                isFirstTime ? Icons.people_outline : Icons.search_off_outlined,
                size: 24,
                color: context.appColors.textDisabled,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isFirstTime
                  ? 'Nenhum cliente cadastrado'
                  : 'Nenhum resultado encontrado',
              style: AppTypography.labelLarge.copyWith(
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isFirstTime
                  ? 'Adicione seu primeiro cliente para começar a\ngerenciar agendamentos.'
                  : 'Tente buscar por outro nome, telefone ou e-mail.',
              style: AppTypography.bodySm.copyWith(
                color: context.appColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFirstTime && onAdd != null) ...[
              const SizedBox(height: AppSpacing.xl),
              BaseButton(
                label: 'Adicionar cliente',
                prefixIcon: Icons.add,
                onPressed: onAdd,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String letter;
  const _SectionHeader({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            color: context.appColors.primary,
            child: Center(
              child: Text(
                letter,
                style: AppTypography.labelLarge.copyWith(
                  color: context.appColors.surface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Divider(
              height: 1,
              color: context.appColors.outline,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Group entry types ────────────────────────────────────────────────────────

sealed class _GroupEntry {}

class _LetterHeader extends _GroupEntry {
  final String letter;
  _LetterHeader(this.letter);
}

class _ClientEntry extends _GroupEntry {
  final ClientModel client;
  _ClientEntry(this.client);
}
