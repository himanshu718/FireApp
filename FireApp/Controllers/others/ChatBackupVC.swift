//
//  ChatBackupVC.swift
//  FireApp
//
//  Created by Devlomi on 3/24/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import UIKit
import RealmSwift
import RxSwift

class ChatBackupVC: BaseVC {
    
    @IBOutlet weak var lastBackupLbl:UILabel!
    @IBOutlet weak var maxSizeAllowedLbl:UILabel!
    @IBOutlet weak var progressView:UIProgressView!
    @IBOutlet weak var tableView:UITableView!
    var okAction:UIAlertAction?
    private let backupUtil = BackupUtil()

    private let backupRestoreRepo = BackupRestoreRepo()
    
    private let extraSpaceNeeded = 500 //500 mb
    
    private var dataSource = [ChatBackupItem]()
    var disposable:Disposable?
    var progressDisposable:Disposable?
    private var totalProgress:Float = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = MediaBackupUtil().getMediaTypeData().map{ChatBackupItem(mediaTypeFileSize: $0, isSelected: false)}

        setupTableView()
        
        let maxSizeAllowedBytes = Config.maxSizeAllowed * 1000000
        maxSizeAllowedLbl.text = Strings.maxSizeAllowed(size: FileUtil.covertToFileString(with: UInt64(maxSizeAllowedBytes)))
        
        
        
