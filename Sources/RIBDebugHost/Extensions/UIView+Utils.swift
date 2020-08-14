//
//  UIView+Utils.swift
//  
//
//  Created by Adam Share on 8/12/20.
//

import Foundation
import UIKit

extension UIView {
    func asImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0.0)
        defer { UIGraphicsEndImageContext() }
        if let context = UIGraphicsGetCurrentContext() {
            layer.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            return image
        }
        return nil
    }
}
