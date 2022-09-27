//
//  UIViewController+Extensions.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 22.01.2022.
//

import UIKit.UIActivityIndicatorView

extension UIViewController {
    func share(with textToShare: String) {
        let id: String = .emojiString + .emojiString + .emojiString + .emojiString + .emojiString + .emojiString
        let objectsToShare = [textToShare, id] as [Any]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.excludedActivityTypes = [UIActivity.ActivityType.addToReadingList]
        self.present(activityVC, animated: true, completion: nil)
    }
}


