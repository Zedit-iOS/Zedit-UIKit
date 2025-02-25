//
//  OnboardingViewController.swift
//  Zedit-UIKit
//
//  Created by Avinash on 25/02/25.
//

import UIKit

class OnboardingViewController: UIViewController {
    
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var generateClipsLogo: UIImageView!
    @IBOutlet weak var generateClipsLabel: UILabel!
    @IBOutlet weak var importClipsLog: UIImageView!
    @IBOutlet weak var importClipsLabel: UILabel!
    @IBOutlet weak var enhanceLogo: UIImageView!
    @IBOutlet weak var enhanceLabel: UILabel!
    @IBOutlet weak var exportLogo: UIImageView!
    @IBOutlet weak var exportLabel: UILabel!
    @IBOutlet weak var getStartedButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ensure all our outlets disable autoresizing if needed.
        [logo, welcomeLabel,
         generateClipsLogo, generateClipsLabel,
         importClipsLog, importClipsLabel,
         enhanceLogo, enhanceLabel,
         exportLogo, exportLabel,
         getStartedButton].forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // MARK: - Configure the Main Logo & Welcome Label
        // Make the main logo flexible (allow it to grow) and the welcome label fixed.
        logo.setContentHuggingPriority(.defaultLow, for: .vertical)
        logo.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        welcomeLabel.setContentHuggingPriority(.required, for: .vertical)
        welcomeLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        let topStack = UIStackView(arrangedSubviews: [logo, welcomeLabel])
        topStack.axis = .vertical
        topStack.alignment = .center
        topStack.spacing = 8
        topStack.distribution = .fill  // Allow logo to grow if needed

        // Optionally, if you want the logo to have a minimum height, you can add:
        // logo.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true

        // MARK: - Configure Feature Stacks
        // Define a fixed icon size for all features.
        let iconSize: CGFloat = 40
        
        func makeFeatureStack(icon: UIImageView, label: UILabel) -> UIStackView {
            // Set icon constraints for consistency:
            NSLayoutConstraint.activate([
                icon.widthAnchor.constraint(equalToConstant: iconSize),
                icon.heightAnchor.constraint(equalToConstant: iconSize)
            ])
            icon.contentMode = .scaleAspectFit
            
            // Use a horizontal stack with fixed spacing.
            let stack = UIStackView(arrangedSubviews: [icon, label])
            stack.axis = .horizontal
            stack.alignment = .center
            stack.spacing = 8
            
            // Give the label a high hugging priority so it doesn't expand disproportionately.
            label.setContentHuggingPriority(.required, for: .horizontal)
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            return stack
        }
        
        let generateClipsStack = makeFeatureStack(icon: generateClipsLogo, label: generateClipsLabel)
        let importClipsStack   = makeFeatureStack(icon: importClipsLog, label: importClipsLabel)
        let enhanceStack       = makeFeatureStack(icon: enhanceLogo, label: enhanceLabel)
        let exportStack        = makeFeatureStack(icon: exportLogo, label: exportLabel)
        
        // Combine all feature stacks into a vertical stack.
        let featuresStack = UIStackView(arrangedSubviews: [generateClipsStack, importClipsStack, enhanceStack, exportStack])
        featuresStack.axis = .vertical
        featuresStack.alignment = .fill
        featuresStack.spacing = 20
        featuresStack.distribution = .equalSpacing
        
        // MARK: - Main Stack: Top section, features, and Get Started button.
        let mainStack = UIStackView(arrangedSubviews: [topStack, featuresStack, getStartedButton])
        mainStack.axis = .vertical
        mainStack.alignment = .fill
        mainStack.spacing = 40
        mainStack.distribution = .equalSpacing  // Ensure even spacing among sections
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)
        
        // Constrain mainStack to the view (with horizontal margins) and center vertically.
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Fix the height of the Get Started button.
        getStartedButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }



    @IBAction func closeOnboarding(_ sender: UIButton) {
        
        dismiss(animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
