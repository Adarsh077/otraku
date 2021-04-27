import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:otraku/controllers/collection.dart';
import 'package:otraku/pages/home/explore_page.dart';
import 'package:otraku/pages/home/collection_page.dart';
import 'package:otraku/pages/home/feed_page.dart';
import 'package:otraku/pages/home/user_page.dart';
import 'package:otraku/utils/config.dart';
import 'package:otraku/widgets/navigation/custom_drawer.dart';
import 'package:otraku/widgets/navigation/nav_bar.dart';

import '../../utils/client.dart';

class HomePage extends StatelessWidget {
  static const ROUTE = '/home';

  static const FEED = 0;
  static const ANIME_LIST = 1;
  static const MANGA_LIST = 2;
  static const EXPLORE = 3;
  static const PROFILE = 4;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const FeedTab(),
      CollectionTab(
        ofAnime: true,
        id: Client.viewerId!,
        collectionTag: Collection.ANIME,
        key: UniqueKey(),
      ),
      CollectionTab(
        ofAnime: false,
        id: Client.viewerId!,
        collectionTag: Collection.MANGA,
        key: UniqueKey(),
      ),
      const ExploreTab(),
      UserTab(Client.viewerId!, null),
    ];

    const drawers = [
      const SizedBox(),
      const CollectionDrawer(Collection.ANIME),
      const CollectionDrawer(Collection.MANGA),
      const ExploreDrawer(),
      const SizedBox(),
    ];

    return ValueListenableBuilder<int>(
      valueListenable: Config.index,
      builder: (_, index, __) => Scaffold(
        extendBody: true,
        drawerScrimColor: Theme.of(context).primaryColor.withAlpha(150),
        bottomNavigationBar: NavBar(
          options: {
            'Feed': FluentIcons.mail_inbox_24_regular,
            'Anime': FluentIcons.movies_and_tv_24_regular,
            'Manga': FluentIcons.bookmark_24_regular,
            'Explore': Icons.explore_outlined,
            'Profile': FluentIcons.person_24_regular,
          },
          onChanged: (page) => Config.setIndex(page),
          initial: index,
        ),
        drawer: drawers[index],
        body: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: Config.TAB_SWITCH_DURATION,
            child: tabs[index],
          ),
        ),
      ),
    );
  }
}
