/*
  Simple local helper to call the Play Developer API using the same logic as the functions scaffold.
  Usage:
    node verify_sub.js <packageName> <subscriptionId> <purchaseToken>

  Requires environment variables when run locally:
    - PROJECT_ID or GCLOUD_PROJECT
    - SECRET_NAME (optional, default PLAY_API_KEY_JSON)
    - or GOOGLE_APPLICATION_CREDENTIALS pointing to a service account JSON
*/

const fetch = require('node-fetch');
const {SecretManagerServiceClient} = require('@google-cloud/secret-manager');
const {google} = require('googleapis');

async function getAuth() {
  const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || process.env.PROJECT_ID || '511866750127';
  const secretName = process.env.SECRET_NAME || 'PLAY_API_KEY_JSON';
  try {
    return new google.auth.GoogleAuth({scopes: ['https://www.googleapis.com/auth/androidpublisher']});
  } catch (_) {
    // try secret manager
    const client = new SecretManagerServiceClient();
    const name = `projects/${projectId}/secrets/${secretName}/versions/latest`;
    const [version] = await client.accessSecretVersion({name});
    const payload = version.payload && version.payload.data ? Buffer.from(version.payload.data, 'base64').toString('utf8') : null;
    const credentials = JSON.parse(payload);
    return new google.auth.GoogleAuth({credentials, scopes: ['https://www.googleapis.com/auth/androidpublisher']});
  }
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length < 3) {
    console.error('Usage: node verify_sub.js <packageName> <subscriptionId> <purchaseToken>');
    process.exit(2);
  }
  const [packageName, subscriptionId, purchaseToken] = args;
  const auth = await getAuth();
  const androidpublisher = google.androidpublisher({version: 'v3', auth});
  const res = await androidpublisher.purchases.subscriptions.get({packageName, subscriptionId, token: purchaseToken});
  console.log(JSON.stringify(res.data, null, 2));
}

main().catch(err => {
  console.error(err && (err.stack || err.message || err));
  process.exit(1);
});
