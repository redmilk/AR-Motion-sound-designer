//
//  
//  CameraCoordinator.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 06.12.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol CameraCoordinatorProtocol {
   
}

final class CameraCoordinator: CoordinatorProtocol, CameraCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = CameraViewModel(coordinator: self)
        let controller = CameraViewController(viewModel: viewModel)
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.pushViewController(controller, animated: false)
    }
    
    func end() {

    }
}
