import UIKit

class PhotoViewController: UIViewController {

    var delegate: CameraResult?
    var takenImage: UIImage?

    @IBOutlet weak var previewImage:UIImageView!
    @IBOutlet weak var loading:UIActivityIndicatorView!
    
    
    @IBAction func cancelTapped(_sender:Any){
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func okTapped(_sender:Any){
        
        self.view.window?.rootViewController?.dismiss(animated: true){
            self.delegate?.imageTaken(image: self.takenImage)
        }
    
    }
    
	override var prefersStatusBarHidden: Bool {
		return true
	}


 

	override func viewDidLoad() {
		super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
	}
 

    func setData(){
        previewImage.image = takenImage
        loading.stopAnimating()
    }
   

}
