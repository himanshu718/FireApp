# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'FireApp' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  # Pods for FireApp
  pod "TabPageViewController"
  pod 'DropDown'

  pod 'GoogleUtilities'
  pod 'RealmSwift'
  pod 'Firebase/AdMob' , '6.33.0'
  pod 'Firebase/Messaging' , '6.33.0'
  pod 'Firebase/Database' , '6.33.0'
  pod 'Firebase/Auth'
  pod 'Firebase/Storage' , '6.33.0'
  pod 'Firebase/Functions', '6.33.0'
  pod 'FirebaseFirestore'
  pod 'FirebaseUI/Phone', '8.5.1'
  pod 'Firebase/Crashlytics'
  pod 'FirebaseAnalytics', '6.9.0'
  pod 'FirebaseCore'
  pod 'GoogleSignIn' 
  pod 'UITextView+Placeholder' , '1.4.0'
  pod "SwiftyCam" , '4.0.0'
  pod 'BubbleTransition' , '4.0.0'
  pod 'LBTATools', '1.0.12'
  pod 'UIColor_Hex_Swift' , '5.1.0'
  pod 'ImageScrollView' , '1.9.2'
  pod 'Hero' , '1.6.1'
  pod 'iRecordView' , '0.1.3'
  pod 'JFContactsPicker' , '2.0.0'
  pod "TTCardView" , '0.1.1'
  pod 'LocationPicker', :git => 'https://github.com/3llomi/LocationPicker'
  pod 'GrowingTextView' , '0.7.2'
  pod 'IQKeyboardManagerSwift' , '6.5.6'
  pod 'ContextMenu' , '0.4.0'
  pod 'CircleProgressButton' , '0.5.1'
  pod 'SwiftEventBus' , '5.0.0'
  pod 'libPhoneNumber-iOS' , '0.9.15'
  pod 'RxSwift', '5.1.1'
  pod 'RxCocoa', '5.1.1'
  pod 'RxFirebase/Database' ,'0.3.8'
  pod 'RxFirebase/Storage' , '0.3.8'
  pod 'RxFirebase/Functions' , '0.3.8'
  pod 'RxOptional' , '4.1.0'
  pod 'CircleProgressView' , '1.2.0'
  pod 'Kingfisher' , '6.2.1'
  pod 'iOSPhotoEditor'
  pod 'AgoraRtcEngine_iOS' , '3.6.2'
  pod 'ALCameraViewController' , '3.1'
  pod 'WXImageCompress' , '0.1.3'
  pod 'DateTimePicker' , '2.5.3'
  pod 'KBStickerView' , '0.1.2'
  
  pod 'Permission/Photos' , '3.1.2'
  pod 'Permission/Notifications' , '3.1.2'
  pod 'Permission/Microphone' , '3.1.2'
  pod 'Permission/MediaLibrary' , '3.1.2'
  pod 'Permission/Contacts' , '3.1.2'
  pod 'Permission/Camera' , '3.1.2'
  
  pod 'BadgeSwift' , '8.0.0'
  pod "AlertBar" , '0.5.0'
  pod 'NotificationBannerSwift' , '3.0.6'
  pod 'NotificationView' , '0.2.5'
  pod 'BottomPopup' , '0.6.0'
  
  pod 'ZIPFoundation'
  pod 'RNCryptor' , '5.1.0'
  pod 'VirgilE3Kit'
  pod 'Paystack'
  pod 'Tabman', '~> 3.0'
  
  
end

target 'NotificationService' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  # Pods for NotificationService
  pod 'GoogleUtilities'
  pod 'RealmSwift'
  pod 'Firebase/Messaging' , '6.33.0'
  pod 'Firebase/Database' , '6.33.0'
  pod 'Firebase/Auth' 
  pod 'Firebase/Storage' , '6.33.0'
  pod 'Firebase/Functions', '6.33.0'
  pod 'RxSwift', '5.1.1'
  pod 'RxCocoa', '5.1.1'
  pod 'RxFirebase/Database' ,'0.3.8'
  pod 'RxFirebase/Storage' , '0.3.8'
  pod 'RxFirebase/Functions' , '0.3.8'
  pod 'RxOptional' , '4.1.0'
  pod 'WXImageCompress' , '0.1.3'
  pod 'SwiftEventBus' , '5.0.0'
  pod 'libPhoneNumber-iOS' , '0.9.15'
  pod 'Kingfisher' , '6.2.1'
  pod 'VirgilE3Kit'
  
end

target 'ShareExtension' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  # Pods for ShareExtension
  
  pod 'RealmSwift'
  pod 'RxSwift', '5.1.1'
  pod 'RxCocoa', '5.1.1'
  
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # some older pods don't support some architectures, anything over iOS 11 resolves that
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
