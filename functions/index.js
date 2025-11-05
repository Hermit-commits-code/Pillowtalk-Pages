const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Aggregates user ratings for a book whenever a rating is written.
 */
exports.aggregateRating = onDocumentWritten("ratings/{ratingId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  const bookId = afterData?.bookId ?? beforeData?.bookId;

  if (!bookId) {
    logger.log("Rating document lacks a bookId. Cannot aggregate.");
    return;
  }

  const db = admin.firestore();
  const bookRef = db.collection("book_aggregates").doc(bookId);
  const ratingsQuery = db.collection("ratings").where("bookId", "==", bookId);

  const ratingsSnapshot = await ratingsQuery.get();

  if (ratingsSnapshot.empty) {
    logger.log("No ratings found for book. Deleting aggregate.", {bookId});
    await bookRef.delete();
    return;
  }

  // Aggregate the new Vetted Spice Meter data
  let totalOverallSpice = 0;
  let totalEmotionalArc = 0;
  const intensityVotes = {};
  const genreVotes = {};
  let ratingCount = 0;

  ratingsSnapshot.forEach((doc) => {
    const data = doc.data();
    if (typeof data?.spiceOverall === "number") {
      totalOverallSpice += data.spiceOverall;
      ratingCount++;
    }
    if (typeof data?.emotionalArc === "number") {
      totalEmotionalArc += data.emotionalArc;
    }
    if (data?.spiceIntensity) {
      intensityVotes[data.spiceIntensity] = (intensityVotes[data.spiceIntensity] || 0) + 1;
    }
    if (Array.isArray(data?.genres)) {
      data.genres.forEach((genre) => {
        genreVotes[genre] = (genreVotes[genre] || 0) + 1;
      });
    }
  });

  const avgOverallSpice = ratingCount > 0 ? totalOverallSpice / ratingCount : 0;
  const avgEmotionalArc = ratingCount > 0 ? totalEmotionalArc / ratingCount : 0;

  // Find the top voted intensity and genre
  const topIntensity = Object.keys(intensityVotes).reduce((a, b) => intensityVotes[a] > intensityVotes[b] ? a : b, "");
  const topGenres = Object.keys(genreVotes).sort((a, b) => genreVotes[b] - genreVotes[a]);

  const dataToUpdate = {
    avgSpiceOverall: avgOverallSpice,
    avgEmotionalArc: avgEmotionalArc,
    topSpiceIntensity: topIntensity,
    genreVotes: genreVotes, // Store all votes for potential future use
    topGenres: topGenres.slice(0, 5), // Store top 5 genres
    totalUserRatings: ratingCount,
  };

  logger.log("Updating book aggregate.", {bookId, data: dataToUpdate});

  await bookRef.set(dataToUpdate, {merge: true});
});
