//
//  ViewController.swift
//  Coffeestats
//
//  Created by Danilo Bürger on 16/03/2017.
//  Copyright © 2017 Danilo Bürger. All rights reserved.
//

import UIKit
import Locksmith

class ViewController: UIViewController, QRCodeScannerDelegate {

    @IBOutlet weak var loginButton: UIBarButtonItem!
    @IBOutlet weak var webView: UIWebView!

    var onTheRun: String? {
        didSet {
            if let onTheRun = onTheRun {
                loginButton.title = "Logout"
                webView.loadRequest(URLRequest(url: URL(string: onTheRun)!))
                try? Locksmith.saveData(data: ["onTheRun": onTheRun], forUserAccount: "coffeestats")
            } else {
                loginButton.title = "Login"
                webView.loadRequest(URLRequest(url: URL(string: "about:blank")!))
                try? Locksmith.deleteDataForUserAccount(userAccount: "coffeestats")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let dictionary = Locksmith.loadDataForUserAccount(userAccount: "coffeestats"),
            let onTheRun = dictionary["onTheRun"] as? String {
            self.onTheRun = onTheRun
        }
    }

    func isAcceptable(_ qrCode: String) -> Bool {
        return qrCode.hasPrefix("https://coffeestats.org/ontherun/")
    }

    func didScan(_ qrCode: String) {
        _ = navigationController?.popToViewController(self, animated: true)
        login(qrCode)
    }

    @IBAction func handleLogin() {
        if onTheRun != nil {
            logout()
        } else {
            let vc = QRCodeScannerViewController()
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func login(_ onTheRun: String) {
        self.onTheRun = onTheRun
    }

    func logout() {
        onTheRun = nil
    }

}
