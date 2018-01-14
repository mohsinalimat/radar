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
        return UIColor(withHex: 0x2c3e50, alpha: 1.0)
    }
}

struct Router {

    func showMainTabController() -> UITabBarController {
        //swiftlint:disable force_cast
        var placesViewController = UIViewController()
        var viewModel = PlaceViewModel(PlaceService())
        
        let optionKingfisher: KingfisherOptionsInfo = {
            return [KingfisherOptionsInfoItem.transition(.fade(0.2))]
        }()
        
        viewModel.openFilter = { delegate in
            let dependecies = FilterPlacesDependecies(FilterViewModel(), FilterDistanceViewModel(), FilterCategoriesViewModel(), delegate)
            self.openFilterPlaces(fromController: placesViewController as! PlacesViewController,
                                  toController: FilterPlacesViewController(dependecies))
        }
        
        viewModel.openMap = { (places: PlacesSections?, location: CLLocation?, sourceRect: CGRect) in
            let dependecies = MapDependecies(places, location)
            self.openMap(fromController: placesViewController as! PlacesViewController,
                         toController: MapViewController(dependecies),
                         sourceRect: sourceRect)
        }
        
        viewModel.openDetailPlace = { place in
            self.openDetailPlace(place, optionKingfisher, placesViewController)
        }
        
        placesViewController = PlacesViewController(PlacesViewDependecies(optionKingfisher, viewModel))
        let locationImage = UIImage(named: "ic_my_location")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        placesViewController.navigationItem.title = "Around here"
        placesViewController.tabBarItem = UITabBarItem(title: "My location", image: locationImage, tag: 1)
        placesViewController.navigationController?.navigationBar.isTranslucent = true
        
        if #available(iOS 11.0, *) {
            placesViewController.navigationController?.navigationBar.largeTitleTextAttributes = [
                NSAttributedStringKey.foregroundColor: UIColor.white,
                NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 28)]
            placesViewController.navigationController?.navigationItem.largeTitleDisplayMode = .always
        }
        
        let settingsController = SettingsViewController(SettingsViewDependecies(SettingsViewModel()))
        let settingsImage = UIImage(named: "ic_settings")?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        settingsController.navigationItem.title = "Settings of app"
        settingsController.tabBarItem = UITabBarItem(title: "Settings", image: settingsImage, tag: 2)
        
        let tabController = UITabBarController()
        tabController.tabBar.tintColor = UIColor.tabColor
        tabController.viewControllers = [placesViewController, settingsController].map({ UINavigationController(rootViewController: $0) })
        return tabController
    }
    
    fileprivate func openDetailPlace(_ place: PlaceModel, _ kingfisherOptions: KingfisherOptionsInfo, _ fromController: UIViewController) {
        let dependecies = DetailPlaceDependecies(place, kingfisherOptions)
        let detailPlaceController = DetailPlaceViewController(dependecies)
        detailPlaceController.hidesBottomBarWhenPushed = true
        fromController.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)
        fromController.navigationController?.pushViewController(detailPlaceController, animated: true)
    }
    
    /// open filter controller
    fileprivate func openFilterPlaces(fromController: PlacesViewController, toController: UIViewController) {
        let navigation = UINavigationController(rootViewController: toController)
        navigation.modalPresentationStyle = UIModalPresentationStyle.popover
        navigation.isNavigationBarHidden = true
        let popover = navigation.popoverPresentationController
        popover?.delegate = fromController
        popover?.barButtonItem = fromController.rightBarButton
        popover?.permittedArrowDirections = UIPopoverArrowDirection.any
        
        fromController.present(navigation, animated: true, completion: nil)
    }
    
    /// open map controller
    fileprivate func openMap(fromController: PlacesViewController, toController: UIViewController, sourceRect: CGRect) {
        let navigation = UINavigationController(rootViewController: toController)
        navigation.modalPresentationStyle = UIModalPresentationStyle.popover
        navigation.isNavigationBarHidden = true
        
        let popover = navigation.popoverPresentationController
        popover?.delegate = fromController
        popover?.sourceRect = sourceRect
        popover?.sourceView = fromController.view
        
        let width = fromController.view.frame.size.width
        let height = fromController.view.frame.size.height - 200.0
        toController.preferredContentSize = CGSize(width: width, height: height)
    
        fromController.present(navigation, animated: true, completion: nil)
    }
}
