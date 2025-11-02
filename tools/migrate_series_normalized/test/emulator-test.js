const fs = require('fs');
const path = require('path');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');

async function runTests() {
  const rulesPath = path.resolve(__dirname, '../../../firestore.rules');
  const rules = fs.readFileSync(rulesPath, 'utf8');
  const testEnv = await initializeTestEnvironment({
    projectId: 'pillowtalk-emulator-test',
    firestore: { rules }
  });

  // Authenticated as alice
  const alice = testEnv.authenticatedContext('alice', {});
  const aliceDb = alice.firestore();

  // alice should be able to write to her own user doc
  await assertSucceeds(aliceDb.collection('users').doc('alice').set({ name: 'Alice' }));

  // alice should NOT be able to create a user doc for bob
  await assertFails(aliceDb.collection('users').doc('bob').set({ name: 'Bob' }));

  // alice should be able to write to her library
  await assertSucceeds(aliceDb.collection('users').doc('alice').collection('library').doc('book1').set({ addedAt: Date.now() }));

  // alice should NOT be able to write to books collection (client-side blocked)
  await assertFails(aliceDb.collection('books').doc('book1').set({ title: 'X' }));

  // alice should NOT be able to write to book_aggregates either
  await assertFails(aliceDb.collection('book_aggregates').doc('book1').set({ title: 'X' }));

  // If admin context exists with custom claim admin=true, writes should succeed
  const adminCtx = testEnv.authenticatedContext('adminUser', { admin: true });
  const adminDb = adminCtx.firestore();
  await assertSucceeds(adminDb.collection('books').doc('book1').set({ title: 'Admin created' }));
  // admin may also write aggregates
  await assertSucceeds(adminDb.collection('book_aggregates').doc('book1').set({ title: 'Aggregated' }));

  // Public (unauthenticated) reads should be allowed on book_aggregates
  const unauth = testEnv.unauthenticatedContext();
  const unauthDb = unauth.firestore();
  await assertSucceeds(unauthDb.collection('book_aggregates').doc('book1').get());

  await testEnv.cleanup();
  console.log('Emulator tests passed (asserts completed)');
}

runTests().catch(err => {
  console.error('Emulator tests failed:', err);
  process.exit(1);
});
