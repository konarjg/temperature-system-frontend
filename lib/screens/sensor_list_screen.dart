import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../providers/sensor_provider.dart';
import '../providers/auth_provider.dart';
import '../models/sensor_model.dart';
import '../widgets/sensor_card.dart';

class SensorListScreen extends StatefulWidget {
  const SensorListScreen({super.key});

  @override
  State<SensorListScreen> createState() => _SensorListScreenState();
}

class _SensorListScreenState extends State<SensorListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SensorProvider>(context, listen: false).loadSensors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sensorProvider = Provider.of<SensorProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: isAdmin ? FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddSensorDialog(context),
      ) : null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Managed Sensors",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            
            // --- Filter Section ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(sensorProvider, "All", null),
                  const SizedBox(width: 8),
                  _buildFilterChip(sensorProvider, "Operational", SensorState.Operational),
                  const SizedBox(width: 8),
                  _buildFilterChip(sensorProvider, "Unavailable", SensorState.Unavailable),
                ],
              ),
            ),
            const SizedBox(height: 15),

            Expanded(
              child: sensorProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: sensorProvider.loadSensors,
                      child: sensorProvider.sensors.isEmpty
                        ? const Center(child: Text("No sensors found", style: TextStyle(color: AppColors.textSecondary)))
                        : ListView.builder(
                        itemCount: sensorProvider.sensors.length,
                        itemBuilder: (context, index) {
                          final sensor = sensorProvider.sensors[index];
                          if (isAdmin) {
                            return _buildDismissibleCard(context, sensor);
                          } else {
                            return SensorCard(sensor: sensor);
                          }
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(SensorProvider provider, String label, SensorState? state) {
    final isSelected = provider.currentFilter == state;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        // If unselecting, go back to null (All)
        provider.filterByState(selected ? state : null);
      },
      checkmarkColor: Colors.white,
      selectedColor: AppColors.primaryBlue,
      backgroundColor: AppColors.cardSurface,
      labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.gridLine),
        borderRadius: BorderRadius.circular(20)
      ),
    );
  }

  // _buildDismissibleCard and _showAddSensorDialog remain the same as previous code...
  Widget _buildDismissibleCard(BuildContext context, SensorModel sensor) {
    return Dismissible(
      key: Key(sensor.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardSurface,
            title: const Text("Delete Sensor", style: TextStyle(color: AppColors.textPrimary)),
            content: const Text("Are you sure? This cannot be undone.", style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancel")),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Delete", style: TextStyle(color: AppColors.error))),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        Provider.of<SensorProvider>(context, listen: false).removeSensor(sensor.id);
      },
      child: SensorCard(sensor: sensor),
    );
  }

  void _showAddSensorDialog(BuildContext context) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text("Add Sensor", style: TextStyle(color: AppColors.textPrimary)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Display Name', 
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gridLine))
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: addressController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'MAC Address', 
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gridLine))
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Cancel")
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await Provider.of<SensorProvider>(context, listen: false)
                      .addSensor(nameController.text, addressController.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                   // Handle error
                }
              }
            },
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}