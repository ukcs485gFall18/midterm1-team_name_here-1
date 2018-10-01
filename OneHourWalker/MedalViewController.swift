//
//  MedalViewController.swift
//  OneHourWalker
//
//  Created by Terrell, Joshua on 9/30/18.
//  Copyright © 2018 Matt Maher. All rights reserved.
//

import UIKit

class MedalViewController: UIViewController
{
    //These are labels used to show the Medals won
    @IBOutlet weak var MedalLabel: UILabel!
    @IBOutlet weak var Medal2Label: UILabel!
    @IBOutlet weak var Medal3Label: UILabel!
    
    @IBOutlet weak var Medal1Info: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //This is to help keep the users medal label unlocked. Still
        //needs some work on it
        let defaults = UserDefaults.standard
        if let medal = defaults.string(forKey: myString){
            MedalLabel.text = medal
        }
    
    }
    
   
    
    var medal1Info: String = "You clicked the button. Yay!"
    
    var myString: String = "Medal Unlocked"
    
    var myMedal2: String = "Medal Unlocked"
    
    //This unlocks a medal for clicking a button
    @IBAction func Medal1(_ sender: Any) {
        //using this to try and keep the user medal label unlocked
        let defaults = UserDefaults.standard.set(MedalLabel.text!, forKey: myString)
        MedalLabel.text = myString
        Medal1Info.text = medal1Info
    }
    
    /*
     other medals
     When you burn a certain amount of calories
     When you run a certain distance
     Also need to figure out how to keep the display showing
     */

}
