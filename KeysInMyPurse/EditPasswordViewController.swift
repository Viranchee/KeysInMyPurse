//
//  EditPasswordViewController.swift
//  KeysInMyPurse
//
//  Created by Viranchee L on 03/08/19.
//  Copyright © 2019 Viranchee L. All rights reserved.
//

import UIKit

class EditPasswordViewController: UIViewController {
  
  @IBOutlet weak var label: UILabel!
  
  @IBOutlet weak var labelPassword: UITextField!
  
  
  override func viewDidLoad() {
    label.text = "Hello"
    labelPassword.text = "Hesel"
  }
}
