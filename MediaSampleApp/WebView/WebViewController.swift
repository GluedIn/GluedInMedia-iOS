//
//  WebViewController.swift
//  GluedIn
//
//  Created by Ashish on 25/08/25.
//

import UIKit
import WebKit


protocol WebViewControllerDelegate: AnyObject {
    func didFinish(title: String?)
}

class WebViewController: UIViewController {

    @IBOutlet weak var viewNavigation: UIView!
    @IBOutlet weak var buttonBack: UIButton!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelUrl: UILabel!
    @IBOutlet weak var webView: WKWebView!
    
    // Observers for KVO on webView.url and (optionally) title
    private var urlObservation: NSKeyValueObservation?
    private var titleObservation: NSKeyValueObservation?
    weak var delegate: WebViewControllerDelegate?
    
    var url: String?
    var navTitle: String?
    
    // MARK: - Cookie Persistence
    private func saveCookies() {
        webView?.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
    }
    
    private func restoreCookies(completion: @escaping () -> Void) {
        let persistedCookies = HTTPCookieStorage.shared.cookies ?? []
        let cookieStore = webView?.configuration.websiteDataStore.httpCookieStore
        let dispatchGroup = DispatchGroup()
        
        for cookie in persistedCookies {
            dispatchGroup.enter()
            cookieStore?.setCookie(cookie) {
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        webView.configuration.preferences.javaScriptEnabled = config.preferences.javaScriptEnabled
        webView.configuration.websiteDataStore = config.websiteDataStore
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1"
        
        webView.navigationDelegate = self
        
        // Inject a script + message handler to catch SPA (pushState/replaceState/popstate/hashchange) URL changes
        let userContent = webView.configuration.userContentController
        userContent.add(self, name: "navigationObserver")
        userContent.addUserScript(makeSPASpyUserScript())

        // Observe URL changes (covers normal navigations, many redirects, and hash changes)
        urlObservation = webView.observe(\.url, options: [.initial, .new]) { [weak self] _, _ in
            self?.updateUrlLabel(self?.webView.url)
        }

        // Optional: keep the nav title in sync with page title
        titleObservation = webView.observe(\.title, options: [.new]) { [weak self] _, _ in
            self?.labelTitle.text = self?.navTitle ?? (self?.webView.title ?? "")
        }
        
        if let urlString = url {
            restoreCookies { [weak self] in
                self?.sendRequest(urlString: urlString)
            }
        }
        
        labelTitle.text = navTitle ?? ""
        labelTitle.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        labelTitle.textColor = .white
        // labelUrl will be set by KVO; keep a fallback for initial passed-in url
        if let initial = url, !(initial.isEmpty) {
            labelUrl.text = initial
        }
        labelUrl.font = UIFont.systemFont(ofSize: 8, weight: .semibold) 
        labelUrl.textColor = .white
        labelUrl.isHidden = true
    }
    
    private func sendRequest(urlString: String) {
        var finalUrlString = urlString
        if !finalUrlString.hasPrefix("http://") && !finalUrlString.hasPrefix("https://") {
            finalUrlString = "https://\(finalUrlString)"
        }

        guard let url = URL(string: finalUrlString) else {
            print("Invalid URL: \(finalUrlString)")
            return
        }

        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    @IBAction func onclickBack(_ sender: UIButton) {
        delegate?.didFinish(title: navTitle)
        navigationController?.popViewController(animated: false)
    }
    
    // MARK: - URL label updater
    private func updateUrlLabel(_ url: URL?) {
        DispatchQueue.main.async { [weak self] in
            self?.labelUrl.text = url?.absoluteString ?? ""
        }
    }
    
    deinit {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "navigationObserver")
        // NSKeyValueObservation references auto-invalidate on deinit
    }

}

extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateUrlLabel(webView.url)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateUrlLabel(webView.url)
        saveCookies()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showErrorPage(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
       
        showErrorPage(error)
    }

    private func showErrorPage(_ error: Error) {
        let errorHTML = """
        <html><head><style>
        body { font-family: -apple-system; text-align: center; padding: 50px; }
        h2 { color: #cc0000; }
        </style></head><body>
        <h2>Failed to load page</h2>
        <p>\(error.localizedDescription)</p>
        </body></html>
        """
        webView.loadHTMLString(errorHTML, baseURL: nil)
    }
}

// MARK: - WKScriptMessageHandler
extension WebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "navigationObserver" else { return }
        if let href = message.body as? String, let url = URL(string: href) {
            updateUrlLabel(url)
        }
    }
}

// MARK: - SPA route-change spy script
private extension WebViewController {
    func makeSPASpyUserScript() -> WKUserScript {
        let source = """
        (function() {
          function notify() {
            try { window.webkit.messageHandlers.navigationObserver.postMessage(window.location.href); } catch(e) {}
          }
          // Hook pushState/replaceState
          (function(history) {
            var pushState = history.pushState;
            history.pushState = function() {
              var ret = pushState.apply(this, arguments);
              notify();
              return ret;
            };
            var replaceState = history.replaceState;
            history.replaceState = function() {
              var ret = replaceState.apply(this, arguments);
              notify();
              return ret;
            };
          })(window.history);
          // Listen to back/forward and hash changes
          window.addEventListener('popstate', notify);
          window.addEventListener('hashchange', notify);
          // Initial notify when DOM is interactive/ready
          document.addEventListener('readystatechange', function() {
            if (document.readyState === 'interactive' || document.readyState === 'complete') {
              notify();
            }
          });
        })();
        """
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }
}
