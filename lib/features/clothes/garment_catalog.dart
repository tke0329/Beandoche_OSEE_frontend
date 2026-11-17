import 'dart:async';

import 'package:flutter/foundation.dart';

import '../auth/auth_controller.dart';
import 'garment_api.dart';
import 'models/catalog_garment.dart';

class GarmentCatalog extends ChangeNotifier {
  GarmentCatalog({required this.auth, GarmentApi? api})
    : _api = api ?? GarmentApi() {
    _token = _currentToken;
    auth.addListener(_authChanged);
  }

  final AuthController auth;
  final GarmentApi _api;
  GarmentPage? _data;
  String? _categoryCode;
  int _page = 0;
  bool _loading = false;
  String? _error;
  int? _failureStatus;
  String? _token;
  bool _requested = false;
  bool _disposed = false;
  int _generation = 0;

  GarmentPage? get data => _data;
  String? get categoryCode => _categoryCode;
  int get page => _page;
  bool get loading => _loading;
  String? get error => _error;
  bool get needsLogin => !auth.isAuthenticated;
  String? get _currentToken =>
      auth.isAuthenticated ? auth.session?.accessToken : null;
  String? imageUrl(String value) => _api.imageUrl(value);

  void _authChanged() {
    final token = _currentToken;
    if (_disposed || token == _token) return;
    _token = token;
    _generation++;
    _data = null;
    _error = null;
    _failureStatus = null;
    _loading = false;
    if (_requested && token != null) {
      unawaited(load(categoryCode: _categoryCode, force: true));
    } else {
      notifyListeners();
    }
  }

  Future<void> load({
    String? categoryCode,
    int page = 0,
    bool force = false,
  }) async {
    if (_disposed) return;
    final changed = categoryCode != _categoryCode || page != _page;
    if (!force && !changed && _requested) return;
    _requested = true;
    _categoryCode = categoryCode;
    _page = page;
    _data = null;
    _error = null;
    _failureStatus = null;
    final generation = ++_generation;
    final token = _currentToken;
    _loading = token != null;
    notifyListeners();
    if (token == null) return;
    try {
      final result = await _api.fetch(
        token,
        categoryCode: categoryCode,
        page: page,
      );
      if (!_disposed && generation == _generation && token == _currentToken) {
        _data = result;
      }
    } on GarmentFailure catch (failure) {
      if (!_disposed && generation == _generation) {
        _error = failure.message;
        _failureStatus = failure.status;
      }
    } catch (_) {
      if (!_disposed && generation == _generation) {
        _error = '상품을 불러오지 못했습니다. 다시 시도해 주세요.';
      }
    } finally {
      if (!_disposed && generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> retry() async {
    if (_failureStatus == 401) await auth.restore();
    if (!_disposed && !_loading) {
      await load(categoryCode: _categoryCode, page: _page, force: true);
    }
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
