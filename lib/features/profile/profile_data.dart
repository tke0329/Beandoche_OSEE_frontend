import 'dart:convert';
import 'dart:typed_data';

class ProfileData {
  const ProfileData({
    required this.userId,
    this.nickname,
    this.image,
    required this.completed,
    this.nextNicknameChange,
  });
  final int userId;
  final String? nickname;
  final Uint8List? image;
  final bool completed;
  final DateTime? nextNicknameChange;

  factory ProfileData.fromJson(Object? json) {
    if (json case {'userId': int id, 'profileCompleted': bool completed}) {
      final nickname = json['nickname'];
      final encoded = json['imageBase64'];
      final next = json['nicknameNextChangeAt'];
      if (id <= 0 ||
          (nickname != null && nickname is! String) ||
          (completed && (nickname is! String || nickname.isEmpty)) ||
          (encoded != null &&
              (encoded is! String || encoded.length > 1400000)) ||
          (next != null && next is! String)) {
        throw const FormatException('Invalid profile');
      }
      return ProfileData(
        userId: id,
        nickname: nickname as String?,
        image: encoded == null ? null : base64Decode(encoded as String),
        completed: completed,
        nextNicknameChange: next == null
            ? null
            : DateTime.parse(next as String),
      );
    }
    throw const FormatException('Invalid profile');
  }
}
