import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:otraku/pages/tabs/explore_tab.dart';
import 'package:otraku/pages/tabs/collections_tab.dart';
import 'package:otraku/pages/tabs/inbox_tab.dart';
import 'package:otraku/pages/tabs/profile_tab.dart';
import 'package:otraku/providers/view_config.dart';

class TabManager extends StatefulWidget {
  static const int INBOX = 0;
  static const int ANIME_LIST = 1;
  static const int MANGA_LIST = 2;
  static const int EXPLORE = 3;
  static const int PROFILE = 4;

  const TabManager();

  @override
  _TabManagerState createState() => _TabManagerState();
}

class _TabManagerState extends State<TabManager> {
  static ScrollController _scrollCtrl;
  List<Widget> _tabs;
  List<BottomNavigationBarItem> _tabItems;
  PageController _pageCtrl;
  int _pageIndex;
  ValueNotifier<bool> _navBarVisibility;

  bool _bottomNavigationPageChange = false;

  void _scrollDirection() {
    if (_scrollCtrl.position.userScrollDirection == ScrollDirection.reverse) {
      if (_navBarVisibility.value) _navBarVisibility.value = false;
    } else if (_scrollCtrl.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_navBarVisibility.value) _navBarVisibility.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: ValueListenableBuilder(
        valueListenable: _navBarVisibility,
        builder: (_, value, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: value ? 56 : 0,
          child: child,
        ),
        child: Wrap(
          children: [
            BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 0,
              currentIndex: _pageIndex,
              items: _tabItems,
              onTap: (index) {
                if (_pageIndex == index) return;

                _bottomNavigationPageChange = true;
                final position = MediaQuery.of(context).size.width * index;
                if (index > _pageIndex) {
                  _pageCtrl.jumpTo(position - 100);
                } else {
                  _pageCtrl.jumpTo(position + 100);
                }

                _pageCtrl
                    .animateTo(
                      position,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.decelerate,
                    )
                    .then((_) => setState(() => _pageIndex = index));
                _bottomNavigationPageChange = false;
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: PageView(
          children: _tabs,
          controller: _pageCtrl,
          onPageChanged: (index) {
            if (!_bottomNavigationPageChange)
              setState(() => _pageIndex = index);
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageIndex = ViewConfig.initialPage;
    _pageCtrl = PageController(initialPage: _pageIndex);

    _navBarVisibility = ValueNotifier(true);
    _scrollCtrl = ScrollController();
    _scrollCtrl.addListener(_scrollDirection);

    _tabs = [
      InboxTab(),
      CollectionsTab(
        isAnime: true,
        scrollCtrl: _scrollCtrl,
        key: UniqueKey(),
      ),
      CollectionsTab(
        isAnime: false,
        scrollCtrl: _scrollCtrl,
        key: UniqueKey(),
      ),
      ExploreTab(_scrollCtrl),
      ProfileTab(),
    ];

    _tabItems = const [
      const BottomNavigationBarItem(
        icon: Icon(FluentSystemIcons.ic_fluent_mail_inbox_filled),
        label: '',
      ),
      const BottomNavigationBarItem(
        icon: Icon(FluentSystemIcons.ic_fluent_movies_and_tv_filled),
        label: '',
      ),
      const BottomNavigationBarItem(
        icon: Icon(FluentSystemIcons.ic_fluent_bookmark_filled),
        label: '',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.explore),
        label: '',
      ),
      const BottomNavigationBarItem(
        icon: Icon(FluentSystemIcons.ic_fluent_person_filled),
        label: '',
      ),
    ];
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.removeListener(_scrollDirection);
      _scrollCtrl.dispose();
    }
    super.dispose();
  }
}
