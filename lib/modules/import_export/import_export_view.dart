import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_app/services/contacts_service.dart';

class ImportExportView extends StatefulWidget {
  const ImportExportView({super.key});

  @override
  State<ImportExportView> createState() => _ImportExportViewState();
}

class _ImportExportViewState extends State<ImportExportView> {
  final contactService = ContactService();
  final importController = TextEditingController();

  String _exportPreview = '';
  String _exportFormat = 'CSV';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateExport();
  }

  Future<void> _generateExport() async {
    setState(() {
      _isLoading = true;
    });

    final data = _exportFormat == 'CSV'
        ? await contactService.exportCsv()
        : await contactService.exportJson();

    setState(() {
      _exportPreview = data;
      _isLoading = false;
    });
  }

  void _copyExport() {
    Clipboard.setData(ClipboardData(text: _exportPreview));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Backup $_exportFormat copiado para a área de transferência!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _importData() async {
    final text = importController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, cole os dados CSV ou JSON no campo acima.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var count = 0;
      if (text.startsWith('[') || text.startsWith('{')) {
        count = await contactService.importJson(text);
      } else {
        count = await contactService.importCsv(text);
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count contatos importados com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      importController.clear();
      _generateExport();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao importar: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadDemoData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Carregar Contatos de Teste'),
        content: const Text(
          'Deseja carregar 5 contatos ricos de demonstração (com fotos, categorias, notas e aniversários)?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Carregar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      await contactService.loadDemoContacts();
      await _generateExport();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contatos de demonstração carregados com sucesso!'), backgroundColor: Colors.blue),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importação e Exportação', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade300, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção de Exportação
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.file_upload_outlined, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Exportar Backup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'CSV', label: Text('CSV')),
                            ButtonSegment(value: 'JSON', label: Text('JSON')),
                          ],
                          selected: {_exportFormat},
                          onSelectionChanged: (val) {
                            setState(() {
                              _exportFormat = val.first;
                            });
                            _generateExport();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Copie os dados abaixo para salvar um backup seguro em uma planilha ou arquivo de texto.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      height: 140,
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black26
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _exportPreview.isEmpty ? 'Nenhum contato para exportar.' : _exportPreview,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                      label: Text(
                        'Copiar Backup $_exportFormat',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _exportPreview.isEmpty ? null : _copyExport,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Seção de Importação
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
                        Icon(Icons.file_download_outlined, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Importar Contatos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cole aqui o conteúdo CSV (com cabeçalho) ou JSON exportado para restaurar contatos.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: importController,
                      maxLines: 4,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      decoration: InputDecoration(
                        hintText: 'Cole o texto CSV ou JSON aqui...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.download, color: Colors.white, size: 18),
                      label: const Text(
                        'Importar Contatos',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isLoading ? null : _importData,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botão rápido para carregar contatos de demonstração
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Carregar Contatos de Demonstração (5 contatos)'),
              onPressed: _loadDemoData,
            ),
          ],
        ),
      ),
    );
  }
}
