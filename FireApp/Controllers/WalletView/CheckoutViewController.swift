////
////  CheckoutViewController.swift
////  FireApp
////
////  Created by Kartik Gupta on 14/12/22.
////  Copyright © 2022 Devlomi. All rights reserved.
////
//
//import UIKit
//import WebKit
//
//class CheckoutViewController: UIViewController, WKNavigationDelegate {
//
//    let callbackUrl = "CALLBACK_URL_GOES_HERE"
//    let pstkUrl =  "AUTHORIZATION_URL_GOES_HERE"
//
//    var webView = WKWebView()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.view.addSubview(webView)
//        webView.translatesAutoresizingMaskIntoConstraints = false
//        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
//        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
//        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
//        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
//
//        let urlRequest = URLRequest.init(url: URL.init(string: pstkUrl)!)
//        webView.load(urlRequest)
//        self.webView.navigationDelegate = self
//    }
//
//    func getQueryStringParameter(url: String, param: String) -> String? {
//        guard let url = URLComponents(string: url) else { return nil }
//        return url.queryItems?.first(where: { $0.name == param })?.value
//    }
//
//    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
//
//        if let url = navigationResponse.response.url {
//
//            /*
//             We control here when the user wants to cancel a payment.
//             By default a cancel action redirects to http://cancelurl.com/.
//             Based on our workflow we can for example remove the webview or push
//             another view to the user.
//             */
//            if url.absoluteString == "http://cancelurl.com/" || url.absoluteString == "https://standard.paystack.co/close" {
//                decisionHandler(.cancel)
//            }
//            else{
//                decisionHandler(.allow)
//            }
//
//            //After a successful transaction we can check if the current url is the callback url
//            //and do what makes sense for our workflow. We can get the transaction reference for example.
//
//            if url.absoluteString.hasPrefix(callbackUrl){
//                if let reference = getQueryStringParameter(url: url.absoluteString, param: "reference") {
//                    print("reference \(reference)")
//                    self.verifyTransaction(reference: reference)
//                }
//            }
//        }
//    }
//
//    func verifyTransaction(reference: String){
//        if let url = URL(string: backendURLString  + "/verify/" + reference) {
//            makeBackendRequest(url: url, message: "verifying " + reference, completion:{(str) -> Void in
//                self.outputOnLabel(str: "Message from paystack on verifying " + reference + ": " + str)
//            })
//        }
//    }
//
//    func makeBackendRequest(url: URL, message: String, completion: @escaping (_ result: String) -> Void){
//        let session = URLSession(configuration: URLSessionConfiguration.default)
//        self.outputOnLabel(str: "Backend: " + message)
//        session.dataTask(with: url, completionHandler: { data, response, error in
//            let successfulResponse = (response as? HTTPURLResponse)?.statusCode == 200
//            if successfulResponse && error == nil && data != nil {
//                if let str = NSString(data: data!, encoding: String.Encoding.utf8.rawValue){
//                    completion(str as String)
//                } else {
//                    self.outputOnLabel(str: "<Unable to read response> while "+message)
//                    print("<Unable to read response>")
//                }
//            } else {
//                if let e=error {
//                    print(e.localizedDescription)
//                    self.outputOnLabel(str: e.localizedDescription)
//                } else {
//                    // There was no error returned though status code was not 200
//                    print("There was an error communicating with your payment backend.")
//                    self.outputOnLabel(str: "There was an error communicating with your payment backend while "+message)
//                }
//            }
//        }).resume()
//    }
//
//}
