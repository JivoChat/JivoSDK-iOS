//
//  FileManager+Extensions.swift
//  JivoFoundation
//
//  Created by Stan Potemkin on 19.02.2023.
//

import Foundation

public enum FileManagerRemovingStrategy {
    case single
    case satellites
}

public extension FileManager {
    func jv_removeItem(at url: URL?, strategy: FileManagerRemovingStrategy = .single) {
        guard let url = url
        else {
            return
        }
        
        do {
            switch strategy {
            case .single:
                try removeItem(at: url)
            case .satellites:
                let parentUrl = url.deletingLastPathComponent()
                try contentsOfDirectory(atPath: parentUrl.path)
                    .filter { name in
                        name.hasPrefix(url.lastPathComponent)
                    }
                    .forEach { name in
                        try? removeItem(at: parentUrl.appendingPathComponent(name))
                    }
            }
        }
        catch {
        }
    }
}
