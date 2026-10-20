import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../profile_avatar.dart';

class ProfileFormPage extends StatefulWidget {
  const ProfileFormPage({
    super.key,
    required this.auth,
    this.initial = false,
    this.onDone,
  });
  final AuthController auth;
  final bool initial;
  final VoidCallback? onDone;
  @override
  State<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<ProfileFormPage> {
  final form = GlobalKey<FormState>();
  late final nickname = TextEditingController(
    text: widget.auth.profile?.nickname ?? '',
  );
  Uint8List? image;
  String? imageName;
  bool removeImage = false;
  bool selecting = false;
  String? localError;

  Future<void> chooseImage() async {
    setState(() {
      selecting = true;
      localError = null;
    });
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'PNG / JPEG',
            extensions: ['png', 'jpg', 'jpeg'],
            mimeTypes: ['image/png', 'image/jpeg'],
            uniformTypeIdentifiers: ['public.png', 'public.jpeg'],
          ),
        ],
      );
      if (file == null) return;
      if (await file.length() > 1048576) throw const FormatException();
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          image = bytes;
          imageName = file.name;
          removeImage = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => localError = '1MB 이하의 PNG 또는 JPEG 이미지를 선택해 주세요.');
      }
    } finally {
      if (mounted) setState(() => selecting = false);
    }
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    final saved = await widget.auth.saveProfile(
      nickname.text.trim(),
      image: image,
      imageName: imageName,
      removeImage: removeImage,
    );
    if (saved && mounted) widget.onDone?.call();
  }

  @override
  void dispose() {
    nickname.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.auth,
    builder: (context, _) {
      final next = widget.auth.profile?.nextNicknameChange;
      final nicknameLocked =
          !widget.initial && next != null && next.isAfter(DateTime.now());
      final busy = widget.auth.busy || selecting;
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.initial ? 'OSEE에 오신 것을 환영해요' : '프로필 수정'),
          actions: [
            if (widget.initial)
              TextButton(
                onPressed: busy ? null : widget.auth.logout,
                child: const Text('로그아웃'),
              ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.initial ? '프로필 만들기' : '나의 프로필',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('OSEE에서 사용할 닉네임을 정해 주세요. 사진은 나중에 추가해도 괜찮아요.'),
                    const SizedBox(height: 32),
                    Center(
                      child: ProfileAvatar(
                        image:
                            image ??
                            (removeImage ? null : widget.auth.profile?.image),
                        radius: 48,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: busy ? null : chooseImage,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('프로필 사진 선택 (선택)'),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                              image = null;
                              imageName = null;
                              removeImage = true;
                            }),
                      child: const Text('기본 아바타 사용'),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nickname,
                      enabled: !busy && !nicknameLocked,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        labelText: '닉네임',
                        helperText: '한글·영문·숫자·밑줄 2~20자',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          RegExp(r'^[가-힣A-Za-z0-9_]{2,20}$')
                              .hasMatch((value ?? '').trim())
                          ? null
                          : '닉네임 형식을 확인해 주세요.',
                    ),
                    if (nicknameLocked)
                      Text(
                        '다음 닉네임 변경: ${next.toLocal().toString().split('.').first}',
                      ),
                    if (localError != null || widget.auth.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            localError ?? widget.auth.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: busy ? null : submit,
                      child: Text(
                        busy
                            ? '저장 중…'
                            : widget.initial
                            ? '다음'
                            : '변경 저장',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
