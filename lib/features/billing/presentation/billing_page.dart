import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/billing/bloc/billing_bloc.dart';
import 'package:scheduler_frontend/features/billing/bloc/billing_event.dart';
import 'package:scheduler_frontend/features/billing/bloc/billing_state.dart';
import 'package:scheduler_frontend/features/business/bloc/business_bloc.dart';
import 'package:scheduler_frontend/features/business/bloc/business_event.dart';
import 'package:scheduler_frontend/features/business/bloc/business_state.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';

// ── Plan display helpers ──────────────────────────────────────────────────────

String planDisplayName(String planName) => switch (planName.toUpperCase()) {
      'PRO' => 'Skedi Pro',
      'PREMIUM' => 'Skedi Plus',
      _ => 'Skedi Free',
    };

const _kDiscountColor = Color(0xFFF59E0B); // amber — shared by banner + border
const _kCheckColor = Color(0xFF43A047); // consistent green for all checkmarks

class _PlanInfo {
  final String backendKey; // 'FREE' | 'PRO' | 'PREMIUM'
  final String displayName;
  final String price;
  final String priceDetail;
  final List<String> features;
  final Color accentColor;
  /// When non-null the card switches to a limited-time offer layout and this
  /// string is rendered inside the amber discount banner (e.g. '50% OFF').
  final String? discount; // ignore: unused_element_parameter
  /// When true renders a "MAIS POPULAR" badge and a stronger border.
  final bool isPopular;

  const _PlanInfo({
    required this.backendKey,
    required this.displayName,
    required this.price,
    required this.priceDetail,
    required this.features,
    required this.accentColor,
    this.discount, // ignore: unused_element_parameter
    this.isPopular = false,
  });
}

const _plans = [
  _PlanInfo(
    backendKey: 'FREE',
    displayName: 'Skedi Free',
    price: 'R\$ 0',
    priceDetail: 'sem custos ocultos',
    features: [
      'Essencial para começar',
      '1 profissional',
      'Clientes ilimitados',
      'Agendamentos ilimitados',
    ],
    accentColor: Color(0xFF9E9E9E),
  ),
  _PlanInfo(
    backendKey: 'PREMIUM',
    displayName: 'Skedi Plus',
    price: 'R\$ 19,90',
    priceDetail: 'por mês',
    isPopular: true,
    features: [
      'Tudo do Free',
      'Ideal para autônomos em crescimento',
      'Visão clara do seu lucro',
      'Suporte prioritário via WhatsApp',
    ],
    accentColor: Color(0xFF5C6BC0),
    // discount: '50% OFF no 1º mês',  ← enable to activate promo layout
  ),
  _PlanInfo(
    backendKey: 'PRO',
    displayName: 'Skedi Pro',
    price: 'R\$ 75',
    priceDetail: 'por mês',
    features: [
      'Tudo do Plus',
      'Para negócios que querem escalar',
      'Múltiplos profissionais',
      'Dashboard financeiro completo',
      'Gestão de cargos',
    ],
    accentColor: Color(0xFF00897B),
  ),
];

// ── BillingPage ───────────────────────────────────────────────────────────────

class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> with WidgetsBindingObserver {
  bool _checkoutLaunched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _checkoutLaunched) {
      _checkoutLaunched = false;
      if (mounted) {
        context.read<BusinessBloc>().add(const BusinessLoadRequested());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BillingBloc, BillingState>(
      listener: (context, state) async {
        if (state is BillingCheckoutReady) {
          final billingBloc = context.read<BillingBloc>();
          final uri = Uri.parse(state.url);
          _checkoutLaunched = true;
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          billingBloc.add(const BillingSessionCleared());
        }
        if (state is BillingSubscriptionCancelled) {
          if (!context.mounted) return;
          context.read<BusinessBloc>().add(const BusinessLoadRequested());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Assinatura cancelada. Você voltou para o plano Skedi Free.'),
            ),
          );
        }
        if (state is BillingError) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
          context.read<BillingBloc>().add(const BillingSessionCleared());
        }
      },
      child: Scaffold(
        backgroundColor: context.appColors.background,
        body: SafeArea(
          child: BlocBuilder<BusinessBloc, BusinessState>(
            builder: (context, businessState) {
              if (businessState is! BusinessLoaded) {
                return const Center(child: CircularProgressIndicator());
              }
              return _BillingContent(business: businessState.active);
            },
          ),
        ),
      ),
    );
  }
}

