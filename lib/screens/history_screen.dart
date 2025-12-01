import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_colors.dart';
import '../providers/sensor_provider.dart';
import '../providers/measurement_provider.dart';
import '../models/sensor_model.dart';
import '../models/measurement_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  int? _selectedSensorId;
  bool _initialDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _loadInitialData() {
    if (!mounted) return;
    
    final sensorP = Provider.of<SensorProvider>(context, listen: false);
    final mp = Provider.of<MeasurementProvider>(context, listen: false);
    
    // If _selectedSensorId is null (All), we need the list of all IDs for SignalR
    List<int>? allIds;
    if (_selectedSensorId == null) {
      allIds = sensorP.sensors.map((s) => s.id).toList();
    }

    mp.setActiveSensor(_selectedSensorId, allSensorIds: allIds);
    mp.fetchRawHistory(refresh: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      Provider.of<MeasurementProvider>(context, listen: false).fetchRawHistory();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sensorProvider = Provider.of<SensorProvider>(context);
    final measurementProvider = Provider.of<MeasurementProvider>(context);

    // --- CRITICAL FIX START ---
    // Validate that _selectedSensorId actually exists in the current list.
    // If the sensor was deleted or filtered out, reset selection to null (All Sensors).
    bool idIsValid = _selectedSensorId == null || 
                     sensorProvider.sensors.any((s) => s.id == _selectedSensorId);

    if (!idIsValid && sensorProvider.sensors.isNotEmpty) {
       // Reset to "All Sensors"
       _selectedSensorId = null;
       // Trigger a data reload for the new selection
       WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
    }
    // --- CRITICAL FIX END ---

    // Handle Initial Load
    if (sensorProvider.sensors.isNotEmpty && !_initialDataLoaded) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (!_initialDataLoaded) {
           _loadInitialData();
           _initialDataLoaded = true;
         }
       });
    }

    if (sensorProvider.sensors.isEmpty) {
      return Center(
        child: sensorProvider.isLoading
          ? const CircularProgressIndicator()
          : const Text("No sensors found", style: TextStyle(color: AppColors.textSecondary))
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            "Measurement History",
            style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          
          _buildDropdown(sensorProvider.sensors),
          
          const SizedBox(height: 15),
          
          // Header Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Date & Time", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                Text("Temperature", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          const SizedBox(height: 10),

          // History List
          Expanded(
            child: measurementProvider.rawHistory.isEmpty && measurementProvider.isHistoryLoading
              ? const Center(child: CircularProgressIndicator())
              : measurementProvider.rawHistory.isEmpty
                ? const Center(child: Text("No records found", style: TextStyle(color: AppColors.textSecondary)))
                : RefreshIndicator(
                    onRefresh: () async => _loadInitialData(),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: measurementProvider.rawHistory.length + 1,
                      separatorBuilder: (ctx, i) => const Divider(color: AppColors.gridLine, height: 1),
                      itemBuilder: (context, index) {
                        if (index == measurementProvider.rawHistory.length) {
                          return measurementProvider.isHistoryLoading
                            ? const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()))
                            : const SizedBox.shrink();
                        }

                        final item = measurementProvider.rawHistory[index];
                        return _buildHistoryItem(item);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(List<SensorModel> sensors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gridLine),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedSensorId,
          dropdownColor: AppColors.cardSurface,
          isExpanded: true,
          style: const TextStyle(color: AppColors.textPrimary),
          items: [
            // "All Sensors" Option
            const DropdownMenuItem<int?>(
              value: null, 
              child: Text("All Sensors", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            // Individual Sensors
            ...sensors.map((s) => DropdownMenuItem<int?>(
              value: s.id,
              child: Text(s.displayName ?? "Sensor ${s.id}"),
            )),
          ],
          onChanged: (val) {
            setState(() {
               _selectedSensorId = val;
               // No need to set _initialDataLoaded here as it's already true if we are changing value
            });
            _loadInitialData();
          },
        ),
      ),
    );
  }

  Widget _buildHistoryItem(MeasurementModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy  HH:mm').format(item.timestamp.toLocal()),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  // Show Sensor ID if viewing "All"
                  if (_selectedSensorId == null)
                    Text("Sensor ${item.sensorId}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
            ],
          ),
          Text(
            "${item.temperature.toStringAsFixed(1)} °C",
            style: const TextStyle(
              color: AppColors.textPrimary, 
              fontWeight: FontWeight.bold,
              fontSize: 16
            ),
          ),
        ],
      ),
    );
  }
}