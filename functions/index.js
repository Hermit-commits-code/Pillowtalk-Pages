const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Aggregates user ratings for a book whenever a rating is written.
 */
exports.aggregateRating = onDocumentWritten(
  'ratings/{ratingId}',
  async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();
    const bookId = afterData?.bookId ?? beforeData?.bookId;

    if (!bookId) {
      logger.log('Rating document lacks a bookId. Cannot aggregate.');
      return;
    }

    const db = admin.firestore();
    const bookRef = db.collection('book_aggregates').doc(bookId);
    const ratingsQuery = db.collection('ratings').where('bookId', '==', bookId);

    const ratingsSnapshot = await ratingsQuery.get();

    if (ratingsSnapshot.empty) {
      logger.log('No ratings found for book. Deleting aggregate.', { bookId });
      await bookRef.delete();
      return;
    }

    // Aggregate the new Vetted Spice Meter data
    let totalSpice = 0.0;
    let totalEmotional = 0.0;
    let spiceCount = 0;
    let emotionalCount = 0;
    const genresSet = new Set();
    const tropesSet = new Set();
    const warningsSet = new Set();

    ratingsSnapshot.forEach((doc) => {
      const data = doc.data() || {};
      const spice = data.spiceOverall;
      const emotional = data.emotionalArc;
      if (typeof spice === 'number') {
        totalSpice += spice;
        spiceCount += 1;
      }
      if (typeof emotional === 'number') {
        totalEmotional += emotional;
        emotionalCount += 1;
      }
      if (Array.isArray(data.genres)) {
        data.genres.forEach((g) => {
          if (g != null) genresSet.add(String(g));
        });
      }
      if (Array.isArray(data.tropes)) {
        data.tropes.forEach((t) => {
          if (t != null) tropesSet.add(String(t));
        });
      }
      if (Array.isArray(data.warnings)) {
        data.warnings.forEach((w) => {
          if (w != null) warningsSet.add(String(w));
        });
      }
    });

    const totalUserRatings = ratingsSnapshot.size;
    const avgSpiceOnPage = spiceCount > 0 ? totalSpice / spiceCount : null;
    const avgEmotionalArc =
      emotionalCount > 0 ? totalEmotional / emotionalCount : null;

    const dataToUpdate = {
      totalUserRatings: totalUserRatings,
      avgSpiceOnPage: avgSpiceOnPage,
      avgEmotionalArc: avgEmotionalArc,
      genres: Array.from(genresSet),
      tropes: Array.from(tropesSet),
      warnings: Array.from(warningsSet),
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    };

    logger.log('Updating book aggregate (server).', {
      bookId,
      data: dataToUpdate,
    });

    await bookRef.set(dataToUpdate, { merge: true });
  },
);
