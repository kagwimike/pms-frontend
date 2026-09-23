import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/property_model.dart';
import '../../providers/property_provider.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Properties')),
          body: RefreshIndicator(
            onRefresh: () => provider.loadProperties(refresh: true),
            child: _buildBody(context, provider),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PropertyProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.properties.isEmpty) {
      return _MessageState(
        message: provider.errorMessage!,
        action: () => provider.loadProperties(refresh: true),
      );
    }
    if (provider.properties.isEmpty) {
      return const _MessageState(message: 'No properties found yet.');
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: provider.properties.length + (provider.hasMore ? 1 : 0),
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == provider.properties.length) {
          provider.loadProperties();
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _PropertyTile(property: provider.properties[index]);
      },
    );
  }
}

class _PropertyTile extends StatelessWidget {
  final PropertyModel property;

  const _PropertyTile({required this.property});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.home_work_outlined)),
        title: Text(property.name),
        subtitle: Text(
          [
            if (property.city.isNotEmpty) property.city,
            if (property.propertyType.isNotEmpty) property.propertyType,
            '${property.totalUnits} units',
          ].join(' • '),
        ),
        trailing: Chip(
          label: Text(property.status.isEmpty ? 'UNKNOWN' : property.status),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String message;
  final VoidCallback? action;

  const _MessageState({required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * .3),
        Center(child: Text(message)),
        if (action != null)
          Center(
            child: TextButton.icon(
              onPressed: action,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
      ],
    );
  }
}
