import UIKit
import FirebaseAuth
import Firebase
import Alamofire
import FirebaseMessaging

public extension UIDevice {
    static var code: String? {
        return current.identifierForVendor?.uuidString
    }
}

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Alamofire.request("https://httpbin.org/get")

        // Do any additional setup after loading the view.
        
        setUpElements()
        
    }

    
    func setUpElements() {
        
        // Hide the error label
        errorLabel.alpha = 0
        
        // Style the elements
        Utilities.styleTextField(emailTextField)
        Utilities.styleTextField(passwordTextField)
        Utilities.styleFilledButton(loginButton)
        
    }
    
    func showError(message:String){
       errorLabel.text = message
       errorLabel.alpha = 1
    }

    
    @IBAction func loginTapped(_ sender: Any) {
        // trim
        let email = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let deviceID = UIDevice.code
        
        // Sign in
        Auth.auth().signIn(withEmail: email, password: password) { (authresult, autherror) in
            
            if autherror != nil {
                // Couldn't sign in
                self.errorLabel.text = autherror!.localizedDescription
                self.errorLabel.alpha = 1
                return
            }
            else {
                Firebase.InstanceID.instanceID().instanceID { result, instanceerror in
//                    guard let error = error else { completionHandler(result); return }
                    if instanceerror == nil {
                        guard let authData = authresult, let instanceID = result?.instanceID else { return }
                        authData.user.getIDToken { authToken, iderror in
                            guard iderror == nil else { self.showError(message: iderror.debugDescription); return }
                            guard let authToken = authToken, let fcmToken = Messaging.messaging().fcmToken else { return }
                            let testString = "Auth Token : " + authToken + "\nFCM Token : " + fcmToken
                            //self.showError(testString)
                            let parameters: Parameters = [
                                "firebase_id_token": authToken,
                                "fcm_token": fcmToken,
                                "device_code": deviceID
                            ]
                            
//                            let parameters: Parameters = ["firebase_id_token": firebaseIDToken, "firebase_iid_token": FIRInstanceID, "fcm_token": fcmToken, "device_code": device

                            // All three of these calls are equivalent
                            Alamofire.request("https://fueru-storage.nakabayashi.work/api/connection", method: .post, parameters: parameters)
                               // .validate(statusCode: 200..<300)
                                .responseJSON { response in
                                    self.showError(message: response.description)
                                }
    
                            //self.authServiceLogin(authToken, withInstanceID: instanceID, fcmToken: fcmToken)
                        }
                    }
                    //self.showErrorAlert(error)
                }
                        //                let homeViewController = self.storyboard?.instantiateViewController(identifier: Constants.Storyboard.homeViewController) as? HomeViewController
                        //
                        //                self.view.window?.rootViewController = homeViewController
                        //                self.view.window?.makeKeyAndVisible()
            }
        }
        
    }
    
}
