import 'dart:math' as math;
import 'package:extensions_plus/extensions_plus.dart';
import 'package:http/http.dart' as http;
import 'package:langchain/langchain.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yourfit/src/utils/index.dart';

/// {@template supabase}
/// Vector store for [Supabase Vector](https://supabase.com/vector)
/// embedding database.
///
/// It assumes a database with the `pg_vector` extension,
/// containing a [tableName] (default: `documents`) and
/// a [postgresFunctionName] (default: `match_documents`)
/// defined as follows:
///
/// ```sql
///  -- Enable the "vector" extension
/// create extension vector
/// with
///   schema extensions;
///
/// -- Create table to store the documents
/// create table documents (
///   id bigserial primary key,
///   content text,
///   metadata jsonb,
///   embedding vector(1536)
/// );
///
/// -- Create PostgreSQL function to query documents
/// create or replace function match_documents (
///   query_embedding vector(1536),
///   match_count int,
///   match_threshold float,
///   filter jsonb
/// ) returns table (
///   id bigint,
///   content text,
///   metadata jsonb,
///   similarity float
/// )
/// language sql stable
/// as $$
///   select
///     documents.id,
///     documents.content,
///     documents.metadata,
///     1 - (documents.embedding <=> query_embedding) as similarity
/// from documents
/// where metadata @> filter
///   and 1 - (documents.embedding <=> query_embedding) > match_threshold
/// order by (documents.embedding <=> query_embedding) asc
///     limit match_count;
/// $$;
/// ```
///
/// See documentation for more details:
/// - [LangChain.dart Supabase docs](https://langchaindart.dev/#/modules/retrieval/vector_stores/integrations/supabase)
/// - [Supabase Vector docs](https://supabase.com/docs/guides/ai)
/// {@endtemplate}
class Supabase extends VectorStore {
  /// Creates a new [Supabase] instance.
  ///
  /// Main configuration options:
  /// - [tableName] (default: `documents`): the Supabase table name.
  /// - `supabaseUrl`: the Supabase URL. You can find it in your project's
  ///   [API settings](https://supabase.com/dashboard/project/_/settings/api).
  ///   E.g. `https://xyzcompany.supabase.co`.
  /// - `supabaseKey`: the Supabase API key. You can find it in your project's
  ///   [API settings](https://supabase.com/dashboard/project/_/settings/api).
  ///
  /// Advance configuration options:
  /// - `headers`: overrides the default Supabase client headers.
  /// - `client`: the HTTP client to use. You can set your own HTTP client if
  ///   you need further customization (e.g. to use a Socks5 proxy).
  Supabase({
    this.tableName = 'documents',
    required  String supabaseUrl,
    required  String supabaseKey,
     Map<String, String> headers = const {},
     http.Client? client,
    required super.embeddings,
  }) : _client = SupabaseClient(
         supabaseUrl,
         supabaseKey,
         headers: headers,
         httpClient: client,
       );

  /// The Supabase client.
  final SupabaseClient _client;

  /// The Supabase table name.
  final String tableName;

  /// The name of the PostgreSQL function that executes the query.
  final postgresFunctionName = 'match_documents';

  /// Returns docs most similar to query using specified search type.
  ///
  /// - [query] is the query to search for.
  /// - [searchType] is the type of search to perform, either
  ///   [VectorStoreSearchType.similarity] (default) or
  ///   [VectorStoreSearchType.mmr].
  @override
  Future<List<Document>> search({
    required  String query,
    required  VectorStoreSearchType searchType,
  }) async {
    try {
      final queryEmbedding = await embeddings.embedQuery(query);

      final docs = await switch (searchType) {
        VectorStoreSimilaritySearch config =>
          similaritySearchByVectorWithScores(
            embedding: queryEmbedding,
            config: config,
          ),
        VectorStoreHybridSearch config => hybridSearch(
          query: query,
          embedding: queryEmbedding,
          config: config,
        ),
        VectorStoreMMRSearch config => maxMarginalRelevanceSearchByVectorAsync(
          embedding: queryEmbedding,
          config: config,
        ),
      };
      return docs as List<Document>;
    } catch (e) {
      logger.severe("Error during search", e);
      return [];
    }
  }

