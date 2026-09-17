/// Data models and utilities for nested command folder hierarchies.
///
/// Folders use forward slash (`/`) as a delimiter, e.g. "Moderation/Bans".
library;

/// Normalizes a folder path by trimming segments, removing empty segments,
/// and joining with `/`.
String normalizeFolderPath(String? raw) {
  if (raw == null) return '';
  final segments = raw
      .split('/')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  return segments.join('/');
}

/// Extracts the display name (last segment) of a folder path.
String folderDisplayName(String path) {
  final normalized = normalizeFolderPath(path);
  if (normalized.isEmpty) return '';
  final segments = normalized.split('/');
  return segments.last;
}

/// Extracts the parent folder path of a given path, or empty string if top-level.
String folderParentPath(String path) {
  final normalized = normalizeFolderPath(path);
  final idx = normalized.lastIndexOf('/');
  if (idx == -1) return '';
  return normalized.substring(0, idx);
}

/// A node representing a folder (or subfolder) in the command hierarchy.
class CommandFolderNode {
  final String fullPath;
  final String name;
  final int depth;
  final String? parentPath;
  final List<CommandFolderNode> subfolders;
  final List<Map<String, dynamic>> commands;

  CommandFolderNode({
    required this.fullPath,
    required this.name,
    required this.depth,
    this.parentPath,
    List<CommandFolderNode>? subfolders,
    List<Map<String, dynamic>>? commands,
  }) : subfolders = subfolders ?? <CommandFolderNode>[],
       commands = commands ?? <Map<String, dynamic>>[];

  /// Total number of commands in this folder and all nested subfolders.
  int get totalCommandCount =>
      commands.length +
      subfolders.fold<int>(0, (sum, sub) => sum + sub.totalCommandCount);

  /// Checks if this folder or any of its subfolders contains commands.
  bool get hasCommands => totalCommandCount > 0;
}

/// Flattened representation of a folder for pickers and dropdowns.
class FlattenedFolderItem {
  final String fullPath;
  final String displayName;
  final int depth;

  const FlattenedFolderItem({
    required this.fullPath,
    required this.displayName,
    required this.depth,
  });

  /// Formatted label with indentation symbol for dropdowns / autocompletes.
  String get indentedLabel {
    if (depth == 0) return displayName;
    final indent = '  ' * depth;
    return '$indent↳ $displayName';
  }
}

/// Root result of building the folder tree.
class CommandFolderTreeResult {
  final List<Map<String, dynamic>> rootCommands;
  final List<CommandFolderNode> rootFolders;
  final Set<String> allFolderPaths;

  const CommandFolderTreeResult({
    required this.rootCommands,
    required this.rootFolders,
    required this.allFolderPaths,
  });

  /// Flattens the hierarchy into an ordered list with depth information.
  List<FlattenedFolderItem> flatten() {
    final list = <FlattenedFolderItem>[];
    void traverse(CommandFolderNode node) {
      list.add(
        FlattenedFolderItem(
          fullPath: node.fullPath,
          displayName: node.name,
          depth: node.depth,
        ),
      );
      for (final sub in node.subfolders) {
        traverse(sub);
      }
    }

    for (final root in rootFolders) {
      traverse(root);
    }
    return list;
  }
}

