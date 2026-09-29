const { HttpsError } = require('firebase-functions').https;
const terminal = new Set(['cancelled', 'canceled', 'cancel', 'rejected', 'reject',
  'completed', 'complete', 'done', 'no_show']);
const active = a => !terminal.has((a.status || '').toLowerCase());
const day = a => (a.date || '').split('T')[0];
function minute(a) {
  const m = /^(\d{1,2}):(\d{2})(?::(\d{2}))?$/.exec(a.time || '');
  return m && +m[1] < 24 && +m[2] < 60 ? +m[1] * 60 + +m[2] : NaN;
}
const fields = ['petId', 'ownerUid', 'assignedUserId', 'date', 'time', 'reason', 'status'];
function validate(a) {
  if (!a || Object.keys(a).some(k => !fields.includes(k))) {
    throw new HttpsError('invalid-argument', 'Invalid appointment fields.');
  }
  for (const key of fields.filter(k => k !== 'assignedUserId')) {
    if (typeof a[key] !== 'string' || !a[key].trim() || a[key].length > 4000) {
      throw new HttpsError('invalid-argument', `Invalid ${key}.`);
    }
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(a.date) || !Number.isFinite(Date.parse(a.date)) ||
      new Date(a.date).toISOString().slice(0, 10) !== a.date || !Number.isFinite(minute(a))) {
    throw new HttpsError('invalid-argument', 'Use a valid date and 24-hour time.');
  }
  if (!['pending', 'confirmed', 'scheduled', 'assigned', 'completed', 'cancelled',
    'rejected', 'rescheduled', 'no_show'].includes(a.status) ||
    (a.assignedUserId != null && typeof a.assignedUserId !== 'string')) {
    throw new HttpsError('invalid-argument', 'Invalid status or assignee.');
  }
}
function id(value) {
  if (typeof value !== 'string' || !value || value.includes('/') || value.length > 200) {
    throw new HttpsError('invalid-argument', 'Invalid record identifier.');
  }
  return value;
}

// One shared lock serializes ALL appointment mutations, including legacy rows.
// Keep every read before writes. No process-local mutex or client availability
// snapshot is trusted. Partition by day only after canonicalizing legacy dates.
async function saveAppointment(db, uid, input) {
  if (!uid) throw new HttpsError('unauthenticated', 'Please sign in.');
  if (!['create', 'update', 'delete'].includes(input?.operation)) {
    throw new HttpsError('invalid-argument', 'Unknown operation.');
  }
  const { operation } = input;
  const ref = input.id ? db.collection('appointments').doc(id(input.id)) :
    db.collection('appointments').doc();
  if (operation !== 'create' && !input.id) {
    throw new HttpsError('invalid-argument', 'Appointment ID is required.');
  }
  if (operation !== 'delete') validate(input.appointment);
  return db.runTransaction(async tx => {
    const lock = db.doc('scheduling_internal/lock');
    const lockSnapshot = await tx.get(lock);
    const user = (await tx.get(db.collection('users').doc(uid))).data();
    const staff = user && ['admin', 'staff', 'veterinarian'].includes(user.role) &&
      (user.role === 'admin' || user.approved === true);
    if (!user || (!staff && user.role !== 'customer')) {
      throw new HttpsError('permission-denied', 'An approved account is required.');
    }
    const snapshot = await tx.get(db.collection('appointments'));
    const previous = snapshot.docs.find(d => d.id === ref.id)?.data();
    if (operation === 'create' && previous) throw new HttpsError('already-exists', 'Appointment already exists.');
    if (operation !== 'create' && !previous) throw new HttpsError('not-found', 'Appointment not found.');
    const a = input.appointment;
    if (!staff) {
      if ((previous && previous.ownerUid !== uid) || (a && a.ownerUid !== uid)) {
        throw new HttpsError('permission-denied', 'This appointment belongs to another customer.');
      }
      if (operation === 'create' && (a.status !== 'pending' || a.assignedUserId)) {
        throw new HttpsError('permission-denied', 'New appointments must be unassigned and pending.');
      }
      if (operation === 'update' && (!active(previous) || a.status !== 'cancelled' ||
          fields.filter(k => k !== 'status').some(k => (a[k] ?? null) !== (previous[k] ?? null)))) {
        throw new HttpsError('permission-denied', 'Customers may only cancel active appointments.');
      }
    }
    if (a) {
      if (previous && previous.ownerUid !== a.ownerUid) {
        throw new HttpsError('permission-denied', 'Ownership cannot change.');
      }
      const pet = (await tx.get(db.collection('pets').doc(id(a.petId)))).data();
      if (!pet || pet.ownerUid !== a.ownerUid) {
        throw new HttpsError('invalid-argument', 'Pet does not belong to this customer.');
      }
      if (active(a) && snapshot.docs.some(d => {
        const b = d.data();
        return d.id !== ref.id && active(b) && day(b) === day(a) &&
          (!Number.isFinite(minute(b)) || Math.abs(minute(a) - minute(b)) < 30);
      })) throw new HttpsError('already-exists', 'Occupied slot. Please choose another time.');
    }
    tx.set(lock, { revision: (lockSnapshot.data()?.revision || 0) + 1 });
    if (operation === 'delete') tx.delete(ref);
    else tx.set(ref, { ...a, appointmentId: ref.id }, { merge: true });
    return { id: ref.id };
  });
}
module.exports = { saveAppointment };
