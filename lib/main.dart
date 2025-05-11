import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:local_auth/local_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstStart = prefs.getBool('isFirstStart') ?? true;
 
  runApp(MyApp(firstStart: isFirstStart));
}



class MyApp extends StatelessWidget {
  final bool firstStart;
  
  const MyApp({super.key, required this.firstStart});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GerEA',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: firstStart ? SetupWizard() : HomeWithBottomNav(),
    );
  } 
}

class NutzerdatenModel {
  String vorname;
  String nachname;
  String geschlecht;
  bool istPrivatVersichert;
  String krankenkasse;
  String groesse;
  String gewicht;
  String blutgruppe;
  String allergien;
  bool depression;
  bool angst;
  bool schlafprobleme;
  String mentaleNotizen;

  NutzerdatenModel({
    required this.vorname,
    required this.nachname,
    required this.geschlecht,
    required this.istPrivatVersichert,
    required this.krankenkasse,
    required this.groesse,
    required this.gewicht,
    required this.blutgruppe,
    required this.allergien,
    required this.depression,
    required this.angst,
    required this.schlafprobleme,
    required this.mentaleNotizen,
  });
}

// Navigation
class HomeWithBottomNav extends StatefulWidget {
  const HomeWithBottomNav({super.key});

  @override
  _HomeWithBottomNavState createState() => _HomeWithBottomNavState();
}

class _HomeWithBottomNavState extends State<HomeWithBottomNav> {
  int _selectedIndex = 2;

  final List<Widget> _pages = [
    NotrufPage(),
    VerlaufPage(),
    HomePage(),
    PersoenlichesPage(),
    EinstellungenPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
      ),//Mainpage
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(8),
            margin: EdgeInsets.only(top: 0, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Text(
              'Always call 112 when life is in danger!',
              style: TextStyle(fontWeight: FontWeight.bold , fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(child: _pages[_selectedIndex]),
        ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.call), label: '112'),
          BottomNavigationBarItem(icon: Icon(Icons.watch_later), label: 'Verlauf'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Persönlich'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Einstellungen'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }

}

// Notrufseite
class NotrufPage extends StatefulWidget {
  const NotrufPage({super.key});

  @override
  _NotrufPageState createState() => _NotrufPageState();

}
Future<void> _refresh(){
    return Future.delayed(Duration(seconds: 2), () {
    });
  }
class _NotrufPageState extends State<NotrufPage> {
  String _permissionStatus = 'Unbekannt';
  String _notrufnummer = '112'; // Standard-Nummer für EU
  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );
  Position? position;
  List<dynamic>? address;

  @override
  void initState() {
    super.initState();
    _initPosition();
  }

  Future<void> _initPosition() async {
    position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
    if (position != null) {
      address = await placemarkFromCoordinates(position!.latitude, position!.longitude);
    }
    setState(() {});
  }
  String get addressString {
    if (address != null && address!.isNotEmpty) {
      return '${address![0].street}, ${address![0].locality}, ${address![0].country}';
    }
    return 'Unbekannt';
  }
  

  Future<void> _checkPermissions() async {
    final micStatus = await Permission.microphone.request();
    final locStatus = await Permission.location.request();

    setState(() {
      _permissionStatus = (micStatus.isGranted && locStatus.isGranted)
          ? 'Mikrofon & Standort erlaubt'
          : 'Nicht alle Berechtigungen erlaubt';
    });
  }
Future<void> _launchUrl(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri)) {
    throw Exception('Could not launch $url');
  }
}
  Future<void> _getEmergencyNumber() async {
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      final countryCode = placemarks.first.isoCountryCode ?? 'EU';

      final emergencyMap = {
        'DE': '112',
        'AT': '112',
        'CH': '112',
        'FR': '112',
        'IT': '112',
        'ES': '112',
        'US': '911',
        'CA': '911',
        'UK': '999',
        'AU': '000',
        'IN': '112',
      };

      setState(() {
        _notrufnummer = emergencyMap[countryCode] ?? '112';
      });
    } catch (e) {
      print('🌍 Fehler bei Standort/Nation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 50),
        ElevatedButton(
          onPressed:  (){
            ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Zum Anrufen länger drücken!'),
        duration: Duration(seconds: 2),
      ),  
    );
          }
           
            , onLongPress: () async {
              await _getEmergencyNumber();
              await FlutterPhoneDirectCaller.callNumber(_notrufnummer + "78aa");
            },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            textStyle: TextStyle(fontSize: 24, color: Colors.black),
            backgroundColor: Colors.red,
            
          ),
          child: Text('Notruf jetzt absetzen', style: TextStyle(color: Colors.black)),
        ),
        SizedBox(height: 40),
        ElevatedButton(
          onPressed: _checkPermissions,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 25),
            textStyle: TextStyle(fontSize: 16, color: Colors.black),
          ),
          child: Text(addressString),
        ),
        SizedBox(height: 20),
        Text("Solltest/sollten gerade du oder andere Menschen in Lebensgafahr sein, rufe sofort den Notdienst! Es zählt jede Sekunde!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        SizedBox(height: 100),
        Text(
          _permissionStatus,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        ElevatedButton(
          onPressed: () {
            launchUrl(Uri.parse("https://www.notruf112.bayern.de/5w/index.php"));
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 25),
            textStyle: TextStyle(fontSize: 16, color: Colors.black),
          ),
          child: Text("Anleitung für Notruf"),
        ),
      ],
    );
  }
}

