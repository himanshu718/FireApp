//
// Created by Devlomi on 2019-07-17.
// Copyright (c) 2019 Devlomi. All rights reserved.
//

import Foundation

enum DownloadUploadState: Int {
    case DEFAULT = 0

    case LOADING = 1
    case SUCCESS = 2
    case FAILED = 3
    //cancelled by user
    case CANCELLED = 4
    
  
}