// ── BillingContent ────────────────────────────────────────────────────────────

class _BillingContent extends StatelessWidget {
  final BusinessModel business;

  const _BillingContent({required this.business});

  bool get _isOwner => business.myStaffRole == StaffRole.owner;
  bool get _hasSubscription =>
      business.planName == 'PRO' || business.planName == 'PREMIUM';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Assinatura',
          style: AppTypography.headingMd.copyWith(
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Gerencie seu plano e assinatura',
          style: AppTypography.bodySm.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Current plan
        _CurrentPlanCard(planName: business.planName),
        const SizedBox(height: AppSpacing.xl),

        Text(
          'Planos disponíveis',
          style: AppTypography.labelLarge.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Cancele quando quiser. Sem fidelidade.',
          style: AppTypography.bodySm.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Three plan cards side by side ─────────────────────────────────
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(_plans.length, (i) {
              final plan = _plans[i];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : AppSpacing.xs,
                    right: i == _plans.length - 1 ? 0 : AppSpacing.xs,
                  ),
                  child: _PlanCard(
                    plan: plan,
                    isCurrent: plan.backendKey == business.planName,
                    isOwner: _isOwner,
                    slug: business.slug,
                  ),
                ),
              );
            }),
          ),
        ),

        // Cancel subscription (owner + active paid plan)
        if (_isOwner && _hasSubscription) ...[
          const SizedBox(height: AppSpacing.lg),
          _CancelSubscriptionSection(slug: business.slug),
        ],

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ── CurrentPlanCard ───────────────────────────────────────────────────────────

class _CurrentPlanCard extends StatelessWidget {
  final String planName;

  const _CurrentPlanCard({required this.planName});

  @override
  Widget build(BuildContext context) {
    final display = planDisplayName(planName);
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        border: Border.all(color: context.appColors.outline),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(Icons.workspace_premium,
              color: context.appColors.primary, size: 28),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plano atual',
                style: AppTypography.caption.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                display,
                style: AppTypography.titleLarge.copyWith(
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          _PlanBadge(planName: planName),
        ],
      ),
    );
  }
}

