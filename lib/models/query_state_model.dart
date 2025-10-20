
class QueryStateModel {

  String genre;
  int year;
  int offset;

  QueryStateModel(
    {
      required this.genre,
      required this.year,
      this.offset = 0,
    }
  );

  String get query => '$genre $year';

  void incrementOffset() => offset += 20;

}