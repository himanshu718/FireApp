//
//  AuthVC.swift
//  FireApp
//
//  Created by iMac on 29/03/24.
//  Copyright © 2024 Devlomi. All rights reserved.
//

import UIKit
import Firebase
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit


@available(iOS 13.0, *)
class AuthVC: UIViewController {
    
    private let appleSignInBtn = ASAuthorizationAppleIDButton()
    fileprivate var currentNonce: String?
    var window: UIWindow?
    
    @IBOutlet weak var btnGoogleSignIN: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextWord: UITextField!
    @IBOutlet weak var confirmPasswordTxt: UITextField!
    @IBOutlet weak var btnSignUp: UIButton!
    @IBOutlet weak var lblSignUp: UILabel!
    
    @IBOutlet weak var lblAccount: UILabel!
    
    @IBOutlet weak var lblDoHaveAccount: UILabel!
    @IBOutlet weak var btnSwitch: UIButton!
    
    @IBOutlet weak var signUpBtnConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var btnForgetPassword: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnForgetPassword.isHidden = true
        setUpUI()
        addAppleSignInButton()
        appleSignInBtn.addTarget(self, action: #selector(signInWithApple), for: .touchUpInside)
    }
    
    func addAppleSignInButton() {
        view.addSubview(appleSignInBtn)
        appleSignInBtn.translatesAutoresizingMaskIntoConstraints = false
        appleSignInBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        appleSignInBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        appleSignInBtn.topAnchor.constraint(equalTo: btnGoogleSignIN.bottomAnchor, constant: 20).isActive = true
        appleSignInBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        appleSignInBtn.layer.cornerRadius = 15
        appleSignInBtn.clipsToBounds = true
    }
    
    func setUpUI(){
        //btnGoogleSignIN
        let buttonImage = UIImage(named: "google")
        let buttonText = "Continue with Google"
        btnGoogleSignIN.setImage(buttonImage, for: .normal)
        btnGoogleSignIN.setTitle(buttonText, for: .normal)
        btnGoogleSignIN.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20)
        
