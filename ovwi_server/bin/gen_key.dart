import '../lib/core/auth_engine.dart';

void main() {

  final key = OvwiAuthEngine.generateApiKey();

  print("Generated key:");
  print(key);

  print("\nHash for DB:");
  print(OvwiAuthEngine.hashKey(key));

}