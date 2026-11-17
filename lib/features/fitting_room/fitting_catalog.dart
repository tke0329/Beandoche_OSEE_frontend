import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../clothes/garment_api.dart';
import '../clothes/models/catalog_garment.dart';
import '../clothes/models/garment_options.dart';

class FittingScope extends InheritedNotifier<FittingCatalog> {
  const FittingScope({
    super.key,
    required FittingCatalog controller,
    required super.child,
  }) : super(notifier: controller);
  static FittingCatalog? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FittingScope>()?.notifier;
}

class FittingCatalog extends ChangeNotifier {
  FittingCatalog({required this.auth, GarmentApi? api})
    : _api = api ?? GarmentApi() {
    _token = _currentToken;
    _userId = auth.session?.userId;
    auth.addListener(_authChanged);
  }
  final AuthController auth;
  final GarmentApi _api;
  final List<CatalogGarment> _items = [];
  final Map<int, (int?, int?)> _choices = {};
  // Personalization: per size, measurement definition -> mm. Kept in memory only.
  final Map<int, Map<int, num>> _fitDraft = {};
  final Map<int, Map<int, num>> _fitSaved = {};
  int? _activeId;
  GarmentDetails? _detail;
  GarmentSelection? _selection;
  bool _loading = false;
  bool _selecting = false;
  String? _error;
  String? _selectionError;
  int? _failureStatus;
  String? _token;
  int? _userId;
  int _generation = 0;
  int _selectionGeneration = 0;
  bool _disposed = false;
  bool _requested = false;

  List<CatalogGarment> get items => List.unmodifiable(_items);
  int? get activeId => _activeId;
  GarmentDetails? get detail => _detail;
  GarmentSelection? get selection => _selection;
  bool get loading => _loading;
  bool get selecting => _selecting;
  String? get error => _error;
  String? get selectionError => _selectionError;
  bool get needsLogin => !auth.isAuthenticated;
  bool contains(int id) => _items.any((item) => item.id == id);
  String? get _currentToken =>
      auth.isAuthenticated ? auth.session?.accessToken : null;
  String? imageUrl(String value) => _api.imageUrl(value);
  int? get selectedVariantId => _choices[_activeId]?.$1;
  int? get selectedSizeId => _choices[_activeId]?.$2;
  GarmentVariant? get selectedVariant => _detail?.options.variants
      .where((variant) => variant.id == selectedVariantId)
      .firstOrNull;

  /// The personalized value for [measurement] at the selected size
  /// (unsaved edit, then saved edit, then the brand's measurement).
  num fitValue(SizeMeasurement measurement) {
    final size = selectedSizeId;
    return _fitDraft[size]?[measurement.definitionId] ??
        _fitSaved[size]?[measurement.definitionId] ??
        measurement.valueMm;
  }

  bool get fitDirty => _fitDraft[selectedSizeId]?.isNotEmpty ?? false;

  void adjustFit(int definitionId, num mm) {
    final size = selectedSizeId;
    if (_disposed || size == null) return;
    (_fitDraft[size] ??= {})[definitionId] = mm;
    notifyListeners();
  }

  /// Back to the brand's measurements for the selected size (still needs saving).
  void resetFit() {
    final size = selectedSizeId;
    final measurements = _selection?.measurements;
    if (_disposed || size == null || measurements == null) return;
    _fitDraft[size] = {for (final m in measurements) m.definitionId: m.valueMm};
    notifyListeners();
  }

  void saveFit() {
    final size = selectedSizeId;
    if (_disposed || size == null) return;
    final draft = _fitDraft.remove(size);
    if (draft != null) (_fitSaved[size] ??= {}).addAll(draft);
    notifyListeners();
  }

  void toggle(CatalogGarment item) {
    if (_disposed || needsLogin) return;
    if (contains(item.id)) {
      remove(item.id);
      return;
    }
    _items.add(item);
    _activeId = item.id;
    _clearDetail();
    notifyListeners();
    if (_requested) unawaited(loadActive());
  }

  void remove(int id) {
    if (_disposed) return;
    _items.removeWhere((item) => item.id == id);
    _choices.remove(id);
    if (_activeId == id) {
      _activeId = _items.firstOrNull?.id;
      _clearDetail();
      if (_requested) unawaited(loadActive());
    }
    notifyListeners();
  }

