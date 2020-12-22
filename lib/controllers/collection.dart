import 'package:get/get.dart';
import 'package:otraku/enums/list_sort_enum.dart';
import 'package:otraku/models/entry_list.dart';
import 'package:otraku/models/sample_data/media_entry.dart';
import 'package:otraku/services/filterable.dart';
import 'package:otraku/services/graph_ql.dart';

class Collection extends GetxController implements Filterable {
  // ***************************************************************************
  // CONSTANTS
  // ***************************************************************************

  static const ANIME = 'anime';
  static const MANGA = 'manga';

  static const _collectionQuery = r'''
    query Collection($userId: Int, $type: MediaType) {
      MediaListCollection(userId: $userId, type: $type) {
        lists {
          name
          isCustomList
          isSplitCompletedList
          status
          entries {
            mediaId
            status
            score
            progress
            progressVolumes
            repeat
            notes
            startedAt {year month day}
            completedAt {year month day}
            updatedAt
            createdAt
            media {
              title {userPreferred}
              format
              status(version: 2)
              startDate {year month day}
              endDate {year month day}
              episodes
              chapters
              volumes
              coverImage {large}
              nextAiringEpisode {timeUntilAiring episode}
            }
          }
        }
        user {
          mediaListOptions {
            rowOrder
            scoreFormat
            animeList {sectionOrder customLists splitCompletedSectionByFormat}
            mangaList {sectionOrder customLists splitCompletedSectionByFormat}
          }
        }
      }
    }
  ''';

  // static const _updateEntryMutation = r'''
  //   mutation UpdateEntry($entryId: Int, $mediaId: Int, $status: MediaListStatus,
  //       $score: Float, $progress: Int, $progressVolumes: Int, $repeat: Int,
  //       $private: Boolean, $notes: String, $hiddenFromStatusLists: Boolean,
  //       $customLists: [String], $startedAt: FuzzyDateInput, $completedAt: FuzzyDateInput) {
  //     SaveMediaListEntry(id: $entryId, mediaId: $mediaId, status: $status,
  //       score: $score, progress: $progress, progressVolumes: $progressVolumes,
  //       repeat: $repeat, private: $private, notes: $notes,
  //       hiddenFromStatusLists: $hiddenFromStatusLists, customLists: $customLists,
  //       startedAt: $startedAt, completedAt: $completedAt) {
  //         mediaId
  //         status
  //         score
  //         progress
  //         progressVolumes
  //         repeat
  //         notes
  //         startedAt {year month day}
  //         completedAt {year month day}
  //         updatedAt
  //         createdAt
  //         media {
  //           title {userPreferred}
  //           format
  //           status(version: 2)
  //           startDate {year month day}
  //           endDate {year month day}
  //           episodes
  //           chapters
  //           volumes
  //           coverImage {large}
  //           nextAiringEpisode {timeUntilAiring episode}
  //         }
  //       }
  //   }
  // ''';

  // static const _removeEntryMutation = r'''
  //   mutation RemoveEntry($entryId: Int) {DeleteMediaListEntry(id: $entryId) {deleted}}
  // ''';

  // ***************************************************************************
  // DATA
  // ***************************************************************************

  final int userId;
  final bool ofAnime;
  final _lists = List<EntryList>().obs;
  final _entries = List<MediaEntry>().obs;
  final _listIndex = 0.obs;
  final Map<String, dynamic> _filters = {};
  bool _fetching = false;
  String _scoreFormat;
  ListSort _sort;

  Collection(this.userId, this.ofAnime);

  // ***************************************************************************
  // GETTERS & SETTERS
  // ***************************************************************************

  bool get fetching => _fetching;

  int get listIndex => _listIndex();

  String get scoreFormat => _scoreFormat;

  set listIndex(int value) {
    if (value < 0 || value >= _lists().length || value == _listIndex()) return;
    _listIndex.value = value;
    filter();
  }

  ListSort get sort => _sort;

  set sort(ListSort val) {
    if (val == _sort) return;
    _sort = val;
    for (final list in _lists()) list.sort(_sort);
    filter();
  }

  List<MediaEntry> get entries => _entries();

  String get currentName => _lists()[_listIndex()].name;

  int get currentCount => _lists()[_listIndex()].entries.length;

  int get totalEntryCount {
    int c = 0;
    for (final list in _lists())
      if (list.status != null) c += list.entries.length;
    return c;
  }

