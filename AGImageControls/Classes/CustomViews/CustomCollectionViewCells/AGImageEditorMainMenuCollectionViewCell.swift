//
//  AGImageEditorMainMenuCollectionViewCell.swift
//  AGPosterSnap
//
//  Created by Michael Liptuga on 14.07.17.
//  Copyright © 2017 Agilie. All rights reserved.
//

import UIKit

class AGImageEditorMainMenuCollectionViewCell: AGMainCollectionViewCell {
   
    struct ViewSizes {
        static let labelSize : CGSize = CGSize(width : 75, height : 36)
    }
    
    lazy var titleLabel : UILabel = { [unowned self] in
        let label = UILabel()
            label.textAlignment = .center
            label.withCornerRadius(radius : 4)
        return label
        }()
    
    open override class func cellSize () -> CGSize {
        return CGSize(width: screenSize.width / 3, height : 86.0)
    }
    
    override func configureForObject (object: Any?) {
        guard let imageEditorItem = object as? AGImageEditorMainMenuItem else { return }

        self.configureTitleLabel(menuItem: imageEditorItem)
    }
    
    override func setupCollectionViewCell() {
        self.contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        setupConstraints()
    }
}

extension AGImageEditorMainMenuCollectionViewCell
{
    fileprivate func configureTitleLabel (menuItem: AGImageEditorMainMenuItem) {
        self.titleLabel.backgroundColor = menuItem.isSelected ? menuItem.selectedBackgroundColor : menuItem.backgroundColor
        self.titleLabel.textColor = menuItem.isSelected ? menuItem.selectedTextColor : menuItem.textColor
        self.titleLabel.text = menuItem.name
        self.titleLabel.isHidden = menuItem.isHidden
    }
}
