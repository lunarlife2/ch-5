//
//  OnBoardingService.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 23/08/26.
//

import Foundation
import AVFoundation
import Photos
import SwiftUI

@Observable
@MainActor
final class OnBoardingService {
    private let permissionsKey = "onboarding.hasRequestedPermissions"
    private let tutorialKey = "onboarding.hasCompletedTutorial"

    var hasRequestedPermissions: Bool {
        didSet { UserDefaults.standard.set(hasRequestedPermissions, forKey: permissionsKey) }
    }
    var hasCompletedTutorial: Bool {
        didSet { UserDefaults.standard.set(hasCompletedTutorial, forKey: tutorialKey) }
    }

    init() {
        hasRequestedPermissions = UserDefaults.standard.bool(forKey: permissionsKey)
        hasCompletedTutorial = UserDefaults.standard.bool(forKey: tutorialKey)
    }

    func requestCameraAndPhotoAccess() async {
        _ = await AVCaptureDevice.requestAccess(for: .video)
        _ = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        hasRequestedPermissions = true
    }
}
