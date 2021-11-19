
import UIKit
import Segment
import Amplitude
import AppsFlyerLib

class JiggleAnalytics: NSObject {
    
    func setupAnalytics() {
        #if !DEBUG
        // Segment
        let configurationSegment = AnalyticsConfiguration(writeKey: Constant.segmentWriteKey)
        configurationSegment.trackApplicationLifecycleEvents = true
        Analytics.setup(with: configurationSegment)
        
        // Amplitude
        Amplitude.instance().trackingSessionEvents = true
        Amplitude.instance().initializeApiKey(Constant.amplitudeApiKey)
        
        // AppsFlyer
        AppsFlyerLib.shared().appsFlyerDevKey = Constant.appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = Constant.appsFlyerAppId
        AppsFlyerLib.shared().delegate = self
        #endif
    }
    
    static func logAmplitudeEvent(_ eventName: String) {
        #if !DEBUG
        Amplitude.instance().logEvent(eventName)
        #endif
    }
    
    static func logAmplitudeEvent(_ eventName: String, with properties: [String : Any]) {
        #if !DEBUG
        Amplitude.instance().logEvent(eventName, withEventProperties: properties)
        #endif
    }
}

extension JiggleAnalytics: AppsFlyerLibDelegate {
    
    func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        
    }
    
    func onConversionDataFail(_ error: Error) {
        
    }
}
