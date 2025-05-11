import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:local_auth/local_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SharedPreferences prefs = await SharedPreferences.getInstance();
  //bool firstStart = prefs.getBool('firstStart') ?? true;
  bool firstStart = true;
  
  runApp(MyApp(firstStart: firstStart));
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

// Datenklasse
class Nutzerdaten {
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
          Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Always call 112 when life is in danger!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
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
        selectedItemColor: Colors.blue,
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
              await FlutterPhoneDirectCaller.callNumber(_notrufnummer + "788");
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
        SizedBox(height: 20),
        Text(
          _permissionStatus,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// Verlaufsseite
class VerlaufPage extends StatelessWidget {
  final List<Map<String, String>> eintraege = [
    {"datum": "12. Mai", "beschreibung": "Severe pain in stomach"},
    {"datum": "6. Mai", "beschreibung": "Cut in finger"},
    {"datum": "4. April", "beschreibung": "Pain while eating"},
  ];

  VerlaufPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: eintraege.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text(eintraege[index]["datum"]!),
            subtitle: Text(eintraege[index]["beschreibung"]!),
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Eintrag Details'),
                content: Text('Details zu ${eintraege[index]["beschreibung"]} am ${eintraege[index]["datum"]}'),
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
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Eintrag gelöscht')),
                );
              },
            ),
          ),
        );
      },
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
        onStatus: (status) => print('Status: \$status'),
        onError: (errorNotification) => print('Fehler: \$errorNotification'),
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
                textStyle: TextStyle(fontSize: 24),
              ),
              child: Text(_isListening ? 'Stoppe Aufnahme' : 'Jetzt Problem beschreiben'),
            ),
            if (_spokenText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Du hast gesagt: $_spokenText'),
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
              textStyle: TextStyle(fontSize: 24),
              backgroundColor: Colors.red
            ),
            child: Text('Problem beschreiben via Auswahlmenu'),
          ),
        ),
      ]
    );
  }}




class PersoenlichesPage extends StatefulWidget {
  const PersoenlichesPage({super.key});

  @override
  _PersoenlichesPageState createState() => _PersoenlichesPageState();
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

  final TextEditingController vornameController = TextEditingController();
  final TextEditingController nachnameController = TextEditingController();
  final TextEditingController groesseController = TextEditingController();
  final TextEditingController gewichtController = TextEditingController();
  final TextEditingController blutgruppeController = TextEditingController();
  final TextEditingController allergienController = TextEditingController();
  final TextEditingController mentaleNotizenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _authenticate();
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
          ElevatedButton(
            onPressed: () {
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
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Daten gespeichert')),
              );
              print("Gespeichert: ${daten.vorname}, Mentale Notiz: ${daten.mentaleNotizen}");
            },
            child: Text('Speichern'),
          ),
        ],
      ),
    );
  }
}


class EinstellungenPage extends StatelessWidget {
  const EinstellungenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Einstellungen', style: TextStyle(fontSize: 24)),
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
          _recommendationCard('Kühle die betroffene Stelle mit kaltem Wasser', Icons.water),
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