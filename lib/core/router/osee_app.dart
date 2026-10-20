import 'package:beandoche_osee_frontend/core/providers/osee_store.dart';
import 'package:beandoche_osee_frontend/core/theme/osee_theme.dart';
import 'package:beandoche_osee_frontend/core/widgets/osee_header.dart';
import 'package:beandoche_osee_frontend/features/home/screens/home_page.dart';
import 'package:beandoche_osee_frontend/features/clothes/screens/clothes_page.dart';
import 'package:beandoche_osee_frontend/features/clothes/widgets/clothes_hover_menu.dart';
import 'package:beandoche_osee_frontend/features/fitting_room/screens/fitting_page.dart';
import 'package:beandoche_osee_frontend/features/wardrobe/screens/wardrobe_page.dart';
import 'package:beandoche_osee_frontend/features/outfits/screens/outfits_page.dart';

import 'package:flutter/material.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/auth/login_page.dart';
import '../../features/profile/screens/mypage.dart';
import '../../features/profile/screens/profile_form_page.dart';
import '../../features/profile/screens/body_setup_page.dart';

import 'dart:async';

class OseeApp extends StatefulWidget {
  const OseeApp({super.key, this.initialStore, this.initialAuth});
  final OseeStore? initialStore;
  final AuthController? initialAuth;
  @override
  State<OseeApp> createState() => _OseeAppState();
}

class _OseeAppState extends State<OseeApp> {
  final navigator = GlobalKey<NavigatorState>();
  bool previouslyAuthenticated = false;
  late final AuthController auth = widget.initialAuth ?? AuthController();

  @override
  void initState() {
    super.initState();
    previouslyAuthenticated = auth.isAuthenticated;
    auth.addListener(onAuthChanged);
    if (widget.initialAuth == null) unawaited(auth.restore());
  }

  void onAuthChanged() {
    if (previouslyAuthenticated && !auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) navigator.currentState?.popUntil((route) => route.isFirst);
      });
    }
    previouslyAuthenticated = auth.isAuthenticated;
  }

  @override
  void dispose() {
    auth.removeListener(onAuthChanged);
    if (widget.initialAuth == null) auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthScope(
    controller: auth,
    child: MaterialApp(
      navigatorKey: navigator,
      title: 'OSEE',
      debugShowCheckedModeBanner: false,
      theme: oseeTheme,
      home: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          if (auth.restoring && auth.session == null) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(semanticsLabel: '로그인 상태 확인 중'),
              ),
            );
          }
          if (!auth.isAuthenticated) return LoginPage(auth: auth);
          if (auth.profile == null) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (auth.busy)
                      const CircularProgressIndicator()
                    else ...[
                      Text(auth.error ?? '프로필을 확인하지 못했습니다.'),
                      TextButton(
                        onPressed: auth.reloadProfile,
                        child: const Text('다시 시도'),
                      ),
                      TextButton(
                        onPressed: auth.logout,
                        child: const Text('로그아웃'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          if (!auth.profile!.completed) {
            return ProfileFormPage(auth: auth, initial: true);
          }
          if (auth.showBodyStep) {
            return BodySetupPage(onNext: auth.finishBodyStep);
          }
          return _OseeWorkspace(initialStore: widget.initialStore);
        },
      ),
    ),
  );
}

class _OseeWorkspace extends StatefulWidget {
  const _OseeWorkspace({this.initialStore});
  final OseeStore? initialStore;

  @override
  State<_OseeWorkspace> createState() => _OseeWorkspaceState();
}

class _OseeWorkspaceState extends State<_OseeWorkspace> {
  late final OseeStore store = widget.initialStore ?? OseeStore();
  late final Future<void> ready = widget.initialStore == null
      ? store.initialize()
      : Future.value();
  int page = 0;
  String category = 'bottom';
  String? subcategory = 'Pants';
  bool clothesMenuOpen = false;

  void open(int index) => setState(() {
    page = index;
    clothesMenuOpen = false;
  });
  void filter(String value, [String? sub]) => setState(() {
    category = value;
    subcategory = sub;
    page = 1;
    clothesMenuOpen = false;
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: ready,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          body: const Center(child: Text('데이터를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.')),
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return AnimatedBuilder(
        animation: store,
        builder: (context, _) => LayoutBuilder(
          builder: (context, size) {
            final wide = size.maxWidth >= 1050;
            return Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: OseeHeader(
                  activePage: page,
                  wide: wide,
                  onNavigate: open,
                  onClothesHover: () => setState(() => clothesMenuOpen = true),
                  onOtherHover: () => setState(() => clothesMenuOpen = false),
                ),
              ),
              body: Stack(
                children: [
                  Positioned.fill(
                    child: [
                      HomePage(open: open),
                      ClothesPage(
                        store: store,
                        category: category,
                        subcategory: subcategory,
                        filter: filter,
                      ),
                      FittingPage(store: store, open: open),
                      WardrobePage(store: store, open: open),
                      OutfitsPage(store: store, open: open),
                      MyPage(
                        userId: AuthScope.of(context).session!.userId,
                        onHome: () => open(0),
                      ),
                    ][page],
                  ),
                  if (wide && clothesMenuOpen)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: ClothesHoverMenu(
                        onSelect: filter,
                        onExit: () => setState(() => clothesMenuOpen = false),
                      ),
                    ),
                ],
              ),
              bottomNavigationBar: wide || page == 5
                  ? null
                  : NavigationBar(
                      selectedIndex: page,
                      onDestinationSelected: open,
                      height: 70,
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          label: 'HOME',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.checkroom_outlined),
                          label: 'CLOTHES',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.accessibility_new_outlined),
                          label: 'FITTING',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.bookmark_border),
                          label: 'WARDROBE',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.grid_view_outlined),
                          label: 'OUTFITS',
                        ),
                      ],
                    ),
            );
          },
        ),
      );
    },
  );

  @override
  void dispose() {
    if (widget.initialStore == null) store.dispose();
    super.dispose();
  }
}
