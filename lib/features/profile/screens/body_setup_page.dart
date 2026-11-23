import 'dart:async';

import 'package:flutter/material.dart';

import '../body_profile.dart';
import '../body_profile_controller.dart';

class BodySetupPage extends StatefulWidget {
  const BodySetupPage({super.key, required this.onNext});
  final VoidCallback onNext;

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
        _inputs[field]!.text = field.display(
          profile.measurements.values[field]!,
        );
      }
    }
    setState(() => _initializing = false);
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final measurements = BodyMeasurements({
      for (final field in BodyMeasurement.values)
        field: field.parseInput(_inputs[field]!.text)!,
    });
    if (await _body!.save(_gender!, measurements) && mounted) widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final body = BodyProfileScope.maybeOf(context);
    if (body == null) {
      return const Scaffold(body: Center(child: Text('로그인 상태를 확인해 주세요.')));
    }
    final busy = _initializing || body.loading || body.saving;
    return Scaffold(
      appBar: AppBar(title: const Text('체형정보 설정')),
      body: SingleChildScrollView(
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
                  const Text('본인의 치수를 입력해 주세요. 인심은 가랑이부터 발목까지의 안쪽 다리 길이입니다.'),
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
                  for (final field in BodyMeasurement.values) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      key: ValueKey(field.key),
                      controller: _inputs[field],
                      enabled: !busy && body.loaded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: field.label,
                        suffixText: field.unit,
                      ),
                      validator: (value) =>
                          field.parseInput(value ?? '') == null
                          ? '${field.unit} 단위의 양수로 입력해 주세요. 소수 ${field.isLength ? '1' : '3'}자리까지 가능합니다.'
                          : null,
                    ),
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
                    '현재 피팅룸에는 선택한 성별의 기본 모델이 표시됩니다. 치수에 따른 체형 변형은 준비 중입니다.',
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: busy || !body.loaded ? null : _save,
                    child: Text(body.saving ? '저장 중…' : '신체정보 저장'),
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