  @override
  Future<List<String>> addVectors({
    required  List<List<double>> vectors,
    required  List<Document> documents,
  }) async {
    try {
      assert(vectors.length == documents.length);

      final List<Map<String, dynamic>> records = [];
      for (var i = 0; i < documents.length; i++) {
        final doc = documents[i];
        records.add({
          if (doc.id != null) 'id': doc.id,
          'metadata': doc.metadata,
          'content': doc.pageContent,
          'embedding': vectors[i],
        });
      }

      final ids = await _client.from(tableName).upsert(records).select('id');
      return ids
          .map(( row) => row['id'])
          .map(( id) => id.toString())
          .toList(growable: false);
    } catch (e) {
      logger.severe("Error adding vectors", e);
      return [];
    }
  }

  @override
  Future<void> delete({required  List<String> ids}) {
    return _client.from(tableName).delete().filter('id', 'in', ids);
  }

  @override
  Future<List<(Document, double similarity)>>
  similaritySearchByVectorWithScores({
    required  List<double> embedding,
     VectorStoreSimilaritySearch config =
        const VectorStoreSimilaritySearch(),
  }) async {
    try {
      final result = await similaritySearchByVectorWithScoresAndEmbeddings(
        embedding: embedding,
        config: config,
      );
      return result
          .map((doc) => (doc.document, doc.similarity))
          .toList(growable: false);
    } catch (e) {
      logger.severe("Error during similarity search with scores", e);
      return [];
    }
  }

  Future<
    List<({Document document, List<double> embeddings, double similarity})>
  >
  similaritySearchByVectorWithScoresAndEmbeddings({
    required  List<double> embedding,
     VectorStoreSimilaritySearch config =
        const VectorStoreSimilaritySearch(),
  }) async {
    try {
      final params = {
        'query_embedding': embedding,
        'match_count': config.k,
        'match_threshold': config.scoreThreshold ?? 0.0,
        'filter': config.filter ?? {},
      };

      final List<dynamic> result = await _client.rpc(
        postgresFunctionName,
        params: params,
      );

      return result
          .map(( row) => row as Map<String, dynamic>)
          .map(
            ( row) => (
              document: Document(
                id: row['id'].toString(),
                pageContent: row['content'] as String,
                metadata: row['metadata'] as Map<String, dynamic>,
              ),
              embeddings: List.from(
                row["embedding"],
                growable: false,
              ).cast<double>(),
              similarity: row['similarity'] as double,
            ),
          )
          .toList(growable: false);
    } catch (e) {
      logger.severe("Error during similarity search with scores and embeddings", e);
      return [];
    }
  }

