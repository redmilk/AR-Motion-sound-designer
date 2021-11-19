//
//  AppDelegate.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 18.11.2021.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
//        JiggleAnalytics().setupAnalytics()
//
//        if UserDefaults.standard.bool(forKey: "firstLaunch") == false {
//            copyFilesFromBundleToDocumentsFolderWith(fileExtension: "wav")
//            copyFilesFromBundleToDocumentsFolderWith(fileExtension: "mp3")
//            Zone.allCases.forEach { zone in
//                if UserDefaults.standard.object(forKey: zone.keyValue) == nil {
//                    UserDefaults.standard.set(zone.rawValue, forKey: zone.keyValue)
//                }
//            }
//            if UserDefaults.standard.object(forKey: "backgroundBeatFileName") == nil {
//                UserDefaults.standard.set("jiggleBeat.wav", forKey: "backgroundBeatFileName")
//            }
//            rootController = UIStoryboard(.onboarding).instantiate(VideoVC.self)
//            UserDefaults.standard.set(true, forKey: "firstLaunch")
//        } else {
//            rootController = UIStoryboard(.main).instantiate(HomeVC.self)
//        }
//        window = UIWindow(frame: UIScreen.main.bounds)
//        window?.rootViewController = rootController
//        window?.makeKeyAndVisible()
//        UIApplication.shared.isIdleTimerDisabled = true
        
        return true
    }
    
//    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let fileName = url.lastPathComponent
//        let destURL = documentsUrl.appendingPathComponent(fileName)
//        if fileName.hasSuffix(".wav") || fileName.hasSuffix(".mp3") {
//            do {
//                if FileManager.default.fileExists(atPath: destURL.path) {
//                    try FileManager.default.removeItem(at: destURL)
//                }
//                try FileManager.default.copyItem(at: url, to: destURL)
//            } catch (let error) {
//                print("Can't copy item at \(url) to \(destURL): \(error)")
//            }
//            return true
//        }
//        return false
//    }
//
//    func copyFilesFromBundleToDocumentsFolderWith(fileExtension: String) {
//        if let resPath = Bundle.main.resourcePath {
//            do {
//                let dirContents = try FileManager.default.contentsOfDirectory(atPath: resPath)
//                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
//                let filteredFiles = dirContents.filter{ $0.contains(fileExtension)}
//                for fileName in filteredFiles {
//                    if let documentsURL = documentsURL {
//                        let sourceURL = Bundle.main.bundleURL.appendingPathComponent(fileName)
//                        let destURL = documentsURL.appendingPathComponent(fileName)
//                        do { try FileManager.default.copyItem(at: sourceURL, to: destURL) } catch { }
//                    }
//                }
//            } catch { }
//        }
//    }
}

