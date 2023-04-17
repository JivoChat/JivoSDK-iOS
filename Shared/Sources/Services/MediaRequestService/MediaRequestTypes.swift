//
// Created by Stan Potemkin on 2019-05-23.
// Copyright (c) 2019 JivoSite. All rights reserved.
//

import Foundation

import UIKit

enum MediaResponse {
    case progress(Double)
    case photo(UIImage, URL?, Date?, String)
    case video(URL)
}