// Verlaufsseite

class VerlaufPage extends StatefulWidget {
  VerlaufPage({super.key});

  @override
  _VerlaufPageState createState() => _VerlaufPageState();
}

class _VerlaufPageState extends State<VerlaufPage> {
  List<Map<String, dynamic>> eintraege = [];

  @override
  void initState() {
    super.initState();
    _loadEntries(); // Lädt die gespeicherten Einträge beim Start
  }

  // Lädt die Einträge aus den SharedPreferences
  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getString('verlauf_eintraege');
    
    if (entriesJson != null) {
      setState(() {
        final List<dynamic> decodedList = jsonDecode(entriesJson);
        eintraege = decodedList.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  // Speichert die Einträge in den SharedPreferences
  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = jsonEncode(eintraege);
    await prefs.setString('verlauf_eintraege', entriesJson);
  }

  Future<void> _refresh() async {
    await _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Verlauf deiner gemeldeten Probleme',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: eintraege.isEmpty
                ? Center(
                    child: Text(
                      'Keine Einträge vorhanden',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: eintraege.length,
                    itemBuilder: (context, index) {
                      final eintrag = eintraege[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text(eintrag["datum"]!),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(eintrag["beschreibung"] ?? ""),
                              SizedBox(height: 4),
                              Text("Stärke: ${eintrag["staerke"] ?? "-"} / 10"),
                              Text("Häufigkeit: ${eintrag["haeufigkeit"] ?? "-"} / 10"),
                            ],
                          ),
                          onTap: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Eintrag Details'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Details zu ${eintrag["beschreibung"]} am ${eintrag["datum"]}'),
                                  SizedBox(height: 8),
                                  Text('Stärke der Schmerzen: ${eintrag["staerke"]} / 10'),
                                  Text('Häufigkeit: ${eintrag["haeufigkeit"]} / 10'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('Schließen'),
                                ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Eintrag löschen?'),
                                  content: Text('Möchten Sie diesen Eintrag wirklich löschen?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text('Abbrechen'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          eintraege.removeAt(index);
                                          _saveEntries(); // Speichert nach dem Löschen
                                        });
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Eintrag gelöscht')),
                                        );
                                      },
                                      child: Text('Löschen'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Neuen Eintrag hinzufügen'),
              onPressed: () {
                String beschreibung = "";
                int staerke = 5;
                int haeufigkeit = 1;
                showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setStateDialog) {
                        return AlertDialog(
                          title: Text('Heutige Beschwerden hinzufügen'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  decoration: InputDecoration(hintText: 'Trage hier deine Beschwerden ein'),
                                  onChanged: (value) {
                                    beschreibung = value;
                                  },
                                ),
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    Text("Stärke:"),
                                    Expanded(
                                      child: Slider(
                                        value: staerke.toDouble(),
                                        min: 1,
                                        max: 10,
                                        divisions: 9,
                                        label: staerke.toString(),
                                        onChanged: (value) {
                                          setStateDialog(() {
                                            staerke = value.round();
                                          });
                                        },
                                      ),
                                    ),
                                    Text("$staerke"),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text("Häufigkeit:"),
                                    Expanded(
                                      child: Slider(
                                        value: haeufigkeit.toDouble(),
                                        min: 1,
                                        max: 10,
                                        divisions: 9,
                                        label: haeufigkeit.toString(),
                                        onChanged: (value) {
                                          setStateDialog(() {
                                            haeufigkeit = value.round();
                                          });
                                        },
                                      ),
                                    ),
                                    Text("$haeufigkeit"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('Abbrechen'),
                            ),
                            TextButton(
                              onPressed: () {
                                if (beschreibung.trim().isEmpty) return;
                                setState(() {
                                  eintraege.add({
                                    "datum": "${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}",
                                    "beschreibung": beschreibung,
                                    "staerke": staerke,
                                    "haeufigkeit": haeufigkeit,
                                  });
                                  _saveEntries(); // Speichert nach dem Hinzufügen
                                });
                                Navigator.of(context).pop();
                              },
                              child: Text('Hinzufügen'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                textStyle: TextStyle(fontSize: 16, color: Colors.black),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _spokenText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => print('Status: $status'),
        onError: (errorNotification) => print('Fehler: $errorNotification'),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (result) {
          setState(() => _spokenText = result.recognizedWords);
        });
      } else {
        print("Sprachdienst nicht verfügbar");
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: _listen,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                textStyle: TextStyle(fontSize: 24, color: Colors.black),
                foregroundColor: Colors.black,
              ),
              child: Text(
                _isListening ? 'Stoppe Aufnahme' : 'Jetzt Problem beschreiben',
                style: TextStyle(color: Colors.black),
              ),
            ),
            if (_spokenText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Du hast gesagt: $_spokenText',
                  style: TextStyle(color: Colors.black),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HilfeBeschreiben()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              textStyle: TextStyle(fontSize: 24, color: Colors.black),
              backgroundColor: Colors.red,
              foregroundColor: Colors.black,
            ),
            child: Text(
              'Problem beschreiben via Auswahlmenu',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
      ]
    );
  }
}






class PersoenlichesPage extends StatefulWidget {
  @override
  _PersoenlichesPageState createState() => _PersoenlichesPageState();
}

class Nutzerdaten {
  final String vorname;
  final String nachname;
  final String geschlecht;
  final bool istPrivatVersichert;
  final String krankenkasse;
  final String groesse;
  final String gewicht;
  final String blutgruppe;
  final String allergien;
  final bool depression;
  final bool angst;
  final bool schlafprobleme;
  final String mentaleNotizen;
  final String notfallKontaktName;
  final String notfallKontaktTelefon;
  final String notfallKontaktEmail;
  final bool notfallKontaktBenachrichtigen;

  Nutzerdaten({
    required this.vorname,
    required this.nachname,
    required this.geschlecht,
    required this.istPrivatVersichert,
    required this.krankenkasse,
    required this.groesse,
    required this.gewicht,
    required this.blutgruppe,
    required this.allergien,
    required this.depression,
    required this.angst,
    required this.schlafprobleme,
    required this.mentaleNotizen,
    this.notfallKontaktName = '',
    this.notfallKontaktTelefon = '',
    this.notfallKontaktEmail = '',
    this.notfallKontaktBenachrichtigen = false,
  });


  Map<String, dynamic> toMap() {
    return {
      'vorname': vorname,
      'nachname': nachname,
      'geschlecht': geschlecht,
      'istPrivatVersichert': istPrivatVersichert,
      'krankenkasse': krankenkasse,
      'groesse': groesse,
      'gewicht': gewicht,
      'blutgruppe': blutgruppe,
      'allergien': allergien,
      'depression': depression,
      'angst': angst,
      'schlafprobleme': schlafprobleme,
      'mentaleNotizen': mentaleNotizen,
      'notfallKontaktName': notfallKontaktName,
      'notfallKontaktTelefon': notfallKontaktTelefon,
      'notfallKontaktEmail': notfallKontaktEmail,
      'notfallKontaktBenachrichtigen': notfallKontaktBenachrichtigen,
    };
  }

  factory Nutzerdaten.fromMap(Map<String, dynamic> map) {
    return Nutzerdaten(
      vorname: map['vorname'] ?? '',
      nachname: map['nachname'] ?? '',
      geschlecht: map['geschlecht'] ?? 'Anderes',
      istPrivatVersichert: map['istPrivatVersichert'] ?? false,
      krankenkasse: map['krankenkasse'] ?? 'Andere',
      groesse: map['groesse'] ?? '',
      gewicht: map['gewicht'] ?? '',
      blutgruppe: map['blutgruppe'] ?? '',
      allergien: map['allergien'] ?? '',
      depression: map['depression'] ?? false,
      angst: map['angst'] ?? false,
      schlafprobleme: map['schlafprobleme'] ?? false,
      mentaleNotizen: map['mentaleNotizen'] ?? '',
      notfallKontaktName: map['notfallKontaktName'] ?? '',
      notfallKontaktTelefon: map['notfallKontaktTelefon'] ?? '',
      notfallKontaktEmail: map['notfallKontaktEmail'] ?? '',
      notfallKontaktBenachrichtigen: map['notfallKontaktBenachrichtigen'] ?? false,
    );
  }
}

class _PersoenlichesPageState extends State<PersoenlichesPage> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;

  bool isPrivate = false;
  String selectedKasse = 'Andere';
  String geschlecht = "Anderes";
  bool depression = false;
  bool angst = false;
  bool schlafprobleme = false;
  bool notfallKontaktBenachrichtigen = false;

  final TextEditingController vornameController = TextEditingController();
  final TextEditingController nachnameController = TextEditingController();
  final TextEditingController groesseController = TextEditingController();
  final TextEditingController gewichtController = TextEditingController();
  final TextEditingController blutgruppeController = TextEditingController();
  final TextEditingController allergienController = TextEditingController();
  final TextEditingController mentaleNotizenController = TextEditingController();
  
  // Notfallkontakt Controller
  final TextEditingController notfallKontaktNameController = TextEditingController();
  final TextEditingController notfallKontaktTelefonController = TextEditingController();
  final TextEditingController notfallKontaktEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _authenticate().then((_) {
      if (_isAuthenticated) {
        _loadData(); // Lade Daten nach erfolgreicher Authentifizierung
      }
    });
  }

