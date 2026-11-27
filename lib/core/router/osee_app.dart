import '../../features/fitting_room/fitting_catalog.dart';
import '../../features/clothes/garment_api.dart';
import '../../features/clothes/garment_catalog.dart';
import '../../features/categories/category_api.dart';
import '../../features/categories/category_catalog.dart';

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
import '../../features/profile/screens/withdrawal_complete_page.dart';
import '../../features/profile/body_profile_controller.dart';
import '../../features/auth/auth_api.dart';

import 'dart:async';

class OseeApp extends StatefulWidget {
  const OseeApp({
    super.key,
    this.initialStore,
    this.initialAuth,
    this.categoryApi,
    this.garmentApi,
    this.fittingApi,
    this.bodyProfileApi,
  });
  final OseeStore? initialStore;
  final AuthController? initialAuth;
  final CategoryApi? categoryApi;
  final GarmentApi? garmentApi;
  final GarmentApi? fittingApi;
  final AuthApi? bodyProfileApi;
  @override
  State<OseeApp> createState() => _OseeAppState();
}

class _OseeAppState extends State<OseeApp> {
  final navigator = GlobalKey<NavigatorState>();
  bool previouslyAuthenticated = false;
  bool loginRequested = false;
  bool openFittingAfterSave = false;
  late final AppLifecycleListener lifecycle;
  late final AuthController auth = widget.initialAuth ?? AuthController();
  late final BodyProfileController bodyProfiles = BodyProfileController(
    auth: auth,
    api: widget.bodyProfileApi,
  );

  @override
  void initState() {
    super.initState();
    previouslyAuthenticated = auth.isAuthenticated;
    auth.addListener(onAuthChanged);
    lifecycle = AppLifecycleListener(
      onResume: () {
        if (!auth.busy) unawaited(auth.restore());
      },
    );
    if (widget.initialAuth == null) unawaited(auth.restore());
  }

  void onAuthChanged() {
    if (auth.isAuthenticated) loginRequested = false;
    if (previouslyAuthenticated && !auth.isAuthenticated) {
      openFittingAfterSave = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) navigator.currentState?.popUntil((route) => route.isFirst);
      });
    }
    previouslyAuthenticated = auth.isAuthenticated;
  }

  @override
  void dispose() {
    auth.removeListener(onAuthChanged);
    lifecycle.dispose();
    bodyProfiles.dispose();
    if (widget.initialAuth == null) auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BodyProfileScope(
    controller: bodyProfiles,
    child: AuthScope(
      controller: auth,
      child: MaterialApp(
        navigatorKey: navigator,
        title: 'OSEE',
        debugShowCheckedModeBanner: false,
        theme: oseeTheme,
        home: ListenableBuilder(
          listenable: auth,
          builder: (context, _) {
            if (!auth.isAuthenticated) {
              if (auth.withdrawalResult != null) {
                return WithdrawalCompletePage(auth: auth);
              }
              if (loginRequested) {
                return LoginPage(
                  auth: auth,
                  onHome: () => setState(() => loginRequested = false),
                );
              }
              return _OseeWorkspace(
                initialStore: widget.initialStore,
                categoryApi: widget.categoryApi,
                garmentApi: widget.garmentApi,
                fittingApi: widget.fittingApi,
                onLogin: () => setState(() => loginRequested = true),
              );
            }
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
              return BodySetupPage(
                onNext: auth.finishBodyStep,
                onSaved: () {
                  openFittingAfterSave = true;
                  auth.finishBodyStep();
                },
              );
            }
            return _OseeWorkspace(
              initialPage: openFittingAfterSave ? 2 : 0,
              initialStore: widget.initialStore,
              categoryApi: widget.categoryApi,
              garmentApi: widget.garmentApi,
              fittingApi: widget.fittingApi,
              onLogin: () => setState(() => loginRequested = true),
            );
          },
        ),
      ),
    ),
  );
}

class _OseeWorkspace extends StatefulWidget {
  const _OseeWorkspace({
    this.initialPage = 0,
    this.initialStore,
    required this.onLogin,
    this.categoryApi,
    this.garmentApi,
    this.fittingApi,
  });
  final OseeStore? initialStore;
  final int initialPage;
  final VoidCallback onLogin;
  final CategoryApi? categoryApi;
  final GarmentApi? garmentApi;
  final GarmentApi? fittingApi;

  @override
  State<_OseeWorkspace> createState() => _OseeWorkspaceState();
}

class _OseeWorkspaceState extends State<_OseeWorkspace> {
  late final OseeStore store = widget.initialStore ?? OseeStore();
  late final Future<void> ready = widget.initialStore == null
      ? store.initialize()
      : Future.value();
  late int page = widget.initialPage;
  String category = 'all';
  String? subcategory;
  bool clothesMenuOpen = false;
  CategoryCatalog? _categories;
  GarmentCatalog? _garments;
  FittingCatalog? _fitting;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fitting ??= FittingCatalog(
      auth: AuthScope.of(context),
      api: widget.fittingApi,
    );
    _garments ??= GarmentCatalog(
      auth: AuthScope.of(context),
      api: widget.garmentApi,
    );
    _categories ??= CategoryCatalog(
      auth: AuthScope.of(context),
      api: widget.categoryApi,
    );
  }

  void open(int index) {
    if (index >= 2 && !AuthScope.of(context).isAuthenticated) {
      if (!AuthScope.of(context).restoring) widget.onLogin();
      return;
    }
    setState(() {
      page = index;
      clothesMenuOpen = false;
    });
  }

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
            final visiblePage =
                !AuthScope.of(context).isAuthenticated && page >= 2 ? 0 : page;
            return FittingScope(
              controller: _fitting!,
              child: Scaffold(
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(64),
                  child: OseeHeader(
                    activePage: visiblePage,
                    wide: wide,
                    onNavigate: open,
                    onClothesHover: () =>
                        setState(() => clothesMenuOpen = true),
                    onOtherHover: () => setState(() => clothesMenuOpen = false),
                  ),
                ),
                body: Stack(
                  children: [
                    Positioned.fill(
                      child: switch (visiblePage) {
                        1 => ClothesPage(
                          garments: _garments!,
                          category: category,
                          subcategory: subcategory,
                          filter: filter,
                          categories: _categories!,
                          onLogin: widget.onLogin,
                        ),
                        2 => FittingPage(catalog: _fitting!, open: open),
                        3 => WardrobePage(store: store, open: open),
                        4 => OutfitsPage(store: store, open: open),
                        5 => MyPage(
                          onHome: () => open(0),
                          onFitting: () => open(2),
                        ),
                        _ => HomePage(open: open),
                      },
                    ),
                    if (wide && clothesMenuOpen)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: ClothesHoverMenu(
                          onSelect: filter,
                          catalog: _categories!,
                          selected: category,
                          subcategory: subcategory,
                          onLogin: () {
                            setState(() => clothesMenuOpen = false);
                            widget.onLogin();
                          },
                          onExit: () => setState(() => clothesMenuOpen = false),
                        ),
                      ),
                  ],
                ),
                bottomNavigationBar: wide || visiblePage == 5
                    ? null
                    : NavigationBar(
                        selectedIndex: visiblePage,
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
              ),
            );
          },
        ),
      );
    },
  );

  @override
  void dispose() {
    _fitting?.dispose();
    _garments?.dispose();
    _categories?.dispose();
    if (widget.initialStore == null) store.dispose();
    super.dispose();
  }
}
