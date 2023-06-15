//
//  WebBrowsingBridge.swift
//  App
//
//  Created by Stan Potemkin on 18.08.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import WebKit

protocol IWebBrowsingBridge: AnyObject {
    func presentBrowser(within container: UIViewController, url: URL, mime: String?)
}

final class WebBrowsingBridge: NSObject, IWebBrowsingBridge, WKNavigationDelegate, WKUIDelegate {
    func presentBrowser(within container: UIViewController, url: URL, mime: String?) {
        let config = WKWebViewConfiguration()
        config.dataDetectorTypes = .all
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        let navigationController = WebBrowsingNavigationController()
        defer {
            container.present(navigationController, animated: true)
        }
        
        let viewController = WebBrowsingViewController()
        viewController.configureNavigationBar(button: .dismiss, target: navigationController, backButtonTapAction: #selector(WebBrowsingNavigationController.handleDismiss))
        viewController.navigationItem.jv_largeDisplayMode = .never
        viewController.edgesForExtendedLayout = []
        viewController.view.backgroundColor = .white
        navigationController.viewControllers = [viewController]
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsLinkPreview = false
        webView.scrollView.bounces = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        webView.frame = viewController.view.bounds
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.view.addSubview(webView)
        
        if let mime = mime {
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    if let data = data {
                        webView.load(data, mimeType: mime, characterEncodingName: "utf-8", baseURL: url)
                        viewController.navigationItem.title = url.lastPathComponent
                    }
                    else {
                        webView.load(URLRequest(url: url))
                        viewController.navigationItem.title = url.absoluteString
                    }
                }
            }
            
            viewController.associatedDataTask = task
            task.resume()
        }
        else {
            webView.load(URLRequest(url: url))
            viewController.navigationItem.title = url.absoluteString
        }
    }
}

fileprivate final class WebBrowsingNavigationController: UINavigationController {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        if #available(iOS 13.0, *) {
            navigationBar.scrollEdgeAppearance = navigationBar.standardAppearance
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func handleDismiss() {
        dismiss(animated: true)
    }
}

fileprivate final class WebBrowsingViewController: UIViewController, NavigationBarConfigurator {
    var associatedDataTask: URLSessionDataTask?
    
    deinit {
        associatedDataTask?.cancel()
    }
}
