//
//  CacheDriver.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 06.09.2019.
//  Copyright © 2019 JivoSite. All rights reserved.
//

import Foundation

import JMCodingKit
import Gzip
import CommonCrypto

struct CacheDriverItem {
    static let live = CacheDriverItem(fileName: "live")
    static let liveCoreData = CacheDriverItem(fileName: "livecd")
    static let typingCache = CacheDriverItem(fileName: "typing_cache.plist")
    static let timezones = CacheDriverItem(fileName: "timezones")
    
    let directoryName: String?
    let fileName: String
    
    init(directoryName: String?, fileName: String) {
        self.directoryName = directoryName
        self.fileName = fileName
    }
    
    init(fileName: String) {
        self.directoryName = nil
        self.fileName = fileName
    }
    
    init(directoryName: String?, hashing longName: String, ext: String?) {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let input = longName.data(using: .utf8) ?? Data()
        var output = Data(count: length)

        _ = output.withUnsafeMutableBytes { outputBytes -> UInt8 in
            input.withUnsafeBytes { inputBytes -> UInt8 in
                if let inputBytesBaseAddress = inputBytes.baseAddress, let outputBytesBlindMemory = outputBytes.bindMemory(to: UInt8.self).baseAddress {
                    let inputLength = CC_LONG(input.count)
                    CC_MD5(inputBytesBaseAddress, inputLength, outputBytesBlindMemory)
                }
                
                return 0
            }
        }
        
        let baseName = output.map({ String(format: "%02hhx", $0) }).joined()
        self.directoryName = directoryName
        self.fileName = [baseName, ext?.jv_valuable].compactMap({ $0 }).joined(separator: ".")
    }
    
    var relativePath: String {
        return [directoryName, fileName]
            .compactMap { $0 }
            .joined(separator: "/")
    }
    
    func within(directory: String?) -> CacheDriverItem {
        return CacheDriverItem(directoryName: directory, fileName: fileName)
    }
    
    func with(ext: String?) -> CacheDriverItem {
        let baseName = fileName.split(separator: ".").first.flatMap(String.init) ?? fileName
        return CacheDriverItem(
            directoryName: directoryName,
            fileName: [baseName, ext].jv_flatten().joined(separator: ".")
        )
    }
}

protocol ICacheDriver: AnyObject {
    func url(item: CacheDriverItem) -> URL?
    func existingUrl(item: CacheDriverItem) -> URL?
    func readObject<T: Codable>(item: CacheDriverItem) -> T?
    func write<T: Codable>(item: CacheDriverItem, object: T?)
    func readElement(item: CacheDriverItem) -> JsonElement?
    func write(item: CacheDriverItem, element: JsonElement?)
    func readData(item: CacheDriverItem) -> Data?
    func write(item: CacheDriverItem, data: Data)
    func delete(item: CacheDriverItem)
    func unzip(item: CacheDriverItem, data: Data) -> Data?
    func clear(item: CacheDriverItem)
    func replace(item: CacheDriverItem, sourceURL: URL) -> URL?
    func link(aliasItem: CacheDriverItem, realItem: CacheDriverItem)
    func link(aliasUrl: URL, realUrl: URL)
    func cleanUp(directoryItem: CacheDriverItem, olderThen: Date)
}

final class CacheDriver: ICacheDriver {
    private let storage: FileManager
    private let namespace: String
    private let cachingURL: URL?
    
    private let jsonCoder = JsonCoder()
    
    init(storage: FileManager, namespace: String, cachingURL: URL? = nil) {
        self.storage = storage
        self.namespace = namespace
        self.cachingURL = cachingURL ?? storage.urls(for: .cachesDirectory, in: .userDomainMask).first
    }
    
    func url(item: CacheDriverItem) -> URL? {
        return obtainItemURL(item)
    }
    
    func existingUrl(item: CacheDriverItem) -> URL? {
        if let url = url(item: item), storage.fileExists(atPath: url.path) {
            return url
        }
        else {
            return nil
        }
    }
    
