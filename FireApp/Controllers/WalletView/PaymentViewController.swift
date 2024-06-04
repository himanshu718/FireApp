//
//  PaymentViewController.swift
//  FireApp
//
//  Created by Kartik Gupta on 10/12/22.
//  Copyright © 2022 Devlomi. All rights reserved.
//

import UIKit
import Paystack
import FirebaseDatabase

class PaymentViewController: UIViewController, PSTCKPaymentCardTextFieldDelegate, UITextFieldDelegate {
    
    // MARK: REPLACE THESE
    // Replace these values with your application's keys
    // Find this at https://dashboard.paystack.co/#/settings/developer
//    let paystackPublicKey = "pk_test_60c9204c830ef444d36bae79499ce421648bb4d7"
     let paystackPublicKey = "pk_live_d5f3fd94e03bcfe9d41fe8166e9503ddd8241d91"
    
    // To set this up, see https://github.com/PaystackHQ/sample-charge-card-backend
    let backendURLString = "https://us-central1-gofernet.cloudfunctions.net/app/getUrl"
//     let backendURLString = "https://calm-scrubland-33409.herokuapp.com"
    
    let verificationUrlString = "https://us-central1-gofernet.cloudfunctions.net/app/verifyUrl?ref="
    
    @IBOutlet weak var netBalanceLabel: UILabel!
    let card : PSTCKCard = PSTCKCard()
    var netsAdded = 0
    @IBOutlet weak var numberOfNetsTxtField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    // MARK: Overrides
    let loading = LoadingViewController()
    override func viewDidLoad() {
        // hide token label and email box
        tokenLabel.text=nil
        tokenLabel.isHidden = true
        chargeCardButton.isEnabled = false
        chargeCardButton.alpha = 0.5
        numberOfNetsTxtField.delegate = self
        numberOfNetsTxtField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)

        emailTextField.delegate = self
        setInitialNetsData()
        // clear text from card details
        // comment these to use the sample data set
        super.viewDidLoad();
        setNavbar()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.title = "Wallet"
        self.navigationController?.navigationBar.topItem?.title = ""
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.init(hexString: "#2196f5")
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    // MARK: Helpers
    func showOkayableMessage(_ title: String, message: String){
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertController.Style.alert
        )
        let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    func dismissKeyboardIfAny(){
        // Dismiss Keyboard if any
        cardDetailsForm.resignFirstResponder()
        
    }
    
    
    // MARK: Properties
    @IBOutlet weak var cardDetailsForm: PSTCKPaymentCardTextField!
    @IBOutlet weak var chargeCardButton: UIButton!
    @IBOutlet weak var tokenLabel: UILabel!
    
    // MARK: Actions
    @IBAction func cardDetailsChanged(_ sender: PSTCKPaymentCardTextField) {
        chargeCardButton.isEnabled = sender.isValid
        chargeCardButton.alpha = sender.isValid ? 1.0 : 0.5
    }
    
    @IBAction func btnBankTransfer(_ sender: Any) {
        if let url = URL(string: Config.bankTransfer) {
            UIApplication.shared.open(url)
        }
    }
    
    @IBAction func chargeCard(_ sender: UIButton) {
        
        dismissKeyboardIfAny()
        
        if !isValidNet(numberOfNetsTxtField.text ?? "") {
            showAlert("Please enter valid amount of net")
            return
        }
        
        if !isValidEmail(emailTextField.text ?? "") {
            showAlert("Please enter a valid Email address")
            return
        }
        
        // Make sure public key has been set
        if (paystackPublicKey == "" || !paystackPublicKey.hasPrefix("pk_")) {
            showOkayableMessage("You need to set your Paystack public key.", message:"You can find your public key at https://dashboard.paystack.co/#/settings/developer .")
            // You need to set your Paystack public key.
            return
        }
        
        Paystack.setDefaultPublicKey(paystackPublicKey)
        
        if cardDetailsForm.isValid {
            
            if backendURLString != "" {
                fetchAccessCodeAndChargeCard()
                return
            }
            showOkayableMessage("Backend not configured", message:"To run this sample, please configure your backend.")
        }
        
    }
    
    func outputOnLabel(str: String){
        DispatchQueue.main.async {
            if let former = self.tokenLabel.text {
                self.tokenLabel.text = former + "\n" + str
            } else {
                self.tokenLabel.text = str
            }
        }
    }
    
    func fetchAccessCodeAndChargeCard() {
        var amountCharged = 0
        if let amount = numberOfNetsTxtField.text, let amountInt = Int(amount) {
            amountCharged = amountInt * 10000
        }
        let parameters: [String: Any] = [
            "amount" : amountCharged,
            "email" : emailTextField.text!
        ]
        if let url = URL(string: backendURLString) {
            showLoader()
            self.makeBackendRequest(url: url, parameters: parameters, message: "fetching access code", completion: { str in
                self.outputOnLabel(str: "Fetched access code: "+str)
                self.chargeWithSDK(newCode: str as NSString)
            })
        }
    }
    