// ── PlanCard ──────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final _PlanInfo plan;
  final bool isCurrent;
  final bool isOwner;
  final String slug;

  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.isOwner,
    required this.slug,
  });

  Color _borderColor(BuildContext context) {
    if (plan.discount != null) return _kDiscountColor;
    if (isCurrent) return context.appColors.primary;
    if (plan.isPopular) return plan.accentColor;
    return context.appColors.outline;
  }

  double get _borderWidth =>
      (plan.discount != null || isCurrent || plan.isPopular) ? 2 : 1;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillingBloc, BillingState>(
      builder: (context, billingState) {
        final isLoading = billingState is BillingLoading;

        return Container(
          decoration: BoxDecoration(
            color: context.appColors.surface,
            border: Border.all(
              color: _borderColor(context),
              width: _borderWidth,
            ),
          ),
          // Column fills the bounded height given by IntrinsicHeight + stretch.
          // Spacer() has zero intrinsic height (so measurement is correct) but
          // fills remaining space during layout, pinning the button to the bottom
          // of every card regardless of how many features each card has.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Discount banner ───────────────────────────────────────
              if (plan.discount != null)
                _DiscountBanner(text: plan.discount!)
              else if (plan.isPopular)
                _PopularBanner(accentColor: plan.accentColor),

              // ── Top content ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Plan name
                    Text(
                      plan.displayName,
                      style: AppTypography.labelLarge.copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    if (isCurrent) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: context.appColors.primary),
                        child: Text(
                          'PLANO ATUAL',
                          style: AppTypography.caption.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // Price
                    _PriceDisplay(
                      price: plan.price,
                      color: plan.discount != null
                          ? _kDiscountColor
                          : plan.accentColor,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.priceDetail,
                      style: AppTypography.bodySm.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    Divider(color: context.appColors.outline, height: 1),
                    const SizedBox(height: AppSpacing.lg),

                    // Feature list — left-aligned block, centered as a unit
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: plan.features
                            .map(
                              (f) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.xs),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      size: 13,
                                      color: plan.discount != null
                                          ? _kDiscountColor
                                          : _kCheckColor,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      f,
                                      style: AppTypography.bodySm.copyWith(
                                        color:
                                            context.appColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Push button to card bottom ────────────────────────────
              const Spacer(),

              // ── Bottom action ─────────────────────────────────────────
              // Cards without a button still get bottom padding so the
              // visual weight matches paid-plan cards.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: !isCurrent && plan.backendKey != 'FREE' && isOwner
                    ? SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: plan.discount != null
                                ? _kDiscountColor
                                : plan.accentColor,
                            shape: const RoundedRectangleBorder(),
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            textStyle: AppTypography.bodySm
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          onPressed: isLoading
                              ? null
                              : () => context.read<BillingBloc>().add(
                                    BillingCheckoutRequested(
                                      slug: slug,
                                      planName: plan.backendKey,
                                    ),
                                  ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Text('Começar Agora'),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── DiscountBanner ────────────────────────────────────────────────────────────

class _DiscountBanner extends StatelessWidget {
  final String text;

  const _DiscountBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _kDiscountColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'OFERTA POR TEMPO LIMITADO',
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 9,
              letterSpacing: 0.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 1),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── PopularBanner ─────────────────────────────────────────────────────────────

class _PopularBanner extends StatelessWidget {
  final Color accentColor;

  const _PopularBanner({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: accentColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Text(
        'MAIS POPULAR',
        style: AppTypography.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.8,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── PriceDisplay ──────────────────────────────────────────────────────────────

class _PriceDisplay extends StatelessWidget {
  final String price;
  final Color color;

  const _PriceDisplay({required this.price, required this.color});

  @override
  Widget build(BuildContext context) {
    final spaceIdx = price.indexOf(' ');
    final symbol = spaceIdx >= 0 ? price.substring(0, spaceIdx) : price;
    final amount = spaceIdx >= 0 ? price.substring(spaceIdx + 1) : '';

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: '$symbol ',
            style: AppTypography.bodyMd.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: amount,
            style: AppTypography.displayLg.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── CancelSubscriptionSection ─────────────────────────────────────────────────

class _CancelSubscriptionSection extends StatelessWidget {
  final String slug;

  const _CancelSubscriptionSection({required this.slug});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: context.appColors.outline),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Cancelar assinatura',
          style: AppTypography.labelLarge.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ao cancelar, você voltará automaticamente para o plano Skedi Free no final do período já pago.',
          style: AppTypography.bodySm.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        BlocBuilder<BillingBloc, BillingState>(
          builder: (context, state) {
            return OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: const RoundedRectangleBorder(),
              ),
              onPressed: state is BillingLoading
                  ? null
                  : () => _confirmCancel(context),
              child: const Text('Cancelar assinatura'),
            );
          },
        ),
      ],
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        title: const Text('Cancelar assinatura?'),
        content: const Text(
          'Você perderá acesso aos recursos do plano ao final do período atual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Manter plano'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx, true);
              context
                  .read<BillingBloc>()
                  .add(BillingCancelRequested(slug: slug));
            },
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

// ── PlanBadge (exported for reuse in sidebar/settings) ────────────────────────

class _PlanBadge extends StatelessWidget {
  final String planName;

  const _PlanBadge({required this.planName});

  Color _badgeColor(BuildContext context) => switch (planName.toUpperCase()) {
        'PRO' => const Color(0xFF00897B),
        'PREMIUM' => const Color(0xFF5C6BC0),
        _ => context.appColors.outline,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _badgeColor(context).withValues(alpha: 0.15),
        border: Border.all(color: _badgeColor(context)),
      ),
      child: Text(
        planDisplayName(planName),
        style: AppTypography.caption.copyWith(
          color: _badgeColor(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Public plan badge widget, reused in sidebar and settings.
class PlanBadge extends StatelessWidget {
  final String planName;

  const PlanBadge({super.key, required this.planName});

  Color _badgeColor(BuildContext context) => switch (planName.toUpperCase()) {
        'PRO' => const Color(0xFF00897B),
        'PREMIUM' => const Color(0xFF5C6BC0),
        _ => context.appColors.textDisabled,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _badgeColor(context).withValues(alpha: 0.12),
        border: Border.all(
            color: _badgeColor(context).withValues(alpha: 0.5)),
      ),
      child: Text(
        planDisplayName(planName),
        style: AppTypography.caption.copyWith(
          color: _badgeColor(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
