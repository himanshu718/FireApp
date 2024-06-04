//
//  MediaPreviewVC.swift
//  FireApp
//
//  Created by Devlomi on 7/31/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
import RealmSwift

protocol MediaPreviewDelegate {
    func didPop(chatId: String, user: User, selectedIndex: IndexPath, currentItemPosition: Int)
}


class MediaPreviewVC: BaseVC, UICollectionViewDelegate, UICollectionViewDataSource {
    var delegate: MediaPreviewDelegate?
    private var items: Results<Message>!
    private var chatId: String!
    private var user: User!
    private var selectedItems = [IndexPath]()


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }



    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var toolbar: UIToolbar!

    @IBOutlet weak var btnForward: UIBarButtonItem!
    @IBOutlet weak var btnDelete: UIBarButtonItem!
    @IBOutlet weak var noItemsLbl: UILabel!

    @IBAction func forwardClicked(_ sender: Any) {


        let itemsToShare = selectedItems.map { items[$0.row] }.sorted(by: { $0.timestamp < $1.timestamp }).map { message -> Any in
            
                return URL(fileURLWithPath: message.localPath)
            }
        


        let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash


        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)

    }

    @IBAction func deleteClicked(_ sender: Any) {
        let alert = UIAlertController(title: Strings.confirmation, message: Strings.deleteItemConfirmation, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.no, style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: Strings.yes, style: .destructive, handler: { action in
         
            let messages = self.selectedItems.map{self.items![$0.row]}
            
            RealmHelper.getInstance(appRealm).deleteMessages(messages: messages)
            self.enableOrDisableItems()


            self.collectionView.reloadData()
            self.isInSelectMode = false

            //close this View if there are no other items
            if self.items.isEmpty {
                self.navigationController?.popToVc(viewController: ChatViewController.self)
            }
        }))
        self.present(alert, animated: true, completion: nil)

    }

    private var isInSelectMode = false {
        didSet {

            navigationItem.rightBarButtonItem?.title = self.isInSelectMode ? Strings.cancel : Strings.select

            if self.isInSelectMode {
                collectionView.allowsMultipleSelection = true


                animateToolbarHiding(hide: false)


            } else {
                collectionView.allowsMultipleSelection = false
                animateToolbarHiding(hide: true)

                for indexPath in selectedItems {
                    collectionView.deselectItem(at: indexPath, animated: true)


                }
            }


        }

    }

    private func animateToolbarHiding(hide: Bool) {
        toolbarBottomConstraint.constant = hide ? -1000 : 0

        if !hide {
            toolbar.isHidden = false
        }

        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        }) { _ in
            if hide {
                self.toolbar.isHidden = true
            }
        }
    }

    fileprivate func enableOrDisableItems() {
        noItemsLbl.isHidden = items.count > 0
        navigationItem.rightBarButtonItem?.isEnabled = items.count > 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        hero.isEnabled = true

        items = RealmHelper.getInstance(appRealm).getMediaInChat(chatId: chatId)

        collectionView.delegate = self
        collectionView.dataSource = self

        user = User()
        user.uid = chatId


        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.select, style: .plain, target: self, action: #selector(handleSelect))
        enableOrDisableItems()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeue(indexPath: indexPath) as MediaPreviewCell
        let message = items[indexPath.row]
        cell.bind(message: message)
        return cell

    }

    @objc private func handleSelect(_ sender: Any) {
        isInSelectMode = !isInSelectMode
    }

    public func initialize(chatId: String) {
        self.chatId = chatId
    }

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {


        if isInSelectMode {
            selectedItems.append(indexPath)
            updateToolbarButtonsVisibility()
        }
        else {
            collectionView.deselectItem(at: indexPath, animated: true)
            let message = items[indexPath.row]
            let storyboard = UIStoryboard(name: "Main", bundle: nil)

            let previewVc = storyboard.instantiateViewController(withIdentifier: "PreviewImageController") as! PreviewImageVideoViewController

            previewVc.initialize(chatId: chatId, user: user, messageId: message.messageId)

//            delegate?.didPop(chatId: chatId, user: user, selectedIndex: indexPath, currentItemPosition: indexPath.row)

//            navigationController?.popViewController(animated: true)
            
            navigationController?.pushViewController(previewVc, animated: true)

        }


    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if isInSelectMode {
            if let index = selectedItems.firstIndex(of: indexPath) {
                
                selectedItems.remove(at: index)
                
                updateToolbarButtonsVisibility()
                if selectedItems.isEmpty {
                    isInSelectMode = false
                }

            }
        }
    }
    private func updateToolbarButtonsVisibility() {
        btnDelete.isEnabled = !selectedItems.isEmpty
        btnForward.isEnabled = !selectedItems.isEmpty
    }


}
