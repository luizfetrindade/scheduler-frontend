import 'package:flutter/material.dart';
import 'package:scheduler_frontend/design_system/base_design_system.dart';
import 'package:scheduler_frontend/features/profile/presentation/widgets/profile_body.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileBlocListener(
      child: Scaffold(
        backgroundColor: context.appColors.background,
        appBar: AppBar(
          backgroundColor: context.appColors.surface,
          elevation: 0,
          title: Text(
            'Perfil',
            style: AppTypography.headingMd
                .copyWith(color: context.appColors.textPrimary),
          ),
          iconTheme: IconThemeData(color: context.appColors.textPrimary),
        ),
        body: const SafeArea(child: ProfileBody()),
      ),
    );
  }
}
