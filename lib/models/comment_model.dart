import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String commentName;
  final String comment;
  final String authorEmail;
  final DateTime? createdAt;

  const Comment({
    required this.commentName,
    required this.comment,
    this.authorEmail = 'Üye Sürücü',
    this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> map) {
    return Comment(
      commentName: map["commentName"] ?? '',
      comment: map["comment"] ?? '',
      authorEmail: map["authorEmail"] ?? 'Üye Sürücü',
      createdAt: map["createdAt"] != null
          ? DateTime.fromMillisecondsSinceEpoch(map["createdAt"])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "commentName": commentName,
      "comment": comment,
      "authorEmail": authorEmail,
      "createdAt": (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    };
  }

  @override
  List<Object?> get props => [
        commentName,
        comment,
        authorEmail,
        createdAt,
      ];
}
