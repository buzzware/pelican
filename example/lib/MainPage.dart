import 'package:flutter/material.dart';

import 'PageOne.dart';
import 'PageTwo.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Navigation Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('One'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PageOne()),
                );
              },
            ),
            ListTile(
              title: const Text('Two'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PageTwo()),
                );
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          'Welcome to Main Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