    private func setAvailableNetsData() {
        showLoader()
        let ref = FireConstants.usersRef.child(FireManager.getUid())
        ref.observeSingleEvent(of: .value) { snapshot in
            if !snapshot.exists() {
                self.dismissLoader()
                self.showAlert("Something went wrong, Please check in sometime if net balance is updated")
                return
            }
            
            print(snapshot) // Its print all values including Snap (User)
            
            print(snapshot.value!)
            
            if let nets = snapshot.childSnapshot(forPath: "netsAvailable").value as? Int {
                let totalNets = nets + self.netsAdded
                ref.child("netsAvailable").setValue(totalNets)
                self.netBalanceLabel.text = "\(totalNets)"
                self.dismissLoader()
                self.showAlert("Congratulations,Your Transaction is Successful!\nYour Updated net balance is \(totalNets)", true)
            } else {
                self.dismissLoader()
                self.showAlert("Something went wrong, Please check in sometime if net balance is updated")
            }
        }
        
    }
    
    private func setInitialNetsData() {
        
        showLoader()
        FirebaseManager.sharedFirebaseManager.getPromotionAvailability { isPromotion, error in
            if error == nil {
                let ref = FireConstants.usersRef.child(FireManager.getUid())
                ref.observeSingleEvent(of: .value) { snapshot in
                    if !snapshot.exists() {
                        self.dismissLoader()
                        return
                    }
                    
                    if let isRewardReceived = snapshot.childSnapshot(forPath: "isRewardReceived").value as? Bool, isRewardReceived {
                        if let nets = snapshot.childSnapshot(forPath: "netsAvailable").value as? Int {
                            self.netBalanceLabel.text = "\(nets)"
                        } else {
                            self.netBalanceLabel.text = "0"
                        }
                        self.dismissLoader()
                    } else if isPromotion ?? false {
                        ref.child("netsAvailable").setValue(10) { (error, _) -> Void in
                            if error == nil {
                                ref.child("isRewardReceived").setValue(true)
                                self.netBalanceLabel.text = "10"
                                self.showAlert("Congratulations, You are awarded 10 Nets as rewards")
                            } else {
                                self.showAlert("Something went wrong, Please try again.")
                            }
                            self.dismissLoader()
                        }
                    } else {
                        if let nets = snapshot.childSnapshot(forPath: "netsAvailable").value as? Int {
                            self.netBalanceLabel.text = "\(nets)"
                        } else {
                            self.netBalanceLabel.text = "0"
                        }
                        self.dismissLoader()
                    }
                }
            } else {
                let ref = FireConstants.usersRef.child(FireManager.getUid())
                ref.observeSingleEvent(of: .value) { snapshot in
                    if !snapshot.exists() {
                        self.dismissLoader()
                        return
                    }
                    if let nets = snapshot.childSnapshot(forPath: "netsAvailable").value as? Int {
                        self.netBalanceLabel.text = "\(nets)"
                    } else {
                        self.netBalanceLabel.text = "0"
                    }
                    self.dismissLoader()
                }
            }
        }
        
    }
    
    func chargeWithSDK(newCode: NSString){
        let transactionParams = PSTCKTransactionParams.init();
        transactionParams.access_code = newCode as String;
        // use library to create charge and get its reference
        PSTCKAPIClient.shared().chargeCard(self.cardDetailsForm.cardParams, forTransaction: transactionParams, on: self, didEndWithError: { (error, reference) in
            self.outputOnLabel(str: "Charge errored")
            // what should I do if an error occured?
            print(error)
            if error._code == PSTCKErrorCode.PSTCKExpiredAccessCodeError.rawValue{
                // access code could not be used
                // we may as well try afresh
            }
            if error._code == PSTCKErrorCode.PSTCKConflictError.rawValue{
                // another transaction is currently being
                // processed by the SDK... please wait
            }
            if let errorDict = (error._userInfo as! NSDictionary?){
                if let errorString = errorDict.value(forKeyPath: "com.paystack.lib:ErrorMessageKey") as! String? {
                    if let reference=reference {
                        self.showOkayableMessage("An error occured while completing "+reference, message: errorString)
                        self.outputOnLabel(str: reference + ": " + errorString)
                        self.verifyTransaction(reference: reference)
                    } else {
                        self.showOkayableMessage("An error occured", message: errorString)
                        self.outputOnLabel(str: errorString)
                    }
                }
            }
            self.chargeCardButton.isEnabled = true;
            self.chargeCardButton.alpha = 1.0
        }, didRequestValidation: { (reference) in
            self.outputOnLabel(str: "requested validation: " + reference)
        }, willPresentDialog: {
            // make sure dialog can show
            // if using a "processing" dialog, please hide it
            self.outputOnLabel(str: "will show a dialog")
        }, dismissedDialog: {
            // if using a processing dialog, please make it visible again
            self.outputOnLabel(str: "dismissed dialog")
        }) { (reference) in
            self.outputOnLabel(str: "succeeded: " + reference)
            self.chargeCardButton.isEnabled = true;
            self.chargeCardButton.alpha = 1.0
            self.verifyTransaction(reference: reference)
        }
        return
    }
    