  List<String> get names {
    List<String> n = [];
    for (final list in _lists()) n.add(list.name);
    return n;
  }

  List<int> get allEntryCounts {
    List<int> c = [];
    for (final list in _lists()) c.add(list.entries.length);
    return c;
  }

  // ***************************************************************************
  // DATA FETCHING
  // ***************************************************************************

  Future<void> fetch() async {
    _fetching = true;
    Map<String, dynamic> data = await GraphQl.request(
      _collectionQuery,
      {
        'userId': userId ?? GraphQl.viewerId,
        'type': ofAnime ? 'ANIME' : 'MANGA',
      },
      popOnError: userId != null,
    );

    if (data == null) {
      _fetching = false;
      return null;
    }

    data = data['MediaListCollection'];

    final metaData = ofAnime
        ? data['user']['mediaListOptions']['animeList']
        : data['user']['mediaListOptions']['mangaList'];
    final bool splitCompleted = metaData['splitCompletedSectionByFormat'];

    _scoreFormat = data['user']['mediaListOptions']['scoreFormat'];
    _sort = ListSortHelper.getEnum(
      data['user']['mediaListOptions']['rowOrder'],
    );

    final List<EntryList> ls = [];
    for (final String section in metaData['sectionOrder']) {
      final index = (data['lists'] as List<dynamic>)
          .indexWhere((listData) => listData['name'] == section);

      if (index == -1) continue;

      final l = (data['lists'] as List<dynamic>).removeAt(index);

      ls.add(EntryList(l, splitCompleted)..sort(_sort));
    }

    for (final l in data['lists'])
      ls.add(EntryList(l, splitCompleted)..sort(_sort));

    _lists.assignAll(ls);
    _listIndex.value = 0;
    filter();
    _fetching = false;
  }

  // ***************************************************************************
  // FILTERING
  // ***************************************************************************

  void filter() {
    final search = (_filters[Filterable.SEARCH] as String)?.toLowerCase();
    final formatIn = _filters[Filterable.FORMAT_IN];
    final formatNotIn = _filters[Filterable.FORMAT_NOT_IN];
    final statusIn = _filters[Filterable.STATUS_IN];
    final statusNotIn = _filters[Filterable.STATUS_NOT_IN];

    final list = _lists()[_listIndex()];
    final List<MediaEntry> e = [];

    for (final entry in list.entries) {
      if (search != null && !entry.title.toLowerCase().contains(search))
        continue;

      if (formatIn != null) {
        bool isIn = false;
        for (final format in formatIn)
          if (entry.format == format) {
            isIn = true;
            break;
          }
        if (!isIn) continue;
      }

      if (formatNotIn != null) {
        bool isIn = false;
        for (final format in formatNotIn)
          if (entry.format == format) {
            isIn = true;
            break;
          }
        if (isIn) continue;
      }

      if (statusIn != null) {
        bool isIn = false;
        for (final status in statusIn)
          if (entry.status == status) {
            isIn = true;
            break;
          }
        if (!isIn) continue;
      }

      if (statusNotIn != null) {
        bool isIn = false;
        for (final status in statusNotIn)
          if (entry.status == status) {
            isIn = true;
            break;
          }
        if (isIn) continue;
      }

      e.add(entry);
    }

    _entries.assignAll(e);
  }

  @override
  dynamic getFilterWithKey(String key) => _filters[key];

  @override
  void setFilterWithKey(String key, {dynamic value, bool update = false}) {
    if (value == null ||
        (value is List && value.isEmpty) ||
        (value is String && value.trim().isEmpty)) {
      _filters.remove(key);
    } else {
      _filters[key] = value;
    }

    if (update) filter();
  }

  @override
  void clearAllFilters({bool update = true}) => clearFiltersWithKeys([
        Filterable.STATUS_IN,
        Filterable.STATUS_NOT_IN,
        Filterable.FORMAT_IN,
        Filterable.FORMAT_NOT_IN,
        Filterable.GENRE_IN,
        Filterable.GENRE_NOT_IN,
      ], update: update);

  @override
  void clearFiltersWithKeys(List<String> keys, {bool update = true}) {
    for (final key in keys) {
      _filters.remove(key);
    }

    if (update) filter();
  }

  @override
  bool anyActiveFilterFrom(List<String> keys) {
    return false;
  }
}