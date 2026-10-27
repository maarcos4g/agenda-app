import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_app/models/contact_model.dart';
import 'package:test_app/modules/contact_details/contact_details_view.dart';
import 'package:test_app/services/contacts_service.dart';

class BirthdaysView extends StatefulWidget {
  const BirthdaysView({super.key});

  @override
  State<BirthdaysView> createState() => _BirthdaysViewState();
}

class _BirthdaysViewState extends State<BirthdaysView> {
  final contactService = ContactService();

  int _selectedMonth = DateTime.now().month;
  List<ContactModel> _monthBirthdays = [];
  List<Map<String, dynamic>> _upcomingBirthdays = [];
  bool _isLoading = true;

  static const List<String> _monthsNames = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  @override
  void initState() {
    super.initState();
    _loadBirthdays();
  }

  Future<void> _loadBirthdays() async {
    final list = await contactService.getBirthdaysOfMonth(_selectedMonth);
    final upcoming = await contactService.getUpcomingBirthdays(daysAhead: 7);

    // Ordenar aniversariantes do mês pelo dia
    list.sort((a, b) {
      final dayA = _getDay(a.birthDate);
      final dayB = _getDay(b.birthDate);
      return dayA.compareTo(dayB);
    });

    setState(() {
      _monthBirthdays = list;
      _upcomingBirthdays = upcoming;
      _isLoading = false;
    });
  }

  int _getDay(String? dateStr) {
    if (dateStr == null) return 99;
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) return int.parse(parts[2]);
    } catch (_) {}
    return 99;
  }

  void _sendBirthdayMessage(ContactModel contact) {
    Clipboard.setData(ClipboardData(
      text: 'Parabéns, ${contact.name}! Desejo muitas felicidades e um dia maravilhoso! 🎉🎂',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mensagem de parabéns para ${contact.name} copiada!'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aniversários', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade300, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Aniversários Próximos (Lembretes)
            if (_upcomingBirthdays.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cake, color: Colors.amber, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Lembretes Próximos (7 dias)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._upcomingBirthdays.map((item) {
                      final contact = item['contact'] as ContactModel;
                      final daysRemaining = item['daysRemaining'] as int;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white24,
                              child: Text(
                                contact.name.isNotEmpty ? contact.name[0] : '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contact.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    daysRemaining == 0
                                        ? '🎉 É HOJE! Parabéns!'
                                        : daysRemaining == 1
                                            ? 'Amanhã!'
                                            : 'Em $daysRemaining dias',
                                    style: TextStyle(
                                      color: daysRemaining == 0 ? Colors.amber : Colors.white70,
                                      fontWeight: daysRemaining == 0 ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.celebration, color: Colors.amber, size: 22),
                              tooltip: 'Copiar mensagem de parabéns',
                              onPressed: () => _sendBirthdayMessage(contact),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Seletor de Mês
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Aniversariantes do Mês',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<int>(
                  value: _selectedMonth,
                  underline: const SizedBox(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14),
                  items: List.generate(12, (index) {
                    final monthNumber = index + 1;
                    return DropdownMenuItem(
                      value: monthNumber,
                      child: Text(_monthsNames[index]),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedMonth = val;
                      });
                      _loadBirthdays();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Lista de Aniversariantes do Mês
            _monthBirthdays.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Nenhum aniversariante em ${_monthsNames[_selectedMonth - 1]}.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _monthBirthdays.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final contact = _monthBirthdays[index];
                      final day = _getDay(contact.birthDate);
                      final hasImg = contact.imagePath != null && contact.imagePath!.trim().isNotEmpty;

                      return ListTile(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContactDetailsView(contact: contact),
                            ),
                          );
                          _loadBirthdays();
                        },
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: hasImg ? NetworkImage(contact.imagePath!) : null,
                          child: !hasImg
                              ? Text(
                                  '$day',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                )
                              : null,
                        ),
                        title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          'Dia $day de ${_monthsNames[_selectedMonth - 1]}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue, size: 20),
                          tooltip: 'Parabenizar',
                          onPressed: () => _sendBirthdayMessage(contact),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
