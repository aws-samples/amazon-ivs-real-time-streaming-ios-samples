import UIKit
import AmazonIVSBroadcast

class TableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "IVS Real-Time SDK \(IVSBroadcastSession.sdkVersion)"
    }
}
