//
//  
//  ExampleViewController.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 18.11.2021.
//
//

import UIKit
import Combine


// MARK: - ExampleViewController

final class ExampleViewController: UIViewController {
    enum State {
        case dummyState
    }
        
    @IBOutlet weak var buttonOne: UIButton!

    private let viewModel: ExampleViewModel
    private var bag = Set<AnyCancellable>()
    
    init(viewModel: ExampleViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: ExampleViewController.self), bundle: nil)
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

private extension ExampleViewController {
    
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
