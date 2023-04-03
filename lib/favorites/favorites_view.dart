import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/common/tile_item.dart';
import 'package:otraku/favorites/favorites_model.dart';
import 'package:otraku/studio/studio_models.dart';
import 'package:otraku/favorites/favorites_provider.dart';
import 'package:otraku/studio/studio_grid.dart';
import 'package:otraku/utils/pagination_controller.dart';
import 'package:otraku/widgets/grids/tile_item_grid.dart';
import 'package:otraku/widgets/layouts/bottom_bar.dart';
import 'package:otraku/widgets/layouts/scaffolds.dart';
import 'package:otraku/widgets/layouts/direct_page_view.dart';
import 'package:otraku/widgets/layouts/top_bar.dart';
import 'package:otraku/widgets/pagination_view.dart';

class FavoritesView extends ConsumerStatefulWidget {
  const FavoritesView(this.id);

  final int id;

  @override
  ConsumerState<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends ConsumerState<FavoritesView> {
  FavoritesTab _tab = FavoritesTab.anime;
  late final _ctrl = PaginationController(
    loadMore: () => ref.read(favoritesProvider(widget.id).notifier).fetch(_tab),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(
      favoritesProvider(widget.id).select((s) => s.getCount(_tab)),
    );

    final onRefresh = () {
      ref.invalidate(favoritesProvider(widget.id));
      return Future.value();
    };

    return PageScaffold(
      bottomBar: BottomBarIconTabs(
        current: _tab.index,
        onChanged: (page) {
          setState(() => _tab = FavoritesTab.values.elementAt(page));
          _ctrl.scrollToTop();
        },
        onSame: (_) => _ctrl.scrollToTop(),
        items: const {
          'Anime': Ionicons.film_outline,
          'Manga': Ionicons.bookmark_outline,
          'Characters': Ionicons.man_outline,
          'Staff': Ionicons.mic_outline,
          'Studios': Ionicons.business_outline,
        },
      ),
      child: TabScaffold(
        topBar: TopBar(
          title: _tab.title,
          trailing: [
            if (count > 0)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
          ],
        ),
        child: DirectPageView(
          current: _tab.index,
          onChanged: (page) => setState(
            () => _tab = FavoritesTab.values.elementAt(page),
          ),
          children: [
            PaginationView<TileItem>(
              provider: favoritesProvider(widget.id).select((s) => s.anime),
              onData: (data) => TileItemGrid(data.items),
              scrollCtrl: _ctrl,
              onRefresh: onRefresh,
              dataType: 'favourite anime',
            ),
            PaginationView<TileItem>(
              provider: favoritesProvider(widget.id).select((s) => s.manga),
              onData: (data) => TileItemGrid(data.items),
              scrollCtrl: _ctrl,
              onRefresh: onRefresh,
              dataType: 'favourite manga',
            ),
            PaginationView<TileItem>(
              provider: favoritesProvider(widget.id).select(
                (s) => s.characters,
              ),
              onData: (data) => TileItemGrid(data.items),
              scrollCtrl: _ctrl,
              onRefresh: onRefresh,
              dataType: 'favourite characters',
            ),
            PaginationView<TileItem>(
              provider: favoritesProvider(widget.id).select((s) => s.staff),
              onData: (data) => TileItemGrid(data.items),
              scrollCtrl: _ctrl,
              onRefresh: onRefresh,
              dataType: 'favourite staff',
            ),
            PaginationView<StudioItem>(
              provider: favoritesProvider(widget.id).select((s) => s.studios),
              onData: (data) => StudioGrid(data.items),
              scrollCtrl: _ctrl,
              onRefresh: onRefresh,
              dataType: 'favourite studios',
            ),
          ],
        ),
      ),
    );
  }
}
