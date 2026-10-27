import 'dart:io';

import 'package:flutter/material.dart';
import 'package:test_app/models/contact_model.dart';
import 'package:test_app/modules/add_contact/add_edit_contact_view.dart';

class DetailsContactView extends StatefulWidget {
  DetailsContactView({super.key, required this.contact});

  ContactModel contact;

  @override
  State<DetailsContactView> createState() => _DetailsContactViewState();
}

class _DetailsContactViewState extends State<DetailsContactView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actionsPadding: EdgeInsets.symmetric(horizontal: 16),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddEditContactScreen(contact: widget.contact,)),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.all(Radius.circular(50)),
              ),
              child: Text(
                'Editar',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(color: Colors.grey.shade300, height: 1),
        ),
      ),
      body: Container(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade500,
                backgroundImage: widget.contact.imagePath != null
                    ? FileImage(File(widget.contact.imagePath!))
                    : null,
                child: widget.contact.imagePath != null
                    ? Text(
                        widget.contact.name[0].toUpperCase(),
                        style: TextStyle(fontSize: 48, color: Colors.white),
                      )
                    : null,
              ),
              SizedBox(height: 56),
              Text(
                widget.contact.name,
                style: TextStyle(fontSize: 24, fontWeight: .bold),
              ),
              SizedBox(height: 56),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: Colors.grey.shade500),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  spacing: 16,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 4,
                          children: [
                            Text(
                              'N° de telefone',
                              style: TextStyle(fontSize: 10),
                            ),
                            Text(
                              widget.contact.phone,
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        Icon(Icons.phone),
                      ],
                    ),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 4,
                          children: [
                            Text('E-mail', style: TextStyle(fontSize: 10)),
                            Text(
                              widget.contact.email,
                              style: TextStyle(
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.mail),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
