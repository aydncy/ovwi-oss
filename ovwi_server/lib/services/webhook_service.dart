enum WebhookEvent {
  userCreated,
  userDeleted,
  tokenGenerated,
  tokenRevoked,
  apiLimitExceeded,
  apiCallMade,
  authorizationGranted,
  authorizationDenied,
}

class WebhookEndpoint {
  final String webhookId;
  final String url;
  final List<WebhookEvent> events;
  final String? secret;
  final bool active;
  final DateTime createdAt;
  int deliveryCount = 0;
  int failureCount = 0;

  WebhookEndpoint({
    required this.webhookId,
    required this.url,
    required this.events,
    this.secret,
    this.active = true,
    required this.createdAt,
  });

  double get successRate => deliveryCount == 0 
    ? 0 
    : ((deliveryCount - failureCount) / deliveryCount) * 100;

  Map<String, dynamic> toJson() => {
    'webhookId': webhookId,
    'url': url,
    'events': events.map((e) => e.toString().split('.').last).toList(),
    'active': active,
    'createdAt': createdAt.toIso8601String(),
    'deliveryCount': deliveryCount,
    'failureCount': failureCount,
    'successRate': '${successRate.toStringAsFixed(2)}%',
  };
}

class WebhookPayload {
  final WebhookEvent event;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String eventId;

  WebhookPayload({
    required this.event,
    required this.data,
    required this.timestamp,
    required this.eventId,
  });

  Map<String, dynamic> toJson() => {
    'event': event.toString().split('.').last,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'eventId': eventId,
  };
}

class WebhookService {
  final Map<String, WebhookEndpoint> _webhooks = {};
  final List<WebhookPayload> _eventLog = [];

  void registerWebhook({
    required String url,
    required List<WebhookEvent> events,
    String? secret,
  }) {
    final webhookId = 'webhook_${DateTime.now().millisecondsSinceEpoch}';
    final webhook = WebhookEndpoint(
      webhookId: webhookId,
      url: url,
      events: events,
      secret: secret,
      createdAt: DateTime.now(),
    );

    _webhooks[webhookId] = webhook;
    print('✅ Webhook registered: $webhookId');
    print('   URL: $url');
    print('   Events: ${events.map((e) => e.toString().split('.').last).join(", ")}');
  }

  Future<void> triggerEvent(WebhookEvent event, Map<String, dynamic> data) async {
    final eventId = 'evt_${DateTime.now().millisecondsSinceEpoch}';
    final payload = WebhookPayload(
      event: event,
      data: data,
      timestamp: DateTime.now(),
      eventId: eventId,
    );

    _eventLog.add(payload);

    // Find matching webhooks
    for (var webhook in _webhooks.values) {
      if (webhook.active && webhook.events.contains(event)) {
        await _deliverWebhook(webhook, payload);
      }
    }

    print('✅ Event triggered: ${event.toString().split('.').last}');
  }

  Future<void> _deliverWebhook(WebhookEndpoint webhook, WebhookPayload payload) async {
    try {
      // Simulate webhook delivery
      print('   📤 Delivering to: ${webhook.url}');
      
      webhook.deliveryCount++;
      print('   ✅ Webhook delivered');
    } catch (e) {
      webhook.failureCount++;
      print('   ❌ Webhook delivery failed: $e');
    }
  }

  List<WebhookEndpoint> listWebhooks() {
    return _webhooks.values.toList();
  }

  Map<String, dynamic> getWebhookStats(String webhookId) {
    final webhook = _webhooks[webhookId];
    if (webhook == null) return {};

    return webhook.toJson();
  }

  void deactivateWebhook(String webhookId) {
    final webhook = _webhooks[webhookId];
    if (webhook != null) {
      _webhooks[webhookId] = WebhookEndpoint(
        webhookId: webhook.webhookId,
        url: webhook.url,
        events: webhook.events,
        secret: webhook.secret,
        active: false,
        createdAt: webhook.createdAt,
      );
      print('⛔ Webhook deactivated: $webhookId');
    }
  }

  List<WebhookPayload> getEventLog({String? webhookId, int limit = 100}) {
    return _eventLog.take(limit).toList();
  }

  Map<String, dynamic> getWebhookPerformance(String webhookId) {
    final webhook = _webhooks[webhookId];
    if (webhook == null) return {};

    return {
      'webhookId': webhookId,
      'url': webhook.url,
      'deliveryCount': webhook.deliveryCount,
      'failureCount': webhook.failureCount,
      'successRate': '${webhook.successRate.toStringAsFixed(2)}%',
      'status': webhook.active ? 'active' : 'inactive',
    };
  }
}
