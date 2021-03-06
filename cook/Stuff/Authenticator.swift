//
//  Authenticator.swift
//  cook
//
//  Created by ned on 04/12/2019.
//  Copyright © 2019 ned. All rights reserved.
//

import AltSign

extension Notification.Name {
    static let fetchAnisetteData = Notification.Name("it.ned.FetchAnisetteData")
    static let receivedAnisetteData = Notification.Name("it.ned.ReceivedAnisetteData")
}

class Authenticator {
    
    var completionHandler: ((ALTAccount?, ALTAppleAPISession?, Error?) -> Void)?
    var appleId: String
    var password: String
    
    deinit {
        DistributedNotificationCenter.default.removeObserver(self)
    }
    
    init(appleId: String, password: String) {
        self.appleId = appleId
        self.password = password
    }
    
    func start() {
        
        // Open Mail.app
        Utils.shell("open", "-j", "-g", "-a", "Mail")
        
        delay(1) {
            DistributedNotificationCenter.default.addObserver(self, selector: #selector(self.received), name: .receivedAnisetteData, object: nil)
            DistributedNotificationCenter.default().postNotificationName(.fetchAnisetteData, object: nil, userInfo: ["uuid": UUID().uuidString], deliverImmediately: true)
        }
    }
    
    @objc func received(_ notification: Notification) {

        func abort(_ error: AuthError) {
            completionHandler?(nil, nil, error)
        }
        
        do {
            guard let userInfo = notification.userInfo else { return abort(.missingUserInfoDictionary) }
            guard let archivedData = userInfo["anisetteData"] as? Data else { return abort(.missingAnisetteData) }
            guard let anisetteData = try NSKeyedUnarchiver.unarchivedObject(ofClass: ALTAnisetteData.self, from: archivedData) else { return abort(.malformedAnisetteData) }
            
            logger.log(.info, "Logging in...")
            ALTAppleAPI.shared.authenticate(appleID: self.appleId, password: self.password, anisetteData: anisetteData, verificationHandler: nil, completionHandler: { [weak self] (account, session, error) in
                self?.completionHandler?(account, session, error)
            })
            
        } catch {
            return abort(.unableToUnarchive)
        }
    }
    
}
