import 'domain_events.dart';

class BlockAnchoredEventHandler {
  Future<void> handle(BlockAnchoredEvent event) async {
    print('[EVENT] Block Anchored: ');
    print('  Sequence: ');
    print('  Timestamp: ');
  }
}

class ApiKeyCreatedEventHandler {
  Future<void> handle(ApiKeyCreatedEvent event) async {
    print('[EVENT] API Key Created: ');
    print('  Tier: ');
    print('  Rate Limit: ');
  }
}
