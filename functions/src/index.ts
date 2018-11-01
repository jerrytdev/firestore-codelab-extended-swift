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

// TODO(DEVELOPER): Import the Cloud Functions for Firebase and the Firebase Admin modules here.
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
type Firestore = admin.firestore.Firestore
const app = admin.initializeApp();

  // TODO(DEVELOPER): Write the computeAverageReview Function here.
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

// TODO(DEVELOPER): Add updateAverage helper function here.
async function updateAverage(db: Firestore, restaurantID: string, newRating: number, prev: boolean) {
  const updateDB = db.collection('restaurants').doc(restaurantID);
  const restaurantDoc = await updateDB.get();
  if (!restaurantDoc.exists) {
    console.log("Document does not exist!");
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
  await updateDB.update({averageRating: newAvgRating, reviewCount: newNumReviews});
  console.log("average updated");
  return null;
}

// TODO(DEVELOPER): Write the updateRest Function here.

// TODO(DEVELOPER): Add updateRestaurant helper function here.
