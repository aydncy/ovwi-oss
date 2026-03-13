abstract class DomainEvent {
  final DateTime timestamp;
  final String aggregateId;
  
  DomainEvent({
    required this.timestamp,
    required this.aggregateId,
  });
}

class BlockAnchoredEvent extends DomainEvent {
  final String blockId;
  final String previousHash;
  final int sequence;
  
  BlockAnchoredEvent({
    required this.blockId,
    required this.previousHash,
    required this.sequence,
    required String aggregateId,
  }) : super(timestamp: DateTime.now().toUtc(), aggregateId: aggregateId);
}

class ApiKeyCreatedEvent extends DomainEvent {
  final String keyId;
  final String tier;
  final int rateLimit;
  
  ApiKeyCreatedEvent({
    required this.keyId,
    required this.tier,
    required this.rateLimit,
    required String aggregateId,
  }) : super(timestamp: DateTime.now().toUtc(), aggregateId: aggregateId);
}

typedef EventHandler<T extends DomainEvent> = Future<void> Function(T event);

class EventBus {
  final Map<Type, List<dynamic>> _handlers = {};
  
  void subscribe<T extends DomainEvent>(EventHandler<T> handler) {
    _handlers.putIfAbsent(T, () => []).add(handler);
  }
  
  Future<void> publish<T extends DomainEvent>(T event) async {
    final handlers = _handlers[T] as List<EventHandler<T>>?;
    if (handlers != null) {
      for (var handler in handlers) {
        await handler(event);
      }
    }
  }
}
