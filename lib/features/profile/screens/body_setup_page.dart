import 'dart:async';

import 'package:flutter/material.dart';

import '../body_profile.dart';
import '../body_profile_controller.dart';
import '../../../core/widgets/avatar_viewer.dart';

const _morphPreview = AvatarViewer.useLocalMorphs;

class BodySetupPage extends StatefulWidget {
  const BodySetupPage({super.key, required this.onNext, this.onSaved});
  final VoidCallback onNext;
  final VoidCallback? onSaved;

  @override
  State<BodySetupPage> createState() => _BodySetupPageState();
}

class _BodySetupPageState extends State<BodySetupPage> {
  final _form = GlobalKey<FormState>();
  final _inputs = {
    for (final field in BodyMeasurement.values) field: TextEditingController(),
  };
  BodyProfileController? _body;
  int? _ownerId;
  String? _gender;
  bool _initializing = true;
  bool _sliderMode = false;

  Iterable<BodyMeasurement> get _fields => BodyMeasurement.values.where(
    (field) => field.isRequired || _gender == 'FEMALE',
  );

  num? _value(BodyMeasurement field) => field.parseInput(_inputs[field]!.text);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = BodyProfileScope.maybeOf(context);
    final owner = controller?.auth.isAuthenticated == true
        ? controller?.auth.session?.userId
        : null;
    if (_body == controller && _ownerId == owner) return;
    _body = controller;
    _ownerId = owner;
    _gender = null;
    _sliderMode = false;
    for (final input in _inputs.values) {
      input.clear();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load());
    });
  }

  Future<void> _load({bool retry = false}) async {
    final body = _body;
    if (body == null) return;
    final owner = _ownerId;
    setState(() => _initializing = true);
    if (retry) {
      await body.retry();
    } else {
      await body.load();
    }
    if (!mounted || owner != _ownerId) return;
    final profile = body.profile;
    if (profile != null) {
      _gender = const {'MALE', 'FEMALE'}.contains(profile.gender)
          ? profile.gender
          : null;
      for (final field in BodyMeasurement.values) {
        final value = profile.measurements.values[field];
        _inputs[field]!.text = value == null ? '' : field.display(value);
      }
    }
    setState(() => _initializing = false);
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final measurements = BodyMeasurements({
      for (final field in _fields)
        if (_value(field) case final num value) field: value,
    });
    if (await _body!.save(_gender!, measurements) && mounted) {
      (widget.onSaved ?? widget.onNext)();
    }
  }

  String? _validate(BodyMeasurement field, String? text) {
    if (!field.isRequired && (text ?? '').trim().isEmpty) return null;
    final value = field.parseInput(text ?? '');
    if (value == null) {
      return '${field.unit} 단위로 입력해 주세요. 소수 ${field.decimalPlaces}자리까지 가능합니다.';
    }
    final bust = _value(BodyMeasurement.chest);
    if (field == BodyMeasurement.underbust && bust != null && value >= bust) {
      return '밑가슴둘레는 가슴둘레보다 작아야 합니다.';
    }
    return null;
  }

  Widget _measurementField(BodyMeasurement field, bool enabled) {
    final bounds = switch (field) {
      BodyMeasurement.height => (120.0, 220.0, 100),
      BodyMeasurement.weight => (35.0, 120.0, 85),
      BodyMeasurement.thigh => (10.0, 36.0, 52),
      _ => (18.0, 60.0, 84),
    };
    final (min, max, divisions) = bounds;
    final value = _value(field);
    final thumb = value == null
        ? (min + max) / 2
        : field.inputUnits(value).clamp(min, max).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: ValueKey(field.key),
          controller: _inputs[field],
          onChanged: (_) => setState(() {}),
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: field.label,
            suffixText: field.unit,
          ),
          validator: (text) => _validate(field, text),
        ),
        if (_sliderMode)
          Semantics(
            label: '${field.label} 조절',
            child: Slider(
              key: ValueKey('${field.key}-slider'),
              min: min,
              max: max,
              divisions: divisions,
              value: thumb,
              label: value == null
                  ? '값 선택'
                  : '${thumb.toStringAsFixed(1)} ${field.unit}',
              semanticFormatterCallback: (value) =>
                  '${value.toStringAsFixed(1)} ${field.unit}',
              onChanged: enabled
                  ? (value) => setState(() {
                      _inputs[field]!.text = value
                          .toStringAsFixed(1)
                          .replaceFirst(RegExp(r'\.0$'), '');
                    })
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _cupField(bool enabled) {
    final band = _value(BodyMeasurement.underbust);
    final cup = BustCup.fromMeasurements(_value(BodyMeasurement.chest), band);
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '가슴컵 (참고)',
        helperText: '밑가슴둘레를 입력하면 컵으로 가슴둘레를 조절할 수 있습니다.',
        helperMaxLines: 2,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BustCup>(
          key: const ValueKey('bust-cup'),
          value: cup,
          isDense: true,
          isExpanded: true,
          hint: const Text('컵 선택'),
          items: [
            for (final cup in BustCup.values)
              DropdownMenuItem(value: cup, child: Text('${cup.label}컵')),
          ],
          onChanged: enabled && band != null && band <= 999999774
              ? (cup) {
                  if (cup == null) return;
                  setState(() {
                    _inputs[BodyMeasurement.chest]!.text = BodyMeasurement.chest
                        .display(band + cup.differenceMm);
                  });
                }
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = BodyProfileScope.maybeOf(context);
    if (body == null) {
      return const Scaffold(body: Center(child: Text('로그인 상태를 확인해 주세요.')));
    }
    final busy = _initializing || body.loading || body.saving;
    final dimensions = <String, num>{};
    if (_morphPreview && _gender != null) {
      for (final field in BodyMeasurement.values.where(
        (field) => field.isMorphDimension,
      )) {
        final value = field.parseInput(_inputs[field]!.text);
        if (value != null) dimensions[field.key] = value;
      }
    }
    Widget preview(double height) => AvatarViewer(
      height: height,
      heightMm: _value(BodyMeasurement.height)?.toInt(),
      weightKg: _value(BodyMeasurement.weight),
      dimensionsMm: dimensions,
      model: _gender == 'MALE' ? AvatarModel.male : AvatarModel.female,
    );
    final enabled = !busy && body.loaded;
    Widget editor({required bool inlinePreview}) => SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '나의 신체정보',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text('키는 cm, 몸무게는 kg, 둘레는 인치(in)로 입력합니다.'),
                const SizedBox(height: 20),
                if (busy)
                  const LinearProgressIndicator(semanticsLabel: '신체정보 처리 중'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey(_gender),
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: '기본 모델'),
                  items: const [
                    DropdownMenuItem(value: 'FEMALE', child: Text('여성')),
                    DropdownMenuItem(value: 'MALE', child: Text('남성')),
                  ],
                  onChanged: busy
                      ? null
                      : (value) => setState(() => _gender = value),
                  validator: (value) =>
                      value == null ? '기본 모델을 선택해 주세요.' : null,
                ),
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('숫자 입력')),
                    ButtonSegment(value: true, label: Text('슬라이더')),
                  ],
                  selected: {_sliderMode},
                  onSelectionChanged: enabled
                      ? (selection) =>
                            setState(() => _sliderMode = selection.single)
                      : null,
                ),
                if (inlinePreview && _gender != null) ...[
                  const SizedBox(height: 16),
                  preview(300),
                ],
                for (final field in _fields) ...[
                  const SizedBox(height: 16),
                  _measurementField(field, enabled),
                  if (field == BodyMeasurement.underbust) ...[
                    const SizedBox(height: 16),
                    _cupField(enabled),
                  ],
                ],
                const SizedBox(height: 20),
                if (body.error != null) ...[
                  Text(
                    body.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  if (!body.loaded)
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => unawaited(_load(retry: true)),
                      child: const Text('다시 시도'),
                    ),
                  const SizedBox(height: 12),
                ],
                const Text(
                  _morphPreview ? '키, 몸무게와 부위별 치수를 모델 지원 범위 안에서 미리보기에 반영합니다.' : '키와 몸무게를 미리보기에 반영합니다. 몸무게는 70kg 기본형을 기준으로 폭과 깊이를 조절합니다.',
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: busy || !body.loaded ? null : _save,
                  child: Text(
                    body.saving
                        ? '저장 중…'
                        : widget.onSaved == null
                        ? '신체정보 저장'
                        : '저장하고 피팅룸 보기',
                  ),
                ),
                TextButton(
                  onPressed: busy ? null : widget.onNext,
                  child: const Text('나중에 입력'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('체형정보 설정')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (!_sliderMode || _gender == null || constraints.maxHeight < 300) {
            return editor(inlinePreview: true);
          }
          if (constraints.maxWidth >= 820) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: Row(
                  children: [
                    Expanded(child: preview(constraints.maxHeight * 0.85)),
                    Expanded(child: editor(inlinePreview: false)),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: [
              preview(
                (constraints.maxHeight * 0.37).clamp(125.0, 240.0).toDouble(),
              ),
              Expanded(child: editor(inlinePreview: false)),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    for (final input in _inputs.values) {
      input.dispose();
    }
    super.dispose();
  }
}
