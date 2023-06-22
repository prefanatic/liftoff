import 'package:flutter/material.dart';
import 'package:lemmy_api_client/v3.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';

import '../../pages/full_post/full_post.dart';
import '../../stores/config_store.dart';
import '../../util/async_store_listener.dart';
import '../../util/extensions/api.dart';
import '../../util/mobx_provider.dart';
import '../../util/observer_consumers.dart';
import 'post_actions.dart';
import 'post_body.dart';
import 'post_info_section.dart';
import 'post_link_preview.dart';
import 'post_media.dart';
import 'post_status.dart';
import 'post_store.dart';
import 'post_title.dart';

class PostTile extends StatelessWidget {
  final PostStore postStore;
  final IsFullPost fullPost;

  const PostTile.fromPostStore(this.postStore, {this.fullPost = true});
  PostTile.fromPostView(PostView post, {this.fullPost = false})
      : postStore = PostStore(post);

  @override
  Widget build(BuildContext context) {
    return Nested(
      children: [
        MobxProvider.value(value: postStore),
        Provider.value(value: fullPost),
        AsyncStoreListener(asyncStore: postStore.savingState),
        AsyncStoreListener(asyncStore: postStore.votingState),
        AsyncStoreListener<BlockedPerson>(
          asyncStore: postStore.userBlockingState,
          successMessageBuilder: (context, state) {
            final name = state.personView.person.preferredName;
            return state.blocked ? '$name blocked' : '$name unblocked';
          },
        ),
        AsyncStoreListener<PostReportView>(
          asyncStore: postStore.reportingState,
          successMessageBuilder: (context, data) => 'Post reported',
        ),
      ],
      child: const _Post(),
    );
  }
}

/// A post overview card
class _Post extends StatelessWidget {
  const _Post();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFullPost = context.read<IsFullPost>();
    return GestureDetector(
      onTap: isFullPost
          ? null
          : () {
              final postStore = context.read<PostStore>();
              Navigator.of(context)
                  .push(FullPostPage.fromPostStoreRoute(postStore));
            },
      child: ObserverBuilder<ConfigStore>(
        builder: (context, store) => DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: store.postCardShadow
                ? const [BoxShadow(blurRadius: 15, color: Colors.black45)]
                : null,
            color: theme.cardColor,
            borderRadius: store.postRoundedCorners
                ? const BorderRadius.all(Radius.circular(10))
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                const PostInfoSection(),
                const PostTitle(),
                if (!store.compactPostView) const PostMedia(),
                if (!store.compactPostView) const PostLinkPreview(),
                if (!store.compactPostView) const PostBody(),
                const PostActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
