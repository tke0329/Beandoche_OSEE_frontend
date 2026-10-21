import 'dart:typed_data';
import 'dart:async';

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
  Timer? nicknameTimer;
  int nicknameVersion = 0;
  bool checkingNickname = false;
  String? nicknameProblem;

  void checkNickname(String value) {
    nicknameTimer?.cancel();
    final version = ++nicknameVersion;
    widget.auth.clearNicknameError();
    final trimmed = value.trim();
    setState(() {
      checkingNickname = false;
      nicknameProblem = null;
      if (widget.initial && trimmed.isEmpty) return;
      if (!RegExp(r'^[가-힣A-Za-z0-9_]{2,20}$').hasMatch(trimmed)) {
        nicknameProblem = '닉네임은 한글·영문·숫자·밑줄 2~20자로 입력해 주세요.';
      } else {
        checkingNickname = true;
      }
    });
    if (!checkingNickname) return;
    nicknameTimer = Timer(const Duration(milliseconds: 350), () async {
      final problem = await widget.auth.checkNickname(trimmed);
      if (!mounted || version != nicknameVersion) return;
      setState(() {
        checkingNickname = false;
        nicknameProblem = problem;
      });
    });
  }

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
    if (checkingNickname ||
        nicknameProblem != null ||
        widget.auth.nicknameError != null) {
      return;
    }
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
    nicknameTimer?.cancel();
    nicknameVersion++;
    nickname.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.auth,
    builder: (context, _) {
      final busy = widget.auth.busy || selecting;
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.initial ? 'OSEE에 오신 것을 환영해요' : '프로필 수정'),
          actions: [
            if (widget.initial)
              TextButton(
                onPressed: busy ? null : widget.auth.logout,
                child: const Text('나가기'),
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
                    Text(
                      widget.initial
                          ? '소셜 인증이 완료됐어요. 프로필을 설정하면 가입이 완료돼요.\n닉네임을 비우면 OSEE_랜덤번호로 만들어 드려요. 사진도 선택 사항이에요.'
                          : 'OSEE에서 사용할 닉네임과 프로필 사진을 관리해요.',
                    ),
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
                      enabled: !busy,
                      maxLength: 20,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: checkNickname,
                      decoration: InputDecoration(
                        labelText: '닉네임',
                        helperText: widget.initial
                            ? '선택 · 비우면 자동 생성 / 한글·영문·숫자·밑줄 2~20자'
                            : '한글·영문·숫자·밑줄 2~20자',
                        helperMaxLines: 2,
                        errorText: nicknameProblem ?? widget.auth.nicknameError,
                        errorStyle: const TextStyle(color: Color(0xffb3261e)),
                        errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xffb3261e)),
                        ),
                        focusedErrorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xffb3261e),
                            width: 2,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (widget.initial && (value ?? '').trim().isEmpty) ||
                              RegExp(r'^[가-힣A-Za-z0-9_]{2,20}$')
                                  .hasMatch((value ?? '').trim())
                          ? null
                          : '닉네임 형식을 확인해 주세요.',
                    ),
                    if (checkingNickname)
                      const Text('닉네임을 확인하고 있어요.', semanticsLabel: '닉네임 확인 중'),
                    if (nicknameProblem != null)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => checkNickname(nickname.text),
                        child: const Text('닉네임 다시 확인'),
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
                      onPressed:
                          busy ||
                              checkingNickname ||
                              nicknameProblem != null ||
                              widget.auth.nicknameError != null
                          ? null
                          : submit,
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
