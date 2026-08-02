import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_routes/models/comment_model.dart';

part 'comments_event.dart';
part 'comments_state.dart';

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  final SharedPreferences _sharedPreferences;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CommentsBloc(
    this._sharedPreferences,
    this._firestore,
    this._firebaseAuth,
  ) : super(CommentsState.initial()) {
    on<CommentsLoad>((event, emit) async {
      final comments = _sharedPreferences.getString("comments");
      if (comments != null) {
        try {
          final jsonData = jsonDecode(comments) as List;
          commentsList = jsonData.map((e) => Comment.fromJson(e)).toList();
        } catch (_) {}
      }
    });

    on<CommentsFetch>((event, emit) async {
      emit(state.copyWith(commentsOption: none()));

      try {
        final querySnapshot = await _firestore
            .collection('comments')
            .where('commentName', isEqualTo: event.commentName)
            .get();

        final firestoreComments = querySnapshot.docs
            .map((doc) => Comment.fromJson(doc.data()))
            .toList();

        if (firestoreComments.isNotEmpty) {
          emit(state.copyWith(commentsOption: some(firestoreComments)));
          return;
        }
      } catch (e) {
        debugPrint('CommentsFetch firestore exception: $e');
      }

      final filteredComments = commentsList
          .where((element) => element.commentName == event.commentName)
          .toList();
      emit(state.copyWith(commentsOption: some(filteredComments)));
    });

    on<CommentAdd>((event, emit) async {
      final currentUser = _firebaseAuth.currentUser;
      final authorEmail = currentUser?.email ?? 'Üye Sürücü';

      final newComment = Comment(
        commentName: event.commentName,
        comment: event.comment,
        authorEmail: authorEmail,
        createdAt: DateTime.now(),
      );

      try {
        await _firestore.collection('comments').add(newComment.toMap());
      } catch (e) {
        debugPrint('CommentAdd firestore exception: $e');
      }

      commentsList.add(newComment);
      final jsonData = commentsList.map((e) => e.toMap()).toList();
      await _sharedPreferences.setString("comments", jsonEncode(jsonData));
      add(CommentsFetch(commentName: event.commentName));
    });
  }

  List<Comment> commentsList = [];
}