        if let backup = BackupRestoreRepo().getBackup(){
            setLastBackupLbl(backupTime: backup.backupTime)
            if backup.isInProgress{
             
                setRightBarButtonAsCancel()
                
                if !BackupUtil.isWorkRunning(){
                    //resmue backup if process dies
                    startBackup(backup: backup)
                    
                                        
                }
                
                if let storedBackup = self.backupRestoreRepo.getBackup(){
                    self.observeProgress(backup: storedBackup)
                }
                

            }else{
                setRightBarButtonAsStart()
            }
        }else{
            
            
            BackupFetcher().fetchBackup().subscribe { (backup) in
                self.setLastBackupLbl(backupTime: backup?.backupTime ?? 0)
                self.setRightBarButtonAsStart()

                
            } onError: { (error) in
                
                
                self.showAlert(type: .error, message: Strings.error)
            }.disposed(by: disposeBag)
        }
                    
        
    }
    
    
    private func setLastBackupLbl(backupTime:Int){
        let lastBackup = backupTime == 0 ? Strings.noBackupMade : TimeHelper.getDateAndTime(date: backupTime.toDate())
        lastBackupLbl.text = lastBackup
    }
    

    
    
    private func setRightBarButtonAsCancel(){
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.cancel, style: .done, target: self, action: #selector(cancelBackupTapped))
    }
    
    private func setRightBarButtonAsStart(){
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.start, style: .done, target: self, action: #selector(startBackupTapped))
    }
    
    private func observeProgress(backup:BackupDB){
        
        self.progressView.progress = 0
        self.progressView.isHidden = false
        
        
        progressDisposable = backupUtil.progressSubject.subscribe { (fileBytesDownloaded) in
            
            
            
            
       

            let totalBytes = backup.fileSize
            if totalBytes == 0{
                return
            }
            let downloadedBytes = backup.downloadedBytes
            let bytes = downloadedBytes + Int(fileBytesDownloaded)
            let progress = Float(100 * bytes / totalBytes) / 100
            
            
            if progress > self.totalProgress{
                self.progressView.progress = progress
                self.totalProgress = progress
            }
            
        }onDisposed: {
            self.totalProgress = 0
        }
        
        progressDisposable?.disposed(by: self.disposeBag)
    }
    
    private func startBackup(backup:BackupDB){
        let password = backup.password
        let selectedItems = Array(backup.mediaTypes.map{MessageType(rawValue: $0)!})
        let allItemsSize = backup.fileSize
        
        self.progressView.isHidden = false
        self.progressView.progress = 0
        
        setRightBarButtonAsCancel()

        disposable =
        backupUtil.backup(password: password,mediaTypes: selectedItems ,allItemsSize: allItemsSize)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe {
            self.backupCompleted()
       
        } onError: { (error) in
            self.showAlert(type: .error, message: Strings.error)

        }
        
        
        
        
    }
    
    @objc private func cancelBackupTapped(){
        cancelBackup()
    }
    
    private func backupCompleted(){
        setRightBarButtonAsStart()
        progressDisposable?.dispose()
        progressView.isHidden = true
        self.showAlert(type: .success, message: Strings.backupDone)

        setRightBarButtonAsStart()
        
        lastBackupLbl.text = TimeHelper.getDateAndTime(date: Date())
        totalProgress = 0
        
    }
    
    private func cancelBackup(){
        let alert = UIAlertController(title: Strings.cancel_backup, message: Strings.cancel_backup_message, preferredStyle: .alert)
        alert.addAction(Alerts.cancelAction)
        alert.addAction(UIAlertAction(title: Strings.ok, style: .destructive, handler: { (_) in
            self.disposable?.dispose()
            self.progressDisposable?.dispose()
            BackupUtil.endBackgroundTask()
            self.setRightBarButtonAsStart()
            self.progressDisposable?.dispose()
            self.progressView.isHidden = true
            self.backupRestoreRepo.delete()
            self.showAlert(type: .error, message: Strings.backup_cancelled)
            self.totalProgress = 0
        }))
        present(alert, animated: true, completion: nil)
        
    }
    @objc private func startBackupTapped(){
        let selectedItems = dataSource.filter({$0.isSelected}).map{$0.mediaTypeFileSize.type}
        
        
        let alert = UIAlertController(title: Strings.enter_password_backup, message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = Strings.password
            textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
            textField.isSecureTextEntry = true
        }
        

        
        let okAction = UIAlertAction(title: Strings.ok, style: .default) { (_) in
            let freeDiskSpaceBytes = DiskStatus.freeDiskSpaceInBytes
            let freeDiskSpaceMB = Units(bytes: freeDiskSpaceBytes).megabytes
            let allItemsSize = self.allItemsSize
            let allItemsSizeMB = Units(bytes: Int64(allItemsSize)).megabytes
        
            
            if Int(allItemsSizeMB) <= Int(freeDiskSpaceMB) + self.extraSpaceNeeded{
                
         

                let textField = alert.textFields![0]
            
                let password = textField.text!
                
                
                let backup = BackupDB()
                backup.password = password
                let mediaTypes = List<Int>()
                mediaTypes.append(objectsIn: selectedItems.map{$0.rawValue})
                backup.mediaTypes = mediaTypes
                backup.fileSize = allItemsSize
                backup.isInProgress = true
                
                self.backupRestoreRepo.saveIfNotExistsOrUpdateNoDispatch(backup: backup)
                
                self.startBackup(backup: backup)
                

                    self.progressDisposable?.dispose()
                if let storedBackup = self.backupRestoreRepo.getBackup(){
                    self.observeProgress(backup: storedBackup)
                
                }


                
              
             
            }else{
                
                let alert = UIAlertController(title: Strings.not_enough_space, message: Strings.free_up_space, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: Strings.ok, style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }

        }
        okAction.isEnabled = false
        self.okAction = okAction
        
        
        let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    private func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func switchChanged(){
        let enableRightBarButton = Int(Units(bytes: Int64(allItemsSize)).megabytes) < Config.maxSizeAllowed
        navigationItem.rightBarButtonItem?.isEnabled = enableRightBarButton
    }
    
    private var allItemsSize:Int{
        return dataSource.filter({$0.isSelected}).map{$0.mediaTypeFileSize.size}.reduce(0,+)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        okAction?.isEnabled = textField.text?.count ?? 0 >= 6
    }

}

struct ChatBackupItem {
    let mediaTypeFileSize:MediaTypeBackupData
    var isSelected:Bool
}


extension ChatBackupVC:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "backupChatCell") as? BackupChatCell{
            let chatBackupItem = dataSource[indexPath.row]
            cell.bind(mediaItem: chatBackupItem.mediaTypeFileSize,index:indexPath.row)
            cell.delegate = self
            return cell
        }
        
        return UITableViewCell()
    }
    
    
}
extension ChatBackupVC:BackupChatCellDelegate{
    func didToggleSwitch(item:MediaTypeBackupData,index:Int,isOn:Bool) {
        dataSource[index].isSelected = isOn
        switchChanged()
    }
}




