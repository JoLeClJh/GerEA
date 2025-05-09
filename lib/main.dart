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

  // Die drei Seiteninhalte
  static const List<Widget> _pages = <Widget>[
    Center(child: Text('Notfall!', style: TextStyle(fontSize: 24))),
    Center(child: Text('Verlauf', style: TextStyle(fontSize: 24))),
    Center(child: Text('Was ist das Problem?', style: TextStyle(fontSize: 24))),
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
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.call), label: '112'),
          BottomNavigationBarItem(icon: Icon(Icons.watch_later), label: 'Verlauf'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Präferenzen'),
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
