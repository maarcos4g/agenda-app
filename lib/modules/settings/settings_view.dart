import 'package:flutter/material.dart';
import 'package:test_app/services/contacts_service.dart';
import 'package:test_app/services/settings_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final settingsService = SettingsService();
  final contactService = ContactService();

  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await settingsService.getSettings();
    setState(() {
      _settings = s;
      _isLoading = false;
    });
  }

  Future<void> _changeTheme(ThemeMode mode) async {
    await settingsService.setTheme(mode);
    _loadSettings();
  }

  Future<void> _toggleAutoBackup(bool val) async {
    await settingsService.setAutoBackup(val);
    _loadSettings();
  }

  Future<void> _changeFrequency(String freq) async {
    await settingsService.setBackupFrequency(freq);
    _loadSettings();
  }

  Future<void> _clearAllContacts() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar Todos os Contatos'),
        content: const Text(
          'Atenção: Esta ação removerá PERMANENTEMENTE todos os contatos salvos da agenda. Tem certeza?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim, Limpar Tudo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await contactService.clearAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos os contatos foram removidos.')),
      );
    }
  }

  Future<void> _loadDemoContacts() async {
    await contactService.loadDemoContacts();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contatos de demonstração carregados com sucesso!'), backgroundColor: Colors.blue),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentTheme = _settings['themeMode'] ?? 'light';
    final autoBackup = _settings['autoBackup'] ?? true;
    final backupFreq = _settings['backupFrequency'] ?? 'Diário';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção Tema
          _buildSectionHeader('Aparência e Tema', Icons.palette_outlined),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Tema Claro'),
                  subtitle: const Text('Interface clássica e iluminada'),
                  leading: const Icon(Icons.wb_sunny_outlined, color: Colors.orange),
                  trailing: currentTheme == 'light'
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () => _changeTheme(ThemeMode.light),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Tema Escuro'),
                  subtitle: const Text('Modo noturno elegante e confortável'),
                  leading: const Icon(Icons.nightlight_round, color: Colors.indigo),
                  trailing: currentTheme == 'dark'
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () => _changeTheme(ThemeMode.dark),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Padrão do Sistema'),
                  subtitle: const Text('Segue as configurações do dispositivo'),
                  leading: const Icon(Icons.settings_system_daydream, color: Colors.grey),
                  trailing: currentTheme == 'system'
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () => _changeTheme(ThemeMode.system),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Seção Backup
          _buildSectionHeader('Backup Automático', Icons.cloud_sync_outlined),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Backup Automático Ativo'),
                  subtitle: const Text('Sincroniza cópia local dos seus contatos'),
                  secondary: const Icon(Icons.backup_outlined, color: Colors.teal),
                  value: autoBackup,
                  onChanged: _toggleAutoBackup,
                ),
                if (autoBackup) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Frequência de Backup'),
                    subtitle: Text(backupFreq),
                    leading: const Icon(Icons.schedule, color: Colors.teal),
                    trailing: DropdownButton<String>(
                      value: backupFreq,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'Diário', child: Text('Diário')),
                        DropdownMenuItem(value: 'Semanal', child: Text('Semanal')),
                        DropdownMenuItem(value: 'Mensal', child: Text('Mensal')),
                      ],
                      onChanged: (val) {
                        if (val != null) _changeFrequency(val);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Seção Gerenciamento de Dados
          _buildSectionHeader('Gerenciar Dados', Icons.storage_outlined),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Carregar Dados de Demonstração'),
                  subtitle: const Text('Adiciona contatos prontos para teste'),
                  leading: const Icon(Icons.auto_awesome, color: Colors.blue),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _loadDemoContacts,
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Limpar Todos os Contatos', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Remove todos os registros da memória local'),
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  onTap: _clearAllContacts,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Informações do App
          Center(
            child: Column(
              children: [
                const Icon(Icons.contacts, size: 36, color: Colors.blue),
                const SizedBox(height: 6),
                const Text(
                  'Agenda de Contatos v1.0.0',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'Desenvolvido com Flutter & SharedPreferences',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
