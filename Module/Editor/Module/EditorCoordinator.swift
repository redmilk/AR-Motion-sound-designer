//
//  
//  EditorCoordinator.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 27.12.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol EditorCoordinatorProtocol {
   
}

final class EditorCoordinator: CoordinatorProtocol, EditorCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init() {

    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = EditorViewModel(coordinator: self)
        let controller = EditorViewController(viewModel: viewModel)

    }
    
    func end() {

    }
}
