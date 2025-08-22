import UIKit

class TableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the table view
        setupTableView()
    }
    
    private func setupTableView() {
        // Set the multi-line title for the navigation bar
        setupNavigationTitle()
        
        // Configure table view appearance
        tableView.backgroundColor = UIColor.systemBackground
    }
    
    private func setupNavigationTitle() {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        
        // Create attributed string with different styles
        let attributedText = NSMutableAttributedString()
        
        // "AmazonIVSBroadcast" - bold, standard style
        let mainTitle = NSAttributedString(
            string: "AmazonIVSBroadcast\n",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 17),
                .foregroundColor: UIColor.label
            ]
        )
        
        // "Real-Time" - cool italic style with different color
        let subtitle = NSAttributedString(
            string: "Real-Time",
            attributes: [
                .font: UIFont.italicSystemFont(ofSize: 15),
                .foregroundColor: UIColor.systemBlue,
                .kern: 1.2 // Letter spacing for a cooler look
            ]
        )
        
        attributedText.append(mainTitle)
        attributedText.append(subtitle)
        
        titleLabel.attributedText = attributedText
        titleLabel.sizeToFit()
        
        navigationItem.titleView = titleLabel
    }

    // MARK: - Table view data source
    // Note: Using static cells from storyboard, so data source methods are not needed

    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0:
            // Live Broadcast - will be handled by segue in storyboard
            break
        case 1:
            // Custom Media Sources - will be handled by segue in storyboard
            break
        case 2:
            // Mixer and Transitions - placeholder functionality
            showPlaceholderAlert(for: "Mixer and Transitions")
        default:
            break
        }
    }
    
    // MARK: - Helper methods
    
    private func showPlaceholderAlert(for feature: String) {
        let alert = UIAlertController(
            title: "Coming Soon",
            message: "\(feature) functionality will be available in a future update.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
