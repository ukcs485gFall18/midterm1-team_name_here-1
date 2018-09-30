//
//  TimerViewController.swift
//  OneHourWalker
//
//  Created by Matthew Maher on 2/18/16.
//  Copyright © 2016 Matt Maher. All rights reserved.
//
//  Code refactored for Swift 4.2 by Darren Powers, Siyuan Chen, and Joshua Terrell
//
import HealthKit
import UIKit
import CoreLocation

class TimerViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var milesLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    //Darren added caloriesLabel, goalLabel, and sourceLabel
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var goalLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    //Siyuan added walkButton, cycleButton
    @IBOutlet weak var walkButton: UIButton!
    @IBOutlet weak var cycleButton: UIButton!
    
    var zeroTime = TimeInterval()
    var timer : Timer = Timer()
    
    var id = 1 // identify Walk+Run and Cycling, id = 1 means Walk+Run is clicked, on the other hand, Cycling is clicked
    
    let locationManager = CLLocationManager()
    var startLocation: CLLocation!
    var lastLocation: CLLocation!
    var distanceTraveled = 0.0
    
    //Darren added energyGoalMet flag
    //For use in achievement system
    var energyGoalMet = false
    
    let healthManager:HealthKitManager = HealthKitManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.requestWhenInUseAuthorization();
        
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }
        else {
            print("Location service disabled");
        }
        
        // We cannot access the user's HealthKit data without specific permission.
        if #available(iOS 9.3, *) {
            getHealthKitPermission()
        } else {
            // Fallback on earlier versions
        }
    }
    
    var height: HKQuantitySample?
    var activeEnergyBurned: HKQuantitySample?
    
    @available(iOS 9.3, *)
    func getHealthKitPermission() {
        
        // Seek authorization in HealthKitManager.swift.
        healthManager.authorizeHealthKit { (authorized,  error) -> Void in
            if authorized {
                
                // Get and set the user's height and calories burned.
                self.setHeight()
                self.setActiveEnergyBurned() //Added by Darren Powers
            } else {
                if error != nil {
                    print(error!)
                }
                print("Permission denied.")
            }
        }
        setHeight()
        setActiveEnergyBurned()// Added by Darren Powers
    }
    
    @available(iOS 9.3, *)
    func setActiveEnergyBurned() {
        /* @desc: Get data on Energy Burned Goal from HealthKit
         * @author: Darren Powers
         * Notes: based on code for setHeight below and includes information gathered from: https://crunchybagel.com/accessing-activity-rings-data-from-healthkit/
         */
        
        // Call HealthKitManager's getSample() method to get active energy for today from HealthKit
        self.healthManager.getEnergyBurned(completion: { (userActiveEnergyBurned, userAEBGoal, error) -> Void in
            
            if( error != nil) {
                print("Error: \(String(describing: error?.localizedDescription))")
                return
            }
            
            var activeEnergyBurnedString = ""
            var calorieGoalString = " "
            var sourceString = ""
            
            if (userAEBGoal == nil) {
                sourceString = "From HealthKit Sample:"
               activeEnergyBurnedString = "Today's Calories: \(String(describing: userActiveEnergyBurned!))"
            } else {
                sourceString = "From Activity Summary:"
                activeEnergyBurnedString = "Today's Calories: \(String(describing: userActiveEnergyBurned!)) cal"
                calorieGoalString = "Calorie Goal: \(String(describing: userAEBGoal)) cal"
                if (Double(userAEBGoal!).isLess(than: userActiveEnergyBurned as! Double)) {
                    self.energyGoalMet = true
                    calorieGoalString += " Congratulations!"
                }
            }
            

            DispatchQueue.global(qos: .userInitiated).async{
                DispatchQueue.main.async {
                    self.sourceLabel.text = sourceString
                    self.caloriesLabel.text = activeEnergyBurnedString
                    self.goalLabel.text = calorieGoalString
                }
            }
            
        })
    }
    
    func setHeight() {
        // Create the HKSample for Height.
        let heightSample = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)
        
        // Call HealthKitManager's getSample() method to get the user's height.
        self.healthManager.getHeight(sampleType: heightSample!, completion: { (userHeight, error) -> Void in
            
            if( error != nil ) {
                print("Error: \(String(describing: error?.localizedDescription))")
                return
            }
            
            var heightString = ""
            
            self.height = userHeight as? HKQuantitySample
            
            // The height is formatted to the user's locale.
            if let meters = self.height?.quantity.doubleValue(for: HKUnit.meter()) {
                let formatHeight = LengthFormatter()
                formatHeight.isForPersonHeightUse = true
                heightString = formatHeight.string(fromMeters: meters)
            }
            
            // Set the label to reflect the user's height.
            /* Darren accessed https://www.raywenderlich.com/5370-grand-central-dispatch-tutorial-for-swift-4-part-1-2 for
             * example of how to fix the DispatchQueue for Swift 4
             */
            DispatchQueue.global(qos: .userInitiated).async{
                DispatchQueue.main.async {
                self.heightLabel.text = heightString
                }
            }
            
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    
    @IBAction func chooseToWalk(_ sender: UIButton) {
        walkButton.setTitleColor(UIColor.orange, for: .normal) // set selected button color to orange
        cycleButton.setTitleColor(UIColor.blue, for: .normal) // set the other button color to default
        id = 1
    }
    
    @IBAction func chooseToCycly(_ sender: UIButton) {
        cycleButton.setTitleColor(UIColor.orange, for: .normal)
        walkButton.setTitleColor(UIColor.blue, for: .normal)
        id = 2
    }
    
    @objc @IBAction func startTimer(sender: AnyObject) {
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(TimerViewController.updateTime), userInfo: nil, repeats: true)
        zeroTime = NSDate.timeIntervalSinceReferenceDate
        
        distanceTraveled = 0.0
        startLocation = nil
        lastLocation = nil
        
        locationManager.startUpdatingLocation()
    }
    
    @IBAction func stopTimer(sender: AnyObject) {
        timer.invalidate()
        locationManager.stopUpdatingLocation()
    }
    
    @objc func updateTime() {
        let currentTime = NSDate.timeIntervalSinceReferenceDate
        var timePassed: TimeInterval = currentTime - zeroTime
        let minutes = UInt8(timePassed / 60.0)
        timePassed -= (TimeInterval(minutes) * 60)
        let seconds = UInt8(timePassed)
        timePassed -= TimeInterval(seconds)
        let millisecsX10 = UInt8(timePassed * 100)
        
        let strMinutes = String(format: "%02d", minutes)
        let strSeconds = String(format: "%02d", seconds)
        let strMSX10 = String(format: "%02d", millisecsX10)
        
        timerLabel.text = "\(strMinutes):\(strSeconds):\(strMSX10)"
        
        if timerLabel.text == "60:00:00" {
            timer.invalidate()
            locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if startLocation == nil {
            startLocation = locations.first
        } else {
            let lastDistance = lastLocation.distance(from: (locations.last )!)
            distanceTraveled += lastDistance * 0.000621371
            
            let trimmedDistance = String(format: "%.2f", distanceTraveled)
            
            milesLabel.text = "\(trimmedDistance) Miles"
        }
        
        lastLocation = locations.last
    }
    
    @IBAction func share(sender: AnyObject) {
        switch id {
        case 1:
            // Selected Walk+Run, saving DistanceWalkingRunning
            healthManager.saveDistanceWalkingRunning(distanceRecorded: distanceTraveled, date: NSDate())
        case 2:
            // Selected Cycling, saving DistanceCycling
            healthManager.saveDistanceCycling(distanceRecorded: distanceTraveled, date: NSDate())
        default:
            // If user has not clicked Walk+Run or Cycling, default is Walk+Run
            healthManager.saveDistanceWalkingRunning(distanceRecorded: distanceTraveled, date: NSDate())

        }
    }

}
