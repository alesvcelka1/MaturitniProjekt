import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import 'workout_detail_page.dart';

/// Kalendář pro plánování a zobrazení tréninků
class CalendarPage extends StatefulWidget {
  final String? userRole;

  const CalendarPage({super.key, this.userRole});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _workoutEvents = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Načti tréninky pro aktuální měsíc
      final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      List<Map<String, dynamic>> workouts;
      
      if (widget.userRole == 'trainer') {
        workouts = await DatabaseService.getTrainerScheduledWorkouts(
          trainerId: currentUser.uid,
          startDate: startOfMonth,
          endDate: endOfMonth,
        );
      } else {
        workouts = await DatabaseService.getUserScheduledWorkouts(
          userId: currentUser.uid,
          startDate: startOfMonth,
          endDate: endOfMonth,
        );
      }

      // Seskup tréninky podle datumu
      final Map<DateTime, List<Map<String, dynamic>>> events = {};
      for (final workout in workouts) {
        final scheduledDate = (workout['scheduled_date'] as Timestamp).toDate();
        final dateKey = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
        
        if (events[dateKey] == null) {
          events[dateKey] = [];
        }
        events[dateKey]!.add(workout);
      }

      if (mounted) {
        setState(() {
          _workoutEvents = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Chyba při načítání tréninků: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _workoutEvents[dateKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Kalendář tréninků'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadWorkouts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Obnovit',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCalendar(),
                const Divider(height: 1),
                Expanded(
                  child: _buildEventsList(),
                ),
              ],
            ),
      floatingActionButton: widget.userRole == 'trainer'
          ? FloatingActionButton.extended(
              onPressed: _showAddWorkoutDialog,
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.add),
              label: const Text('Naplánovat trénink'),
            )
          : null,
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        locale: 'cs_CZ',
        calendarStyle: CalendarStyle(
          markersMaxCount: 3,
          markerDecoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          weekendTextStyle: const TextStyle(color: Colors.red),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          _loadWorkouts();
        },
      ),
    );
  }

  Widget _buildEventsList() {
    if (_selectedDay == null) {
      return const Center(
        child: Text('Vyberte den pro zobrazení tréninků'),
      );
    }

    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Žádné tréninky na ${_selectedDay!.day}. ${_selectedDay!.month}. ${_selectedDay!.year}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final workout = events[index];
        return _buildWorkoutCard(workout);
      },
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout) {
    final scheduledDate = (workout['scheduled_date'] as Timestamp).toDate();
    final status = workout['status'] as String;
    final workoutName = workout['workout_name'] as String;
    final notes = workout['notes'] as String?;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Dokončeno';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Zrušeno';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.event;
        statusText = 'Naplánováno';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showWorkoutOptions(workout),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      workoutName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm').format(scheduledDate),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notes,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showWorkoutOptions(Map<String, dynamic> workout) {
    final status = workout['status'] as String;
    final workoutId = workout['workout_id'] as String;
    final scheduledWorkoutId = workout['id'] as String;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.blue),
              title: const Text('Zobrazit detail'),
              onTap: () async {
                Navigator.pop(context);
                
                // Načti workout data
                final doc = await FirebaseFirestore.instance
                    .collection('workouts')
                    .doc(workoutId)
                    .get();
                
                if (doc.exists && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutDetailPage(
                        workoutId: workoutId,
                        workoutData: doc.data() as Map<String, dynamic>,
                      ),
                    ),
                  );
                }
              },
            ),
            if (status == 'scheduled' && widget.userRole == 'client') ...[
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Označit jako dokončený'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await DatabaseService.completeScheduledWorkout(scheduledWorkoutId);
                    
                    // Ulož také do completed_workouts
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser != null) {
                      final workoutDoc = await FirebaseFirestore.instance
                          .collection('workouts')
                          .doc(workoutId)
                          .get();
                      
                      if (workoutDoc.exists) {
                        final workoutData = workoutDoc.data() as Map<String, dynamic>;
                        final exercises = List<Map<String, dynamic>>.from(
                          workoutData['exercises'] ?? []
                        );
                        
                        await DatabaseService.saveCompletedWorkout(
                          workoutId: workoutId,
                          workoutName: workout['workout_name'],
                          userId: currentUser.uid,
                          durationSeconds: 0,
                          completedExercises: exercises.map((exercise) => {
                            'name': exercise['name'],
                            'planned_sets': exercise['sets'] ?? 1,
                            'completed_sets': exercise['sets'] ?? 1,
                            'reps': exercise['reps'] ?? 0,
                            'load': exercise['load'] ?? '',
                          }).toList(),
                        );
                      }
                    }
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Trénink dokončen!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadWorkouts();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Chyba: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
            if (widget.userRole == 'trainer') ...[
              ListTile(
                leading: const Icon(Icons.edit_calendar, color: Colors.orange),
                title: const Text('Přesunout na jiný datum'),
                onTap: () {
                  Navigator.pop(context);
                  _showRescheduleDialog(scheduledWorkoutId, workout);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Zrušit trénink'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await DatabaseService.cancelScheduledWorkout(scheduledWorkoutId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Trénink zrušen'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      _loadWorkouts();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Chyba: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Smazat z kalendáře'),
                onTap: () async {
                  Navigator.pop(context);
                  
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Smazat trénink?'),
                      content: const Text('Opravdu chcete smazat tento naplánovaný trénink?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Zrušit'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Smazat'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    try {
                      await DatabaseService.deleteScheduledWorkout(scheduledWorkoutId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Trénink smazán'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadWorkouts();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Chyba: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddWorkoutDialog() {
    showDialog(
      context: context,
      builder: (context) => const _AddWorkoutDialog(),
    ).then((result) {
      if (result == true) {
        _loadWorkouts();
      }
    });
  }

  void _showRescheduleDialog(String scheduledWorkoutId, Map<String, dynamic> workout) {
    final currentDate = (workout['scheduled_date'] as Timestamp).toDate();
    DateTime selectedDate = currentDate;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(currentDate);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Přesunout trénink'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Datum'),
                subtitle: Text('${selectedDate.day}. ${selectedDate.month}. ${selectedDate.year}'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('cs', 'CZ'),
                  );
                  if (date != null) {
                    setDialogState(() {
                      selectedDate = date;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Čas'),
                subtitle: Text(selectedTime.format(context)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setDialogState(() {
                      selectedTime = time;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Zrušit'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                
                try {
                  await DatabaseService.rescheduleWorkout(scheduledWorkoutId, newDateTime);
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trénink přesunut'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadWorkouts();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Chyba: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Uložit'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog pro přidání naplánovaného tréninku (pouze pro trenéry)
class _AddWorkoutDialog extends StatefulWidget {
  const _AddWorkoutDialog();

  @override
  State<_AddWorkoutDialog> createState() => _AddWorkoutDialogState();
}

class _AddWorkoutDialogState extends State<_AddWorkoutDialog> {
  String? _selectedWorkoutId;
  String? _selectedWorkoutName;
  String? _selectedClientId;
  String? _selectedClientName;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Naplánovat trénink'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Výběr klienta
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(_selectedClientName ?? 'Vybrat klienta'),
              subtitle: _selectedClientName != null ? const Text('Klient vybrán') : null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectClient,
            ),
            const Divider(),
            // Výběr tréninku
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: Text(_selectedWorkoutName ?? 'Vybrat trénink'),
              subtitle: _selectedWorkoutName != null ? const Text('Trénink vybrán') : null,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectWorkout,
            ),
            const Divider(),
            // Výběr data
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Datum'),
              subtitle: Text('${_selectedDate.day}. ${_selectedDate.month}. ${_selectedDate.year}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectDate,
            ),
            // Výběr času
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Čas'),
              subtitle: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectTime,
            ),
            const SizedBox(height: 16),
            // Poznámky
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Poznámky (volitelné)',
                border: OutlineInputBorder(),
                hintText: 'Např. zaměřit se na...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Zrušit'),
        ),
        ElevatedButton(
          onPressed: _canSchedule() ? _scheduleWorkout : null,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Naplánovat'),
        ),
      ],
    );
  }

  bool _canSchedule() {
    return _selectedWorkoutId != null && _selectedClientId != null;
  }

  void _selectClient() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Načti všechny klienty (nebo jen ty přiřazené k trenérovi)
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'client')
        .get();

    if (!mounted) return;

    final client = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vybrat klienta'),
        content: SizedBox(
          width: double.maxFinite,
          child: snapshot.docs.isEmpty
              ? const Center(child: Text('Nemáte žádné klienty'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.docs[index];
                    final data = doc.data();
                    return ListTile(
                      title: Text(data['display_name'] ?? 'Neznámý'),
                      subtitle: Text(data['email'] ?? ''),
                      onTap: () => Navigator.pop(context, {
                        'id': doc.id,
                        'name': data['display_name'] ?? 'Neznámý',
                      }),
                    );
                  },
                ),
        ),
      ),
    );

    if (client != null) {
      setState(() {
        _selectedClientId = client['id'];
        _selectedClientName = client['name'];
      });
    }
  }

  void _selectWorkout() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Načti tréninky trenéra
    final snapshot = await FirebaseFirestore.instance
        .collection('workouts')
        .where('trainer_id', isEqualTo: currentUser.uid)
        .get();

    if (!mounted) return;

    final workout = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vybrat trénink'),
        content: SizedBox(
          width: double.maxFinite,
          child: snapshot.docs.isEmpty
              ? const Center(child: Text('Nemáte žádné tréninky'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.docs[index];
                    final data = doc.data();
                    return ListTile(
                      title: Text(data['workout_name'] ?? 'Bez názvu'),
                      subtitle: Text(data['description'] ?? ''),
                      onTap: () => Navigator.pop(context, {
                        'id': doc.id,
                        'name': data['workout_name'] ?? 'Bez názvu',
                      }),
                    );
                  },
                ),
        ),
      ),
    );

    if (workout != null) {
      setState(() {
        _selectedWorkoutId = workout['id'];
        _selectedWorkoutName = workout['name'];
      });
    }
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('cs', 'CZ'),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _scheduleWorkout() async {
    if (!_canSchedule()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      await DatabaseService.scheduleWorkout(
        workoutId: _selectedWorkoutId!,
        workoutName: _selectedWorkoutName!,
        userId: _selectedClientId!,
        trainerId: currentUser.uid,
        scheduledDate: scheduledDateTime,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trénink naplánován!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
