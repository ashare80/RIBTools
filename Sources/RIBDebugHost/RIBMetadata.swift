//
//  RIBMetadata.swift
//  
//
//  Created by Adam Share on 8/13/20.
//

import Foundation
import RIBs

struct RIBMetadata: Codable, Hashable {
    public var children: [RIBMetadata]
    public var presenterName: String?
    public var routerName: String
    public var objectIdentifier: String
    
    public init(_ router: Routing) {
        children = router.children.map(RIBMetadata.init)
        objectIdentifier = ObjectIdentifier(router).debugDescription
        routerName = String(describing: type(of: router))
        
        if let router = router as? ViewableRouting {
            presenterName = String(describing: type(of: router.viewControllable))
        }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.objectIdentifier == rhs.objectIdentifier
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(objectIdentifier)
    }
}
