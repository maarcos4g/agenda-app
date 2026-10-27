import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_app/models/contact_model.dart';
import 'package:test_app/modules/edit_contact/edit_contact_view.dart';
import 'package:test_app/services/contacts_service.dart';

class ContactDetailsView extends StatefulWidget {
  final ContactModel contact;

  const ContactDetailsView({super.key, required this.contact});

  @override
  State<ContactDetailsView> createState() => _ContactDetailsViewState();
}

class _ContactDetailsViewState extends State<ContactDetailsView> {
  final service = ContactService();
  late ContactModel _contact;

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
  }

  Future<void> _toggleFavorite() async {
    final updated = _contact.copyWith(isFavorite: !(_contact.isFavorite == true));
    await service.update(updated);
    setState(() {
      _contact = updated;
    });
  }

  Future<void> _deleteContact() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Contato'),
        content: Text('Tem certeza que deseja remover "${_contact.name}" da agenda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await service.delete(_contact);
      if (!mounted) return;
      Navigator.pop(context, true); // true indica que houve exclusão
    }
  }

  Future<void> _editContact() async {
    final result = await Navigator.push<ContactModel>(
      context,
      MaterialPageRoute(
        builder: (context) => EditContactView(contact: _contact),
      ),
    );

    if (result != null) {
      setState(() {
        _contact = result;
      });
    }
  }

  void _copyToClipboard(String label, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copiado para a área de transferência!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFav = _contact.isFavorite == true;
    final hasImage = _contact.imagePath != null && _contact.imagePath!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Contato', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.star : Icons.star_border,
              color: isFav ? Colors.amber : null,
            ),
            tooltip: isFav ? 'Remover dos Favoritos' : 'Favoritar',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Contato',
            onPressed: _editContact,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Excluir Contato',
            onPressed: _deleteContact,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade300, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Avatar e Nome
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: hasImage ? NetworkImage(_contact.imagePath!) : null,
                    child: !hasImage
                        ? Text(
                            _contact.name.isNotEmpty ? _contact.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.blue),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _contact.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (_contact.company != null && _contact.company!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _contact.company!,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Ações rápidas de contato
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionBtn(
                  icon: Icons.phone,
                  label: 'Ligar',
                  color: Colors.green,
                  onTap: () => _copyToClipboard('Telefone', _contact.phone),
                ),
                _buildActionBtn(
                  icon: Icons.email,
                  label: 'E-mail',
                  color: Colors.blue,
                  onTap: () => _copyToClipboard('E-mail', _contact.email),
                ),
                _buildActionBtn(
                  icon: Icons.share,
                  label: 'Compartilhar',
                  color: Colors.orange,
                  onTap: () => _copyToClipboard('Contato', '${_contact.name} - ${_contact.phone}'),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Cartão de Informações
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoTile(
                      icon: Icons.phone_outlined,
                      title: 'Telefone',
                      subtitle: _contact.phone,
                      onCopy: () => _copyToClipboard('Telefone', _contact.phone),
                    ),
                    const Divider(height: 20),
                    _buildInfoTile(
                      icon: Icons.email_outlined,
                      title: 'E-mail',
                      subtitle: _contact.email,
                      onCopy: () => _copyToClipboard('E-mail', _contact.email),
                    ),
                    if (_contact.birthDate != null && _contact.birthDate!.isNotEmpty) ...[
                      const Divider(height: 20),
                      _buildInfoTile(
                        icon: Icons.cake_outlined,
                        title: 'Aniversário',
                        subtitle: _formatBirthDate(_contact.birthDate!),
                      ),
                    ],
                    if (_contact.city != null && _contact.city!.isNotEmpty) ...[
                      const Divider(height: 20),
                      _buildInfoTile(
                        icon: Icons.location_on_outlined,
                        title: 'Cidade',
                        subtitle: _contact.city!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Observações
            if (_contact.notes != null && _contact.notes!.isNotEmpty) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notes_outlined, size: 20, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Observações', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_contact.notes!, style: const TextStyle(fontSize: 14, height: 1.4)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Categorias
            if (_contact.categories.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text('Categorias', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _contact.categories.map((cat) {
                  return Chip(
                    avatar: const Icon(Icons.label, size: 16, color: Colors.blue),
                    label: Text(cat),
                    backgroundColor: Colors.blue.shade50,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Grupos
            if (_contact.groups.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text('Grupos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _contact.groups.map((group) {
                  return Chip(
                    avatar: const Icon(Icons.group, size: 16, color: Colors.teal),
                    label: Text(group),
                    backgroundColor: Colors.teal.shade50,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onCopy,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.grey.shade600),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(subtitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        if (onCopy != null)
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
            tooltip: 'Copiar',
            onPressed: onCopy,
          ),
      ],
    );
  }

  String _formatBirthDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return dateStr;
  }
}
