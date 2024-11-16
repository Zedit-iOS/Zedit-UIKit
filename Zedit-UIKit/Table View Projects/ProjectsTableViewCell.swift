//
//  ProjectsTableViewCell.swift
//  Zedit-UIKit
//
//  Created by Avinash on 28/10/24.
//

import UIKit

class ProjectsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func update(with project:Project){
        nameLabel.text = project.name
        
    }

}
