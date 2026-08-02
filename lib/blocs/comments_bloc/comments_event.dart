part of 'comments_bloc.dart';

sealed class CommentsEvent extends Equatable {
  const CommentsEvent();

  @override
  List<Object> get props => [];
}

class CommentsLoad extends CommentsEvent {}

class CommentsFetch extends CommentsEvent {
  const CommentsFetch({required this.commentName});
  final String commentName;

  @override
  List<Object> get props => [commentName];
}

class CommentAdd extends CommentsEvent {
  const CommentAdd({required this.commentName, required this.comment});
  final String commentName;
  final String comment;

  @override
  List<Object> get props => [commentName, comment];
}
