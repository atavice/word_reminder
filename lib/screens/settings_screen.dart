import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  int _frequency = 5;
  int _startHour = 9;
  int _endHour = 21;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loadSettings();
      _loaded = true;
    }
  }

  Future<void> _loadSettings() async {
    final notifService =
        context.read<WordProvider>().notificationService;
    final enabled = await notifService.isEnabled();
    final freq = await notifService.getFrequency();
    final start = await notifService.getStartHour();
    final end = await notifService.getEndHour();

    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _frequency = freq;
        _startHour = start;
        _endHour = end;
      });
    }
  }

  Future<void> _saveSettings() async {
    final provider = context.read<WordProvider>();
    final notifService = provider.notificationService;
    await notifService.setEnabled(_notificationsEnabled);
    await notifService.setFrequency(_frequency);
    await notifService.setStartHour(_startHour);
    await notifService.setEndHour(_endHour);
    await notifService.scheduleWordReminders(provider.dbService);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ayarlar kaydedildi!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notification section
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Bildirimler'),
                  subtitle: const Text('Kelime hatırlatma bildirimleri'),
                  value: _notificationsEnabled,
                  onChanged: (val) => setState(() => _notificationsEnabled = val),
                ),
                if (_notificationsEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Günlük bildirim sayısı'),
                    subtitle: Text('$_frequency bildirim / gün'),
                    trailing: SizedBox(
                      width: 200,
                      child: Slider(
                        value: _frequency.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '$_frequency',
                        onChanged: (val) =>
                            setState(() => _frequency = val.round()),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Başlangıç saati'),
                    subtitle: Text('$_startHour:00'),
                    trailing: IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: _startHour, minute: 0),
                        );
                        if (time != null) {
                          setState(() => _startHour = time.hour);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Bitiş saati'),
                    subtitle: Text('$_endHour:00'),
                    trailing: IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: _endHour, minute: 0),
                        );
                        if (time != null) {
                          setState(() => _endHour = time.hour);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Info section
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('WordReminder'),
                  subtitle: Text('v1.0.0'),
                ),
                ListTile(
                  leading: Icon(Icons.code),
                  title: Text('Flutter ile geliştirildi'),
                  subtitle: Text('SQLite + Provider'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          FilledButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Ayarları Kaydet'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
