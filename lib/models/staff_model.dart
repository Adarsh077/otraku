class StaffModel {
  final int id;
  final String firstName;
  final String middleName;
  final String lastName;
  final List<String> altNames;
  final String description;
  final String? imageUrl;
  final String? language;
  final List<String> primaryOccupations;
  final String? gender;
  final String? homeTown;
  final int? age;
  final int? startYear;
  final int? endYear;
  final int favourites;
  final bool isFavouriteBlocked;
  bool isFavourite;

  StaffModel._({
    required this.id,
    required this.imageUrl,
    required this.language,
    required this.primaryOccupations,
    required this.gender,
    required this.homeTown,
    required this.age,
    required this.startYear,
    required this.endYear,
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.description = '',
    this.altNames = const [],
    this.favourites = 0,
    this.isFavourite = false,
    this.isFavouriteBlocked = false,
  });

  factory StaffModel(Map<String, dynamic> map) {
    final yearsActive = (map['yearsActive'] as List<dynamic>).cast<int>();
    final alts = map['name']['alternative'] != null
        ? (map['name']['alternative'] as List<dynamic>).cast<String>()
        : <String>[];
    if (map['name']['native'] != null)
      alts.insert(0, map['name']['native'].toString());
    final occupations = map['primaryOccupations'] != null
        ? (map['primaryOccupations'] as List<dynamic>).cast<String>()
        : <String>[];

    return StaffModel._(
      id: map['id'],
      firstName: map['name']['first'] ?? '',
      middleName: map['name']['middle'] ?? '',
      lastName: map['name']['last'] ?? '',
      altNames: alts,
      imageUrl: map['image']['large'],
      language: map['languageV2'],
      primaryOccupations: occupations,
      gender: map['gender'],
      homeTown: map['homeTown'],
      age: map['age'],
      startYear: yearsActive.length > 0 ? yearsActive[0] : null,
      endYear: yearsActive.length > 1 ? yearsActive[1] : null,
      description: map['description'] ?? '',
      favourites: map['favourites'] ?? 0,
      isFavourite: map['isFavourite'] ?? false,
      isFavouriteBlocked: map['isFavouriteBlocked'] ?? false,
    );
  }
}