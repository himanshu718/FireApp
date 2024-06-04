//
//  NetworkTypesTableVC.swift
//  FireApp
//
//  Created by Devlomi on 11/18/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit

class NetworkTypesTableVC: BaseTableVC {

    private var mediaType: MediaType!
    private var currentTypeIndex: IndexPath!

    override func viewDidLoad() {
        super.viewDidLoad()


        let networkType = UserDefaultsManager.getAutoDownloadTypeForMediaType(mediaType)
        var index = 0
        switch networkType {
        case .never:
            index = 0
        case .wifi:
            index = 1
        default:
            index = 2
        }

        currentTypeIndex = IndexPath(row: index, section: 0)
        
        navigationItem.title = mediaType.string
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if indexPath == currentTypeIndex {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentTypeIndex = indexPath
        tableView.reloadData()

        var selectedNetworkType: AutoDownloadNetworkType!
        
        switch indexPath.row {
        case 0:
            selectedNetworkType = .never
        case 1:
            selectedNetworkType = .wifi
        default:
            selectedNetworkType = .wifi_cellular
        }
        
        UserDefaultsManager.setAutoDownloadTypeForMediaType(mediaType, selectedNetworkType)
    }

    func initialize(mediaType: MediaType) {
        self.mediaType = mediaType
    }


}
