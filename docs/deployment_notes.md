# Deployment notes for subscription verification service

This file documents recommended deployment patterns for the Play subscription verification service (server-side) and RTDN handling.

Recommended architecture

- Use Cloud Run or Cloud Functions as the runtime for your verification service.
- Assign a dedicated service account (e.g. `play-api-verifier@PROJECT_ID.iam.gserviceaccount.com`) to the runtime with minimal IAM roles needed:
  - roles/pubsub.subscriber (if pulling messages)
  - roles/pubsub.viewer (optional)
  - roles/secretmanager.secretAccessor (to read the service account JSON key if stored there)
  - (When needed) roles/iam.serviceAccountTokenCreator (for impersonation flows)

Deployment approaches

A. Cloud Functions (quick):

- Use a HTTP function to accept purchase tokens from the app and perform verification using the Play API.
- Add a separate background function triggered by Pub/Sub messages from RTDN to reconcile subscription state.

Deploy example (gcloud):

```bash
# deploy HTTP function (node 18)
gcloud functions deploy verifyPurchase \
  --gen2 \
  --runtime=nodejs18 \
  --region=us-central1 \
  --entry-point=verifyPurchase \
  --trigger-http \
  --service-account=play-api-verifier@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --set-secrets=PLAY_API_KEY=projects/YOUR_PROJECT_ID/secrets/PLAY_API_KEY:latest

# deploy Pub/Sub consumer function
gcloud functions deploy handleRtdn \
  --gen2 \
  --runtime=nodejs18 \
  --region=us-central1 \
  --entry-point=handleRtdn \
  --trigger-topic=play-rtdn-topic \
  --service-account=play-api-verifier@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

B. Cloud Run (recommended for complex logic):

- Containerize your verifier code and deploy to Cloud Run. Use an HTTP endpoint for client-initiated verification and configure a separate service (or subscription) for RTDN handling.
- Cloud Run makes it easier to add more dependencies and manage concurrency.

Security

- Use Secret Manager to store sensitive values (service account JSON or other secrets). Grant the function/service account the `roles/secretmanager.secretAccessor` role so it can read secrets at runtime.
- Restrict Pub/Sub topic access using IAM bindings and only permit Play Console service account to publish.
- Use HTTPS-only endpoints and verify incoming requests using an application-level secret (for client->server verification endpoint) to prevent abuse.

CI/CD notes

- Add a CI step to deploy the function with the right service account and inject the required secrets.
- Do not store secrets in CI logs. Use encrypted secrets in your CI provider.

Testing & verification

- Use Play Console internal testing or license tester accounts to obtain purchase tokens.
- For RTDN, publish a test message to the topic and confirm that your handler processes it correctly:

```bash
gcloud pubsub topics publish play-rtdn-topic --message='{"test":"rtdn"}'
```

Troubleshooting

- If `purchases.subscriptions.get` returns 401/403: check that your service account is recognized by the Play Console and the service account has been granted Play Console access.
- If RTDN messages are not arriving: ensure Play Console RTDN configuration points to the correct `projects/YOUR_PROJECT_ID/topics/NAME` and that the Play Console service account has `roles/pubsub.publisher` on that topic.

Next steps I can do for you

- Scaffold the Cloud Function code and a small test harness that:
  - accepts a purchase token and calls `purchases.subscriptions.get`
  - stores/updates `users/{uid}.isPro` in Firestore after verification
  - adds a Pub/Sub-triggered function to reconcile RTDN messages

Would you like me to scaffold the Cloud Function and a small test harness now? I can also add automated unit tests for the verification logic (mocking Play API responses).