  Future<List<Document>> maxMarginalRelevanceSearchByVectorAsync({
    required  List<double> embedding,
     VectorStoreMMRSearch config = const VectorStoreMMRSearch(),
  }) async {
    try {
      logger.info(
        "MMR search: fetching ${config.fetchK} candidates, target: ${config.k}, λ: ${config.lambdaMult}",
      );

      List<({Document document, List<double> embeddings, double similarity})>
      docs = await similaritySearchByVectorWithScoresAndEmbeddings(
        embedding: embedding,
        config: VectorStoreSimilaritySearch(k: config.fetchK),
      );

      if (docs.isEmpty) {
        logger.info("MMR: no documents retrieved");
        return [];
      }

      final List<List<double>> embeddings = [
        ...docs.map((doc) => doc.embeddings),
      ];

      logger.info("MMR: ${embeddings.length} embeddings retrieved");
      logger.info(
        "MMR: initial similarities: ${docs.map((d) => d.similarity.toStringAsFixed(3)).join(', ')}",
      );

      final mostSimilarEmbeddingIndex = getIndexesMostSimilarEmbeddings(
        embedding,
        embeddings,
      ).first;

      logger.info(
        "MMR: starting with most similar index $mostSimilarEmbeddingIndex",
      );

      final selectedEmbeddings = [embeddings[mostSimilarEmbeddingIndex]];
      final selectedEmbeddingsIndexes = [mostSimilarEmbeddingIndex];
      final similaritiesAndIndexes = docs.toIndexMap().map(
        (index, doc) => MapEntry(index, doc.similarity),
      );

      logger.info(
        "MMR: similarity map keys: ${similaritiesAndIndexes.keys.toList()}",
      );

      int iteration = 0;
      while (selectedEmbeddingsIndexes.length <
          math.min(config.k, embeddings.length)) {
        iteration++;
        logger.info("\n--- MMR Iteration $iteration ---");
        logger.info("Current selection: ${selectedEmbeddingsIndexes.join(', ')}");

        double bestScore = double.negativeInfinity;
        int bestIndex = -1;

        try {
          final similarityToSelected = [
            ...embeddings.map(
              (e) => calculateSimilarity(e, selectedEmbeddings),
            ),
          ];

          logger.info(
            "Similarity matrix: ${similarityToSelected.length} rows × ${similarityToSelected.first.length} cols",
          );

          int candidatesChecked = 0;
          similaritiesAndIndexes.forEach((index, similarityScore) {
            if (selectedEmbeddingsIndexes.contains(index)) {
              return;
            }

            candidatesChecked++;

            final maxSimilarityToSelected = similarityToSelected[index].maxBy(
              (value) => value,
            );

            final score =
                config.lambdaMult * similarityScore -
                (1 - config.lambdaMult) * maxSimilarityToSelected!;

            if (score > bestScore) {
              bestScore = score;
              bestIndex = index;
              logger.info("  ^ NEW BEST");
            }
          });

          logger.info("Checked $candidatesChecked candidates");

          if (bestIndex == -1) {
            logger.info("No valid candidate found, breaking");
            break;
          }

          selectedEmbeddings.add(embeddings[bestIndex]);
          selectedEmbeddingsIndexes.add(bestIndex);
          logger.info(
            "Selected index $bestIndex with MMR score ${bestScore.toStringAsFixed(3)}",
          );
        } catch (e) {
          logger.severe("MMR iteration $iteration error", e);
          break;
        }
      }
      return docs.indexed
          .where((item) => selectedEmbeddingsIndexes.contains(item.$1))
          .map((item) => item.$2.document)
          .toList();
    } catch (e) {
      logger.severe("Error during MMR search", e);
      return [];
    }
  }

  Future<List<Document>> hybridSearch({
    required String query,
    required List<double> embedding,
     VectorStoreHybridSearch config = const VectorStoreHybridSearch(),
  }) async {
    try {
      return await hybridSearchByVector(
        query: query,
        embedding: embedding,
        config: config,
      );
    } catch (e) {
      logger.severe("Error during hybrid search", e);
      return [];
    }
  }

  Future<List<Document>> hybridSearchByVector({
    required String query,
    required List<double> embedding,
    required VectorStoreHybridSearch config,
  }) async {
    final params = {
      'query_text': query,
      'query_embedding': embedding,
      'match_count': config.fetchK,
      "full_text_weight": config.textWeight,
      "semantic_weight": config.semanticWeight,
      "rrf_k": 50,
    };

    try {
      final List<dynamic> result = await _client.rpc(
        postgresFunctionName,
        params: params,
      );

      return result
          .map(( row) => row as Map<String, dynamic>)
          .map(
            ( row) => Document(
              id: row['id'].toString(),
              pageContent: row['content'] as String,
              metadata: row['metadata'] as Map<String, dynamic>,
            ),
          )
          .toList(growable: false);
    } catch (e) {
      logger.severe("Error during hybrid search by vector", e);
      return [];
    }
  }
}
