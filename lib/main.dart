import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'details_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            title: 'Smart Door Lock Report',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: const MyHomePage(),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        return const Center(child: CircularProgressIndicator());
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
      FirebaseDatabase.instance.ref().child('Event_Log');
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
        final name = item['details']['name']?.toLowerCase() ?? '';
        final timeDetected = item['time_detected']?.toLowerCase() ?? '';
        final additionalInfo =
            item['details']['additional_info']?.toLowerCase() ?? '';
        return name.contains(query) ||
            timeDetected.contains(query) ||
            additionalInfo.contains(query);
      }).toList();
    });
  }

  DateTime parseDateTime(String dateTimeString) {
    List<String> formats = [
      "yyyy-MM-dd HH:mm:ss",
      "yyyy-MM-ddTHH:mm:ss",
      "yyyy-MM-ddTHH:mm:ss.SSSSSS",
      "yyyy-MM-ddTHH:mm:ssZ",
      "yyyy-MM-ddTHH:mm:ss.SSSZ",
      "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    ];
    for (var format in formats) {
      try {
        return DateFormat(format).parse(dateTimeString);
      } catch (e) {
        // Catch and ignore the error to try the next format
      }
    }
    // Fallback to DateTime.parse
    return DateTime.parse(dateTimeString);
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.filter_list),
                hintText: 'Search',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(60),
                1: FlexColumnWidth(),
                2: FixedColumnWidth(80),
              },
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Time',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Event',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(), // Empty cell for alignment with Details button
                  ],
                ),
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
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData ||
                    snapshot.data?.snapshot.value == null) {
                  return const Center(child: Text('No Data Available'));
                } else {
                  dynamic data = snapshot.data!.snapshot.value;
                  if (data is Map<dynamic, dynamic>) {
                    dataList = data.entries.map((entry) {
                      dynamic log = entry.value;
                      if (log is Map<dynamic, dynamic>) {
                        return {
                          'event_type': log['event_type'] ?? 'Unknown',
                          'time_detected': log['time_detected'] ?? 'Unknown',
                          'details': log['details'] ??
                              {'name': 'Unknown', 'additional_info': 'Unknown'},
                        };
                      } else {
                        return {
                          'event_type': 'Unknown',
                          'time_detected': 'Unknown',
                          'details': {
                            'name': 'Unknown',
                            'additional_info': 'Unknown'
                          },
                        };
                      }
                    }).toList();

                    dataList.sort((a, b) {
                      DateTime dateA = parseDateTime(a['time_detected']);
                      DateTime dateB = parseDateTime(b['time_detected']);
                      return dateB.compareTo(dateA);
                    });

                    filteredDataList = dataList.where((item) {
                      final name = item['details']['name']?.toLowerCase() ?? '';
                      final timeDetected =
                          item['time_detected']?.toLowerCase() ?? '';
                      final additionalInfo =
                          item['details']['additional_info']?.toLowerCase() ??
                              '';
                      final query = searchController.text.toLowerCase();
                      return name.contains(query) ||
                          timeDetected.contains(query) ||
                          additionalInfo.contains(query);
                    }).toList();

                    return ListView.builder(
                      itemCount: filteredDataList.length,
                      itemBuilder: (context, index) {
                        String time = filteredDataList[index]['time_detected'];
                        DateTime dateTime = parseDateTime(time);
                        String formattedTime =
                            DateFormat("HH:mm").format(dateTime);
                        String name = filteredDataList[index]['details']
                                ['name'] ??
                            'Unknown';
                        String eventType =
                            filteredDataList[index]['event_type'] ?? 'Unknown';
                        String additionalInfo = filteredDataList[index]
                                ['details']['additional_info'] ??
                            'No Description';
                        String eventDescription = eventType == 'ACCESS_GRANTED'
                            ? '$name $additionalInfo'
                            : additionalInfo;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 16.0),
                          child: Table(
                            columnWidths: const {
                              0: FixedColumnWidth(60),
                              1: FlexColumnWidth(),
                              2: FixedColumnWidth(80),
                            },
                            children: [
                              TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(formattedTime),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(eventDescription),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DetailsPage(
                                                data: filteredDataList[index]),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 8),
                                        textStyle:
                                            const TextStyle(fontSize: 12),
                                      ),
                                      child: const Text('Details'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(child: Text('Unexpected data format'));
                  }
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Tab 1'),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Tab 2'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Tab 3'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Tab 4'),
        ],
        currentIndex: 0,
        onTap: (index) {
          // Handle tab change
        },
      ),
    );
  }
}
