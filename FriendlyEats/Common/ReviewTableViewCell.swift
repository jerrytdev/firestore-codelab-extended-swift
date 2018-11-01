//
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

import UIKit
import Firebase

class ReviewTableViewCell: UITableViewCell {

  @IBOutlet var usernameLabel: UILabel?
  @IBOutlet var reviewContentsLabel: UILabel!
  @IBOutlet var starsView: ImmutableStarsView!
  @IBOutlet weak var yumsLabel: UILabel!
  @IBOutlet weak var userIcon: UIImageView?
  @IBOutlet weak var yumButton: UIButton!
  @IBOutlet weak var restaurantNameLabel: UILabel?

  var review: Review!

  func populate(review: Review) {
    self.review = review
    restaurantNameLabel?.text = review.restaurantName
    usernameLabel?.text = review.userInfo.name
    userIcon?.sd_setImage(with: review.userInfo.photoURL)
    starsView.rating = review.rating
    reviewContentsLabel.text = review.text
    showYumText()
  }
  
  func showYumText() {
    switch review.yumCount {
    case 0:
      yumsLabel.isHidden = true
    case 1:
      yumsLabel.isHidden = false
      yumsLabel.text = "1 yum"
    default:
      yumsLabel.isHidden = false
      yumsLabel.text = "\(review.yumCount) yums"
    }
  }

  @IBAction func yumWasTapped(_ sender: Any) {
    
    guard let currentUser = Auth.auth().currentUser else { return }

    let reviewReference = Firestore.firestore()
      .collection("reviews")
      .document(review.documentID)
    Firestore.firestore().runTransaction( { (transaction, errorPointer) -> Any? in
      // 1. Get latest review from DB
      let reviewSnapshot: DocumentSnapshot
      do {
          try reviewSnapshot = transaction.getDocument(reviewReference)
      } catch let error as NSError {
        errorPointer?.pointee = error
        return nil
      }
      
      // 2. Perform internal logic
      guard let latestReview = Review(document: reviewSnapshot) else {
        let error = NSError(domain: "FriendlyEatsErrorDomain", code: 0, userInfo: [
          NSLocalizedDescriptionKey: "Review at \(reviewReference.path) didn't look valid"
          ])
        errorPointer?.pointee = error
        return nil
      }
      let newYumCount = latestReview.yumCount + 1
      
      // 3. Write new yum to subcollection
      let newYum = Yum(documentID: currentUser.uid, username: currentUser.displayName ?? "Unknown user")
      let newYumReference = reviewReference.collection("yums").document(newYum.documentID)
      transaction.setData(newYum.documentData, forDocument: newYumReference)
      
      //4. update the yum count
      transaction.updateData(["yumCount": newYumCount], forDocument: reviewReference)
      
      return nil
    }) { (_, error) in
      if let error = error {
        print("Error updating yum count: \(error)")
      } else {
        print("yum count successfully updated")
      }
    }
    
    /*
     Bad!
    // Let's increment the yumCount! - Step 10
    let reviewReference = Firestore.firestore()
      .collection("reviews")
      .document(review.documentID)
    reviewReference.getDocument { (snapshot,error) in
      if let error = error {
        print("Got an error fetching the document? \(error)")
        return
      }
      guard let snapshot = snapshot else { return }
      guard let review = Review(document: snapshot) else { return }
      print("This review currently has \(review.yumCount) yums")
      let newYumCount = review.yumCount+1
      
      guard let currentUser = Auth.auth().currentUser else { return }
      let newYum = Yum(documentID: currentUser.uid, username: currentUser.displayName ?? "Unknown user")
      let newYumReference = reviewReference.collection("yums").document(newYum.documentID)
      newYumReference.setData(newYum.documentData, completion: { (error) in
        if let error = error {
          print("Got an error adding the new yum document \(error)")
        } else {
          reviewReference.updateData(["yumCount": newYumCount]) { err in
              if let err = err {
                print("Error updating yum count: \(err)")
              } else {
                print("yum count updated successfully")
            }
          }
        }
      })
    }
    */
    
  }

}
