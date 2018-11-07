//
//  LazyRestaurantTableViewDataSource.swift
//  FriendlyEats
//
//  Created by Jerry Tung on 11/7/18.
//  Copyright © 2018 Firebase. All rights reserved.
//

import UIKit
import Firebase

@objc class LazyRestaurantTableViewDataSource: NSObject, UITableViewDataSource {
  
  private var restaurants: [Restaurant] = []
  private var documents: [QueryDocumentSnapshot] = []
  private let updateHandler: () -> ()
  private let query: Query
  private var isFetchingUpdates = false

  public init(query: Query, updateHandler: @escaping () -> ()) {
    self.query = query
    self.updateHandler = updateHandler
  }
  
  public func fetchNext() {
    if isFetchingUpdates {
      return
    }
    isFetchingUpdates = true
    
    let nextQuery: Query
    
    if let lastDocument = documents.last {
      nextQuery = query.start(afterDocument: lastDocument).limit(to: 50)
    } else {
      nextQuery = query.limit(to: 50)
    }
    
    nextQuery.getDocuments { (QuerySnapshot, error) in
      guard let snapshot = QuerySnapshot else {
        print("Error fetching next documents: \(error!)")
        self.isFetchingUpdates = false
        return
      }
    
      let newRestaurants = snapshot.documents.map { doc-> Restaurant in
        guard let restaurant = Restaurant(document: doc) else {
          fatalError("Error serializing restaurant with document snapshot: \(doc)")
        }
        return restaurant
      }
      
      self.restaurants += newRestaurants
      self.documents += snapshot.documents
      self.updateHandler()
      self.isFetchingUpdates = false
    }
  }

  public subscript(index: Int) -> Restaurant {
      return restaurants[index]
  }
  
  public var count: Int {
    return restaurants.count
  }
  
  // MARK: - UITableViewDataSource
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantTableViewCell", for: indexPath) as! RestaurantTableViewCell
    let restaurant = restaurants[indexPath.row]
    cell.populate(restaurant:restaurant)
    return cell
  }
}
