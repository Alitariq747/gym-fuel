import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

export const deleteAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Not signed in.");
  }

  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);

  // 1) Delete all user data (including subcollections)
  await db.recursiveDelete(userRef);

  // 2) Delete the Auth user
  await admin.auth().deleteUser(uid);

  return {ok: true};
});