        setUpTextField(emailTextField, imageName: "mail", placeholder: "Email")
        setUpTextField(passwordTextWord, imageName: "password", placeholder: "Password")
        setUpTextField(confirmPasswordTxt, imageName: "password", placeholder: "Confirm Password")
        
        
    }
    
    func setUpTextField(_ textField: UITextField, imageName: String, placeholder: String) {
        let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .center
        imageView.tintColor = textField.placeholderColor
        imageView.frame = CGRect(x: 0, y: 0, width: 50, height: textField.frame.height)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: textField.frame.height))
        view.addSubview(imageView)
        textField.leftViewMode = .always
        textField.leftView = view
        textField.placeholder = placeholder
    }
    
    func isValidEmail(_ email: String) -> Bool {
        // Regular expression for validating email address
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    
    @IBAction func btnGoogleSignInAction(_ sender: UIButton) {
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [unowned self] result, error in
            guard error == nil else {
                // Handle the error appropriately
                return // Exit the scope if there's an error
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString
            else {
                // Handle the scenario where either user is nil or idToken is nil
                return // Exit the scope if either user or idToken is nil
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            Auth.auth().signIn(with: credential) { authResult, error in
                print("authResult\(authResult)")
                guard error == nil else {
                    print(error)
                    return
                }
                
                // User is successfully signed in
                UserDefaultsManager.setAgreedToPolicy(bool: true)
                let vc = LoginVC()
                AppDelegate.shared.window?.rootViewController = vc
            }
        }
    }
    
    @objc func signInWithApple(_ sender: Any) {
        startSignInWithAppleFlow()
    }
    
    @IBAction func btnSignInAction(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert(type: .error, message: "Please enter your email")
            return
        }
        
        guard isValidEmail(email) else {
            showAlert(type: .error, message: "Please enter a valid email address")
            return
        }
        
        guard let password = passwordTextWord.text, !password.isEmpty else {
            showAlert(type: .error, message: "Please enter your password")
            return
        }
        
        if lblSignUp.text == "Sign Up" {
            guard let confirmPassword = confirmPasswordTxt.text, !confirmPassword.isEmpty else {
                showAlert(type: .error, message: "Please confirm your password")
                return
            }
            
            if password != confirmPassword {
                showAlert(type: .error, message: "Passwords don't match")
                return
            }
            
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.showAlert(type: .error, message: error.localizedDescription)
                } else {
                    // Send email verification
                    authResult?.user.sendEmailVerification(completion: { (error) in
                        if let error = error {
                            print("Error sending verification email: \(error.localizedDescription)")
                            // Handle error while sending verification email
                        } else {
                            // Verification email sent successfully
                            self.lblSignUp.text = "Sign In"
                            self.lblAccount.text = "Sign in to your account"
                            self.confirmPasswordTxt.isHidden = true
                            self.btnSignUp.setTitle("Sign In", for: .normal)
                            self.lblDoHaveAccount.text = "Don't have an account ?"
                            self.btnSwitch.setTitle("Sign Up", for: .normal)
                            self.signUpBtnConstraint.constant = 53
                            self.btnForgetPassword.isHidden = false
                            self.emailTextField.text = ""
                            self.passwordTextWord.text = ""
                            self.confirmPasswordTxt.text = ""
                            self.showAlert(type: .success, message: "Verification email sent. Please verify your email before signing in.")
                        }
                    })
                }
            }
        } else {
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.showAlert(type: .error, message: error.localizedDescription)
                } else {
                    // Check if the user's email is verified
                    if let user = Auth.auth().currentUser, user.isEmailVerified {
                        UserDefaultsManager.setAgreedToPolicy(bool: true)
                        
                        // Check if user data exists in the database
                        let usersRef = Database.database().reference().child("users").child(user.uid)
                        usersRef.observeSingleEvent(of: .value) { (snapshot, error) in
                            // Check for errors
                            if let error = error {
                                print("Error fetching user data: \(error)")
                                return
                            }
                            if snapshot.exists() {
                                // User data exists, save user or perform other actions
                                if let userData = snapshot.value as? [String: Any] {
                                    // Assuming User is your custom model class
                                    let user = User(value: userData)
//                                    self.saveUser(user)
                                    let realmHelper = RealmHelper.getInstance(appRealm)
                                    let uid = authResult?.user.uid
                                    let currentUid = CurrentUid(uid: uid!)
                                    realmHelper.saveObjectToRealm(object: currentUid)
            
                                    UserDefaultsManager.setUserInfoSaved(true)
                                    let rootNavController = self.storyboard!.instantiateViewController(withIdentifier: "RootNavController")
                                    AppDelegate.shared.window?.rootViewController = rootNavController
                                }
                            } else {
                                // User data does not exist, redirect to enter username activity
                                let vc = LoginVC()
                                AppDelegate.shared.window?.rootViewController = vc
                            }
                        } withCancel: { (error) in
                            // Handle database error
                        }
                        
                        // Redirect to main activity if user data exists
                        
                    } else {
                        self.showAlert(type: .error, message: "Please verify your email before signing in.")
                    }
                }
            }
            
        }
    }
    
    
    @IBAction func btnSignIn(_ sender: Any) {
        
        if lblSignUp.text == "Sign In" {
            lblSignUp.text = "Sign Up"
            lblAccount.text = "Create your account"
            confirmPasswordTxt.isHidden = false
            btnSignUp.setTitle("Sign Up", for: .normal)
            lblDoHaveAccount.text = "Already have an account ?"
            btnSwitch.setTitle("Sign In", for: .normal)
            signUpBtnConstraint.constant = 85
            btnForgetPassword.isHidden = true
            emailTextField.text = ""
            passwordTextWord.text = ""
            confirmPasswordTxt.text = ""
        } else {
            lblSignUp.text = "Sign In"
            lblAccount.text = "Sign in to your account"
            confirmPasswordTxt.isHidden = true
            btnSignUp.setTitle("Sign In", for: .normal)
            lblDoHaveAccount.text = "Don't have an account ?"
            btnSwitch.setTitle("Sign Up", for: .normal)
            signUpBtnConstraint.constant = 53
            btnForgetPassword.isHidden = false
            emailTextField.text = ""
            passwordTextWord.text = ""
            confirmPasswordTxt.text = ""
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    
    @IBAction func btnForgetPasswordAction(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert(type: .error, message: "Please enter your email")
            return
        }
        
        guard isValidEmail(email) else {
            showAlert(type: .error, message: "Please enter a valid email address")
            return
        }
        
        // Send password reset email
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                self.showAlert(type: .error, message: error.localizedDescription)
            } else {
                self.showAlert(type: .success, message: "Password reset email sent successfully. Please check your email inbox.")
            }
        }
    }
    
   

    // Function to generate a random nonce string
    fileprivate func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    // Function to create SHA256 hash
    fileprivate func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
    }

    // Function to start Apple sign-in flow
    @available(iOS 13.0, *)
    func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

}

extension UITextField {
    var placeholderColor: UIColor? {
        get {
            guard let placeholderText = self.placeholder else { return nil }
            return attributedPlaceholder?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        }
    }
}

@available(iOS 13.0, *)
extension AuthVC: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            // Initialize a Firebase credential, including the user's full name.
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    print("Error signing in with Apple: \(error.localizedDescription)")
                    return
                }
                
                // User is signed in to Firebase with Apple successfully.
                UserDefaultsManager.setAgreedToPolicy(bool: true)
                let vc = LoginVC()
                AppDelegate.shared.window?.rootViewController = vc
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple errored: \(error.localizedDescription)")
        // Handle error
    }
}

@available(iOS 13.0, *)
extension AuthVC: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }
}


