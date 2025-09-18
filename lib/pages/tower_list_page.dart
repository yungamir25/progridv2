import 'package:flutter/material.dart';
import '../models/tower.dart';
import 'tower_details_page.dart';

class TowerListPage extends StatefulWidget {
  final List<Tower> towers;

  const TowerListPage({super.key, required this.towers});

  @override
  _TowerListPageState createState() => _TowerListPageState();
}

class _TowerListPageState extends State<TowerListPage> {
  late List<Tower> filteredTowers;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRegion;

  @override
  void initState() {
    super.initState();
    filteredTowers = widget.towers;
    _searchController.addListener(_filterTowers);
  }

  void _filterTowers() {
    setState(() {
      filteredTowers = widget.towers.where((tower) {
        bool matchesRegion = _selectedRegion == null || tower.region == _selectedRegion;
        bool matchesSearch = tower.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                             tower.id.toLowerCase().contains(_searchController.text.toLowerCase());
        return matchesRegion && matchesSearch;
      }).toList();
    });
  }

  // Method to handle region selection
  void _onRegionChanged(String? newRegion) {
    setState(() {
      _selectedRegion = newRegion;
      _filterTowers(); // Reapply the filter when the region changes
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tower List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Towers',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Region Dropdown
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedRegion,
              hint: Text('Select Region'),
              onChanged: _onRegionChanged,
              items: <String>[
                'Central', 'Northern', 'Southern', 'East Coast', 'Sabah', 'Sarawak'
              ].map<DropdownMenuItem<String>>((String region) {
                return DropdownMenuItem<String>(
                  value: region,
                  child: Text(region),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTowers.length,
              itemBuilder: (context, index) {
                final tower = filteredTowers[index];
                return ListTile(
                  title: Text(tower.name),
                  subtitle: Text('Progress: ${tower.progress}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TowerDetailsPage(tower: tower),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
