
import UIKit
import AVFoundation
import AVKit
import LBTATools

class VideoViewController: UIViewController {

	override var prefersStatusBarHidden: Bool {
		return true
	}

	private var videoURL: URL
	var player: AVPlayer?
	var playerController: AVPlayerViewController?
	var delegate: CameraResult!
	var time: CGFloat!

	init(videoURL: URL, time: CGFloat, delegate: CameraResult) {
		self.videoURL = videoURL
		self.delegate = delegate
		self.time = time
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}


	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.backgroundColor = UIColor.black
		player = AVPlayer(url: videoURL)
		playerController = AVPlayerViewController()

		guard player != nil && playerController != nil else {
			return
		}
		playerController!.showsPlaybackControls = false

		playerController!.player = player!
		self.addChild(playerController!)
		self.view.addSubview(playerController!.view)
		playerController!.view.frame = view.frame
		NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player!.currentItem)

		let okButton = UIButton()
		okButton.setImage(#imageLiteral(resourceName: "check_circle_filled-1"), for: UIControl.State())

		okButton.translatesAutoresizingMaskIntoConstraints = true

		view.addSubview(okButton)

		okButton.addTarget(self, action: #selector(VideoViewController.self.okTapped(sender:)), for: .touchUpInside)

		okButton.tintColor = "#d7d7d7".toUIColor()

		okButton.translatesAutoresizingMaskIntoConstraints = false

		okButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -63).isActive = true

		okButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -51).isActive = true

		let cancelButton = UIButton()
		cancelButton.setImage(#imageLiteral(resourceName: "cancel_circle"), for: UIControl.State())

		cancelButton.translatesAutoresizingMaskIntoConstraints = false

		view.addSubview(cancelButton)

		cancelButton.addTarget(self, action: #selector(VideoViewController.self.cancelTapped(sender:)), for: .touchUpInside)
		cancelButton.tintColor = "#d7d7d7".toUIColor()
		cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 63).isActive = true
		cancelButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -51).isActive = true

		let redCircle = CircleView()
		redCircle.widthAnchor.constraint(equalToConstant: 15).isActive = true
		redCircle.heightAnchor.constraint(equalToConstant: 15).isActive = true

		let timerTxt = UILabel(text: time.fromatSecondsFromTimer())

		timerTxt.textColor = .black

		let stack = UIStackView(arrangedSubviews: [redCircle, timerTxt])
		stack.translatesAutoresizingMaskIntoConstraints = false
		stack.spacing = 10

		view.addSubview(stack)

		stack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
		stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true




	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		player?.play()
	}

	@objc func cancel() {
		dismiss(animated: true, completion: nil)
	}

	@objc fileprivate func playerItemDidReachEnd(_ notification: Notification) {
		if self.player != nil {
			self.player!.seek(to: CMTime.zero)
			self.player!.play()
		}
	}

	@objc private func okTapped(sender: Any) {
		delegate?.videoTaken(videoUrl: videoURL)
		self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
	}

	@objc private func cancelTapped(sender: Any) {
		do {
			try videoURL.deleteFile()
		} catch {

		}

		dismiss(animated: true, completion: nil)
	}

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