    func readObject<T: Codable>(item: CacheDriverItem) -> T? {
        let url = obtainItemURL(item)
        guard let data = storage.contents(atPath: url.path) else {
            return nil
        }
        
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    func write<T: Codable>(item: CacheDriverItem, object: T?) {
        if let object = object {
            guard let data = try? JSONEncoder().encode(object) else { return }
            try? data.write(to: obtainItemURL(item))
        }
        else {
            delete(item: item)
        }
    }
    
    func readElement(item: CacheDriverItem) -> JsonElement? {
        let url = obtainItemURL(item)
        guard let data = FileManager.default.contents(atPath: url.path) else {
            return nil
        }
        
        return jsonCoder.decode(binary: data, encoding: .utf8)
    }
    
    func write(item: CacheDriverItem, element: JsonElement?) {
        guard let element = element else {
            return delete(item: item)
        }
        
        if let data = jsonCoder.encodeToBinary(element, encoding: .utf8) {
            try? data.write(to: obtainItemURL(item), options: .atomicWrite)
        }
    }
    
    func readData(item: CacheDriverItem) -> Data? {
        let url = obtainItemURL(item)
        return FileManager.default.contents(atPath: url.path)
    }
    
    func write(item: CacheDriverItem, data: Data) {
        let url = obtainItemURL(item)
        try? data.write(to: url, options: .atomicWrite)
    }
    
    func delete(item: CacheDriverItem) {
        let url = obtainItemURL(item)
        try? FileManager.default.removeItem(at: url)
    }
    
    func unzip(item: CacheDriverItem, data: Data) -> Data? {
        guard data.isGzipped else {
            return data
        }
        
        do {
            return try data.gunzipped()
        }
        catch {
            return data
        }
    }
    
    func clear(item: CacheDriverItem) {
        let url = obtainItemURL(item)
        try? storage.removeItem(at: url)
    }
    
    func replace(item: CacheDriverItem, sourceURL: URL) -> URL? {
        guard let targetURL = url(item: item) else {
            return nil
        }
        
        try? storage.removeItem(at: targetURL)
        try? storage.moveItem(at: sourceURL, to: targetURL)
        
        return targetURL
    }
    
    func link(aliasItem: CacheDriverItem, realItem: CacheDriverItem) {
        if let aliasURL = url(item: aliasItem), let realURL = url(item: realItem) {
            link(aliasUrl: aliasURL, realUrl: realURL)
        }
    }
    
    func link(aliasUrl: URL, realUrl: URL) {
        try? storage.linkItem(at: realUrl, to: aliasUrl)
    }
    
    func cleanUp(directoryItem: CacheDriverItem, olderThen: Date) {
        guard
            let directoryUrl = url(item: directoryItem),
            let items = try? storage.contentsOfDirectory(atPath: directoryUrl.path)
        else {
            return
        }
        
        for item in items {
            let itemUrl = directoryUrl.appendingPathComponent(item)
            
            guard
                let itemAttributes = try? storage.attributesOfItem(atPath: itemUrl.path),
                let itemCreationDate = itemAttributes[.creationDate] as? Date,
                itemCreationDate < olderThen
            else {
                continue
            }
            
            try? storage.removeItem(at: itemUrl)
        }
    }
    
    private func obtainItemURL(_ item: CacheDriverItem) -> URL {
        guard let cachingURL = cachingURL else {
            return URL(fileURLWithPath: "/tmp/jivo/\(item.relativePath)")
        }
        
        let url: URL
        if namespace.isEmpty {
            url = cachingURL
                .appendingPathComponent(item.relativePath, isDirectory: false)
        }
        else {
            url = cachingURL
                .appendingPathComponent(namespace, isDirectory: true)
                .appendingPathComponent(item.relativePath, isDirectory: false)
        }
        
        let directoryURL = url.deletingLastPathComponent()
        if !storage.fileExists(atPath: directoryURL.path) {
            try? storage.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return url
    }
}
