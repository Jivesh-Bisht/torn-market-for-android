import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Torn Item Calculator',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          elevation: 4,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      home: const ItemListPage(),
    );
  }
}

class ItemListPage extends StatefulWidget {
  const ItemListPage({super.key});

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  final formatter = NumberFormat('#,###');

  String formatPrice(double value) {
    return formatter.format(value.round());
  }

  final Map<String, String> items = {
    'Bunch of Flowers': '97',
    'Dozen Roses': '129',
    'Single Red Rose': '183',
    'Bunch of Black Roses': '184',
    'Sheep Plushie': '186',
    'Teddy Bear Plushie': '187',
    'Kitten Plushie': '215',
    'Jaguar Plushie': '258',
    'Dahlia': '260',
    'Wolverine Plushie': '261',
    'Crocus': '263',
    'Orchid': '264',
    'Nessie Plushie': '266',
    'Heather': '267',
    'Red Fox Plushie': '268',
    'Monkey Plushie': '269',
    'Ceibo Flower': '271',
    'Edelweiss': '272',
    'Chamois Plushie': '273',
    'Panda Plushie': '274',
    'Peony': '276',
    'Cherry Blossom': '277',
    'Lion Plushie': '281',
    'African Violet': '282',
    'Camel Plushie': '384',
    'Tribulus Omanense': '385',
    'Banana Orchid': '617',
    'Stingray Plushie': '618',
    'Daffodil': '901',
    'Bunch of Carnations': '902',
    'White Lily': '903',
    'Funeral Wreath': '904'
  };

  final Map<String, double> avgPrices = {};
  final Map<String, int> quantities = {};
  bool loading = true;
  Timer? priceRefreshTimer;

  @override
  void initState() {
    super.initState();
    fetchAllPrices();
    priceRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      fetchAllPrices();
    });
  }

  @override
  void dispose() {
    priceRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchAllPrices() async {
    setState(() {
      loading = true;
    });
    for (var entry in items.entries) {
      final price = await fetchPrice(entry.value);
      avgPrices[entry.key] = price;
    }
    setState(() {
      loading = false;
    });
  }

  Future<double> fetchPrice(String id) async {
    final url = Uri.parse(
        "https://api.torn.com/v2/market/$id/itemmarket?key=VxpLRizVKf8YMCXA");
    final response = await http.get(url);
    final data = json.decode(response.body);
    return (data["itemmarket"]["item"]["average_price"] ?? 0).toDouble();
  }

  double get totalAmount {
    double total = 0;
    for (var item in items.keys) {
      int qty = quantities[item] ?? 0;
      double price = avgPrices[item] ?? 0;
      total += qty * price;
    }
    return total;
  }

  double get totalPayable => totalAmount * 0.98;

  int get cartItemCount {
    return quantities.entries.where((e) => e.value > 0).length;
  }

  void showCart() {
    final cartItems = quantities.entries
        .where((e) => e.value > 0)
        .map((e) => {
              'name': e.key,
              'amount': e.value,
            })
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white.withAlpha(242), // Fixed: Replaced withOpacity with withAlpha
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Shopping Cart",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const Divider(),
              if (cartItems.isEmpty)
                const Text("Cart is empty", style: TextStyle(fontSize: 16)),
              if (cartItems.isNotEmpty)
                ...cartItems.map<Widget>((item) => ListTile(
                      title: Text(item['name'] as String),
                      trailing: Text("x${item['amount']}"),
                    )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.teal, Colors.green]),
              ),
              child: Text(
                "Menu",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.teal),
              title: const Text("Refresh Prices Now"),
              onTap: () {
                Navigator.pop(context);
                fetchAllPrices();
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("Torn Item Calculator"),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: showCart,
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      "$cartItemCount",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      String name = items.keys.elementAt(index);
                      double price = avgPrices[name] ?? 0;
                      return Container(
  margin: const EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.9),
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 90,
              child: TextField(
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Qty",
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.5), // transparent feel
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  border: InputBorder.none, // no border
                ),
                onChanged: (val) {
                  setState(() {
                    quantities[name] = int.tryParse(val) ?? 0;
                  });
                },
              ),
            ),
            Text(
              "Avg Price: ${formatPrice(price)}",
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87),
            ),
          ],
        ),
      ],
    ),
  ),
);

                    },
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total Amount: ${formatPrice(totalAmount)}",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal)),
                      Text("Total Payable: ${formatPrice(totalPayable)}",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}