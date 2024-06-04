//
//  RestoreBackupVC.swift
//  FireApp
//
//  Created by Devlomi on 3/28/21.
//  Copyright © 2021 Devlomi. All rights reserved.
//

import UIKit
import RxSwift
import FirebaseDatabase
import RealmSwift
class RestoreBackupVC: BaseVC {
    @IBOutlet weak var topLbl: UILabel!
    @IBOutlet weak var timeLbl: UILabel!
    @IBOutlet weak var fileSizeLbl: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    var backup: BackupDB?
    
    private let backupRestoreRepo = BackupRestoreRepo()
    private let restoreBackupUtil = RestoreBackupUtil()
    private var progressDisposable: Disposable? = nil
    private var disposable: Disposable? = nil
    
    private var showProgress = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        hideOrShowSubviews(isHidden: true)
        
        
        if UserDefaultsManager.isCheckedForBackup(), let backup = backupRestoreRepo.getBackup() {
            self.backup = backup
            updateUI(backup: backup)
            
            showProgress = false
            
            if backup.isInProgress {
                
                setRightBarButtonAsCancel()
                setLeftButtonEnabled(false)
                
                if !RestoreBackupUtil.isWorkRunning() {
                    //resmue backup if process dies
                    startRestore(password: backup.password, backup: backup)
                }
                
                if let storedBackup = self.backupRestoreRepo.getBackup() {
                    self.observeProgress(backup: storedBackup)
                }
                
            } else {
                setRightBarButtonAsStart()
                hideOrShowSubviews(isHidden: false)
            }
        } else {
            showProgress = true
            self.checkForBackup()
        }
        
        
        
        
        
        
        
    }
    
    
    private func observeProgress(backup: BackupDB) {
        var totalProgress: Float = 0
        self.restoreBackupUtil.progressSubject.subscribe { (fileBytesDownloaded) in
            
            
            guard let fileBytesDownloaded = fileBytesDownloaded.element else {
                return
            }
            
            
            
            
            let totalBytes = backup.fileSize
            if totalBytes == 0 {
                return
            }
            
            let downloadedBytes = backup.downloadedBytes
            let bytes = downloadedBytes + Int(fileBytesDownloaded)
            let progress = Float(100 * bytes / totalBytes) / 100
            if progress > totalProgress {
                self.progressView.progress = progress
                totalProgress = progress
            }
        }.disposed(by: disposeBag)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        if showProgress{
            self.present(loadingAlert(), animated: false, completion: nil)
        }
    }
    
    
    private func setRightBarButtonAsCancel() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.cancel, style: .done, target: self, action: #selector(cancelRestoreTapped))
    }
    
    private func setRightBarButtonAsStart() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.restore, style: .plain, target: self, action: #selector(self.restoreTapped))
    }
    
    @objc private func cancelRestoreTapped() {
        cancelRestore()
        
    }
    
    private func setLeftButtonEnabled(_ bool:Bool){
        navigationItem.leftBarButtonItem?.isEnabled = bool
    }
    
    
    private func restoreCompleted() {
        goToNextVC()
    }
    
    private func cancelRestore() {
        
        let alert = UIAlertController(title: Strings.cancel_backup, message: Strings.cancel_backup_message, preferredStyle: .alert)
        alert.addAction(Alerts.cancelAction)
        alert.addAction(UIAlertAction(title: Strings.ok, style: .destructive, handler: { (_) in
            self.disposable?.dispose()
            self.progressDisposable?.dispose()
            RestoreBackupUtil.endBackgroundTask()
            self.setRightBarButtonAsStart()
            self.progressDisposable?.dispose()
            self.progressView.isHidden = true
            self.showAlert(type: .error, message: Strings.backup_cancelled)
            self.setLeftButtonEnabled(true)
            
        }))
        present(alert, animated: true, completion: nil)
        
    }
    fileprivate func checkForBackup() {
        BackupFetcher().fetchBackup().subscribe { (backup) in
            
            
            
            //            self.dismiss(animated: true, completion: nil)
            
            //if exists
            if let backup = backup {
                self.backup = backup
                self.updateUI(backup: backup)
                
            } else {
                UserDefaultsManager.setCheckedForBackup(true)
                self.goToNextVC()
            }
            
        } onError: { (error) in
            self.showAlert(type: .error, message: Strings.error)
        }.disposed(by: disposeBag)
    }
    
    private func updateUI(backup: BackupDB) {
        hideOrShowSubviews(isHidden: false)
        topLbl.text = "Backup Found"
        timeLbl.text = TimeHelper.getDateAndTime(date: backup.backupTime.toDate())
        fileSizeLbl.text = FileUtil.covertToFileString(with: UInt64(backup.fileSize))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.skip, style: .plain, target: self, action: #selector(self.skipTapped))
        setRightBarButtonAsStart()
    }
    
    private func goToNextVC() {
        
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "SetupUserNavVC") as! UINavigationController
        self.dismiss(animated: false) {
            self.view.window?.rootViewController = newViewController
            self.view.window?.makeKeyAndVisible()
        }
        //        self.navigationController?.pushViewController(newViewController, animated: true)
        
    }
    
    @objc private func skipTapped() {
        let alert = UIAlertController(title:Strings.skip_restoring_messages , message: Strings.skip_restoring_messages_message, preferredStyle: .alert)
        alert.addAction(Alerts.cancelAction)
        alert.addAction(UIAlertAction(title: Strings.skip, style: .destructive, handler: { (_) in
            UserDefaultsManager.setCheckedForBackup(true)
            self.goToNextVC()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func restoreTapped() {
        guard let backup = backup else {
            return
        }
        
        let alert = UIAlertController(title: Strings.enter_backup_password_alert, message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = Strings.password
            textField.isSecureTextEntry = true
        }
        
        
        
        
        
        
        let okAction = UIAlertAction(title: Strings.ok, style: .default) { (_) in
            if let password = alert.textFields![0].text {
                let encryptedStoredPassword = backup.encryptedPassword
                
                if self.restoreBackupUtil.isPasswordValid(password: password, encryptedPassword: encryptedStoredPassword) {
                    
                    UserDefaultsManager.setCheckedForBackup(true)
                    self.backupRestoreRepo.updatePassword(password)
                    self.startRestore(password: password, backup: backup)
                    
                    
                    
                } else {
                    self.showInvalidPasswordAlert()
                }
            }
        }
        
        let cancelAction = Alerts.cancelAction
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
        
    }
    
    private func startRestore(password: String, backup: BackupDB) {
        
        setRightBarButtonAsCancel()
        setLeftButtonEnabled(false)
        progressView.isHidden = false
        progressView.progress = 0
        
        let mediaTypes = backup.mediaTypes.map { MessageType(rawValue: $0)! }
        
        
        disposable = self.restoreBackupUtil
            .restore(password: password, mediaTypes: Array(mediaTypes))
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe {
                self.restoreCompleted()
                self.progressView.progress = 1.0
                self.progressView.isHidden = true
                
            } onError: { (error) in
                self.showAlert(type: .error, message: Strings.error)
            }
        
        self.observeProgress(backup: backup)
    }
    
    private func showInvalidPasswordAlert() {
        let alert = UIAlertController(title: Strings.invalid_password, message: nil, preferredStyle: .alert)
        alert.addAction(Alerts.okAction)
        present(alert, animated: true, completion: nil)
    }
    
    private func hideOrShowSubviews(isHidden: Bool) {
        for view in view.subviews {
            if view != progressView {
                view.isHidden = isHidden
            }
        }
    }
}
