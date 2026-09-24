// LA BASE LOCALE — ET SON POINT D'OUVERTURE UNIQUE.
//
// POURQUOI CE FICHIER EXISTE : `databases/variables.db` était ouverte dans
// `SqliteVariableStore.init()`, c'est-à-dire à l'intérieur de la seule classe
// qui s'en servait. La file hors-ligne a besoin de la MÊME base — un fichier
// SQLite ne tolère pas deux ouvertures concurrentes avec deux jeux d'options
// différents (sqflite met en cache le descripteur gagnant et IGNORE les
// options suivantes), et une seconde base créerait deux sources de vérité
// locales. Le chemin, la version et le schéma vivent donc ici, une fois, et
// les deux dépôts l'appellent.
//
// LA VERSION 6 AJOUTE `command_outbox`, RIEN D'AUTRE. Les migrations des
// versions 1 à 5 sont reprises À L'IDENTIQUE de `SqliteVariableStore` : leur
// ordre et leur tolérance (des `try/catch` autour des `ALTER TABLE`, parce
// qu'une colonne peut déjà exister après une migration interrompue) décident
// de la survie des données d'un utilisateur qui met à jour, et les réécrire
// « plus proprement » serait prendre le risque de perdre des variables.
//
// CE FICHIER N'EST PAS UN DÉPÔT : il ouvre et il crée. Aucun accès aux
// données n'y vit — `SqliteVariableStore` et `CommandOutboxStore` s'en
// chargent, chacun sur son périmètre.

import 'package:bot_creator/core/storage/app_storage_directory.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Version du schéma de `databases/variables.db`.
///
/// 6 = l'ajout de `command_outbox` (la file hors-ligne).
const int variablesDatabaseSchemaVersion = 6;

/// Nom de la table de la file hors-ligne.
const String commandOutboxTableName = 'command_outbox';

/// Le schéma de la file, TEL QUE SPÉCIFIÉ (plan §5.2), sans colonne en plus.
///
/// LA CLÉ PRIMAIRE COMPOSITE EST LA PROMESSE DU GRANULAIRE : une ligne par
/// couple (bot, commande), donc « le dernier qui écrit gagne » PAR COMMANDE —
/// jamais par bot. Deux appareils qui éditent deux commandes différentes du
/// même bot ne s'écrasent pas mutuellement dans la file.
const String commandOutboxCreateSql = '''
  CREATE TABLE IF NOT EXISTS command_outbox (
    bot_id TEXT NOT NULL,
    command_id TEXT NOT NULL,
    payload_hash TEXT NOT NULL,
    payload_json TEXT NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    last_error TEXT NOT NULL DEFAULT '',
    created_at INTEGER NOT NULL,
    PRIMARY KEY (bot_id, command_id)
  )
''';

bool _ffiInitialized = false;

/// Ouvre (et crée au besoin) `databases/variables.db`.
///
/// IDEMPOTENT PAR CONSTRUCTION : deux appels rendent le MÊME descripteur
/// (sqflite en garde un par chemin). Les appelants ne doivent ni le fermer
/// l'un sans l'autre, ni supposer qu'ils en possèdent un personnel.
Future<Database> openVariablesDatabase() async {
  // sqflite sur poste de travail exige une initialisation FFI explicite.
  // Hors bureau, la fabrique est déjà celle de la plateforme (Android/iOS) :
  // c'est pourquoi la condition est la même que celle du dépôt des variables.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux)) {
    if (!_ffiInitialized) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _ffiInitialized = true;
    }
  }

  final docsDir = await getAppStorageDirectory();
  final dbPath = join(docsDir.path, 'databases', 'variables.db');

  final db = await openDatabase(
    dbPath,
    version: variablesDatabaseSchemaVersion,
    onCreate: (db, version) async {
      await createVariablesSchema(db);
      await ensureCommandOutboxTable(db);
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await migrateVariablesSchemaToV2(db);
      }
      if (oldVersion < 3) {
        await ensureVariablesSecondaryIndexes(db);
      }
      if (oldVersion < 4) {
        await addVariablesExpiresAtColumn(db);
      }
      if (oldVersion < 5) {
        await addVariablesExpiresAtColumn(db);
      }
      if (oldVersion < 6) {
        await ensureCommandOutboxTable(db);
      }
    },
  );

  // Filet APRÈS ouverture, comme pour la colonne `expires_at` : une base
  // ouverte par un binaire plus ancien, ou une migration interrompue, ne doit
  // pas rendre la file absente. Les deux instructions sont idempotentes.
  await ensureVariablesSecondaryIndexes(db);
  await addVariablesExpiresAtColumn(db);
  await ensureCommandOutboxTable(db);

  return db;
}