  // Methode zum Laden der Daten aus SharedPreferences
  Future<void> _loadData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      setState(() {
        vornameController.text = prefs.getString('vorname') ?? '';
        nachnameController.text = prefs.getString('nachname') ?? '';
        geschlecht = prefs.getString('geschlecht') ?? 'Anderes';
        isPrivate = prefs.getBool('istPrivatVersichert') ?? false;
        selectedKasse = prefs.getString('krankenkasse') ?? 'Andere';
        groesseController.text = prefs.getString('groesse') ?? '';
        gewichtController.text = prefs.getString('gewicht') ?? '';
        blutgruppeController.text = prefs.getString('blutgruppe') ?? '';
        allergienController.text = prefs.getString('allergien') ?? '';
        depression = prefs.getBool('depression') ?? false;
        angst = prefs.getBool('angst') ?? false;
        schlafprobleme = prefs.getBool('schlafprobleme') ?? false;
        mentaleNotizenController.text = prefs.getString('mentaleNotizen') ?? '';
        
        // Notfallkontakt Daten laden
        notfallKontaktNameController.text = prefs.getString('notfallKontaktName') ?? '';
        notfallKontaktTelefonController.text = prefs.getString('notfallKontaktTelefon') ?? '';
        notfallKontaktEmailController.text = prefs.getString('notfallKontaktEmail') ?? '';
        notfallKontaktBenachrichtigen = prefs.getBool('notfallKontaktBenachrichtigen') ?? false;
      });
      
