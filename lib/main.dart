// Hauptimport
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:local_auth/local_auth.dart';

void main() {
  runApp(MyApp());
  
}

class MySecureApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _authenticate(); // beim Start authentifizieren
  }

  Future<void> _authenticate() async {
    try {
      bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Bitte mit Fingerabdruck oder Gesicht entsperren',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        setState(() {
          _isAuthenticated = true;
        });
      }
    } catch (e) {
      print("Fehler bei authentifizierung: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return MyApp(); 
    } else {
      return Scaffold(
        body: Center(child: Text('Authentifizierung erforderlich...')),
      );
    }
  }
}



class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GerEA',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeWithBottomNav(),
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
  @override
  _NotrufPageState createState() => _NotrufPageState();
}

class _NotrufPageState extends State<NotrufPage> {
  String _permissionStatus = 'Unbekannt';

  Future<void> _checkPermissions() async {
    final micStatus = await Permission.microphone.request();
    final locStatus = await Permission.location.request();

    setState(() {
      _permissionStatus = (micStatus.isGranted && locStatus.isGranted)
          ? '✅ Mikrofon & Standort erlaubt'
          : '❌ Nicht alle Berechtigungen erlaubt';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 50),
        ElevatedButton(
          onPressed:  _checkPermissions , onLongPress: () => FlutterPhoneDirectCaller.callNumber('1111112121'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            textStyle: TextStyle(fontSize: 24, color: Colors.black),
            backgroundColor: Colors.red,
            
          ),
          child: Text('Notruf jetzt absetzen', style: TextStyle(color: Colors.black)),
        ),
        SizedBox(height: 20),
        Text("Solltest/sollten gerade du oder andere Menschen in Lebensgafahr sein, rufe sofort den Notdienst! Es zählt jede Sekunde!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
                // Hier könnte eine Löschfunktion implementiert werden
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

// HOMEPAGE mit Sprachfunktion + Navigationsbutton
class HomePage extends StatefulWidget {
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
        print("🚫 Sprachdienst nicht verfügbar");
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
                child: Text('Du hast gesagt: ' + _spokenText),
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
            child: Text('Problem beschreiben via Auswahlmenu'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              textStyle: TextStyle(fontSize: 24),
              backgroundColor: Colors.red
            ),
          ),
        ),
      ]
    );
  }}




class PersoenlichesPage extends StatefulWidget {
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
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Einstellungen', style: TextStyle(fontSize: 24)),
    );
  }
}
class HilfeBeschreiben extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tippe auf das Nachligendste')),
      body: Center(
        child: Text('Willkommen auf der neuen Seite!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