/// Builds a hierarchical folder tree from commands and empty folders.
CommandFolderTreeResult buildCommandFolderTree({
  required List<Map<String, dynamic>> commands,
  required Set<String> emptyFolders,
}) {
  final rootCommands = <Map<String, dynamic>>[];
  final allFolderPaths = <String>{};

  // Collect all folder paths and direct commands per path
  final commandsByFolder = <String, List<Map<String, dynamic>>>{};

  for (final cmd in commands) {
    final rawFolder = (cmd['folder'] ?? '').toString();
    final normalized = normalizeFolderPath(rawFolder);
    if (normalized.isEmpty) {
      rootCommands.add(cmd);
    } else {
      commandsByFolder.putIfAbsent(normalized, () => []).add(cmd);
      // Ensure all ancestor paths exist
      var current = normalized;
      while (current.isNotEmpty) {
        allFolderPaths.add(current);
        current = folderParentPath(current);
      }
    }
  }

  for (final empty in emptyFolders) {
    final normalized = normalizeFolderPath(empty);
    if (normalized.isNotEmpty) {
      var current = normalized;
      while (current.isNotEmpty) {
        allFolderPaths.add(current);
        current = folderParentPath(current);
      }
    }
  }

  // Create node map for all paths
  final nodeMap = <String, CommandFolderNode>{};
  for (final path in allFolderPaths) {
    final segments = path.split('/');
    final depth = segments.length - 1;
    final name = segments.last;
    final parent = depth > 0 ? folderParentPath(path) : null;
    nodeMap[path] = CommandFolderNode(
      fullPath: path,
      name: name,
      depth: depth,
      parentPath: parent,
      commands: commandsByFolder[path] ?? <Map<String, dynamic>>[],
    );
  }

  // Assemble parent-child relationships
  final rootFolders = <CommandFolderNode>[];
  final sortedPaths = allFolderPaths.toList()..sort();

  for (final path in sortedPaths) {
    final node = nodeMap[path]!;
    if (node.parentPath == null) {
      rootFolders.add(node);
    } else {
      final parentNode = nodeMap[node.parentPath];
      if (parentNode != null && !parentNode.subfolders.contains(node)) {
        parentNode.subfolders.add(node);
      }
    }
  }

  // Sort subfolders alphabetically at all levels
  void sortNodes(List<CommandFolderNode> list) {
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    for (final node in list) {
      sortNodes(node.subfolders);
    }
  }

  sortNodes(rootFolders);

  return CommandFolderTreeResult(
    rootCommands: rootCommands,
    rootFolders: rootFolders,
    allFolderPaths: allFolderPaths,
  );
}

/// Applies a cascading rename from [oldPath] to [newPath] on commands and empty folders.
void cascadeRenameFolder({
  required String oldPath,
  required String newPath,
  required List<Map<String, dynamic>> commands,
  required Set<String> emptyFolders,
  required void Function(Map<String, dynamic> updatedCommand) onUpdateCommand,
}) {
  final cleanOld = normalizeFolderPath(oldPath);
  final cleanNew = normalizeFolderPath(newPath);
  if (cleanOld.isEmpty || cleanNew.isEmpty || cleanOld == cleanNew) return;

  final oldPrefix = '$cleanOld/';

  // 1. Update commands
  for (final cmd in commands) {
    final current = normalizeFolderPath((cmd['folder'] ?? '').toString());
    if (current == cleanOld) {
      final updated = Map<String, dynamic>.from(cmd);
      updated['folder'] = cleanNew;
      onUpdateCommand(updated);
    } else if (current.startsWith(oldPrefix)) {
      final subSuffix = current.substring(oldPrefix.length);
      final updated = Map<String, dynamic>.from(cmd);
      updated['folder'] = '$cleanNew/$subSuffix';
      onUpdateCommand(updated);
    }
  }

  // 2. Update empty folders set
  final oldSet = Set<String>.from(emptyFolders);
  emptyFolders.clear();
  for (final f in oldSet) {
    final normalized = normalizeFolderPath(f);
    if (normalized == cleanOld) {
      emptyFolders.add(cleanNew);
    } else if (normalized.startsWith(oldPrefix)) {
      final subSuffix = normalized.substring(oldPrefix.length);
      emptyFolders.add('$cleanNew/$subSuffix');
    } else {
      emptyFolders.add(f);
    }
  }
}

/// Cascading deletion result: which commands should be updated (un-foldered) and
/// which empty folders should be removed.
void cascadeDeleteFolder({
  required String targetPath,
  required List<Map<String, dynamic>> commands,
  required Set<String> emptyFolders,
  required void Function(Map<String, dynamic> updatedCommand) onUpdateCommand,
}) {
  final cleanTarget = normalizeFolderPath(targetPath);
  if (cleanTarget.isEmpty) return;

  final targetPrefix = '$cleanTarget/';

  // Remove folder from commands matching targetPath or under targetPath
  for (final cmd in commands) {
    final current = normalizeFolderPath((cmd['folder'] ?? '').toString());
    if (current == cleanTarget || current.startsWith(targetPrefix)) {
      final updated = Map<String, dynamic>.from(cmd)..remove('folder');
      onUpdateCommand(updated);
    }
  }

  // Remove empty folders
  emptyFolders.removeWhere((f) {
    final normalized = normalizeFolderPath(f);
    return normalized == cleanTarget || normalized.startsWith(targetPrefix);
  });
}
