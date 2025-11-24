import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String? _error;

  int vendorCount = 0;
  int warehouseCount = 0;
  int productsCount = 0;
  int customersCount = 0;
  double totalSales = 0;
  double totalStockValue = 0;

  // sales data from API
  List<Map<String, dynamic>> dailySales = [];
  List<Map<String, dynamic>> monthlySales = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getVendors(),
        ApiService.getWarehouses(),
        ApiService.getProducts(),
        ApiService.getCustomers(),
        ApiService.getSalesSummary(),
      ]);

      final vendors = results[0];
      final warehouses = results[1];
      final products = results[2];
      final customers = results[3];
      final sales = results[4];

      setState(() {
        vendorCount = vendors.length;
        warehouseCount = warehouses.length;
        productsCount = products.length;
        customersCount = customers.length;

        // compute stock value from products if fields exist
        double stockVal = 0;
        for (var p in products) {
          final purchasePrice = (p['purchasePrice'] ?? p['PurchasePrice'] ?? 0);
          final qty = (p['quantityInStock'] ?? p['QuantityInStock'] ?? p['quantity'] ?? 0);
          final a = _toDouble(purchasePrice);
          final b = _toDouble(qty);
          stockVal += a * b;
        }
        totalStockValue = stockVal;

        // sales: expect array of objects with saleDate and totalSalesAmount
        if (sales is List) {
          dailySales = sales.map<Map<String, dynamic>>((s) {
            final dateRaw = s['saleDate'] ?? s['SaleDate'] ?? s['date'] ?? s['Date'];
            DateTime? dt;
            if (dateRaw != null) {
              try {
                dt = DateTime.parse(dateRaw.toString());
              } catch (_) {
                // fallback
                dt = DateTime.tryParse(dateRaw.toString()) ?? DateTime.now();
              }
            } else {
              dt = DateTime.now();
            }
            final amt = _toDouble(s['totalSalesAmount'] ?? s['TotalSalesAmount'] ?? s['amount'] ?? 0);
            return {'date': dt!, 'amount': amt};
          }).toList();

          // compute totalSales (sum)
          totalSales = dailySales.fold(0.0, (p, e) => p + (e['amount'] as double));

          // compute monthly aggregation
          final Map<String, double> monthly = SplayTreeMap(); // sorted map
          for (var item in dailySales) {
            final DateTime d = item['date'];
            final key = '${_monthLabel(d)} ${d.year}';
            monthly[key] = (monthly[key] ?? 0) + (item['amount'] as double);
          }
          monthlySales = monthly.entries
              .map((e) => {'month': e.key, 'total': e.value})
              .toList();
        } else {
          dailySales = [];
          monthlySales = [];
        }
      });
    } catch (ex, st) {
      setState(() {
        _error = ex.toString();
        // keep loading false
      });
      debugPrint('API error: $ex\n$st');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    final s = v.toString();
    return double.tryParse(s.replaceAll(',', '')) ?? 0.0;
  }

  String _monthLabel(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[d.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📊 Dashboard Overview', style: GoogleFonts.poppins()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      drawer: _buildDrawer(context),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 12),
          Text('Failed to load data', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(_error ?? '', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadAllData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI rows
            Wrap(spacing: 10, runSpacing: 10, children: [
              _kpiCard(icon: FontAwesomeIcons.users, label: 'Vendors', value: vendorCount.toString()),
              _kpiCard(icon: FontAwesomeIcons.warehouse, label: 'Warehouses', value: warehouseCount.toString()),
              _kpiCard(icon: FontAwesomeIcons.box, label: 'Products', value: productsCount.toString()),
              _kpiCard(icon: FontAwesomeIcons.userPlus, label: 'Customers', value: customersCount.toString()),
              _kpiCard(icon: FontAwesomeIcons.moneyBillWave, label: 'Total Sales', value: 'Rs ${totalSales.toInt()}'),
              _kpiCard(icon: FontAwesomeIcons.coins, label: 'Stock Value', value: 'Rs ${totalStockValue.toInt()}'),
            ]),

            const SizedBox(height: 18),

            // Entity Overview (bar)
            _sectionTitle('Entity Overview'),
            SizedBox(height: 220, child: _entityBarChart()),

            const SizedBox(height: 12),

            // Entity Ratio (pie)
            _sectionTitle('Entity Ratio'),
            SizedBox(height: 220, child: _entityPieChart()),

            const SizedBox(height: 12),

            // Monthly Sales
            _sectionTitle('Monthly Sales'),
            SizedBox(height: 240, child: _monthlyBarChart()),

            const SizedBox(height: 12),

            // Daily Sales (line)
            _sectionTitle('Daily Sales'),
            SizedBox(height: 220, child: _dailyLineChart()),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard({required IconData icon, required String label, required String value}) {
    final double w = (MediaQuery.of(context).size.width - 48) / 2;
    return Container(
      width: w < 160 ? MediaQuery.of(context).size.width - 24 : w,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.teal.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.teal, size: 20),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
        ])
      ]),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  // ---------------- Charts ----------------

  Widget _entityBarChart() {
    final values = [vendorCount.toDouble(), warehouseCount.toDouble(), productsCount.toDouble(), customersCount.toDouble()];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: BarChart(
        BarChartData(
          maxY: (values.reduce((a,b) => a>b?a:b) + 5).toDouble(),
          barGroups: List.generate(values.length, (i) => BarChartGroupData(x: i, barRods: [
            BarChartRodData(toY: values[i], color: _colorForIndex(i), width: 18, borderRadius: BorderRadius.circular(6))
          ])),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double val, _) {
                  const labels = ['Vendors','Warehouses','Products','Customers'];
                  final idx = val.toInt();
                  if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                  return SideTitleWidget(child: Text(labels[idx], style: GoogleFonts.poppins(fontSize: 11)), axisSide: AxisSide.bottom);
                }
            )),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _entityPieChart() {
    final sections = [
      PieChartSectionData(value: vendorCount.toDouble(), color: const Color(0xFF0dcaf0), title: vendorCount.toString(), radius: 50, titleStyle: GoogleFonts.poppins(color: Colors.white)),
      PieChartSectionData(value: warehouseCount.toDouble(), color: const Color(0xFFffc107), title: warehouseCount.toString(), radius: 45, titleStyle: GoogleFonts.poppins(color: Colors.white)),
      PieChartSectionData(value: productsCount.toDouble(), color: const Color(0xFF20c997), title: productsCount.toString(), radius: 50, titleStyle: GoogleFonts.poppins(color: Colors.white)),
      PieChartSectionData(value: customersCount.toDouble(), color: const Color(0xFF6610f2), title: customersCount.toString(), radius: 40, titleStyle: GoogleFonts.poppins(color: Colors.white)),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 30)),
    );
  }

  Widget _monthlyBarChart() {
    final labels = monthlySales.map((m) => m['month'].toString()).toList();
    final values = monthlySales.map((m) => _toDouble(m['total'])).toList();
    final max = values.isEmpty ? 10.0 : (values.reduce((a,b) => a>b?a:b) * 1.2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: BarChart(
        BarChartData(
          maxY: max,
          barGroups: List.generate(values.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: values[i], color: Colors.teal, width: 14, borderRadius: BorderRadius.circular(6))])),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: labels.length <= 8,
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx < 0 || idx >= labels.length) return const SizedBox();
                return SideTitleWidget(child: Text(labels[idx], style: GoogleFonts.poppins(fontSize: 10)), axisSide: AxisSide.bottom);
              },
            )),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _dailyLineChart() {
    // show last up-to 12 points
    final points = dailySales;
    final lastN = points.length > 20 ? 20 : points.length;
    final slice = points.sublist(points.length - lastN, points.length);
    final spots = List.generate(slice.length, (i) => FlSpot(i.toDouble(), _toDouble(slice[i]['amount'])));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: LineChart(LineChartData(
        minY: 0,
        lineBarsData: [
          LineChartBarData(isCurved: true, spots: spots, color: Colors.green, belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.18)), dotData: FlDotData(show: false), barWidth: 2.5,)
        ],
        titlesData: FlTitlesData(leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      )),
    );
  }

  Color _colorForIndex(int i) {
    const cols = [Color(0xFF0dcaf0), Color(0xFFffc107), Color(0xFF20c997), Color(0xFF6610f2)];
    return cols[i % cols.length];
  }

  // ---------------- Drawer ----------------
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.dashboard, color: Colors.white)),
              title: Text('MyERP', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              subtitle: Text('Admin', style: GoogleFonts.poppins(fontSize: 12)),
            ),
            const Divider(),
            ListTile(leading: const Icon(Icons.people), title: const Text('Vendors'), onTap: () => _navigatePlaceholder('Vendors')),
            ListTile(leading: const Icon(Icons.shopping_cart), title: const Text('Purchases'), onTap: () => _navigatePlaceholder('Purchases')),
            ListTile(leading: const Icon(Icons.inventory_2), title: const Text('Products'), onTap: () => _navigatePlaceholder('Products')),
            ListTile(leading: const Icon(Icons.warehouse), title: const Text('Warehouses'), onTap: () => _navigatePlaceholder('Warehouses')),
            ListTile(leading: const Icon(Icons.bar_chart), title: const Text('Sales Summary'), onTap: () => _navigatePlaceholder('Sales Summary')),
            const Spacer(),
            const Divider(),
            ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () {
              // implement logout flow if needed
              Navigator.of(context).pop();
            }),
            const SizedBox(height: 12)
          ],
        ),
      ),
    );
  }

  void _navigatePlaceholder(String name) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navigate to $name (implement)')));
  }
}
