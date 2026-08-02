part of 'comments_bloc.dart';

class CommentsState extends Equatable {
  const CommentsState({required this.commentsOption});

  final Option<List<Comment>> commentsOption;

  factory CommentsState.initial() {
    return CommentsState(
      commentsOption: none(),
    );
  }

  CommentsState copyWith({
    Option<List<Comment>>? commentsOption,
  }) {
    return CommentsState(
      commentsOption: commentsOption ?? this.commentsOption,
    );
  }

  List<Comment> get list {
    return commentsOption.fold(() => [], (a) => a);
  }

  @override
  List<Object> get props => [
        commentsOption,
      ];
}
