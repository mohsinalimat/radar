//
//  Router.swift
//  Circle
//
//  Created by Kviatkovskii on 09/12/2017.
//  Copyright © 2017 Kviatkovskii. All rights reserved.
//

import UIKit
import Kingfisher
import Swinject

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
        let container = Container()
        
        container.register(KingfisherOptionsInfo.self) { _ in
            self.optionKingfisher
        }
        
        container.register(PlaceViewModel.self) { (r) in
            var viewModel = PlaceViewModel(PlaceService(), kingfisher: r.resolve(KingfisherOptionsInfo.self)!, locationService: locationService)
            
            viewModel.openFilter = {
                UIImpactFeedbackGenerator().impactOccurred()
                let containerFilter = Container()
                containerFilter.register(FilterViewModel.self) { _ in
                    FilterViewModel()
                }
                containerFilter.register(FilterDistanceViewModel.self) { _ in
                    FilterDistanceViewModel()
                }
                containerFilter.register(FilterCategoriesViewModel.self) { _ in
                    FilterCategoriesViewModel()
                }
                self.openFilterPlaces(fromController: placesViewController as! PlacesViewController, toController: FilterPlacesViewController(containerFilter))
            }
            
            var mapController = UIViewController()
            viewModel.openMap = { places, location in
                mapController = MapViewController(places: places, userLocation: location, placeViewModel: viewModel)
                self.openMap(fromController: placesViewController, toController: mapController)
            }
            
            viewModel.reloadMap = { places, location in
                guard let map = mapController as? MapViewController else { return }
                map.places = places
                map.userLocation = location
            }
            
            viewModel.openDetailPlace = { place, favoritesViewModel in
                self.openDetailPlace(place, favoritesViewModel, placesViewController)
            }
            
            return viewModel
        }
        
        container.register(LocationService.self) { _ in
            locationService
        }
        
        placesViewController = PlacesViewController(container)
        let locationImage = UIImage(named: "ic_my_location")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        placesViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("mylocation", comment: "Title for main tab"),
                                                       image: locationImage,
                                                       tag: 0)
        placesViewController.navigationController?.navigationBar.isTranslucent = true
        
        // Search Controller
        var searchViewController = UIViewController()
        
        container.register(SearchViewModel.self) { _ in
            var viewModel = SearchViewModel(container)
            
            viewModel.openDetailPlace = { place, favoritesViewModel in
                self.openDetailPlace(place, favoritesViewModel, searchViewController)
            }
            
            return viewModel
        }
        
        searchViewController = SearchViewController(container)
        let searchImage = UIImage(named: "ic_search")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        searchViewController.navigationItem.title = NSLocalizedString("findPlace", comment: "Title for navigation bar in search tab")
        searchViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("search", comment: "Title for search tab"),
                                                       image: searchImage,
                                                       tag: 1)
        searchViewController.navigationController?.navigationBar.isTranslucent = true
        
        // Favorites Controller
        var favoritesViewController = UIViewController()
        container.register(FavoritesViewModel.self) { _ in
            var favoritesViewModel = FavoritesViewModel(container: container)
            favoritesViewModel.openDetailPlace = { place, viewModel in
                self.openDetailPlace(place, viewModel, favoritesViewController)
            }
            return favoritesViewModel
        }
        favoritesViewController = FavoritesViewController(container)
        let favoriteImage = UIImage(named: "ic_favorite")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        favoritesViewController.navigationItem.title = NSLocalizedString("favorites",
                                                                         comment: "Title for navigation bar in favorites tab")
        favoritesViewController.tabBarItem = UITabBarItem(title: NSLocalizedString("favorites", comment: "Title for favorites tab"),
                                                          image: favoriteImage,
                                                          tag: 2)
        favoritesViewController.navigationController?.navigationBar.isTranslucent = true
        
        // Setting Controller
        var settingsController = UIViewController()
        container.register(SettingsViewModel.self) { _ in
            var settingViewModel = SettingsViewModel()
            settingViewModel.openSearchHistory = {
                self.openSearchHistory(settingsController)
            }
            settingViewModel.openListFavoritesNotice = {
                self.openListFavoritesNotice(settingsController)
            }
            return settingViewModel
        }
        settingsController = SettingsViewController(container)
        let settingsImage = UIImage(named: "ic_settings")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        settingsController.navigationItem.title = NSLocalizedString("appSettings",
                                                                    comment: "Title for navigation bar in settings tab")
        settingsController.tabBarItem = UITabBarItem(title: NSLocalizedString("settings", comment: "Title for settings tab"),
                                                     image: settingsImage,
                                                     tag: 3)
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
        let container = Container()
        container.register(ListFavoritesNoticeViewModel.self) { _ in
            ListFavoritesNoticeViewModel()
        }
        let listNoticeController = ListFavoritesNoticeViewController(container)
        let newNavController = UINavigationController(rootViewController: listNoticeController)
        newNavController.navigationBar.isTranslucent = true
        fromController.present(newNavController, animated: true, completion: nil)
    }
    
    fileprivate func openSearchHistory(_ fromController: UIViewController) {
        let container = Container()
        container.register(SearchHistoryViewModel.self) { _ in
            SearchHistoryViewModel()
        }
        let showHistoryController = SearchHistoryViewController(container)
        let newNavController = UINavigationController(rootViewController: showHistoryController)
        newNavController.navigationBar.isTranslucent = true
        fromController.present(newNavController, animated: true, completion: nil)
    }
    
    /// open detail controller about place
    fileprivate func openDetailPlace(_ place: PlaceModel, _ favoritesViewModel: FavoritesViewModel, _ fromController: UIViewController) {
        let container = Container()
        container.register(PlaceModel.self) { _ in
            place
        }
        container.register(FavoritesService.self) { _ in
            FavoritesService()
        }
        container.register(KingfisherOptionsInfo.self) { _ in
            self.optionKingfisher
        }
        container.register(OpenGraphService.self) { _ in
            OpenGraphService()
        }
        container.register(FavoritesViewModel.self) { _ in
            favoritesViewModel
        }
        
        container.register(DetailPlaceViewModel.self) { _ in
            DetailPlaceViewModel(container)
        }
        
        let detailPlaceController = DetailPlaceViewController(container)
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
        toController.view.transform = CGAffineTransform(translationX: -fromController.view.frame.width, y: 0)
        fromController.view.addSubview(toController.view)
        UIView.animate(withDuration: 0.3) {
            toController.view.transform = CGAffineTransform(translationX: 0, y: 0)
        }
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
