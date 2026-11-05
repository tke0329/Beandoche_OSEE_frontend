import 'dart:async';

import 'package:flutter/foundation.dart';

import '../auth/auth_controller.dart';
import 'catalog_category.dart';
import 'category_api.dart';

class CategoryCatalog extends ChangeNotifier {
  CategoryCatalog({required this.auth, CategoryApi? api})
    : _api = api ?? CategoryApi() {
    _token = _currentToken;
    auth.addListener(_authChanged);
  }
  final AuthController auth;
  final CategoryApi _api;
  List<CatalogCategory> categories = const [];
  bool loading = false;
  String? error;
  int? _failureStatus;
  String? _token;
  bool _requested = false;
  bool _disposed = false;
  int _generation = 0;
  bool get needsLogin => !auth.isAuthenticated;
  String? get _currentToken =>
      auth.isAuthenticated ? auth.session?.accessToken : null;

  void _authChanged() {
    final token = _currentToken;
    if (token == _token || _disposed) return;
    _token = token;
    _generation++;
    categories = const [];
    error = null;
    loading = false;
    if (_requested && token != null) {
      unawaited(load(force: true));
    } else {
      notifyListeners();
    }
  }

  Future<void> load({bool force = false}) async {
    if (_disposed || (loading && !force) || (_requested && !force)) return;
    _requested = true;
    final token = _currentToken;
    if (token == null) return;
    final generation = ++_generation;
    loading = true;
    error = null;
    _failureStatus = null;
    notifyListeners();
    try {
      final result = await _api.fetch(token);
      if (_disposed || generation != _generation || token != _currentToken) {
        return;
      }
      categories = result;
    } on CategoryFailure catch (failure) {
      if (!_disposed && generation == _generation) {
        error = failure.message;
        _failureStatus = failure.status;
      }
    } catch (_) {
      if (!_disposed && generation == _generation) {
        error = '카테고리를 불러오지 못했습니다. 다시 시도해 주세요.';
      }
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> retry() async {
    if (_failureStatus == 401) await auth.restore();
    if (!_disposed && !loading) await load(force: true);
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    auth.removeListener(_authChanged);
    _api.close();
    super.dispose();
  }
}
