Client-side Friend Request Flow

Overview
- The Add Friend flow is now fully client-side and does not rely on Cloud Functions.
- When a user enters an email, the client queries `users` by `email` to resolve the target UID, and then creates a pending request document under the recipient's `users/{targetUid}/friends/{senderUid}` document.
- The recipient sees pending requests via the existing `getPendingFriendRequestsStream()` which lists `users/{uid}/friends` where `status == 'pending'`.
- Acceptance is performed by the recipient and updates their `users/{uid}/friends/{senderUid}` document to `status: 'accepted'` and writes a reciprocal accepted doc for the sender in a batched write.

Security (Firestore rules)
- Rules are updated in `firestore.rules` to:
  - Allow the sender (authenticated) to create a pending request under the recipient's friends collection only when the document ID equals the sender's uid and `status == 'pending'`.
  - Allow the recipient to update `status` from `pending` to `accepted` (and provide `acceptedAt` timestamp).
  - Allow either party to delete a pending request (cancel/decline).

Testing checklist (run on your dev machine/emulator)
1. Start a debug build on your emulator or device:

```bash
flutter run -d <device-id>
```

2. Open the Friends screen and press the Add Friend button.
3. Enter an email of an existing user (test account) and send the request.
   - Expected: you should see a SnackBar "Friend request sent!" and the callable should not be invoked.
4. On the target account (either on another device/emulator or a different profile), open Friends -> Requests and verify the pending request appears.
5. Accept the request on the target account.
   - Expected: both users should show each other in the Friends list (accepted state) and both `users/{uid}/friends/{otherUid}` docs should exist with `status: 'accepted'`.

Capture logs (adb)
- To collect logs while reproducing the flow (Android):

```bash
adb logcat -v time | grep -i "Friends" -i
```

Important notes
- If your production rules require stricter privacy (no direct `where('email', '==', ...)` queries from client), consider introducing a small `users_by_email/{normalizedEmail}` mapping document that contains only the UID for lookup.
- The client still uses other callables for admin/developer tools (in `lib/services/user_management_service.dart`). Those remain unchanged.

If you want me to run additional changes (remove `cloud_functions` dependency, migrate any admin callables to alternative flows, or add an optional `users_by_email` mapping), tell me and I'll implement them.