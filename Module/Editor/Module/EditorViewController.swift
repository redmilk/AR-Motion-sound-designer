//
//  
//  EditorViewController.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 27.12.2021.
//
//

import UIKit
import Combine


// MARK: - EditorViewController

final class EditorViewController: UIViewController {
    enum State {
        case dummyState
    }
        
    private let viewModel: EditorViewModel
    private var bag = Set<AnyCancellable>()
    
    init(viewModel: EditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: EditorViewController.self), bundle: nil)
        /**
         CONNECT FILE'S OWNER TO SUPERVIEW IN XIB FILE
         CONNECT FILE'S OWNER TO SUPERVIEW IN XIB FILE
         CONNECT FILE'S OWNER TO SUPERVIEW IN XIB FILE
         */
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        handleStates()
    }
}

// MARK: - Internal

private extension EditorViewController {
    
    /// Handle ViewModel's states
    func handleStates() {
        viewModel.output.sink(receiveValue: { [weak self] state in
            switch state {
            case .dummyState:
                break
            }
        })
        .store(in: &bag)
    }
}
