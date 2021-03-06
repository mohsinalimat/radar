//
//  FavoritesViewModel.swift
//  Circle
//
//  Created by Kviatkovskii on 01/02/2018.
//  Copyright © 2018 Kviatkovskii. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import Swinject
import Kingfisher

typealias FavoritesNotify = (addFavorites: Bool, allowNotify: Bool?)

struct FavoritesViewModel {
    lazy var dataSource: [FavoritesModel] = {
        var favorites: [Favorites] = []
        do {
            let realm = try Realm()
            favorites = realm.objects(Favorites.self).sorted(byKeyPath: "date", ascending: false).map({ $0 })
        } catch {
            print(error)
        }
        return updateValue(favorites)
    }()
    /// open detail place controller
    var openDetailPlace: ((PlaceModel, FavoritesViewModel) -> Void) = { _, _ in }
    let optionsKingfisher: KingfisherOptionsInfo
    
    init(container: Container) {
        self.optionsKingfisher = container.resolve(KingfisherOptionsInfo.self)!
    }
    
    func updateValue(_ favorites: [Favorites]) -> [FavoritesModel] {
        var result: [FavoritesModel] = []
        
        favorites.forEach { (item) in
            let ratingStar = NSAttributedString(string: "\(item.ratingStar)",
                attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18.0),
                             NSAttributedString.Key.foregroundColor: colorForRating(item.ratingStar)])
            let ratingCount = NSAttributedString(string: " \(item.ratingCount)",
                attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0),
                             NSAttributedString.Key.foregroundColor: UIColor.gray])
            
            let resultRating = NSMutableAttributedString(attributedString: ratingStar)
            resultRating.append(ratingCount)
            
            let title = NSAttributedString(string: "\(item.title ?? "")",
                attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17.0),
                             NSAttributedString.Key.foregroundColor: UIColor.black])
            let about = NSAttributedString(string: "\n\n\(item.about ?? "")",
                attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0),
                             NSAttributedString.Key.foregroundColor: UIColor.gray])
            
            let resultTitle = NSMutableAttributedString(attributedString: title)
            resultTitle.append(about)
            
            result.append(FavoritesModel(id: item.id,
                                         name: item.title,
                                         title: resultTitle,
                                         rating: resultRating,
                                         picture: URL(string: item.picture ?? ""),
                                         categories: item.categories.map({ Categories(rawValue: $0)! }),
                                         subCategories: item.subCategories.map({ $0 }),
                                         ratingStar: item.ratingStar,
                                         ratingCount: item.ratingCount,
                                         about: item.about,
                                         website: item.website))
        }
        
        return result
    }
    
    fileprivate func colorForRating(_ rating: Float) -> UIColor {
        var color = UIColor()
        switch rating {
        case 3.4...5.0:
            color = UIColor(withHex: 0x2ecc71, alpha: 1.0)
        case 1.8...3.4:
            color = .black
        default:
            color = UIColor(withHex: 0xc0392b, alpha: 1.0)
        }
        return color
    }
    
    /// check, if place adding to favorites
    func checkAddAndNotify(_ place: PlaceModel) -> FavoritesNotify {
        var favorites: [Favorites] = []
        do {
            let realm = try Realm()
            favorites = realm.objects(Favorites.self).filter("id = \(place.id)").map({ $0 })
        } catch {
            print(error)
        }
        
        return FavoritesNotify(!favorites.isEmpty, favorites.first?.notify)
    }
    
    func allowNotify(place: PlaceModel) -> Bool {
        UIImpactFeedbackGenerator().impactOccurred()
        
        var result = false
        do {
            let realm = try Realm()
            let favorite = realm.objects(Favorites.self).filter("id = \(place.id)").first
            
            if let oldFavorite = favorite {
                try realm.write {
                    result = !oldFavorite.notify
                    oldFavorite.notify = !oldFavorite.notify
                }
            }
        } catch {
            print(error)
        }
        return result
    }
    
    /// added to favorites
    func addToFavorite(place: PlaceModel) {
        UIImpactFeedbackGenerator().impactOccurred()

        do {
            let realm = try Realm()
            let favorite = Favorites()
            
            favorite.id = place.id
            favorite.title = place.name
            favorite.about = place.about
            favorite.ratingCount = place.ratingCount ?? 0
            favorite.ratingStar = place.ratingStar ?? 0
            favorite.date = Date()
            favorite.latitude = place.location?.latitude ?? 0.0
            favorite.longitude = place.location?.longitude ?? 0.0
            favorite.notify = true
            
            place.categories?.forEach({ category in
                favorite.categories.append(category.rawValue)
            })
            
            place.subCategories?.forEach({ subCategiry in
                favorite.subCategories.append(subCategiry)
            })
            
            favorite.picture = place.coverPhoto?.absoluteString
            favorite.website = place.website
            
            try realm.write {
                realm.add(favorite)
            }
        } catch {
            print(error)
        }
    }
    
    /// deleted from favorites
    func deleteFromFavorites(id: Int) {
        UIImpactFeedbackGenerator().impactOccurred()
        
        do {
            let realm = try Realm()
            let favorite = realm.objects(Favorites.self).filter("id = \(id)")
            
            try realm.write {
                realm.delete(favorite)
            }
        } catch {
            print(error)
        }
    }
}
