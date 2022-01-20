//
//  
//  EditorViewModel.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 27.12.2021.
//
//

import Foundation
import Combine

final class EditorViewModel {
    enum Action {
        case dummyAction
    }
    
    let input = PassthroughSubject<EditorViewModel.Action, Never>()
    let output = PassthroughSubject<EditorViewController.State, Never>()
    
    private let coordinator: EditorCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: EditorCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension EditorViewModel {
    
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
