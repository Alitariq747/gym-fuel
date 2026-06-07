import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Deletes every meal image stored for a user.
 * @param {string} uid Firebase Auth user id.
 * @return {Promise<void>} Resolves after matching Storage objects are removed.
 */
async function deleteUserMealImages(uid: string): Promise<void> {
  const bucket = admin.storage().bucket();
  const prefix = `users/${uid}/mealImages/`;

  await bucket.deleteFiles({
    prefix,
    force: true,
  });
}

/**
 * Deletes all monthly usage quota documents for a user.
 * @param {string} uid Firebase Auth user id.
 * @return {Promise<void>} Resolves after the quota subtree is removed.
 */
async function deleteUserUsageQuotas(uid: string): Promise<void> {
  const db = admin.firestore();
  const quotaRef = db.collection("usageQuotas").doc(uid);

  await db.recursiveDelete(quotaRef);
}

export const deleteAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Not signed in.");
  }

  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);

  await deleteUserMealImages(uid);
  await deleteUserUsageQuotas(uid);
  await db.recursiveDelete(userRef);
  await admin.auth().deleteUser(uid);

  return {ok: true};
});
