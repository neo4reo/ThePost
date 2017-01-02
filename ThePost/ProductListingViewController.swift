//
//  ProductListingViewController.swift
//  ThePost
//
//  Created by Andrew Robinson on 12/27/16.
//  Copyright © 2016 The Post. All rights reserved.
//

import UIKit
import Firebase

class ProductListingViewController: UIViewController, UICollectionViewDataSource {
    
    var jeepModel: Jeep!

    @IBOutlet weak var collectionView: UICollectionView!
    
    private var products: [Product] = []
    
    private var ref: FIRDatabaseReference!
    private var productRef: FIRDatabaseReference?
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()
                
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: floor(view.frame.width * (190/414)), height: floor(view.frame.height * (235/736)))
        
        collectionView.dataSource = self
        
        if let start = jeepModel.startYear, let end = jeepModel.endYear, let name = jeepModel.name {
            navigationController!.navigationBar.topItem!.title = name + " \(start)-\(end)"
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if productRef == nil {
            productRef = ref.child("products")
            
            productRef!.observe(.childAdded, with: { snapshot in
                if let productDict = snapshot.value as? [String: Any] {
                    if let jeepModel = JeepModel.enumFromString(string: productDict["jeepModel"] as! String) {
                        if let condition = Condition.enumFromString(string: productDict["condition"] as! String) {
                            let product = Product(withName: productDict["name"] as! String,
                                                  model: jeepModel,
                                                  price: productDict["price"] as! Float,
                                                  condition: condition)
                            self.products.append(product)
                            self.collectionView.reloadData()
                        }
                    }
                }
            })
            
            productRef!.observe(.childRemoved, with: { snapshot in
                if let productDict = snapshot.value as? [String: Any] {
                    if let jeepModel = JeepModel.enumFromString(string: productDict["jeepModel"] as! String) {
                        if let condition = Condition.enumFromString(string: productDict["condition"] as! String) {
                            let product = Product(withName: productDict["name"] as! String,
                                                  model: jeepModel,
                                                  price: productDict["price"] as! Float,
                                                  condition: condition)
                            
                            let index = self.indexOfMessage(product)
                            self.products.remove(at: index)
                            
                            self.collectionView.reloadData()
                        }
                    }
                }
            })
        }
    }
    
    deinit {
        ref.removeAllObservers()
        
        if let productRef = productRef {
            productRef.removeAllObservers()
        }
    }
    
    // MARK: - CollectionView datasource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "plpContentCell", for: indexPath) as! ProductListingContentCollectionViewCell
        let product = products[indexPath.row]
        
        cell.favoriteCountLabel.text = "4"
        cell.descriptionLabel.text = product.simplifiedDescription
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        let string = formatter.string(from: floor(product.price) as NSNumber)
        let endIndex = string!.index(string!.endIndex, offsetBy: -3)
        let truncated = string!.substring(to: endIndex) // Remove the .00 from the price.
        cell.priceLabel.text = truncated
        
        if product.images.count > 0 {
            cell.imageView.image = product.images[0]
        }
        
        cell.nameLabel.text = product.name
        
        return cell
    }
    
    // MARK: - Helpers
    
    func indexOfMessage(_ snapshot: Product) -> Int {
        var index = 0
        for product in self.products {
            
            // TODO: This check can be true for more than one product...
            if snapshot.name == product.name {
                return index
            }
            index += 1
        }
        return -1
    }

}