  void select(int id) {
    if (_disposed || !contains(id) || _activeId == id) return;
    _activeId = id;
    _clearDetail();
    notifyListeners();
    unawaited(loadActive());
  }

  void _clearDetail() {
    _generation++;
    _selectionGeneration++;
    _detail = null;
    _selection = null;
    _loading = false;
    _selecting = false;
    _error = null;
    _selectionError = null;
    _failureStatus = null;
  }

  void _authChanged() {
    if (_disposed) return;
    final token = _currentToken;
    if (token == _token) return;
    final userId = auth.session?.userId;
    if (token == null || userId != _userId) {
      _items.clear();
      _choices.clear();
      _activeId = null;
    }
    _token = token;
    _userId = userId;
    _clearDetail();
    notifyListeners();
    if (_requested && token != null) unawaited(loadActive());
  }

  Future<void> loadActive({bool force = false}) async {
    if (_disposed || _loading || (!force && _detail != null)) return;
    _requested = true;
    final id = _activeId;
    final token = _currentToken;
    if (id == null || token == null) return;
    _clearDetail();
    final generation = ++_generation;
    _loading = true;
    notifyListeners();
    try {
      final detail = await _api.details(token, id);
      if (_disposed || generation != _generation || token != _currentToken) {
        return;
      }
      _detail = detail;
      final old = _choices[id];
      final variant =
          detail.options.variants.where((v) => v.id == old?.$1).firstOrNull ??
          detail.options.variants.firstOrNull;
      final size = variant?.sizes
          .where((s) => s.id == old?.$2 && s.available)
          .firstOrNull;
      _choices[id] = (variant?.id, size?.id);
      if (size != null) unawaited(chooseSize(size.id));
    } on GarmentFailure catch (failure) {
      if (!_disposed && generation == _generation) {
        _error = failure.message;
        _failureStatus = failure.status;
      }
    } catch (_) {
      if (!_disposed && generation == _generation) {
        _error = '상품 정보를 불러오지 못했습니다. 다시 시도해 주세요.';
      }
    } finally {
      if (!_disposed && generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  void chooseVariant(int id) {
    if (_disposed ||
        _detail == null ||
        _activeId == null ||
        selectedVariantId == id ||
        !_detail!.options.variants.any((variant) => variant.id == id)) {
      return;
    }
    _selectionGeneration++;
    _choices[_activeId!] = (id, null);
    _selection = null;
    _selectionError = null;
    _selecting = false;
    notifyListeners();
  }

  Future<void> chooseSize(int id) async {
    final productId = _activeId;
    final variant = selectedVariant;
    final token = _currentToken;
    if (_disposed ||
        productId == null ||
        variant == null ||
        token == null ||
        !variant.sizes.any((size) => size.id == id && size.available)) {
      return;
    }
    _choices[productId] = (variant.id, id);
    final generation = ++_selectionGeneration;
    _selection = null;
    _selectionError = null;
    _selecting = true;
    notifyListeners();
    try {
      final result = await _api.selection(token, productId, variant.id, id);
      if (!_disposed &&
          generation == _selectionGeneration &&
          token == _currentToken) {
        _selection = result;
      }
    } on GarmentFailure catch (failure) {
      if (!_disposed && generation == _selectionGeneration) {
        _selectionError = failure.message;
        _failureStatus = failure.status;
      }
    } catch (_) {
      if (!_disposed && generation == _selectionGeneration) {
        _selectionError = '옵션 정보를 불러오지 못했습니다. 다시 시도해 주세요.';
      }
    } finally {
      if (!_disposed && generation == _selectionGeneration) {
        _selecting = false;
        notifyListeners();
      }
    }
  }

  Future<void> retry() async {
    if (_failureStatus == 401) await auth.restore();
    if (!_disposed) await loadActive(force: true);
  }

  Future<void> retrySelection() async {
    if (_failureStatus == 401) await auth.restore();
    final size = selectedSizeId;
    if (!_disposed && size != null) await chooseSize(size);
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _selectionGeneration++;
    auth.removeListener(_authChanged);
    _api.close();
    super.dispose();
  }
}
