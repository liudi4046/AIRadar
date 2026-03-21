import 'package:flutter/material.dart';

class EntityScreen extends StatelessWidget {
  final String entityId;
  const EntityScreen({super.key, required this.entityId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('Entity: $entityId')),
    );
  }
}
