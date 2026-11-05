import 'package:flutter/material.dart';

import '../../features/profile/profile_menu.dart';
import '../../features/auth/auth_controller.dart';

class OseeHeader extends StatelessWidget {
  const OseeHeader({
    super.key,
    required this.activePage,
    required this.wide,
    required this.onNavigate,
    required this.onClothesHover,
    required this.onOtherHover,
  });
  final int activePage;
  final bool wide;
  final ValueChanged<int> onNavigate;
  final VoidCallback onClothesHover;
  final VoidCallback onOtherHover;

  @override
  Widget build(BuildContext context) {
    final logo = InkWell(
      onTap: () => onNavigate(0),
      child: const Text(
        'OSEE',
        style: TextStyle(
          fontFamily: 'Inter',
          color: Color(0xff141414),
          fontSize: 21,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: -1.26,
        ),
      ),
    );
    final profile = ProfileMenu(
      key: ValueKey(AuthScope.of(context).isAuthenticated),
      onProfile: () => onNavigate(5),
    );
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: wide ? 52 : 20),
          child: wide
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(alignment: Alignment.centerLeft, child: logo),
                    Center(
                      child: SizedBox(
                        width: (MediaQuery.sizeOf(context).width - 320).clamp(
                          0.0,
                          1000.0,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var index = 1; index <= 4; index++) ...[
                                if (index > 1) const SizedBox(width: 54),
                                MouseRegion(
                                  onEnter: (_) => index == 1
                                      ? onClothesHover()
                                      : onOtherHover(),
                                  child: InkWell(
                                    onTap: () => onNavigate(index),
                                    child: Text(
                                      const [
                                        'HOME',
                                        'CLOTHES',
                                        'FITTING ROOM',
                                        'WARDROBE',
                                        'OUTFITS',
                                      ][index],
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 25,
                                        height: 1.5,
                                        letterSpacing: .23,
                                        fontWeight: activePage == index
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: activePage == index
                                            ? const Color(0xff141414)
                                            : const Color(0xffc3c7ce),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    Align(alignment: Alignment.centerRight, child: profile),
                  ],
                )
              : Row(children: [logo, const Spacer(), profile]),
        ),
      ),
    );
  }
}
