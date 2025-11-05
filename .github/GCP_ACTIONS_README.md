GitHub Actions deploy for Spicy-Reads

Quick start

1. In your repository settings on GitHub, add a secret named `GCP_SA_KEY` containing the full JSON of a service account key that has permissions to create Pub/Sub topics, update IAM, enable APIs, and deploy Cloud Functions. This can be the same `play-api-verifier` key if that account has adequate permissions, or a higher-privileged deploy account used only by CI.

2. Optionally, note the Play Console publisher service account email (when you link Play Console to your project you will see a service account like `service-<numbers>@gcp-sa-playdeveloper.iam.gserviceaccount.com`). You can pass it when running the workflow to automatically add pubsub publisher rights on the topic.

3. Open the Actions tab in GitHub, find the workflow 'Deploy Spicy-Reads Cloud Functions', choose 'Run workflow', and supply `play_service_account_email` if you have it. Run.

What the workflow does

- Enables necessary APIs (Play Developer / Pub/Sub / Functions / Secret Manager / Firestore)
- Creates the Pub/Sub topic `play-rtdn-topic` if it doesn't exist
- Optionally adds the Play Console service account as a publisher to the topic
- Grants `play-api-verifier@<PROJECT_ID>.iam.gserviceaccount.com` some common runtime roles (Secret Accessor, Datastore user, Logs writer)
- Deploys `verifyPurchase` (HTTP) and `handleRtdn` (Pub/Sub) Cloud Functions using the `functions/` folder as source

Notes & security

- The GitHub secret `GCP_SA_KEY` is sensitive: limit who can run Actions and prefer using a short-lived CI service account where possible.
- If you prefer not to store a JSON key in GitHub, consider using Workload Identity Federation or a dedicated CI identity.

If you want, I can also add a small GitHub Actions step to create a GitHub secret from the Cloud Console via an automation token — let me know.
