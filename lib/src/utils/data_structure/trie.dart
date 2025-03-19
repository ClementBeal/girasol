class TrieNode {
  final Map<String, TrieNode> children = {};
  bool isEndOfWord = false;
}

/// Data structure to store strings in an efficient way
/// The goal is to reduce the memory usage. It usually uses less
/// memory than a set.
class Trie {
  final TrieNode root = TrieNode();

  /// Insert the [word] into the trie
  void insert(String word) {
    TrieNode current = root;

    for (var char in word.split("")) {
      current.children.putIfAbsent(char, () => TrieNode());
      current = current.children[char]!;
    }

    current.isEndOfWord = true;
  }

  /// Check if the [word] is present in the trie
  bool exists(String word) {
    TrieNode current = root;

    for (var char in word.split("")) {
      if (!current.children.containsKey(char)) return false;

      current = current.children[char]!;
    }

    return current.isEndOfWord;
  }

  /// Return the first word and remove it from the trie
  String? pop() {
    TrieNode current = root;
    StringBuffer wordBuffer = StringBuffer();
    List<TrieNode> path = [];
    List<String> pathChars = [];

    while (true) {
      if (current.isEndOfWord) {
        current.isEndOfWord = false;
        break;
      }

      if (current.children.isEmpty) {
        return null; // Trie is empty
      }

      String nextChar = current.children.keys.first;
      path.add(current);
      pathChars.add(nextChar);
      current = current.children[nextChar]!;
      wordBuffer.write(nextChar);
    }

    // Clean up empty nodes
    for (int i = path.length - 1; i >= 0; i--) {
      TrieNode parent = path[i];
      String char = pathChars[i];

      if (parent.children[char]!.children.isEmpty &&
          !parent.children[char]!.isEndOfWord) {
        parent.children.remove(char);
      } else {
        break;
      }
    }

    return wordBuffer.toString();
  }
}
