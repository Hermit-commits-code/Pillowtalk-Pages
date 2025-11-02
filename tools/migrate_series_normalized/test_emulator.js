const fs = require('fs');
const path = require('path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');

async function runTests() {
  const projectId = 'pillowtalk-test-' + Date.now();
  const rules = fs.readFileSync(path.resolve(process.cwd(), '../../firestore.rules'), 'utf8');

  const testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });

  try {
    // Authenticated user A
    const alice = testEnv.authenticatedContext('alice-uid');
    const aliceDb = alice.firestore();

    // Authenticated user B
    const bob = testEnv.authenticatedContext('bob-uid');
    const bobDb = bob.firestore();

    // 1) Alice should be allowed to create her user doc
    await assertSucceeds(aliceDb.collection('users').doc('alice-uid').set({ name: 'Alice' }));

    // 2) Alice should NOT be allowed to create Bob's user doc
    await assertFails(aliceDb.collection('users').doc('bob-uid').set({ name: 'Evil' }));

    // 3) Alice can add to her library
    await assertSucceeds(aliceDb.collection('users').doc('alice-uid').collection('library').doc('book1').set({ addedAt: 1 }));

    // 4) Alice cannot write to books (community) collection
    await assertFails(aliceDb.collection('books').doc('book1').set({ title: 'X', avgSpice: 5 }));

    // 5) Top-level ratings: Alice can create rating that claims her UID
    await assertSucceeds(aliceDb.collection('ratings').doc('r1').set({ userId: 'alice-uid', bookId: 'book1', spice: 3 }));

    // 6) Alice cannot create a rating that claims Bob's UID
    await assertFails(aliceDb.collection('ratings').doc('r2').set({ userId: 'bob-uid', bookId: 'book1', spice: 2 }));

    console.log('All emulator rule checks completed (expected results).');
  } finally {
    await testEnv.cleanup();
  }
}

runTests().catch(err => {
  console.error('Emulator tests failed:', err);
  process.exit(1);
});
