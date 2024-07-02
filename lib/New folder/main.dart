import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'details_page.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Door Lock Report',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF005fa8),
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Color(0xFF005fa8),
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      home: const LoginPage(),
      routes: {
        '/home': (context) => const MyHomePage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final DatabaseReference databaseReference =
      FirebaseDatabase.instance.ref().child('Access_Log');
  List<Map<String, dynamic>> dataList = [];
  List<Map<String, dynamic>> filteredDataList = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      filterData();
    });
  }

  void filterData() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredDataList = dataList.where((item) {
        final name = item['name']?.toLowerCase() ?? '';
        final timeDetected = item['time_detected']?.toLowerCase() ?? '';
        return name.contains(query) || timeDetected.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Door Lock Report'),
        actions: [
          const CircleAvatar(
            backgroundImage: NetworkImage('https://via.placeholder.com/150'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.black),
                    suffixIcon:
                        const Icon(Icons.filter_list, color: Colors.black),
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: const [
                    SizedBox(
                        width: 60,
                        child: Text('Time',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black))),
                    Expanded(
                        flex: 3,
                        child: Text('Event',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black))),
                    Expanded(flex: 1, child: SizedBox()),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: databaseReference.onValue,
                  builder: (BuildContext context,
                      AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red)));
                    } else if (!snapshot.hasData ||
                        snapshot.data?.snapshot.value == null) {
                      return const Center(
                          child: Text('No Data Available',
                              style: TextStyle(color: Colors.black)));
                    } else {
                      dynamic data = snapshot.data!.snapshot.value;
                      if (data is Map<dynamic, dynamic>) {
                        dataList = data.entries.map((entry) {
                          dynamic log = entry.value;
                          if (log is Map<dynamic, dynamic>) {
                            return {
                              'name': log['name'] ?? 'Unknown',
                              'time_detected':
                                  log['time_detected'] ?? 'Unknown',
                            };
                          } else {
                            return {
                              'name': 'Unknown',
                              'time_detected': 'Unknown',
                            };
                          }
                        }).toList();

                        dataList.sort((a, b) {
                          DateFormat format = DateFormat("yyyy-MM-dd HH:mm:ss");
                          DateTime aDate = format.parse(a['time_detected']);
                          DateTime bDate = format.parse(b['time_detected']);
                          return bDate.compareTo(aDate);
                        });

                        filterData();

                        return ListView.builder(
                          itemCount: filteredDataList.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                          width: 60,
                                          child: Text(
                                              DateFormat('HH:mm').format(
                                                  DateFormat(
                                                          "yyyy-MM-dd HH:mm:ss")
                                                      .parse(filteredDataList[
                                                              index]
                                                          ['time_detected'])),
                                              style: const TextStyle(
                                                  color: Colors.black))),
                                      Expanded(
                                          flex: 3,
                                          child: Text(
                                              filteredDataList[index]['name'],
                                              style: const TextStyle(
                                                  color: Colors.black))),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DetailsPage(
                                                  data:
                                                      filteredDataList[index]),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF005fa8),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text('Details',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Colors.black),
                                ],
                              ),
                            );
                          },
                        );
                      } else {
                        return const Center(
                            child: Text('Unexpected data format',
                                style: TextStyle(color: Colors.black)));
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
