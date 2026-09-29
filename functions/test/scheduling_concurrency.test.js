const test = require('node:test');
const assert = require('node:assert/strict');
const admin = require('firebase-admin');
const { saveAppointment } = require('../scheduling');

// Never allow this integration test to touch a live Firebase project.
const projectId = 'demo-furfectcare-concurrency';

test('two independent clients racing for an overlapping slot: exactly one commits',
  { timeout: 90000 }, async () => {
    assert.ok(process.env.FIRESTORE_EMULATOR_HOST,
      'Run with firebase emulators:exec --only firestore. Live execution is forbidden.');
    assert.match(process.env.FIRESTORE_EMULATOR_HOST, /^(127\.0\.0\.1|localhost):\d+$/);
    const appA = admin.initializeApp({ projectId }, 'concurrency-client-a');
    const appB = admin.initializeApp({ projectId }, 'concurrency-client-b');
    const dbA = appA.firestore();
    const dbB = appB.firestore();
    try {
      const suffix = `${Date.now()}`;
      const ownerA = `race-owner-a-${suffix}`;
      const ownerB = `race-owner-b-${suffix}`;
      const petA = `race-pet-a-${suffix}`;
      const petB = `race-pet-b-${suffix}`;
      const appointmentA = `race-appointment-a-${suffix}`;
      const appointmentB = `race-appointment-b-${suffix}`;
      const date = '2099-10-01';
      const seed = dbA.batch();
      seed.set(dbA.doc(`users/${ownerA}`), { role: 'customer', approved: true });
      seed.set(dbA.doc(`users/${ownerB}`), { role: 'customer', approved: true });
      seed.set(dbA.doc(`pets/${petA}`), { ownerUid: ownerA });
      seed.set(dbA.doc(`pets/${petB}`), { ownerUid: ownerB });
      await seed.commit();

      const request = (id, ownerUid, petId, time) => ({
        operation: 'create', id,
        appointment: { ownerUid, petId, date, time, reason: 'Checkup',
          status: 'pending', assignedUserId: null },
      });
      // The two 30-minute windows overlap despite having different start times.
      // Independent Firestore clients exercise real emulator transactions;
      // no fake database, process-local lock, or mocked transaction is involved.
      const results = await Promise.allSettled([
        saveAppointment(dbA, ownerA, request(appointmentA, ownerA, petA, '09:00')),
        saveAppointment(dbB, ownerB, request(appointmentB, ownerB, petB, '09:15')),
      ]);
      const successes = results.filter(r => r.status === 'fulfilled');
      const failures = results.filter(r => r.status === 'rejected');
      assert.equal(successes.length, 1, 'Exactly one competing booking must succeed');
      assert.equal(failures.length, 1, 'Exactly one competing booking must fail');
      assert.equal(failures[0].reason.code, 'already-exists');
      assert.match(failures[0].reason.message, /Occupied slot/);

      const records = await dbA.collection('appointments').where('date', '==', date).get();
      assert.equal(records.size, 1, 'Only one appointment may be persisted for this race');
      assert.equal(records.docs[0].id, successes[0].value.id);
      assert.equal(records.docs[0].data().status, 'pending');
      console.log(`Race verified: winner=${successes[0].value.id}; ` +
        `loser=${failures[0].reason.code}; persisted=${records.size}`);
    } finally {
      await Promise.all([appA.delete(), appB.delete()]);
    }
  });
