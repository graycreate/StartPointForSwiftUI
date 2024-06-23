#if os(iOS)
import SwiftUI
import Combine
import WebKit

@dynamicMemberLookup
public class WebViewStore: ObservableObject {
  @Published public var webView: FullScreenWKWebView {
    didSet {
      setupObservers()
    }
  }
  
  public init(webView: FullScreenWKWebView = FullScreenWKWebView()) {
    self.webView = webView
    self.webView.isOpaque = false
    self.webView.navigationDelegate = webView
    setupObservers()
  }
  
  private func setupObservers() {
    func subscriber<Value>(for keyPath: KeyPath<FullScreenWKWebView, Value>) -> NSKeyValueObservation {
      return webView.observe(keyPath, options: [.prior]) { _, change in
        if change.isPrior {
          self.objectWillChange.send()
        }
      }
    }
    // Setup observers for all KVO compliant properties
    observers = [
      subscriber(for: \.title),
      subscriber(for: \.url),
      subscriber(for: \.isLoading),
      subscriber(for: \.estimatedProgress),
      subscriber(for: \.hasOnlySecureContent),
      subscriber(for: \.serverTrust),
      subscriber(for: \.canGoBack),
      subscriber(for: \.canGoForward)
    ]
    if #available(iOS 15.0, macOS 12.0, *) {
      observers += [
        subscriber(for: \.themeColor),
        subscriber(for: \.underPageBackgroundColor),
        subscriber(for: \.microphoneCaptureState),
        subscriber(for: \.cameraCaptureState)
      ]
    }
#if swift(>=5.7)
    if #available(iOS 16.0, macOS 13.0, *) {
      observers.append(subscriber(for: \.fullscreenState))
    }
#else
    if #available(iOS 15.0, macOS 12.0, *) {
      observers.append(subscriber(for: \.fullscreenState))
    }
#endif
  }
  
  private var observers: [NSKeyValueObservation] = []
  
  public subscript<T>(dynamicMember keyPath: KeyPath<WKWebView, T>) -> T {
    webView[keyPath: keyPath]
  }
}


#if os(iOS)
/// A container for using a WKWebView in SwiftUI
public struct WebView: View, UIViewRepresentable {
  /// The WKWebView to display
  public let webView: WKWebView
  
  public init(webView: WKWebView) {
    self.webView = webView
  }
  
  public func makeUIView(context: UIViewRepresentableContext<WebView>) -> WKWebView {
    webView
  }
  
  public func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<WebView>) {
  }
}
#endif

#if os(macOS)
/// A container for using a WKWebView in SwiftUI
public struct WebView: View, NSViewRepresentable {
  /// The WKWebView to display
  public let webView: WKWebView
  
  public init(webView: WKWebView) {
    self.webView = webView
  }
  
  public func makeNSView(context: NSViewRepresentableContext<WebView>) -> WKWebView {
    webView
  }
  
  public func updateNSView(_ uiView: WKWebView, context: NSViewRepresentableContext<WebView>) {
  }
}
#endif

public class FullScreenWKWebView: WKWebView, WKNavigationDelegate {
  public var mailToClicked: ((String) -> Void)?
  
  public override var safeAreaInsets: UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
  }
  
  public func webView(_ webView: WKWebView,
                      decidePolicyFor navigationAction: WKNavigationAction,
                      decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    guard let url = navigationAction.request.url else {
      decisionHandler(.allow)
      return
    }
    
    if url.scheme == "mailto" {
      if let mailToClicked = self.mailToClicked {
        mailToClicked(url.absoluteString)
        decisionHandler(.cancel)
        return
      }
      if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        decisionHandler(.cancel)
      } else {
        decisionHandler(.allow)
      }
    } else {
      decisionHandler(.allow)
    }
  }
  
}
#endif
