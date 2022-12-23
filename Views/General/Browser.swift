//
//  Browser.swift
//  Life@USTC (iOS)
//
//  Created by TiankaiMa on 2022/12/15.
//

import SwiftUI
import WebKit


struct SwiftUIWebView: UIViewRepresentable {
    typealias UIViewType = WKWebView
    let webView: WKWebView
    var url: URL
    
    init(url: URL) {
        self.url = url
        let wkWebConfig = WKWebViewConfiguration()
        for cookie in mainUstcCasClient.vaildCookie() {
            wkWebConfig.websiteDataStore.httpCookieStore.setCookie(cookie)
        }
        wkWebConfig.defaultWebpagePreferences.preferredContentMode = .mobile
        wkWebConfig.upgradeKnownHostsToHTTPS = true
        webView = WKWebView(frame: .zero, configuration: wkWebConfig)
        // identify self as mobile client, so that the website will render the mobile version
        webView.customUserAgent = #"Mozilla/5.0 (iPod; CPU iPhone OS 12_0 like macOS) AppleWebKit/602.1.50 (KHTML, like Gecko) Version/12.0 Mobile/14A5335d Safari/602.1.50"#
    }
    func makeUIView(context: Context) -> WKWebView {
        self.webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        self.webView.load(URLRequest(url: url))
    }
}

struct Browser: View {
    var url: URL
    var title: String
    
    var body: some View {
        SwiftUIWebView(url: url)
            .padding([.leading,.trailing],2)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: self.url) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
    
    init(url: URL, title: String? = nil) {
        self.url = url
        if let title {
            self.title = title
        } else {
            self.title = "Detail"
        }
        self.title = NSLocalizedString(self.title, comment: "")
    }
}
