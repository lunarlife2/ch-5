//
//  DeviceCalibration.swift
//  CustomJewelryDesigner
//
//  Created by Ni Komang Ayu Juliana on 12/08/26.
//

import UIKit

struct DeviceCalibration {

    static func deviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)

        let machineMirror = Mirror(
            reflecting: systemInfo.machine
        )

        return machineMirror.children.reduce("") {
            identifier,
            element in

            guard
                let value = element.value as? Int8,
                value != 0
            else {
                return identifier
            }

            return identifier + String(
                UnicodeScalar(UInt8(value))
            )
        }
    }

    static let ppiTable: [String: CGFloat] = [

        // iPad Pro 11-inch M4
        "iPad14,3": 264,
        "iPad14,4": 264,

        // iPad Pro 13-inch M4
        "iPad14,5": 264,
        "iPad14,6": 264,

        // iPad Pro 11-inch M5
        "iPad17,1": 264,
        "iPad17,2": 264,

        // iPad Pro 13-inch M5
        "iPad17,3": 264,
        "iPad17,4": 264
    ]

    static func pointsPerMM(for screen: UIScreen) -> CGFloat? {

        let identifier = deviceIdentifier()

        guard let ppi = ppiTable[identifier] else {
            return nil
        }

        let pointsPerInch = ppi / screen.scale

        return pointsPerInch / 25.4
    }
}
