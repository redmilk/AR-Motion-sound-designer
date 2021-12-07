//
//  ApplicationCoordinator.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 18.11.2021.
//

import Foundation
import UIKit.UIWindow

final class ApplicationCoordinator: CoordinatorProtocol {
    
    unowned let window: UIWindow
    var navigationController: UINavigationController?
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func start() {
        navigationController = UINavigationController()
        window.rootViewController = navigationController
        var isFirstLaunch: Bool = true
        isFirstLaunch ? self.showAppTutorial() : self.showContent()
    }
    
    private func showAppTutorial() {
        let appTutorialModule = CameraCoordinator(navigationController: navigationController)
        appTutorialModule.start()
    }
    
    private func showContent() {

    }
}
