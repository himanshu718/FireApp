//
//  TextStatusVC.swift
//  FireApp
//
//  Created by Devlomi on 11/2/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift

protocol TextStatusDelegate {
    func didFinishWithText(textStatus:TextStatus)
}

class TextStatusVC: BaseVC {

    var delegate:TextStatusDelegate?
    
    //MARK: - Outlets
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var placeholderTextView: UITextView!

    @IBOutlet weak var btnFont: UIButton!
    @IBOutlet weak var btnBackground: UIButton!

    @IBOutlet weak var btnUpload: UIButton!

    @IBOutlet weak var btnUploadBottomConstraints: NSLayoutConstraint!

    let bottomConstraintConstant: CGFloat = 32

    let colors = TextStatusColors.colors
    var fonts: [UIFont]!
    var fontsNames = [String]()

    var currentFontIndex = 0
    var currentBackgroundIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        currentBackgroundIndex = colors.randomIndex()
        view.backgroundColor = colors[currentBackgroundIndex].toUIColor()

        fonts = getFonts()

        placeholderTextView.text = Strings.type_astatus
      
        btnFont.addTarget(self, action: #selector(btnFontTapped), for: .touchUpInside)
        btnBackground.addTarget(self, action: #selector(btnBackgroundTapped), for: .touchUpInside)
        btnUpload.addTarget(self, action: #selector(btnUploadTapped), for: .touchUpInside)

        textView.resizeFont()
        placeholderTextView.resizeFont()

        textView.delegate = self

        listenForKeyboard = true

        IQKeyboardManager.shared.enable = false

    }

    override func keyboardWillShow(keyboardFrame: CGRect?) {
        if let keyboardFrame = keyboardFrame {
            
            btnUploadBottomConstraints.constant = (keyboardFrame.height / 1.2)  + bottomConstraintConstant
            
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
    }

    //move upload button above the keyboard
    override func keyBoardWillHide() {
        btnUploadBottomConstraints.constant = bottomConstraintConstant
    }

    @objc private func btnUploadTapped() {
        let textStatus = TextStatus(text: textView.text, fontName: fontsNames[currentFontIndex], backgroundColor: colors[currentBackgroundIndex])
        delegate?.didFinishWithText(textStatus: textStatus)
        navigationController?.popViewController(animated: true)
    }

    @objc private func btnFontTapped() {
        currentFontIndex = currentFontIndex + 1 > fonts.lastIndex() ? 0 : currentFontIndex + 1
        let font = fonts[currentFontIndex]
        textView.font = font
        btnFont.titleLabel?.font = font.withSize(32)
        placeholderTextView.font = fonts[currentFontIndex]

        placeholderTextView.resizeFont()
        textView.resizeFont()

    }

    @objc private func btnBackgroundTapped() {
        currentBackgroundIndex = currentBackgroundIndex + 1 > colors.lastIndex() ? 0 : currentBackgroundIndex + 1

        view.backgroundColor = colors[currentBackgroundIndex].toUIColor()
    }



    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }

    private func getFonts() -> [UIFont] {
        var fonts = [UIFont]()

        if let infoDict = Bundle.main.infoDictionary,
            let fontFiles = infoDict["UIAppFonts"] as? [String] {
            for fontFile in fontFiles {
                fonts.append(UIFont.getFontByFileName(fontFile))
                fontsNames.append(fontFile)
            }
        }
        //if for any reason something above did not work revert back to system font
        if fonts.isEmpty {
            fonts.append(UIFont.systemFont(ofSize: 18))
        }

        return fonts
    }

}

extension TextStatusVC: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        placeholderTextView.isHidden = textView.text.isNotEmpty
        btnUpload.isEnabled = textView.text.isNotEmpty
        textView.resizeFont()
    }

}
