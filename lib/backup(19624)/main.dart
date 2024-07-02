import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // Library untuk memformat tanggal
import 'details_page.dart'; // Import halaman detail

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
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
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
            child: Row(
              children: const [
                SizedBox(
                    width: 60,
                    child: Text('Time',
                        style: TextStyle(
                            fontWeight: FontWeight
                                .bold))), // Menetapkan lebar tetap untuk kolom Time
                Expanded(
                    flex: 3,
                    child: Text('Event',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: SizedBox()), // For the Details button
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
                          'name': log['name'] ?? 'Unknown',
                          'time_detected': log['time_detected'] ?? 'Unknown',
                        };
                      } else {
                        return {
                          'name': 'Unknown',
                          'time_detected': 'Unknown',
                        };
                      }
                    }).toList();

                    // Mengurutkan data berdasarkan 'time_detected' dan membalik urutannya
                    dataList.sort((a, b) {
                      DateFormat format = DateFormat("yyyy-MM-dd HH:mm:ss");
                      DateTime dateA = format.parse(a['time_detected']);
                      DateTime dateB = format.parse(b['time_detected']);
                      return dateB.compareTo(dateA); // Balik urutannya
                    });

                    filteredDataList = dataList.where((item) {
                      final name = item['name']?.toLowerCase() ?? '';
                      final timeDetected =
                          item['time_detected']?.toLowerCase() ?? '';
                      final query = searchController.text.toLowerCase();
                      return name.contains(query) ||
                          timeDetected.contains(query);
                    }).toList();

                    return ListView.builder(
                      itemCount: filteredDataList.length,
                      itemBuilder: (context, index) {
                        String time = filteredDataList[index]['time_detected'];
                        DateTime dateTime =
                            DateFormat("yyyy-MM-dd HH:mm:ss").parse(time);
                        String formattedTime =
                            DateFormat("HH:mm").format(dateTime);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          child: ListTile(
                            title: Row(
                              children: [
                                SizedBox(
                                  width:
                                      60, // Menetapkan lebar tetap untuk waktu
                                  child: Text(
                                      formattedTime), // Menampilkan jam dan menit
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(filteredDataList[index]['name'] ??
                                      'No Name'),
                                ),
                                Expanded(
                                  flex: 1,
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
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                    child: const Text('Details'),
                                  ),
                                ),
                              ],
                            ),
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
