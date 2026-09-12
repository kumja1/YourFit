import 'package:langchain/langchain.dart';

class VectorStoreHybridSearch extends VectorStoreMMRSearch {
  final int semanticWeight;
  final int textWeight;

  const VectorStoreHybridSearch({
    this.textWeight = 1,
    this.semanticWeight = 1,
  });
}
