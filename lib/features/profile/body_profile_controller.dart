import 'package:flutter/widgets.dart';

import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import 'body_profile.dart';

class BodyProfileScope extends InheritedNotifier<BodyProfileController> {
  const BodyProfileScope({
    super.key,
    required BodyProfileController controller,
    required super.child,
  }) : super(notifier: controller);

  static BodyProfileController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BodyProfileScope>()?.notifier;
}

class BodyProfileController extends ChangeNotifier {
  BodyProfileController({required this.auth, AuthApi? api})
    : _api = api ?? AuthApi() {
    _userId = _currentUserId;
    auth.addListener(_authChanged);
  }

  final AuthController auth;
  final AuthApi _api;
  BodyProfile? profile;
  bool loading = false;
  bool saving = false;
  bool loaded = false;
  String? error;
  int? _userId;
  int _request = 0;
  bool _disposed = false;
  int? get _currentUserId => auth.isAuthenticated ? auth.session?.userId : null;

  void _authChanged() {
    if (_disposed || _userId == _currentUserId) return;
    _userId = _currentUserId;
    _request++;
    profile = null;
    loaded = false;
    loading = false;
    saving = false;
    error = null;
    notifyListeners();
  }

  Future<void> load({bool force = false}) async {
    if (_disposed ||
        _userId == null ||
        saving ||
        loading ||
        (loaded && !force)) {
      return;
    }
    final request = ++_request;
    final user = _userId;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _api.bodyProfile(auth.session!.accessToken);
      if (!_isCurrent(request, user)) return;
      profile = result;
      loaded = true;
    } on AuthFailure catch (failure) {
      if (_isCurrent(request, user)) error = failure.message;
    } catch (_) {
      if (_isCurrent(request, user)) error = '신체정보를 불러오지 못했습니다. 다시 시도해 주세요.';
    } finally {
      if (_isCurrent(request, user)) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> save(String gender, BodyMeasurements measurements) async {
    if (_disposed || _userId == null || loading || saving) return false;
    final request = ++_request;
    final user = _userId;
    saving = true;
    error = null;
    notifyListeners();
    try {
      final saved = await _api.saveBodyProfile(
        auth.session!.accessToken,
        gender,
        measurements,
      );
      if (!_isCurrent(request, user)) return false;
      profile = saved;
      loaded = true;
      return true;
    } on AuthFailure catch (failure) {
      if (_isCurrent(request, user)) error = failure.message;
      return false;
    } catch (_) {
      if (_isCurrent(request, user)) error = '신체정보를 저장하지 못했습니다. 다시 시도해 주세요.';
      return false;
    } finally {
      if (_isCurrent(request, user)) {
        saving = false;
        notifyListeners();
      }
    }
  }

  bool _isCurrent(int request, int? user) =>
      !_disposed && request == _request && user == _currentUserId;

  Future<void> retry() async {
    await auth.restore();
    if (!_disposed) await load(force: true);
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    auth.removeListener(_authChanged);
    _api.close();
    super.dispose();
  }
}
