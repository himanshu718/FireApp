//
//  ProximitySensorHelper.swift
//  FireApp
//
//  Created by Devlomi on 12/26/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

protocol ProximitySensorDelegate {
    func didChange(near:Bool)
}
class ProximitySensorHelper {
    private var delegate:ProximitySensorDelegate
    
    init(delegate:ProximitySensorDelegate) {
        self.delegate = delegate
    }
    
    func setProximitySensorEnabled(_ enabled: Bool) {
        let device = UIDevice.current
        device.isProximityMonitoringEnabled = enabled
        if device.isProximityMonitoringEnabled {
            NotificationCenter.default.addObserver(self, selector: #selector(proximityChanged), name: UIDevice.proximityStateDidChangeNotification, object: device)
        } else {
            NotificationCenter.default.removeObserver(self, name: UIDevice.proximityStateDidChangeNotification, object: nil)
        }
    }

    @objc private func proximityChanged(_ notification: Notification) {
        if let device = notification.object as? UIDevice {
            let near = device.proximityState
            delegate.didChange(near: near)
        }
    }
}
