// lib/screens/bus_list_page.dart

import 'package:amman_tms_mobile/core/services/fleet_service.dart';
import 'package:amman_tms_mobile/models/bus_model.dart';
import 'package:amman_tms_mobile/widgets/bus_card_widget.dart';
import 'package:flutter/material.dart';
// Ganti dengan widget BusCard yang sudah dibuat sebelumnya

class BusListPage extends StatefulWidget {
  const BusListPage({super.key});

  @override
  State<BusListPage> createState() => _BusListPageState();
}

class _BusListPageState extends State<BusListPage> {
  // Gunakan Future untuk menampung hasil pemanggilan API
  late Future<List<Bus>> _busFuture;

  // State untuk menyimpan daftar bus asli dan yang sudah difilter
  List<Bus> _allBuses = [];
  List<Bus> _filteredBuses = [];

  // State untuk filter dan pencarian
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  List<String> _statusOptions = ['All'];

  @override
  void initState() {
    super.initState();
    // Memulai pemanggilan API saat halaman pertama kali dibuka
    _loadData();
    _searchController.addListener(_filterBuses);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterBuses);
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi untuk memanggil API dan memproses hasilnya
  Future<void> _loadData() async {
    setState(() {
      _busFuture = _fetchAndProcessBuses();
    });
  }

  Future<List<Bus>> _fetchAndProcessBuses() async {
    try {
      final response = await FleetService()
          .getFleetsWithPagination(); // Ambil lebih banyak data untuk demo
      final List<dynamic> busData = response['data'];
      final List<Bus> buses = busData
          .map((item) => Bus.fromJson(item))
          .toList();

      // Update state untuk filter setelah data berhasil didapat
      setState(() {
        _allBuses = buses;
        _filteredBuses = buses;
        _statusOptions = ['All', ...buses.map((b) => b.status).toSet()];
        _filterBuses(); // Terapkan filter awal
      });

      return buses;
    } catch (e) {
      // Jika terjadi error, lempar kembali agar bisa ditangani FutureBuilder
      throw Exception(e.toString());
    }
  }

  void _filterBuses() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBuses = _allBuses.where((bus) {
        final statusMatch =
            _selectedStatus == 'All' || bus.status == _selectedStatus;
        final queryMatch =
            query.isEmpty ||
            bus.licensePlate.toLowerCase().contains(query) ||
            bus.driver.toLowerCase().contains(query);
        return statusMatch && queryMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Armada Bus',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: FutureBuilder<List<Bus>>(
              future: _busFuture,
              builder: (context, snapshot) {
                // Menampilkan indikator loading saat data diambil
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Menampilkan pesan error jika terjadi masalah
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                // Jika data kosong
                if (_filteredBuses.isEmpty) {
                  return const Center(
                    child: Text(
                      'Bus tidak ditemukan.',
                      style: TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                    ),
                  );
                }

                // Menampilkan daftar bus jika data berhasil dimuat
                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _filteredBuses.length,
                    itemBuilder: (context, index) {
                      final bus = _filteredBuses[index];
                      // Ganti dengan widget BusCard Anda
                      return BusCard(bus: bus);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk search bar (tidak berubah)
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari plat nomor atau pengemudi...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  // Widget untuk filter chips (tidak berubah)
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _statusOptions.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final status = _statusOptions[index];
            final isSelected = _selectedStatus == status;
            return FilterChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = status;
                });
                _filterBuses(); // Panggil filter setelah status berubah
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.8),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              checkmarkColor: Colors.white,
              shape: StadiumBorder(
                side: BorderSide(color: Colors.grey.shade300),
              ),
            );
          },
        ),
      ),
    );
  }
}
