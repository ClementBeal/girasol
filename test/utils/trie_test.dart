import 'package:girasol/src/utils/data_structure/trie.dart';
import 'package:test/test.dart';

void main() {
  group("trie", () {
    test("insert & exist", () {
      final trie = Trie();

      trie.insert("hello");
      trie.insert("helloworld");

      expect(trie.exists("hello"), isTrue);
      expect(trie.exists("helloworld"), isTrue);
      expect(trie.exists("hellowo"), isFalse);
    });

    test("pop", () {
      final trie = Trie();

      trie.insert("hello");

      expect(trie.pop(), "hello");
      expect(trie.pop(), isNull);
    });
  });
}
