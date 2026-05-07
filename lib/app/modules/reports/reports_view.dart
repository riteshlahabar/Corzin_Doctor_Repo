import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/cow_walking_loader.dart';
import '../home/home_controller.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({
    super.key,
    required this.controller,
  });

  final HomeController controller;

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  DateTime _selectedDate = DateTime.now();
  int _selectedTab = 0;
  bool _loading = false;
  String _error = '';

  int _totalRequest = 0;
  double _totalEarning = 0;
  double _medicationCost = 0;
  List<Map<String, dynamic>> _items = const [];

  String get _activeTabKey => _selectedTab == 0 ? 'earnings' : 'clients';

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadReports);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    final profile = widget.controller.profile.value;
    if (profile == null) return;

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final response = await _apiService.fetchDoctorReports(
        doctorId: profile.id,
        tab: _activeTabKey,
        date: _selectedDate,
        search: _searchController.text.trim(),
      );
      final data = response['data'];
      final summaryRaw = data is Map ? data['summary'] : null;
      final itemsRaw = data is Map ? data['items'] : null;
      final summary = summaryRaw is Map
          ? summaryRaw.map((key, value) => MapEntry(key.toString(), value))
          : <String, dynamic>{};
      final list = itemsRaw is List
          ? itemsRaw
              .whereType<Map>()
              .map((row) => row.map((key, value) => MapEntry(key.toString(), value)))
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _totalRequest = _toInt(summary['total_request']);
        _totalEarning = _toDouble(summary['total_earning']);
        _medicationCost = _toDouble(summary['medication_cost']);
        _items = list;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _items = const [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _dateLabel(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  String _money(dynamic value) {
    final numeric = _toDouble(value);
    return 'Rs ${numeric.toStringAsFixed(0)}';
  }

  DateTime? _parseDate(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _loadReports);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
    });
    await _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Reports',
          style: TextStyle(fontFamily: 'SF Pro Display', fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: _selectedTab == 0
                          ? 'Search farmer, animal, concern'
                          : 'Search client name or phone',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event_rounded, size: 16),
                  label: Text(_dateLabel(_selectedDate)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Request',
                    value: '$_totalRequest',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Earning',
                    value: _money(_totalEarning),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    title: 'Medication Cost',
                    value: _money(_medicationCost),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6F1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      title: 'My Earnings',
                      selected: _selectedTab == 0,
                      onTap: () async {
                        if (_selectedTab == 0) return;
                        setState(() {
                          _selectedTab = 0;
                        });
                        await _loadReports();
                      },
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      title: 'My Clients',
                      selected: _selectedTab == 1,
                      onTap: () async {
                        if (_selectedTab == 1) return;
                        setState(() {
                          _selectedTab = 1;
                        });
                        await _loadReports();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadReports,
              child: _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CowWalkingLoader(label: 'Loading reports...'));
    }
    if (_error.isNotEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              _error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: OutlinedButton(
              onPressed: _loadReports,
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(
            child: Text(
              'No report data for selected date.',
              style: TextStyle(color: AppColors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final row = _items[index];
        return _selectedTab == 0 ? _earningItem(row) : _clientItem(row);
      },
    );
  }

  Widget _earningItem(Map<String, dynamic> row) {
    final completedAt = _parseDate(row['completed_at'] ?? row['last_activity_at']);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${row['farmer_name'] ?? '-'}  •  ${row['animal_name'] ?? '-'}',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            (row['concern'] ?? '-').toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.grey),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total: ${_money(row['total_earning'])}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Medication: ${_money(row['medication_cost'])}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            completedAt == null
                ? '-'
                : DateFormat('dd MMM yyyy, hh:mm a').format(completedAt.toLocal()),
            style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _clientItem(Map<String, dynamic> row) {
    final lastActivity = _parseDate(row['last_activity_at']);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (row['farmer_name'] ?? '-').toString(),
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            'Contact: ${(row['farmer_phone'] ?? '-').toString()}',
            style: const TextStyle(fontSize: 12, color: AppColors.grey),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Requests: ${_toInt(row['total_requests'])}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                _money(row['total_earning']),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Medication: ${_money(row['medication_cost'])}',
            style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            lastActivity == null
                ? '-'
                : 'Last Location: ${DateFormat('dd MMM yyyy, hh:mm a').format(lastActivity.toLocal())}',
            style: const TextStyle(fontSize: 11.5, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: AppColors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.white : AppColors.black,
          ),
        ),
      ),
    );
  }
}
