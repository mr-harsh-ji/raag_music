import 'package:get_it/get_it.dart';
import 'package:raag_music/locals/language_provider.dart';

extension Translate on String {
  String get tr {
    return GetIt.instance<LanguageProvider>().getTranslatedString(this);
  }
}
