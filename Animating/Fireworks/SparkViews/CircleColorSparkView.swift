//
//  CircleColorSparkView.swift
//  Good Deed Counter
//
//  Created by Mary Paskhaver on 12/21/20.
//  Copyright © 2020 Nostaw. All rights reserved.
//

import UIKit

final class CircleColorSparkView: SparkView {

    init(color: UIColor, size: CGSize) {
        super.init(frame: CGRect(origin: .zero, size: size))
        self.backgroundColor = color
        self.layer.cornerRadius = self.frame.width / 2.0
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension UIColor {

    static var sparkColorSet1: [UIColor] = {
        return [
            UIColor(red:0.89, green:0.58, blue:0.70, alpha:1.00),
            UIColor(red:0.96, green:0.87, blue:0.62, alpha:1.00),
            UIColor(red:0.67, green:0.82, blue:0.94, alpha:1.00),
            UIColor(red:0.54, green:0.56, blue:0.94, alpha:1.00),
        ]
    }()
}
