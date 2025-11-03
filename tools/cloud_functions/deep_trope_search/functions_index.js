const functions = require('firebase-functions');
const { app } = require('./index');

// Export as an HTTP function for Firebase Functions deployment
exports.searchTropes = functions.https.onRequest(app);
