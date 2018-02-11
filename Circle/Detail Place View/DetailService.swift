//
//  DetailService.swift
//  Circle
//
//  Created by Kviatkovskii on 11/02/2018.
//  Copyright © 2018 Kviatkovskii. All rights reserved.
//

import RxSwift
import UIKit
import Unbox

struct DetailService {
    func loadPicture(id: Int) -> Observable<URL?> {
        let params: [String: Any] = ["fields": "picture.type(large).redirect(false)"]
        let request = FBSDKGraphRequest(graphPath: "\(id)", parameters: params, httpMethod: "GET")
        return Observable.create({ (observable) in
            _ = request?.start(completionHandler: { (_, result, error) in
                guard error == nil else {
                    observable.on(.error(error!))
                    return
                }
                
                if let data = result as? [String: Any], let model: DetailServiceModel = try? unbox(dictionary: data) {
                    observable.on(.next(model.url))
                }
            })
            return Disposables.create()
        })
    }
}
