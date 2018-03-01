//
//  Router.swift
//  Circle
//
//  Created by Kviatkovskii on 09/12/2017.
//  Copyright © 2017 Kviatkovskii. All rights reserved.
//

import UIKit
import Kingfisher

fileprivate extension UIColor {
    static var tabColor: UIColor {
        return UIColor(withHex: 0xf82462, alpha: 1.0)
    }
}

struct Router {
    fileprivate let optionKingfisher: KingfisherOptionsInfo = {
        return [KingfisherOptionsInfoItem.transition(.fade(0.2))]
    }()
    
    func showMainTabController(_ locationService: LocationService, startTab: Int = 0) -> UITabBarController {
        //swiftlint:disable force_cast
        var placesViewController = UIViewController()
        var viewModel = PlaceViewModel(PlaceService())
        
        viewModel.openFilter = {
            let dependecies = FilterPlacesDependecies(FilterViewModel(), FilterDistanceViewModel(), FilterCategoriesViewModel())
            self.openFilterPlaces(fromController: placesViewController as! PlacesViewController,
                                  toController: FilterPlacesViewController(dependecies))
        }
        
        var mapController = UIViewController()
        viewModel.openMap = { places, location in
            let dependecies = MapDependecies(places, location, viewModel)
            mapController = MapViewController(dependecies)
            self.openMap(fromController: placesViewController, toController: mapController)
        }
        
        viewModel.reloadMap = { places, location in
            guard let map = mapController as? MapViewController else { return }
            map.places = places
            map.userLocation = location
            map.addPointOnMap(places: places)
        }
        
        viewModel.openDetailPlace = { place, title, rating, favoritesViewModel in
            self.openDetailPlace(place, title, rating, favoritesViewModel, placesViewController)
        }
        
        placesViewController = PlacesViewController(PlacesViewDependecies(optionKingfisher,
                                                                          viewModel,
                                                                          locationService))
        let locationImage = UIImage(named: "ic_my_location")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        placesViewController.navigationItem.title = "Around here"
        placesViewController.tabBarItem = UITabBarItem(title: "My location", image: locationImage, tag: 0)
        placesViewController.navigationController?.navigationBar.isTranslucent = true
        
        // Search Controller
        var searchViewController = UIViewController()
        var searchViewModel = SearchViewModel(viewModel)
        
        searchViewModel.openDetailPlace = { place, title, rating, favoritesViewModel in
            self.openDetailPlace(place, title, rating, favoritesViewModel, searchViewController)
        }
        
        searchViewController = SearchViewController(SeacrhPlaceDependecies(searchViewModel, optionKingfisher))
        let searchImage = UIImage(named: "ic_search")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        searchViewController.navigationItem.title = "Find a place"
        searchViewController.tabBarItem = UITabBarItem(title: "Search", image: searchImage, tag: 1)
        searchViewController.navigationController?.navigationBar.isTranslucent = true
        
        // Favorites Controller
        var favoritesViewController = UIViewController()
        var favoritesViewModel = FavoritesViewModel()
        
        favoritesViewModel.openDetailPlace = { place, title, rating, viewModel in
            self.openDetailPlace(place, title, rating, viewModel, favoritesViewController)
        }
        
        favoritesViewController = FavoritesViewController(FavoritesDependencies(favoritesViewModel, optionKingfisher))
        let favoriteImage = UIImage(named: "ic_favorite")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        favoritesViewController.navigationItem.title = "Favorites"
        favoritesViewController.tabBarItem = UITabBarItem(title: "Favorites", image: favoriteImage, tag: 2)
        favoritesViewController.navigationController?.navigationBar.isTranslucent = true
        
        // Setting Controller
        var settingsController = UIViewController()
        var settingViewModel = SettingsViewModel()
        settingViewModel.openSearchHistory = {
            self.openSearchHistory(settingsController)
        }
        
        settingViewModel.openListFavoritesNotice = {
            self.openListFavoritesNotice(settingsController)
        }
        
        settingsController = SettingsViewController(SettingsViewDependecies(settingViewModel))
        let settingsImage = UIImage(named: "ic_settings")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        settingsController.navigationItem.title = "Application settings"
        settingsController.tabBarItem = UITabBarItem(title: "Settings", image: settingsImage, tag: 3)
        settingsController.navigationController?.navigationBar.isTranslucent = true
        
        // Tab View Controller
        let tabController = UITabBarController()
        tabController.tabBar.tintColor = UIColor.tabColor
        tabController.viewControllers = [placesViewController,
                                         searchViewController,
                                         favoritesViewController,
                                         settingsController].map({ UINavigationController(rootViewController: $0) })
        tabController.selectedIndex = startTab
        return tabController
    }
    