/// Crée la table `variables` (schéma complet, colonne `expires_at` incluse).
Future<void> createVariablesSchema(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE variables (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bot_id TEXT NOT NULL,
      scope TEXT NOT NULL,
      context_id_1 TEXT NOT NULL,
      context_id_2 TEXT,
      key TEXT NOT NULL,
      value_raw TEXT NOT NULL,
      value_type TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      expires_at INTEGER,
      UNIQUE(bot_id, scope, context_id_1, context_id_2, key),
      CHECK(scope IN ('_global_', 'guild', 'user', 'channel', 'guildMember', 'message'))
    )
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_bot_lookup ON variables(bot_id, scope, context_id_1, context_id_2)',
  );
  await ensureVariablesSecondaryIndexes(db);
}

/// Crée la file hors-ligne si elle n'est pas là. Idempotent.
Future<void> ensureCommandOutboxTable(DatabaseExecutor db) async {
  await db.execute(commandOutboxCreateSql);
}

Future<void> ensureVariablesSecondaryIndexes(DatabaseExecutor db) async {
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_scope_key_lookup ON variables(bot_id, scope, key)',
  );
}

/// Migration 1 → 2 : reconstruit `variables` avec la contrainte `UNIQUE` et le
/// `CHECK` sur `scope` (les lignes hors périmètre sont écartées, pas recopiées).
Future<void> migrateVariablesSchemaToV2(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE variables_v2 (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bot_id TEXT NOT NULL,
      scope TEXT NOT NULL,
      context_id_1 TEXT NOT NULL,
      context_id_2 TEXT,
      key TEXT NOT NULL,
      value_raw TEXT NOT NULL,
      value_type TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      UNIQUE(bot_id, scope, context_id_1, context_id_2, key),
      CHECK(scope IN ('_global_', 'guild', 'user', 'channel', 'guildMember', 'message'))
    )
  ''');

  await db.execute('''
    INSERT INTO variables_v2 (
      id, bot_id, scope, context_id_1, context_id_2, key, value_raw, value_type, created_at, updated_at
    )
    SELECT
      id, bot_id, scope, context_id_1, context_id_2, key, value_raw, value_type, created_at, updated_at
    FROM variables
    WHERE scope IN ('_global_', 'guild', 'user', 'channel', 'guildMember', 'message')
  ''');

  await db.execute('DROP TABLE variables');
  await db.execute('ALTER TABLE variables_v2 RENAME TO variables');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_bot_lookup ON variables(bot_id, scope, context_id_1, context_id_2)',
  );
}

/// Ajoute `expires_at`. L'échec est TOLÉRÉ : la colonne peut déjà exister
/// (migration interrompue, base créée par une autre branche), et refuser
/// l'ouverture pour cette raison fermerait l'accès aux variables.
Future<void> addVariablesExpiresAtColumn(DatabaseExecutor db) async {
  try {
    final rows = await db.rawQuery(
      "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'variables' LIMIT 1",
    );
    if (rows.isEmpty) return;
    final sql = (rows.first['sql'] as String?) ?? '';
    if (sql.contains('expires_at')) return;

    await db.execute('ALTER TABLE variables ADD COLUMN expires_at INTEGER');
  } catch (_) {}
}
