import 'package:copmap_flutter/models/duty.dart';
import 'package:copmap_flutter/models/officer.dart';
import 'package:copmap_flutter/services/database_service.dart';
import 'package:copmap_flutter/services/location_service.dart';
import 'package:copmap_flutter/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';

class CreateDutyView extends StatefulWidget {
  const CreateDutyView({super.key});

  @override
  State<CreateDutyView> createState() => _CreateDutyViewState();
}

class _CreateDutyViewState extends State<CreateDutyView> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  late final LocationService _locationService;

  DutyType _selectedType = DutyType.patrolling;
  final TextEditingController _areaController = TextEditingController();
  DateTime? _startTime;
  DateTime? _endTime;
  final Set<String> _selectedOfficers = {};
  bool _isSubmitting = false;

  LatLng? _selectedLocation;
  final Completer<GoogleMapController> _mapController = Completer();
  List<Suggestion> _suggestions = [];
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // In a real app, this key should be in a config file or environment variable
    _locationService = LocationService('AIzaSyAdHjZCHQkSz3O7J1S7iPdckUqCgkVvM14');
  }

  @override
  void dispose() {
    _areaController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isNotEmpty) {
        setState(() => _isSearching = true);
        try {
          final suggestions = await _locationService.fetchSuggestions(query);
          setState(() {
            _suggestions = suggestions;
            _isSearching = false;
          });
        } catch (e) {
          setState(() => _isSearching = false);
          debugPrint('Error fetching suggestions: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location Search Error: $e'),
                backgroundColor: AppTheme.statusOffline,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } else {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _selectSuggestion(Suggestion suggestion) async {
    setState(() {
      _areaController.text = suggestion.description;
      _suggestions = [];
      FocusScope.of(context).unfocus();
    });

    try {
      final latLng = await _locationService.getLatLng(suggestion.placeId);
      final position = LatLng(latLng['lat']!, latLng['lng']!);
      
      setState(() {
        _selectedLocation = position;
      });

      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
    } catch (e) {
      debugPrint('Error getting latlng: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create Duty', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          const Text('Assign a new patrol or bandobast duty', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Duty Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 24),
                    
                    // Duty Type
                    const Text('Duty Type', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _TypeSelector(
                          label: 'Patrolling', 
                          isSelected: _selectedType == DutyType.patrolling,
                          onTap: () => setState(() => _selectedType = DutyType.patrolling),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _TypeSelector(
                          label: 'Bandobast', 
                          isSelected: _selectedType == DutyType.bandobast,
                          onTap: () => setState(() => _selectedType = DutyType.bandobast),
                        )),
                      ],
                    ),

                    const SizedBox(height: 20),
                    
                    // Area Search
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Area / Location', style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _areaController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search for patrol area or location',
                            prefixIcon: const Icon(LucideIcons.search, size: 20),
                            suffixIcon: _isSearching ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))) : null,
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: AppTheme.background,
                          ),
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        ),
                        if (_suggestions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.card,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.secondary),
                            ),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _suggestions.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.secondary),
                              itemBuilder: (context, index) {
                                final suggestion = _suggestions[index];
                                return ListTile(
                                  title: Text(suggestion.description, style: const TextStyle(fontSize: 13)),
                                  onTap: () => _selectSuggestion(suggestion),
                                );
                              },
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Map Preview
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.secondary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(28.6139, 77.2090),
                          zoom: 12,
                        ),
                        onMapCreated: (controller) => _mapController.complete(controller),
                        markers: _selectedLocation == null ? {} : {
                          Marker(
                            markerId: const MarkerId('selected_location'),
                            position: _selectedLocation!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                          ),
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Time
                    Row(
                      children: [
                        Expanded(
                          child: _DateTimePicker(
                            label: 'Start Time',
                            selectedDate: _startTime,
                            onPick: (d) => setState(() => _startTime = d),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _DateTimePicker(
                            label: 'End Time',
                            selectedDate: _endTime,
                            onPick: (d) => setState(() => _endTime = d),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Officers List
                    const Text('Assign Officers'),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.secondary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: StreamBuilder<List<Officer>>(
                        stream: _db.getFieldOfficersStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          final officers = snapshot.data!;
                          
                          if (officers.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.users,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No field officers found',
                                    style: TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Field officers need to register with their email accounts',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          return ListView.builder(
                            itemCount: officers.length,
                            itemBuilder: (context, index) {
                              final officer = officers[index];
                              final isSelected = _selectedOfficers.contains(officer.id);
                              
                              return ListTile(
                                onTap: () {
                                  setState(() {
                                    isSelected 
                                      ? _selectedOfficers.remove(officer.id) 
                                      : _selectedOfficers.add(officer.id);
                                  });
                                },
                                leading: Checkbox(
                                  value: isSelected,
                                  onChanged: (v) {
                                    setState(() {
                                      v! ? _selectedOfficers.add(officer.id) : _selectedOfficers.remove(officer.id);
                                    });
                                  },
                                ),
                                title: Text(officer.name),
                                subtitle: Text('${officer.badge} • ${officer.email}'),
                                selected: isSelected,
                                selectedTileColor: AppTheme.primary.withValues(alpha: 0.1),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: officer.status == OfficerStatus.active 
                                        ? AppTheme.statusActive.withValues(alpha: 0.2)
                                        : officer.status == OfficerStatus.issue
                                        ? AppTheme.statusWarning.withValues(alpha: 0.2)
                                        : AppTheme.statusOffline.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    officer.status.toString().split('.').last,
                                    style: TextStyle(
                                      color: officer.status == OfficerStatus.active 
                                          ? AppTheme.statusActive
                                          : officer.status == OfficerStatus.issue
                                          ? AppTheme.statusWarning
                                          : AppTheme.statusOffline,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (_selectedOfficers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('${_selectedOfficers.length} officers selected', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: (_isSubmitting || _selectedOfficers.isEmpty || _selectedLocation == null) ? null : _submit,
                        child: _isSubmitting 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text('Create Duty'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null || _selectedLocation == null) return;

    setState(() => _isSubmitting = true);

    try {
      final duty = Duty(
        id: 'duty_${DateTime.now().millisecondsSinceEpoch}',
        type: _selectedType,
        area: _areaController.text,
        startTime: _startTime!,
        endTime: _endTime!,
        assignedOfficerIds: _selectedOfficers.toList(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
      );

      await _db.createDuty(duty);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duty created successfully'), backgroundColor: AppTheme.statusActive),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.statusOffline),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    _areaController.clear();
    setState(() {
      _startTime = null;
      _endTime = null;
      _selectedOfficers.clear();
      _selectedLocation = null;
      _suggestions = [];
    });
  }
}

class _TypeSelector extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeSelector({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.background,
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.secondary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final Function(DateTime) onPick;

  const _DateTimePicker({required this.label, required this.selectedDate, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context, 
              firstDate: DateTime.now(), 
              lastDate: DateTime.now().add(const Duration(days: 30)),
              initialDate: DateTime.now(),
            );
            if (date != null && context.mounted) {
              final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
              if (time != null) {
                onPick(DateTime(date.year, date.month, date.day, time.hour, time.minute));
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.background,
              border: Border.all(color: AppTheme.secondary),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null ? selectedDate.toString().split('.')[0] : 'Select Date & Time',
                    style: TextStyle(color: selectedDate != null ? Colors.white : Colors.grey),
                  ),
                ),
                const Icon(LucideIcons.calendar, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