    fileprivate func openListFavoritesNotice(_ fromController: UIViewController) {
        let listNoticeController = ListFavoritesNoticeViewController(ListFavoritesNoticeDependecies(ListFavoritesNoticeViewModel()))
        let newNavController = UINavigationController(rootViewController: listNoticeController)
        newNavController.navigationBar.isTranslucent = true
        fromController.present(newNavController, animated: true, completion: nil)
    }
    
    fileprivate func openSearchHistory(_ fromController: UIViewController) {
        let showHistoryController = SearchHistoryViewController(SearchHistoryDependecies(SearchHistoryViewModel()))
        let newNavController = UINavigationController(rootViewController: showHistoryController)
        newNavController.navigationBar.isTranslucent = true
        fromController.present(newNavController, animated: true, completion: nil)
    }
    
    /// open detail controller about place
    fileprivate func openDetailPlace(_ place: PlaceModel,
                                     _ title: NSMutableAttributedString?,
                                     _ rating: NSMutableAttributedString?,
                                     _ favoritesViewModel: FavoritesViewModel,
                                     _ fromController: UIViewController) {
        let dependecies = DetailPlaceDependecies(DetailPlaceViewModel(place, title, rating, FavoritesService()),
                                                 favoritesViewModel,
                                                 optionKingfisher,
                                                 OpenGraphService())
        let detailPlaceController = DetailPlaceViewController(dependecies)
        detailPlaceController.hidesBottomBarWhenPushed = true
        fromController.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)
        fromController.navigationController?.pushViewController(detailPlaceController, animated: true)
    }
    
    /// open filter controller
    fileprivate func openFilterPlaces(fromController: PlacesViewController, toController: UIViewController) {
        let navigation = UINavigationController(rootViewController: toController)
        navigation.modalPresentationStyle = .popover
        navigation.isNavigationBarHidden = true
        let popover = navigation.popoverPresentationController
        popover?.delegate = fromController
        popover?.barButtonItem = fromController.rightBarButton
        popover?.permittedArrowDirections = .any
        
        fromController.present(navigation, animated: true, completion: nil)
    }
    
    /// open map controller
    fileprivate func openMap(fromController: UIViewController, toController: UIViewController) {
        fromController.addChildViewController(toController)
        toController.view.bounds = fromController.view.bounds
        fromController.view.addSubview(toController.view)
        toController.didMove(toParentViewController: fromController)
    }
    
    func openPopoverLabel(fromController: DetailPlaceViewController, toController: UIViewController, height: CGFloat) {
        let navigation = UINavigationController(rootViewController: toController)
        navigation.modalPresentationStyle = .popover
        navigation.isNavigationBarHidden = true
        let popover = navigation.popoverPresentationController
        popover?.delegate = fromController
        popover?.permittedArrowDirections = .up
        
        var rect = fromController.titlePlace.bounds
        rect.size.height = rect.height - 20.0
        
        popover?.sourceRect = rect
        popover?.sourceView = fromController.titlePlace
        toController.preferredContentSize = CGSize(width: fromController.view.frame.width, height: height)
        
        fromController.present(navigation, animated: true, completion: nil)
    }
}
