import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_routes/blocs/auth_bloc/auth_bloc.dart';
import 'package:smart_routes/blocs/comments_bloc/comments_bloc.dart';
import 'package:smart_routes/colors.dart';

Future<void> showCommentsPopup(BuildContext context,
    {required String commentsName}) {
  context.read<CommentsBloc>().add(CommentsFetch(commentName: commentsName));
  final textController = TextEditingController();

  void submitComment() {
    final authState = context.read<AuthBloc>().state;
    if (authState.isGuest) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: Colors.orange),
              SizedBox(width: 8),
              Text("Üye Girişi Gerekli"),
            ],
          ),
          content: const Text(
              "Yorum yapabilmek ve topluluğa katkı sağlayabilmek için lütfen ücretsiz üye girişi yapın."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("Tamam"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.pop(context);
                context.read<AuthBloc>().add(AuthLogout());
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
              child: const Text("Giriş Yap / Üye Ol"),
            ),
          ],
        ),
      );
      return;
    }

    final commentText = textController.text.trim();
    if (commentText.isEmpty) return;

    context.read<CommentsBloc>().add(CommentAdd(
          commentName: commentsName,
          comment: commentText,
        ));
    textController.clear();
  }

  return showDialog(
    context: context,
    builder: (context) {
      return BlocBuilder<CommentsBloc, CommentsState>(
        builder: (context, state) {
          return state.commentsOption.fold(() {
            return const Center(child: CircularProgressIndicator());
          }, (a) {
            return Dialog(
              backgroundColor: appCardBackgroundColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0)),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.8,
                width: MediaQuery.sizeOf(context).width * 0.9,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      "$commentsName Yorumları",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: a.isEmpty
                          ? const Center(
                              child: Text(
                                "Henüz yorum yapılmamış.\nİlk yorumu sen yap!",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white60),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: a.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, color: Colors.white12),
                              itemBuilder: (context, index) {
                                final item = a[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: appPrimaryColor.withOpacity(0.2),
                                    child: Icon(Icons.person,
                                        color: appAccentColor),
                                  ),
                                  title: Text(
                                    item.authorEmail,
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w600,
                                      color: appAccentColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item.comment,
                                    style: const TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 12.0,
                        left: 16.0,
                        right: 16.0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: appSurfaceColor,
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 8.0),
                          child: TextField(
                            controller: textController,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            decoration: const InputDecoration.collapsed(
                              hintText: "Bir yorum ekle...",
                              hintStyle: TextStyle(color: Colors.white54),
                            ),
                            onSubmitted: (_) => submitComment(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          backgroundColor: Colors.white,
                          foregroundColor: appPrimaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: submitComment,
                        icon: const Icon(Icons.send, color: appPrimaryColor, size: 18),
                        label: const Text(
                          "Yorum Yap",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: appPrimaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0)
                  ],
                ),
              ),
            );
          });
        },
      );
    },
  );
}
