//
//  Routing+Utils.swift
//  
//
//  Created by Adam Share on 8/12/20.
//

import Foundation
import RIBs

extension Routing {
    func metadata() -> RIBMetadata {
        return RIBMetadata.init(self)
    }
    
    func findChildRouterBy(className: String) -> Routing? {
        let currentRouter = String(describing: type(of: self))
        guard className != currentRouter else {
            return self
        }
        
        for child in children {
            if let found = child.findChildRouterBy(className: className) {
                return found
            }
        }
        
        return nil
    }
    
    func captureRouterView(className: String) -> Data? {
        guard let router = findChildRouterBy(className: className) as? ViewableRouting,
            let view = router.viewControllable.uiviewController.view,
            let captureImage = view.asImage() else {
                return nil
        }
        return captureImage.pngData()
    }
    
    func tree() -> RIBMetadata {
        return RIBMetadata(self)
    }
}
