//
//  
//  CameraViewModel.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 06.12.2021.
//
//

import Foundation
import Combine
import AVFoundation
import UIKit

/// MARK: - Dependencies
extension CameraViewModel: ErrorHandlerProvider, SoundWithHandposeMechanicsProvider, SoundDropProvidable { }

final class CameraViewModel {
   enum Action {
      /// entry point for module
       case configureSession(videoPreview: CaptureVideoPreviewView,
                             annotationsPreview: AnnotationsOverlayView,
                             collectionMatrix: UICollectionView)
       case startSession
       case stopSession
       case toggleSession
       case viewDidLoad
   }
   
   let input = PassthroughSubject<CameraViewModel.Action, Never>()
   let output = PassthroughSubject<CameraViewController.State, Never>()
   
   private let coordinator: CameraCoordinatorProtocol & CoordinatorProtocol
   private var bag = Set<AnyCancellable>()
   
   init(coordinator: CameraCoordinatorProtocol & CoordinatorProtocol) {
      self.coordinator = coordinator
      
      /// handle actions sent to self
      input.sink(receiveValue: { [weak self] action in
         switch action {
         case .configureSession(let videPreview, let annotationsPreview, let collectionMatrix):
            self?.handposeMechanics.input.send(.configure(
               collection: collectionMatrix,
               videoPreview: videPreview,
               annotationsPreview: annotationsPreview))
         case .startSession:
            self?.handposeMechanics.input.send(.startSession)
         case .stopSession:
            self?.handposeMechanics.input.send(.stopSession)
         case .toggleSession:
             if let isRunning = self?.handposeMechanics.isSessionRunning {
                 self?.handposeMechanics.input.send(isRunning ? .stopSession : .startSession)
             }
         case .viewDidLoad: break
         }
      }).store(in: &bag)
      
      /// handle response from handpose mechanicsb
      handposeMechanics.output
         .throttle(for: .milliseconds(250), scheduler: DispatchQueue.main, latest: true)
         .sink(receiveValue: { [weak self] response in
            switch response {
            case .playSoundForZone(let soundName):
               ZoneBaseAudio.shared.playSoundForZone(with: soundName)
            case .captureSessionReceived(let preconfiguredCaptureSession):
               self?.output.send(.captureSessionReceived(preconfiguredCaptureSession))
            }
         })
         .store(in: &self.bag)
   }
   
   deinit {
      Logger.log(String(describing: self), type: .deinited)
   }
}
