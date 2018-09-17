//
//  PlaceViewModel.swift
//  Circle
//
//  Created by Kviatkovskii on 01/01/2018.
//  Copyright © 2018 Kviatkovskii. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift
import Kingfisher

enum TypeView: Int {
    case table, map
}

struct PlaceViewModel: Place {
    fileprivate let disposeBag = DisposeBag()
    
    let placeService: PlaceService
    /// open filter controller
    var openFilter: (() -> Void) = { UIImpactFeedbackGenerator().impactOccurred() }
    /// open map controller
    var openMap: (([PlaceModel], CLLocation?) -> Void) = { _, _ in UIImpactFeedbackGenerator().impactOccurred() }
    /// open detail place controller
    var openDetailPlace: ((PlaceModel, NSMutableAttributedString?, NSMutableAttributedString?, FavoritesViewModel) -> Void) = { _, _, _, _ in }
    /// reload places on map
    var reloadMap: (([PlaceModel], CLLocation?) -> Void) = { _, _ in }
    
    var places: BehaviorRelay<PlaceDataModel> = BehaviorRelay<PlaceDataModel>(value: PlaceDataModel(data: [], next: nil))
    var heightHeader: CGFloat = 100.0
    var searchForMinDistance: Bool = false
    let kingfisherOptions: KingfisherOptionsInfo
    
    var typeView: TypeView {
        var type = TypeView(rawValue: 0)!
        do {
            let realm = try Realm()
            let settings = realm.objects(Settings.self).first
            type = TypeView(rawValue: settings?.typeViewMainTab ?? 0)!
        } catch {
            print(error)
        }
        return type
    }
    
    init(_ service: PlaceService, kingfisher: KingfisherOptionsInfo) {
        self.placeService = service
        self.kingfisherOptions = kingfisher
    }
    
    func changeTypeView(_ type: TypeView) {
        do {
            let realm = try Realm()
            let settings = realm.objects(Settings.self).first
            
            try realm.write {
                guard let oldSettings = settings else {
                    let newSettings = Settings()
                    newSettings.typeViewMainTab = type.rawValue
                    realm.add(newSettings)
                    return
                }
                oldSettings.typeViewMainTab = type.rawValue
            }
        } catch {
            print(error)
        }
    }
    
    /// load more places
    func getMorePlaces(url: URL) {
        placeService.loadMorePlaces(url: url)
            .asObservable()
            .subscribe(onNext: { (newPlaces) in
                var oldPlaces = self.places.value
                oldPlaces.data += newPlaces.data
                oldPlaces.next = newPlaces.next
                self.places.accept(oldPlaces)
            })
            .disposed(by: disposeBag)
    }
    
    /// get info about for current location
    func getPlaces(location: CLLocation?, distance: CLLocationDistance, searchTerm: String? = nil) {
        var categories = PlaceSetting().allCategories
        
        if searchTerm == nil {
            do {
                let realm = try Realm()
                let selectedCategories = realm.objects(FilterSelectedCategory.self)
                if !selectedCategories.isEmpty {
                    categories = selectedCategories.map({ Categories(rawValue: $0.category)! })
                }
            } catch {
                print(error)
            }
        }
        
        placeService.loadPlaces(location, categories, distance, searchTerm)
            .asObservable()
            .bind(to: places)
            .disposed(by: disposeBag)
    }
}

protocol Place {
    /// open filter controller
    var openFilter: (() -> Void) { get set }
    /// open map controller
    var openMap: (([PlaceModel], CLLocation?) -> Void) { get set }
    /// open detail place controller
    var openDetailPlace: ((PlaceModel, NSMutableAttributedString?, NSMutableAttributedString?, FavoritesViewModel) -> Void) { get set }
    /// reload places on map
    var reloadMap: (([PlaceModel], CLLocation?) -> Void) { get set }
    
    var typeView: TypeView { get }
    var placeService: PlaceService { get }
    var places: BehaviorRelay<PlaceDataModel> { get }
    var heightHeader: CGFloat { get }
    var searchForMinDistance: Bool { get }
    var kingfisherOptions: KingfisherOptionsInfo { get }

}