    func verifyTransaction(reference: String){
        showLoader()
        if let url = URL(string: verificationUrlString + reference) {
            let session = URLSession(configuration: URLSessionConfiguration.default)
            self.outputOnLabel(str: "Backend: " + "Verification")
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            let task = session.dataTask(with: request) { data, response, error in
                let successfulResponse = (response as? HTTPURLResponse)?.statusCode == 200
                if successfulResponse && error == nil && data != nil {
                    self.dismissLoader()
                    let paymentModel = try? JSONDecoder().decode(VerifyPayment.self, from: data!)
                    if paymentModel?.status == true {
                        self.netsAdded = ((paymentModel?.data?.amount ?? 0) / 100) / 100

                        self.setAvailableNetsData()
                    } else {
                        self.showAlert("Something wrong. Please try again")
                    }
                } else {
                    self.dismissLoader()
                    self.showAlert("Something wrong. Please try again")
                    if let e=error {
                        print(e.localizedDescription)
                        self.outputOnLabel(str: e.localizedDescription)
                    } else {
                        // There was no error returned though status code was not 200
                        print("There was an error communicating with your payment backend.")
                        self.outputOnLabel(str: "There was an error communicating with your payment backend while" + "verification")
                    }
                }
            }
            
            task.resume()
        }
    }
    
    func makeBackendRequest(url: URL, parameters: [String:Any], message: String, completion: @escaping (_ result: String) -> Void){
        let session = URLSession(configuration: URLSessionConfiguration.default)
        self.outputOnLabel(str: "Backend: " + message)
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        request.httpBody = parameters.percentEncoded()
        let task = session.dataTask(with: request) { data, response, error in
            let successfulResponse = (response as? HTTPURLResponse)?.statusCode == 200
            if successfulResponse && error == nil && data != nil {
                
                let paymentModel = try? JSONDecoder().decode(InitPayment.self, from: data!)

                if let str = paymentModel?.data?.accessCode {
                    self.dismissLoader()
                    completion(str as String)
                }  else {
                    self.dismissLoader()
                    self.showAlert("Something wrong. Please try again")
                    self.outputOnLabel(str: "<Unable to read response> while "+message)
                    print("<Unable to read response>")
                }
            } else {
                self.dismissLoader()
                self.showAlert("Something wrong. Please try again")
                if let e=error {
                    print(e.localizedDescription)
                    self.outputOnLabel(str: e.localizedDescription)
                } else {
                    // There was no error returned though status code was not 200
                    print("There was an error communicating with your payment backend.")
                    self.outputOnLabel(str: "There was an error communicating with your payment backend while "+message)
                }
            }
        }
        
        task.resume()
    }
    
    func setNavbar(){
        if #available(iOS 13.0, *) {
            // Create a custom navigation bar appearance for iOS 13 and later
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.backgroundColor = UIColor.init(hexString: "#2196f5")
            navigationBarAppearance.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
            navigationController?.navigationBar.standardAppearance = navigationBarAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        } else {
            // For iOS versions prior to 13
            navigationController?.navigationBar.barTintColor = UIColor.init(hexString: "#2196f5")
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        }
    }
    
    
}

extension PaymentViewController {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField == numberOfNetsTxtField {
            if let amount = textField.text, let amountInt = Int(amount) {
                chargeCardButton.setTitle("Proceed to Pay \(amountInt * 100) Naira", for: .normal)
            } else {
                chargeCardButton.setTitle("Proceed to Pay", for: .normal)
            }
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func isValidNet(_ net: String) -> Bool {
        if let net = Int(net), net > 0 {
            return true
        }
        return false
    }
    
    func showAlert(_ message: String, _ okAction: Bool = false) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default) { _ in
                // Code in this block will trigger when OK button is tapped.
                if okAction {
                    self.navigationController?.popViewController(animated: true)
                }
                print("Ok button tapped");
                
            })
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func showLoader() {
        DispatchQueue.main.async {
            self.loading.show(text: "Please wait...".localized)
        }
        
    }
    
    func dismissLoader() {
        DispatchQueue.main.async {
            self.loading.dismiss()
        }
    }
}

extension Dictionary {
    func percentEncoded() -> Data? {
        map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed: CharacterSet = .urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
