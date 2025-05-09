import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GerEA',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeWithBottomNav(),
    );
  }
}

class HomeWithBottomNav extends StatefulWidget {
  @override
  _HomeWithBottomNavState createState() => _HomeWithBottomNavState();
}

class VerlaufPage extends StatelessWidget {
  final List<Map<String, String>> eintraege = [
    {"datum": "12. Mai", "beschreibung": "Severe pain in stomach"},
    {"datum": "6. Mai", "beschreibung": "Cut in finger"},
    {"datum": "4. April", "beschreibung": "Pain while eating"},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: eintraege.length,
            itemBuilder: (context, index) {
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(eintraege[index]["datum"]!),
                  subtitle: Text(eintraege[index]["beschreibung"]!),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HomeWithBottomNavState extends State<HomeWithBottomNav> {
  int _selectedIndex = 2;
  String _permissionStatus = 'Unbekannt';

  Future<void> _checkPermissions() async {
    final micStatus = await Permission.microphone.request();
    final locStatus = await Permission.location.request();

    setState(() {
      if (micStatus.isGranted && locStatus.isGranted) {
        _permissionStatus = '✅ Mikrofon & Standort erlaubt';
      } else {
        _permissionStatus = '❌ Nicht alle Berechtigungen erlaubt';
      }
    });
  }

  List<Widget> get _pages => <Widget>[
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: _checkPermissions,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                textStyle: TextStyle(fontSize: 24),
              ),
              child: Text('Notruf jetzt absetzen'),
            ),
            SizedBox(height: 20),
            Text(
              _permissionStatus,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        VerlaufPage(),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                print('Großer Knopf wurde gedrückt!');
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                textStyle: TextStyle(fontSize: 24),
              ),
              child: Text('Jetzt Problem beschreiben'),
            ),
          ],
        ),
        Center(child: Text('Präferenzen', style: TextStyle(fontSize: 24))),
        Center(child: Text('Einstellungen', style: TextStyle(fontSize: 24))),
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
        title: Text('Guten Tag!'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
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
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.call), label: '112'),
          BottomNavigationBarItem(icon: Icon(Icons.watch_later), label: 'Verlauf'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Einstellungen'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}