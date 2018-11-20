//  Copyright (c) 2018 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
type Firestore = admin.firestore.Firestore
const app = admin.initializeApp();

export const computeAverageReview = functions.firestore
  .document('reviews/{reviewId}').onWrite((change, context) => {
  // get the data from the write event
  const eventData = change.after.data();
  // get the previous value, if it exists
  const prev = change.before;
  const rating = eventData.rating;
  let previousValue
  if (prev.exists) {
    previousValue = prev.data();
    const prevRating = previousValue.rating;
    if (rating === prevRating) {
      console.log("not a new rating");
      return null;
    }
  }
  const restaurantID = eventData.restaurantID;
  const db = app.firestore()
  if (prev.exists) {
    const difference = previousValue.rating - rating
    return updateAverage(db, restaurantID, difference, true)
  } else {
    return updateAverage(db, restaurantID, rating, false)
  }
});

export const updateRest = functions.firestore.document('restaurants/{restaurantID}').onUpdate((change, context) => {
  const eventData = change.after.data();
  const restaurantID = context.params.restaurantID;
  const prevEventData = change.before.data();
  const name = eventData.name;
  const oldName = prevEventData.name;
  if (oldName === name) {
    console.log("change was not in name. No need to update reviews.")
    return null;
  }
  const db = app.firestore();
  return updateRestaurant(db, restaurantID, name);
});

async function updateAverage(db: Firestore, restaurantID: string, newRating: number, prev: boolean) {
  const updateDB = db.collection('restaurants').doc(restaurantID);
  const transactionResult = await db.runTransaction(t=> {
    return (async () => {
      const restaurantDoc = await t.get(updateDB);
      if (!restaurantDoc.exists) {
        console.log("Document does not exist!")
        return null;
      }
      const oldRating = restaurantDoc.data().averageRating;
      const oldNumReviews = restaurantDoc.data().reviewCount;
      let newNumReviews = oldNumReviews + 1;
      let newAvgRating = ((oldRating*oldNumReviews)+newRating)/newNumReviews;
      if (prev) {
        newNumReviews = oldNumReviews;
        newAvgRating = ((oldRating*oldNumReviews)-newRating)/oldNumReviews;
      }
      await t.update(updateDB, {averageRating: newAvgRating, reviewCount: newNumReviews});
      console.log("average updated");
      return null;
    })();
  })

  return transactionResult;
}


async function updateRestaurant(db: Firestore, restaurantID: string, name: string) {
  const updateRef = db.collection('reviews');
  const queryRef = updateRef.where('restaurantID', '==', restaurantID);
  const batch = db.batch();
  const reviewsSnapshot = await queryRef.get();
  for (const doc of reviewsSnapshot.docs) {
    await batch.update(doc.ref, {restaurantName: name});
  };
  await batch.commit();
  console.log(`name of restaurant updated to ${name}`);
}





