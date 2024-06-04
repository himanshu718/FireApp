//
//  BaseCell.swift
//  FireApp
//
//  Created by Devlomi on 7/11/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
protocol CellDelegate {
    func didClickCell(indexPath: IndexPath?)
    func didClickProgressBtn(indexPath: IndexPath)
    func didLongClickCell(indexPath: IndexPath?, view: UIView?)
    func didSelectItem(at indexPath: IndexPath)
    func didClickQuotedMessage(at indexPath: IndexPath)
}

class BaseCell: UITableViewCell {

    @IBOutlet weak var replyView: ReplyView!
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var progressButton: CustomProgressButton!
    //this might be null if the inherited class does not have sizeLbl
    @IBOutlet weak var sizeLbl: UILabel!


    var isInSelectMode = false
    var isMessageSelected = false

    var cellDelegate: CellDelegate?
    var indexPath: IndexPath!

    private var progressToken: CustomProgressButton.DisposeToken?

    func setBackgroundColor() -> Bool {
        return true
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none
        self.backgroundColor = .clear
        self.layer.backgroundColor = UIColor.clear.cgColor

        containerView.isUserInteractionEnabled = true
        containerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewTapped)))
        containerView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(viewLongTapped(sender:))))

        if replyView != nil {
            replyView.isUserInteractionEnabled = true
            replyView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(replyViewTapped)))
        }



    }



    @objc private func replyViewTapped() {
        cellDelegate?.didClickQuotedMessage(at: indexPath)
    }

    @objc private func viewTapped() {
        cellDelegate?.didClickCell(indexPath: indexPath)

    }

    @objc private func viewLongTapped(sender: UILongPressGestureRecognizer) {
        if (sender.state == UIGestureRecognizer.State.began) {
            cellDelegate?.didLongClickCell(indexPath: indexPath, view: containerView)
        }
    }


    func bind(message: Message,user:User) {
        timeLbl.text = TimeHelper.getTimeOnly(date: message.timestamp.toDate())
        initProgressButton(message: message)
        if replyView != nil {
            replyView.isHidden = message.quotedMessage == nil
            if let quotedMessage = message.quotedMessage {
                replyView.bind(quotedMessage: quotedMessage, user: user)
            }
        }
        
        if sizeLbl != nil{
              if message.downloadUploadState == .FAILED || message.downloadUploadState == .CANCELLED{
                      sizeLbl.isHidden = false
                      sizeLbl.text = message.metatdata
                  }else{
                      sizeLbl.isHidden = true
                  }
          }


    }

    private func initProgressButton(message: Message) {
        if progressButton == nil {
            return
        }

        progressButton.isSentType = message.typeEnum.isSentType()
        progressButton.downloadUploadState = message.downloadUploadState
        
        progressToken = progressButton.onTap { _ in
            self.cellDelegate?.didClickProgressBtn(indexPath: self.indexPath)
        }
    }
    func updateProgress(progress: Float) {
        if progressButton == nil {
            return
        }

        progressButton.strokeMode = .border(width: 4)
        progressButton.inProgressStrokeColor = .red
        progressButton.resume()
        progressButton.progress = progress

    }

    override func prepareForReuse() {
        super.prepareForReuse()
        progressToken?.dispose()

    }






}
