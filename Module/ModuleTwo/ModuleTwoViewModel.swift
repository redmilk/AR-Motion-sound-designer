//
//  
//  ModuleTwoViewModel.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 18.11.2021.
//
//

import Foundation
import Combine

final class ModuleTwoViewModel {
    enum Action {
        case dummyAction
    }
    
    let input = PassthroughSubject<ModuleTwoViewModel.Action, Never>()
    let output = PassthroughSubject<ModuleTwoViewController.State, Never>()
    
    private let coordinator: ModuleTwoCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: ModuleTwoCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension ModuleTwoViewModel {
    
    /// Handle ViewController's actions
    private func dispatchActions() {
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .dummyAction:
                break
            }
        })
        .store(in: &bag)
    }
    
}
