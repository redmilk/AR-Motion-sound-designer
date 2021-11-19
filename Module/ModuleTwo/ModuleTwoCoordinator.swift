//
//  
//  ModuleTwoCoordinator.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 18.11.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol ModuleTwoCoordinatorProtocol {
   
}

final class ModuleTwoCoordinator: CoordinatorProtocol, ModuleTwoCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init() {

    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = ModuleTwoViewModel(coordinator: self)
        let controller = ModuleTwoViewController(viewModel: viewModel)
        
    }
    
    func end() {

    }
}
