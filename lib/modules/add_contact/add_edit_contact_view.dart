import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:test_app/models/contact_model.dart';
import 'package:test_app/modules/home/home_view.dart';
import 'package:test_app/services/contacts_service.dart';

class AddEditContactScreen extends StatefulWidget {
  AddEditContactScreen({super.key, this.contact});
  ContactModel? contact;

  @override
  State<AddEditContactScreen> createState() => _AddEditContactScreenState();
}

class _AddEditContactScreenState extends State<AddEditContactScreen> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = MaskedTextController(mask: '(00) 00000-0000');

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      nameController.text = widget.contact!.name;
      emailController.text = widget.contact!.email;
      phoneController.text = widget.contact!.phone;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actionsPadding: EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          widget.contact == null ? 'Novo Contato' : 'Editar Contato',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: Colors.black87),
        ),
        actions: [
          GestureDetector(
            onTap: () async {
              if (formKey.currentState!.validate()) {
                final contact = ContactModel(
                  id: widget.contact?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  imagePath: widget.contact?.imagePath,
                  name: nameController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                );
                if (widget.contact == null) {
                  await ContactService().add(contact);
                } else {
                  await ContactService().update(contact);
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeView()),
                );
              }
            },
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.white),
            ),
          ),
        ],
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(color: Colors.grey.shade300, height: 1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 24,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                  'https://avatars.githubusercontent.com/u/124599?v=4',
                ),
              ),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Nome',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                validator: (String? value) =>
                    value?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'E-mail',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                validator: (String? value) =>
                    value?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Telefone',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                validator: (String? value) =>
                    value?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
