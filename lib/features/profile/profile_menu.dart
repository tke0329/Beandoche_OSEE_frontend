import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import 'profile_avatar.dart';

class ProfileMenu extends StatefulWidget {
  const ProfileMenu({super.key, required this.onProfile});
  final VoidCallback onProfile;
  @override
  State<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  final controller = OverlayPortalController();
  final link = LayerLink();
  Timer? closing;
  void show() {
    closing?.cancel();
    if (!controller.isShowing) controller.show();
  }

  void hide() {
    closing?.cancel();
    controller.hide();
  }

  void later() {
    closing?.cancel();
    closing = Timer(const Duration(milliseconds: 180), () {
      if (mounted) controller.hide();
    });
  }

  void openProfile() {
    hide();
    widget.onProfile();
  }

  Future<void> logout(AuthController auth) async {
    hide();
    await auth.logout();
    if (mounted && auth.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(auth.error!)));
    }
  }

  @override
  void dispose() {
    closing?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final profile = auth.profile;
    return CompositedTransformTarget(
      link: link,
      child: OverlayPortal(
        controller: controller,
        overlayChildBuilder: (context) => Positioned(
          left: 0,
          top: 0,
          child: CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 10),
            child: MouseRegion(
              onEnter: (_) => show(),
              onExit: (_) => later(),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 280,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            ProfileAvatar(image: profile?.image),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                profile?.nickname ?? 'OSEE 회원',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('회원 ID: ${auth.session?.userId ?? ''}'),
                        const SizedBox(height: 8),
                        const Text('체형정보 · 준비 중'),
                        const Divider(height: 28),
                        TextButton.icon(
                          onPressed: openProfile,
                          icon: const Icon(Icons.person_outline),
                          label: const Text('마이페이지로 이동'),
                        ),
                        TextButton.icon(
                          onPressed: auth.busy ? null : () => logout(auth),
                          icon: const Icon(Icons.logout),
                          label: const Text('로그아웃'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        child: MouseRegion(
          onEnter: (_) => show(),
          onExit: (_) => later(),
          child: Focus(
            onFocusChange: (focused) => focused ? show() : later(),
            child: IconButton.filledTonal(
              tooltip: '마이페이지',
              onPressed: openProfile,
              icon: ProfileAvatar(image: profile?.image, radius: 18),
            ),
          ),
        ),
      ),
    );
  }
}
