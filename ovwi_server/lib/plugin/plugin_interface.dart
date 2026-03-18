abstract class OVWIPlugin {
  String get name;
  String get version;
  String get description;
  List<String> get dependencies;

  Future<void> initialize();
  Future<void> execute(Map<String, dynamic> config);
  Future<void> shutdown();
}

enum PluginType {
  logging,
  billing,
  analytics,
  monitoring,
  security,
  custom,
}

class PluginMetadata {
  final String pluginId;
  final String name;
  final String version;
  final PluginType type;
  final String author;
  final String description;
  final List<String> requiredScopes;
  final DateTime createdAt;
  bool enabled;

  PluginMetadata({
    required this.pluginId,
    required this.name,
    required this.version,
    required this.type,
    required this.author,
    required this.description,
    required this.requiredScopes,
    required this.createdAt,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'pluginId': pluginId,
    'name': name,
    'version': version,
    'type': type.toString().split('.').last,
    'author': author,
    'description': description,
    'requiredScopes': requiredScopes,
    'enabled': enabled,
    'createdAt': createdAt.toIso8601String(),
  };
}

class LoggingPlugin implements OVWIPlugin {
  @override
  String get name => 'OVWI Logging Plugin';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Advanced logging and monitoring for OVWI';

  @override
  List<String> get dependencies => ['logging', 'intl'];

  @override
  Future<void> initialize() async {
    print('✅ Logging Plugin initialized');
  }

  @override
  Future<void> execute(Map<String, dynamic> config) async {
    final logLevel = config['logLevel'] ?? 'INFO';
    final destination = config['destination'] ?? 'console';
    print('📝 Logging configured: level=$logLevel, destination=$destination');
  }

  @override
  Future<void> shutdown() async {
    print('⛔ Logging Plugin shutdown');
  }
}

class BillingPlugin implements OVWIPlugin {
  @override
  String get name => 'OVWI Billing Plugin';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Usage-based billing and metering';

  @override
  List<String> get dependencies => ['ql', 'stripe'];

  @override
  Future<void> initialize() async {
    print('✅ Billing Plugin initialized');
  }

  @override
  Future<void> execute(Map<String, dynamic> config) async {
    final pricePerRequest = config['pricePerRequest'] ?? 0.01;
    final billingCycle = config['billingCycle'] ?? 'monthly';
    print('💰 Billing configured: \$${pricePerRequest}/req, cycle=$billingCycle');
  }

  @override
  Future<void> shutdown() async {
    print('⛔ Billing Plugin shutdown');
  }
}

class AnalyticsPlugin implements OVWIPlugin {
  @override
  String get name => 'OVWI Analytics Plugin';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Real-time analytics and insights';

  @override
  List<String> get dependencies => ['prometheus', 'grafana'];

  @override
  Future<void> initialize() async {
    print('✅ Analytics Plugin initialized');
  }

  @override
  Future<void> execute(Map<String, dynamic> config) async {
    final metricsInterval = config['metricsInterval'] ?? 60;
    final dashboardUrl = config['dashboardUrl'] ?? 'http://disabled:3000';
    print('📊 Analytics configured: interval=${metricsInterval}s, dashboard=$dashboardUrl');
  }

  @override
  Future<void> shutdown() async {
    print('⛔ Analytics Plugin shutdown');
  }
}

class PluginManager {
  final Map<String, OVWIPlugin> _plugins = {};
  final Map<String, PluginMetadata> _metadata = {};

  Future<void> loadPlugin(
    OVWIPlugin plugin,
    PluginMetadata metadata,
  ) async {
    _plugins[metadata.pluginId] = plugin;
    _metadata[metadata.pluginId] = metadata;
    
    if (metadata.enabled) {
      await plugin.initialize();
      print('✅ Plugin loaded: ${metadata.name} v${metadata.version}');
    }
  }

  Future<void> executePlugin(
    String pluginId,
    Map<String, dynamic> config,
  ) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) {
      print('❌ Plugin not found: $pluginId');
      return;
    }

    final metadata = _metadata[pluginId];
    if (metadata == null || !metadata.enabled) {
      print('⚠️ Plugin disabled: $pluginId');
      return;
    }

    await plugin.execute(config);
    print('✅ Plugin executed: $pluginId');
  }

  Future<void> unloadPlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin != null) {
      await plugin.shutdown();
      _plugins.remove(pluginId);
      print('✅ Plugin unloaded: $pluginId');
    }
  }

  List<PluginMetadata> listPlugins() {
    return _metadata.values.toList();
  }

  Map<String, dynamic> getPluginInfo(String pluginId) {
    final metadata = _metadata[pluginId];
    if (metadata == null) return {};
    return metadata.toJson();
  }

  Future<void> enablePlugin(String pluginId) async {
    final metadata = _metadata[pluginId];
    if (metadata != null) {
      metadata.enabled = true;
      final plugin = _plugins[pluginId];
      if (plugin != null) {
        await plugin.initialize();
        print('✅ Plugin enabled: $pluginId');
      }
    }
  }

  Future<void> disablePlugin(String pluginId) async {
    final metadata = _metadata[pluginId];
    if (metadata != null) {
      metadata.enabled = false;
      print('⛔ Plugin disabled: $pluginId');
    }
  }
}








