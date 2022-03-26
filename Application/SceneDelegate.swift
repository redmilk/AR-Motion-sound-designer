//
//  SceneDelegate.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 18.11.2021.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, SoundDropProvidable {
    
    var window: UIWindow?
    var applicationCoordinator: ApplicationCoordinator!
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window!.makeKeyAndVisible()
        
        applicationCoordinator = ApplicationCoordinator(window: window!)
        applicationCoordinator.start()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        soundDrop.receiveSoundFile(URLContexts.first!.url)
    }
}