      print("Daten erfolgreich geladen");
    } catch (e) {
      print("Fehler beim Laden der Daten: $e");
    }
  }

  // Methode zum Speichern der Daten in SharedPreferences
  Future<void> _saveData() async {
    try {
      final daten = Nutzerdaten(
        vorname: vornameController.text,
        nachname: nachnameController.text,
        geschlecht: geschlecht,
        istPrivatVersichert: isPrivate,
        krankenkasse: selectedKasse,
        groesse: groesseController.text,
        gewicht: gewichtController.text,
        blutgruppe: blutgruppeController.text,
        allergien: allergienController.text,
        depression: depression,
        angst: angst,
        schlafprobleme: schlafprobleme,
        mentaleNotizen: mentaleNotizenController.text,
        notfallKontaktName: notfallKontaktNameController.text,
        notfallKontaktTelefon: notfallKontaktTelefonController.text,
        notfallKontaktEmail: notfallKontaktEmailController.text,
        notfallKontaktBenachrichtigen: notfallKontaktBenachrichtigen,
      );
      
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Speichere alle Werte
      await prefs.setString('vorname', daten.vorname);
      await prefs.setString('nachname', daten.nachname);
      await prefs.setString('geschlecht', daten.geschlecht);
      await prefs.setBool('istPrivatVersichert', daten.istPrivatVersichert);
      await prefs.setString('krankenkasse', daten.krankenkasse);
      await prefs.setString('groesse', daten.groesse);
      await prefs.setString('gewicht', daten.gewicht);
      await prefs.setString('blutgruppe', daten.blutgruppe);
      await prefs.setString('allergien', daten.allergien);
      await prefs.setBool('depression', daten.depression);
      await prefs.setBool('angst', daten.angst);
      await prefs.setBool('schlafprobleme', daten.schlafprobleme);
      await prefs.setString('mentaleNotizen', daten.mentaleNotizen);
      
      // Notfallkontakt Daten speichern
      await prefs.setString('notfallKontaktName', daten.notfallKontaktName);
      await prefs.setString('notfallKontaktTelefon', daten.notfallKontaktTelefon);
      await prefs.setString('notfallKontaktEmail', daten.notfallKontaktEmail);
      await prefs.setBool('notfallKontaktBenachrichtigen', daten.notfallKontaktBenachrichtigen);
      
      print("Gespeichert: ${daten.vorname}, Notfallkontakt: ${daten.notfallKontaktName}");
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Daten gespeichert')),
      );
    } catch (e) {
      print("Fehler beim Speichern der Daten: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern der Daten')),
      );
    }
  }
  
  // Methode zum Senden einer Notfall-E-Mail
  Future<void> _sendEmergencyEmail() async {
    try {
      // Hier würde die E-Mail-Versand-Implementierung erfolgen
      // Dafür benötigt man ein Package wie flutter_email_sender oder url_launcher
      // Beispiel-Implementierung mit url_launcher:
      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: notfallKontaktEmailController.text,
        queryParameters: {
          'subject': 'Medizinischer Notfall - ${vornameController.text} ${nachnameController.text}',
          'body': 'Dies ist eine automatische Benachrichtigung über einen medizinischen Notfall.\n\n'
              'Patient: ${vornameController.text} ${nachnameController.text}\n'
              'Blutgruppe: ${blutgruppeController.text}\n'
              'Allergien: ${allergienController.text}\n'
              'Bitte kontaktieren Sie umgehend medizinisches Fachpersonal.',
        },
      );
      
      // Launch-Methode würde hier aufgerufen
      // await launch(emailLaunchUri.toString());
      
      print("Notfall-E-Mail-Link generiert: $emailLaunchUri");
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notfall-E-Mail würde gesendet werden an: ${notfallKontaktEmailController.text}')),
      );
    } catch (e) {
      print("Fehler beim Erstellen der Notfall-E-Mail: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Erstellen der Notfall-E-Mail')),
      );
    }
  }

  Future<void> _authenticate() async {
    try {
      bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Bitte mit Fingerabdruck oder Gesicht entsperren',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: false,
        ),
      );
      if (didAuthenticate) {
        setState(() {
          _isAuthenticated = true;
        });
      }
    } catch (e) {
      print("Fehler bei Authentifizierung: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Center(child: Text('Authentifizierung erforderlich...'));
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          Text('Grunddaten', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: vornameController,
                  decoration: InputDecoration(labelText: 'Vorname'),
                ),
                TextField(
                  controller: nachnameController,
                  decoration: InputDecoration(labelText: 'Nachname'),
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Wähle dein Geschlecht'),
                  value: geschlecht,
                  onChanged: (String? newValue) {
                    setState(() {
                      geschlecht = newValue!;
                    });
                  },
                  items: ['Männlich', 'Weiblich', 'Anderes']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text('Krankenkasse', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: Text(isPrivate ? 'Privat versichert' : 'Gesetzlich versichert'),
            value: isPrivate,
            onChanged: (bool value) {
              setState(() {
                isPrivate = value;
              });
            },
          ), 
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Wähle deine Krankenkasse'),
              value: selectedKasse,
              onChanged: (String? newValue) {
                setState(() {
                  selectedKasse = newValue!;
                });
              },
              items: ['AOK', 'TK', 'Barmer', 'DAK', 'HKK', 'Privat', 'Andere']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Text('Körperliche Informationen', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: groesseController,
                  decoration: InputDecoration(labelText: 'Größe (cm)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: gewichtController,
                  decoration: InputDecoration(labelText: 'Gewicht (kg)'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: blutgruppeController.text.isNotEmpty ? blutgruppeController.text : null,
                  decoration: InputDecoration(labelText: 'Blutgruppe'),
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                      .map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      blutgruppeController.text = newValue;
                    }
                  },
                ),
                TextField(
                  controller: allergienController,
                  decoration: InputDecoration(labelText: 'Allergien'),
                ),
              ],
            ),
          ),
          Text('Mentale Gesundheit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          CheckboxListTile(
            title: Text("Depressionen"),
            value: depression,
            onChanged: (val) {
              setState(() {
                depression = val ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: Text("Angstzustände"),
            value: angst,
            onChanged: (val) {
              setState(() {
                angst = val ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: Text("Schlafprobleme"),
            value: schlafprobleme,
            onChanged: (val) {
              setState(() {
                schlafprobleme = val ?? false;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: mentaleNotizenController,
              decoration: InputDecoration(labelText: 'Weitere mentale Notizen'),
              maxLines: 3,
            ),
          ),
          SizedBox(height: 20),
          Text('Notfallkontakt', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: notfallKontaktNameController,
                  decoration: InputDecoration(labelText: 'Name des Notfallkontakts'),
                ),
                TextField(
                  controller: notfallKontaktTelefonController,
                  decoration: InputDecoration(labelText: 'Telefonnummer des Notfallkontakts'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: notfallKontaktEmailController,
                  decoration: InputDecoration(labelText: 'E-Mail des Notfallkontakts'),
                  keyboardType: TextInputType.emailAddress,
                ),
                SwitchListTile(
                  title: Text('Notfallkontakt per E-Mail benachrichtigen'),
                  value: notfallKontaktBenachrichtigen,
                  onChanged: (bool value) {
                    setState(() {
                      notfallKontaktBenachrichtigen = value;
                    });
                  },
                ),
                if (notfallKontaktBenachrichtigen && notfallKontaktEmailController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _sendEmergencyEmail();
                      },
                      icon: Icon(Icons.email),
                      label: Text('Test-Notfall-E-Mail senden'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _saveData(); // Verwende die neue Speichermethode
            },
            child: Text('Alle Daten speichern'),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class EinstellungenPage extends StatefulWidget {
  const EinstellungenPage({super.key});

  @override
  _EinstellungenPageState createState() => _EinstellungenPageState();
}

class _EinstellungenPageState extends State<EinstellungenPage> {
  bool _isDeleting = false;

  Future<void> _deleteAllData() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      await prefs.remove('vorname');
      await prefs.remove('nachname');
      await prefs.remove('geschlecht');
      await prefs.remove('istPrivatVersichert');
      await prefs.remove('krankenkasse');
      await prefs.remove('groesse');
      await prefs.remove('gewicht');
      await prefs.remove('blutgruppe');
      await prefs.remove('allergien');
      await prefs.remove('depression');
      await prefs.remove('angst');
      await prefs.remove('schlafprobleme');
      await prefs.remove('mentaleNotizen');
      
      // Notfallkontakt Daten löschen
      await prefs.remove('notfallKontaktName');
      await prefs.remove('notfallKontaktTelefon');
      await prefs.remove('notfallKontaktEmail');
      await prefs.remove('notfallKontaktBenachrichtigen');
      
      // Verlauf Einträge löschen
      await prefs.remove('verlauf_eintraege');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alle Daten wurden erfolgreich gelöscht')),
      );
    } catch (e) {
      print("Fehler beim Löschen der Daten: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Löschen der Daten')),
      );
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alle Daten löschen?'),
          content: Text(
            'Diese Aktion löscht alle deine persönlichen Daten, Notfallkontakte und den Verlauf. '
            '       Diese Aktion kann nicht rückgängig gemacht werden!',
            style: TextStyle(color: Colors.red[700]),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Löschen', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAllData();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Einstellungen', 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),
          
          // Datenschutz-Sektion
          Text('Datenschutz und Privatsphäre', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          
          // Button zum Löschen aller Daten
          ElevatedButton.icon(
            onPressed: _isDeleting ? null : _showDeleteConfirmationDialog,
            icon: Icon(Icons.delete_forever, color: Colors.white),
            label: _isDeleting 
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Wird gelöscht...'),
                  ],
                )
              : Text('Alle gespeicherten Daten löschen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Löscht alle persönlichen Daten, Notfallkontakte und Verlaufseinträge',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          
          Divider(height: 40),
          
          // Mehr Einstellungs-Optionen
          // ...
        ],
      ),
    );
  }
}
class HilfeBeschreiben extends StatefulWidget {
  const HilfeBeschreiben({super.key});

  @override
  _HilfeBeschreibenState createState() => _HilfeBeschreibenState();
}

class _HilfeBeschreibenState extends State<HilfeBeschreiben> {
  String selectedCategory = '';
  Map<String, List<String>> subOptions = {
    'Schmerzen': ['Kopfschmerzen', 'Bauchschmerzen', 'Brustschmerzen', 'Rückenschmerzen', 'Gelenkschmerzen'],
    'Verletzungen': ['Schnittwunde', 'Verbrennung', 'Knochenbruch', 'Prellung', 'Verstauchung'],
    'Atmung': ['Kurzatmigkeit', 'Atemnot', 'Husten', 'Pfeifen beim Atmen'],
    'Haut': ['Ausschlag', 'Schwellung', 'Rötung', 'Juckreiz'],
    'Verdauung': ['Übelkeit', 'Erbrechen', 'Durchfall', 'Verstopfung'],
    'Andere': ['Fieber', 'Schwindel', 'Bewusstlosigkeit', 'Allergische Reaktion']
  };
  
  String selectedSubOption = '';
  String beschreibung = '';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Problem beschreiben')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Wähle die Kategorie deines Problems:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: subOptions.keys.length,
                itemBuilder: (context, index) {
                  String category = subOptions.keys.elementAt(index);
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedCategory == category ? Colors.blue : Colors.grey.shade200,
                      foregroundColor: selectedCategory == category ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        selectedCategory = category;
                        selectedSubOption = '';
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getCategoryIcon(category)),
                        SizedBox(height: 8),
                        Text(category, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (selectedCategory.isNotEmpty) ...[
              SizedBox(height: 20),
              Text(
                'Wähle genauer aus:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: subOptions[selectedCategory]?.length ?? 0,
                  itemBuilder: (context, index) {
                    String option = subOptions[selectedCategory]![index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedSubOption == option ? Colors.blue : Colors.grey.shade200,
                          foregroundColor: selectedSubOption == option ? Colors.white : Colors.black,
                          minimumSize: Size(120, 100),
                        ),
                        onPressed: () {
                          setState(() {
                            selectedSubOption = option;
                          });
                        },
                        child: Text(option, textAlign: TextAlign.center),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (selectedSubOption.isNotEmpty) ...[
              SizedBox(height: 20),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Weitere Beschreibung (optional)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  beschreibung = value;
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {

                  String problem = '$selectedCategory: $selectedSubOption';
                  if (beschreibung.isNotEmpty) {
                    problem += ' - $beschreibung';
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Problem erfasst: $problem')),
                  );
                  
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => ErgebnisSeite(problem: problem),
                    )
                  );
                },
                child: Text('Hilfe anfordern', style: TextStyle(fontSize: 18)),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Schmerzen': return Icons.sick;
      case 'Verletzungen': return Icons.healing;
      case 'Atmung': return Icons.air;
      case 'Haut': return Icons.personal_injury;
      case 'Verdauung': return Icons.restaurant;
      case 'Andere': return Icons.help_outline;
      default: return Icons.help;
    }
  }
}

class ErgebnisSeite extends StatelessWidget {
  final String problem;
  
  const ErgebnisSeite({super.key, required this.problem});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ergebnis')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dein beschriebenes Problem:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(problem, style: TextStyle(fontSize: 16)),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Empfohlene Maßnahmen:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: _getRecommendations(problem),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Zurück zur Auswahl', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _getRecommendations(String problem) {
    if (problem.contains('Kopfschmerzen')) {
      return ListView(
        children: [
          _recommendationCard('Trinke ausreichend Wasser', Icons.water_drop),
          _recommendationCard('Ruhe dich in einem dunklen Raum aus', Icons.nightlight),
          _recommendationCard('Schmerzmittel (z.B. Ibuprofen) können helfen', Icons.medication),
          _recommendationCard('Bei anhaltenden Schmerzen: Arzt aufsuchen', Icons.local_hospital),
        ],
      );
    } else if (problem.contains('Verbrennung')) {
      return ListView(
        children: [
          _recommendationCard('Kühle die betroffene Stelle mit kaltem Waaser', Icons.water),
          _recommendationCard('Keine Salben auf frische Verbrennungen', Icons.do_not_disturb),
          _recommendationCard('Bei Blasenbildung oder größeren Flächen: Arzt aufsuchen', Icons.local_hospital),
        ],
      );
    }
    return ListView(
      children: [
        _recommendationCard('Bei anhaltenden Beschwerden suche einen Arzt auf', Icons.local_hospital),
        _recommendationCard('Achte auf ausreichende Flüssigkeitszufuhr', Icons.water_drop),
        _recommendationCard('Ruhe und Schonung können helfen', Icons.bed),
      ],
    );
  }
  
  Widget _recommendationCard(String text, IconData icon) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(text),
      ),
    );
  }
}

class SetupWizard extends StatefulWidget {
  const SetupWizard({super.key});

  @override
  _SetupWizardState createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 6; // Increased from 5 to 6
  
  // Nutzerdaten
  String vorname = '';
  String nachname = '';
  String geschlecht = "Anderes";
  bool istPrivatVersichert = false;
  String krankenkasse = 'Andere';
  String groesse = '';
  String gewicht = '';
  String blutgruppe = '';
  String allergien = '';
  bool depression = false;
  bool angst = false;
  bool schlafprobleme = false;
  String mentaleNotizen = '';
  bool berechtigungMikrofon = false;
  bool berechtigungStandort = false;
  bool berechtigungAnrufe = false;
  bool berechtigungBiometrie = false;
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  Future<void> _checkPermissions() async {
    final micStatus = await Permission.microphone.request();
    final locStatus = await Permission.location.request();
    final phoneStatus = await Permission.phone.request();
    
    setState(() {
      berechtigungMikrofon = micStatus.isGranted;
      berechtigungStandort = locStatus.isGranted;
      berechtigungAnrufe = phoneStatus.isGranted;
    });
  }
  
  Future<void> _finishSetup() async {

    final daten = Nutzerdaten(
      vorname: vorname,
      nachname: nachname,
      geschlecht: geschlecht,
      istPrivatVersichert: istPrivatVersichert,
      krankenkasse: krankenkasse,
      groesse: groesse,
      gewicht: gewicht,
      blutgruppe: blutgruppe,
      allergien: allergien,
      depression: depression,
      angst: angst,
      schlafprobleme: schlafprobleme,
      mentaleNotizen: mentaleNotizen,
    );
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('firstStart', false);
    
    

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomeWithBottomNav())
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Willkommen bei GerEA'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildWillkommensSeite(),
                _buildPersonlicheDatenSeite(),
                _buildGesundheitsDatenSeite(),
                _buildMentaleGesundheitSeite(),
                _buildNavigationsSeite(), // Add this new page
                _buildBerechtigungenSeite(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  ElevatedButton(
                    onPressed: _previousPage,
                    child: Text('Zurück'),
                  )
                else
                  SizedBox(width: 80),
                Text('${_currentPage + 1}/$_totalPages'),
                _currentPage < _totalPages - 1
                    ? ElevatedButton(
                        onPressed: _nextPage,
                        child: Text('Weiter'),
                      )
                    : ElevatedButton(
                        onPressed: _finishSetup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Text('Fertigstellen'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWillkommensSeite() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.health_and_safety, size: 80, color: Colors.blue),
          SizedBox(height: 20),
          Text(
            'Willkommen bei GerEA',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            'Dein persönlicher Gesundheitsassistent in Notfällen',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Was diese App macht',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '• Schnelle Hilfe bei medizinischen Problemen\n'
                    '• Direkter Zugang zu Notrufdiensten\n'
                    '• Persönliches Gesundheitsprofil für Notfälle\n'
                    '• Hilfestellung bei alltäglichen Gesundheitsfragen',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 30),
          Text(
            'In den nächsten Schritten sammeln wir wichtige Informationen, '
            'um dir im Notfall besser helfen zu können.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            'Deine Daten werden sicher auf deinem Gerät gespeichert.',
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPersonlicheDatenSeite() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Persönliche Daten',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Warum ist das wichtig?', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    'Im Notfall können diese Daten dem medizinischen Personal helfen, dich schnell zu identifizieren und die richtige Versorgung zu gewährleisten.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              labelText: 'Vorname',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              vorname = value;
            },
          ),
          SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'Nachname',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              nachname = value;
            },
          ),
          SizedBox(height: 16),
          Text('Geschlecht'),
          DropdownButton<String>(
            isExpanded: true,
            value: geschlecht,
            onChanged: (String? newValue) {
              setState(() {
                geschlecht = newValue!;
              });
            },
            items: ['Männlich', 'Weiblich', 'Anderes']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          SizedBox(height: 16),
          SwitchListTile(
            title: Text(istPrivatVersichert ? 'Privat versichert' : 'Gesetzlich versichert'),
            value: istPrivatVersichert,
            onChanged: (bool value) {
              setState(() {
                istPrivatVersichert = value;
              });
            },
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Wähle deine Krankenkasse',
              border: OutlineInputBorder(),
            ),
            value: krankenkasse,
            onChanged: (String? newValue) {
              setState(() {
                krankenkasse = newValue!;
              });
            },
            items: ['AOK', 'TK', 'Barmer', 'DAK', 'HKK', 'Privat', 'Andere']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGesundheitsDatenSeite() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gesundheitsdaten',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Warum ist das wichtig?', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    'Diese medizinischen Informationen können im Notfall lebensrettend sein. Beispielsweise ist die Blutgruppe bei Transfusionen wichtig, während Allergien Ärzten helfen, gefährliche Medikamente zu vermeiden.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Diese Informationen können im Notfall wichtig sein:',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Größe (cm)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              groesse = value;
            },
          ),
          SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'Gewicht (kg)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              gewicht = value;
            },
          ),
          SizedBox(height: 16),
          Text('Blutgruppe (falls bekannt)'),
          DropdownButton<String>(
            hint: Text('Bitte wählen'),
            isExpanded: true,
            value: blutgruppe.isEmpty ? null : blutgruppe,
            onChanged: (String? newValue) {
              setState(() {
                blutgruppe = newValue ?? '';
              });
            },
            items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unbekannt']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Allergien (durch Komma getrennt)',
              hintText: 'z.B. Nüsse, Penicillin, Gluten',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              allergien = value;
            },
            maxLines: 2,
          ),
          SizedBox(height: 16),
          Text(
            'Hinweis: Du kannst diese Informationen später in deinem Profil ändern.',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMentaleGesundheitSeite() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mentale Gesundheit',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Warum ist das wichtig?', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    'Die psychische Gesundheit ist genauso wichtig wie die körperliche. Diese Informationen helfen uns, dir angemessene Hilfe anzubieten und Rettungskräfte zu informieren, falls bestimmte psychische Bedingungen berücksichtigt werden sollten.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Diese Informationen sind für eine umfassende Betreuung wichtig und werden vertraulich behandelt.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 20),
          Text(
            'Leidest du unter einer der folgenden Beschwerden?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          CheckboxListTile(
            title: Text("Depressionen"),
            value: depression,
            onChanged: (val) {
              setState(() {
                depression = val ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: Text("Angstzustände"),
            value: angst,
            onChanged: (val) {
              setState(() {
                angst = val ?? false;
              });
            },
          ),
          CheckboxListTile(
            title: Text("Schlafprobleme"),
            value: schlafprobleme,
            onChanged: (val) {
              setState(() {
                schlafprobleme = val ?? false;
              });
            },
          ),
          SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Weitere Notizen zur mentalen Gesundheit',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              mentaleNotizen = value;
            },
            maxLines: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Hinweis: Du musst diese Fragen nicht beantworten, wenn du nicht möchtest.',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBerechtigungenSeite() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Berechtigungen',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Warum brauchen wir diese Berechtigungen?', 
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    'Diese Berechtigungen ermöglichen die Kernfunktionen der App. Ohne sie können wir dir im Notfall nicht optimal helfen. Alle Daten werden sicher und nur für den vorgesehenen Zweck verwendet.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Für die volle Funktionalität benötigt die App folgende Berechtigungen:',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 24),
          _permissionTile(
            title: 'Mikrofon',
            subtitle: 'Für die Spracheingabe deiner Beschwerden',
            granted: berechtigungMikrofon,
          ),
          _permissionTile(
            title: 'Standort',
            subtitle: 'Um im Notfall deinen Standort an Rettungskräfte übermitteln zu können',
            granted: berechtigungStandort,
          ),
          _permissionTile(
            title: 'Telefon',
            subtitle: 'Um im Notfall direkt Anrufe tätigen zu können',
            granted: berechtigungAnrufe,
          ),
          SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              icon: Icon(Icons.security),
              label: Text('Berechtigungen erteilen'),
              onPressed: _checkPermissions,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  'Du bist fast fertig!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Klicke unten auf "Fertigstellen", um zur App zu gelangen.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _permissionTile({required String title, required String subtitle, required bool granted}) {
    return ListTile(
      leading: Icon(
        granted ? Icons.check_circle : Icons.radio_button_unchecked,
        color: granted ? Colors.green : Colors.grey,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: granted 
        ? Icon(Icons.done, color: Colors.green)
        : Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
  
  Widget _buildNavigationsSeite() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Navigation',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'So verwendest du die GerEA App:',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          
          _navigationFeatureCard(
            icon: Icons.call,
            title: '112',
            description: 'Direkter Zugang zum Notruf mit deinem aktuellen Standort. Ein langer Druck auf den Notruf-Button wählt die Notrufnummer deiner aktuellen Region.'
          ),
          
          _navigationFeatureCard(
            icon: Icons.watch_later,
            title: 'Verlauf',
            description: 'Hier findest du alle deine bisherigen medizinischen Vorfälle und Notfälle chronologisch aufgelistet. Tippe auf einen Eintrag, um Details zu sehen.'
          ),
          
          _navigationFeatureCard(
            icon: Icons.home,
            title: 'Home',
            description: 'Die Hauptseite der App. Hier kannst du Gesundheitsprobleme entweder per Sprachaufnahme oder über das Auswahlmenü beschreiben und erhältst sofort Hilfestellungen.'
          ),
          
          _navigationFeatureCard(
            icon: Icons.person,
            title: 'Persönlich',
            description: 'Verwalte deine persönlichen und medizinischen Daten. Diese Informationen können im Notfall für Rettungskräfte äußerst wichtig sein.'
          ),
          
          _navigationFeatureCard(
            icon: Icons.settings,
            title: 'Einstellungen',
            description: 'Hier kannst du die App nach deinen Wünschen konfigurieren, Berechtigungen verwalten und Hilfe erhalten.'
          ),
          
          SizedBox(height: 20),
          Center(
            child: Text(
              'Du kannst jederzeit zwischen diesen Seiten wechseln, indem du die entsprechenden Icons in der unteren Navigationsleiste antippst.',
              style: TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _navigationFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: Colors.blue),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}