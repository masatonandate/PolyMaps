//
//  CustomSearchBar.swift
//  PolyMaps
//
//  Created by Masato Nandate on 2/18/24.
//

import Foundation
import UIKit

class CustomSearchBarViewContainerView: UIView{
    private let textField = CustomSearchBarView()
    
    // Delegate for the CustomSearchBarView, which is embedded
    weak var textFieldDelegate: UITextFieldDelegate? {
        didSet {
            textField.delegate = textFieldDelegate
        }
    }
    
    override init(frame: CGRect){
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder){
        super.init(coder: coder)
        setup()
    }
    private func setup(){
        addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
                
        // Pin the text field to the edges of the container view
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        //adds corner radius
        layer.cornerRadius = 15
        layer.masksToBounds = false
        // Add shadow
        layer.shadowColor = UIColor.black.cgColor // Shadow color
        layer.shadowOpacity = 1 // Shadow opacity
        layer.shadowOffset = CGSize(width: 0, height: 10) // Shadow offset
        layer.shadowRadius = 20 // Shadow radius
    }
}

class CustomSearchBarView : UITextField{
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    private func setup(){
        self.placeholder = "Enter Address"
        self.textColor = UIColor(.gray)
        //Add some left padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}


