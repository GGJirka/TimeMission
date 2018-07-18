import 'package:shared_preferences/shared_preferences.dart';

class LanguageManager {
  SharedPreferences sharedPreferences;
  bool isCzech;

  List<Language> words = <Language>[
    new Language(englishText: "Start working", czechText: "Začít pracovat"),
    new Language(englishText: "Stop working", czechText: "Přestat pracovat"),

    new Language(
        englishText: "You are not working at the moment!",
        czechText: "Momentálně nepracuješ!"),
    new Language(englishText: "Started at", czechText: "Začal jsi v"),
    new Language(englishText: "Project", czechText: "Projekt"),

    new Language(englishText: "Work type", czechText: "Typ práce"),
    new Language(englishText: "Settings", czechText: "Nastavení"),

    new Language(englishText: "Work Records", czechText: "Pracovní Záznamy"),
    new Language(englishText: "Exit", czechText: "Exit"),

    new Language(englishText: "Display language", czechText: "Jazyk"),
    new Language(englishText: "English", czechText: "Angličtina"),

    new Language(englishText: "Czech", czechText: "Čeština"),

    new Language(englishText: "Description", czechText: "Popis práce"),
    new Language(englishText: "Cancel", czechText: "Zrušit"),
    new Language(englishText: "Add", czechText: "Přidat"),
    new Language(englishText: "Skip", czechText: "Přeskočit"),

    new Language(
        englishText: "Error with login. Enter a valid username and password",
        czechText: "Chyba při přihlášení. Zadejte správné přihlašovací údaje"),
    //15
    new Language(
        englishText: "Couldn't connect to server",
        czechText: "Chyba při spojení se serverem"),
    new Language(englishText: "Logging in", czechText: "Přihlašování"),
    new Language(englishText: "Username", czechText: "Jméno"),
    new Language(englishText: "Password", czechText: "Heslo"),
    new Language(
        englishText: "  Remember me", czechText: "  Zapomatovat údaje"),
    new Language(englishText: "Login", czechText: "Přihlásit se"),

    new Language(englishText: "Monday", czechText: "Pondělí"),
    new Language(englishText: "Tuesday", czechText: "Úterý"),
    new Language(englishText: "Wednesday", czechText: "Středa"),
    new Language(englishText: "Thursday", czechText: "Čtvrtek"),
    new Language(englishText: "Friday", czechText: "Pátek"),
    new Language(
        englishText: "Work added successfully",
        czechText: "Pracovní záznam byl přidán"),
    new Language(
        englishText: "To make change you need to restart app",
        czechText: "Aby se projevila změna, musíte aplikaci restarovat"),
    new Language(englishText: "Change user", czechText: "Změnit uživatele"),
    new Language(englishText: "Upload", czechText: "Nahrát"),
    new Language(englishText: "Comment", czechText: "Poznámka"),
    new Language(englishText: "Waiting for upload",
        czechText: "Záznamy připravené k odeslání"),
    new Language(
        englishText: "You have project waiting to upload. Would you like to continue anyway?",
        czechText: "Máte neodeslané pracovní záznamy. Chcete i přesto pokračovat?"),
    new Language(englishText: "UPLOAD ALL", czechText: "NAHRÁT VŠECHNY"),
    new Language(
        englishText: "Waiting for upload", czechText: "Připraveny k nahrání"),

    new Language(englishText: "Work time must be longer than 10 min",
        czechText: "Čas práce musí být delší jak 10min"),
  ];

  setLanguage() async {
    sharedPreferences = await SharedPreferences.getInstance();
    isCzech = sharedPreferences.get("language") == "czech" ? true : false;
  }

  String getWords(int index) {
    return isCzech
        ? words[index].czechText
        : words[index].englishText;
  }
}

class Language {
  String englishText;

  String czechText;

  Language({this.englishText, this.czechText});
}
