//
//  PhotoLibraryTypes.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 02/06/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation

import UIKit

enum PhotoSizeType: String {
    case preview
    case big
    case full
    case model
    case export
}

enum PhotoResult {
    case progress(Double)
    case image(UIImage, URL?, Date?, String)
    case failure
}
