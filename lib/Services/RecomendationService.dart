
import 'package:cloud_firestore/cloud_firestore.dart';

import '../FbObjects/FbPost.dart';

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<FbPost>> getRecommendationsForPost(FbPost currentPost, {int maxResults = 5}) async {
    final allPostsSnapshot = await _firestore.collection('Posts').get();

    List<FbPost> allPosts = allPostsSnapshot.docs
        .map((doc) => FbPost.fromFirestore(doc))
        .where((post) => post.uid != currentPost.uid && post.sAutorUid != currentPost.sAutorUid)
        .toList();

    // Calculamos la similitud para cada post
    allPosts.sort((a, b) {
      int scoreA = _calculateSimilarity(currentPost, a);
      int scoreB = _calculateSimilarity(currentPost, b);
      return scoreB.compareTo(scoreA);
    });

    // Devolvemos los N mejores
    return allPosts.take(maxResults).toList();
  }

  int _calculateSimilarity(FbPost a, FbPost b) {
    int score = 0;

    // 1. Coincidencia de artista
    if (a.artista.toLowerCase() == b.artista.toLowerCase()) {
      score += 3;
    }

    // 2. Coincidencia en al menos un género
    if (a.categoria.any((genre) => b.categoria.contains(genre))) {
      score += 2;
    }

    // 3. Año cercano
    if ((a.anio - b.anio).abs() <= 3) {
      score += 1;
    }

    return score;
  }
}
