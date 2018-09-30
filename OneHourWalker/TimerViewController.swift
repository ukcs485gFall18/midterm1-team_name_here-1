//
//  TimerViewController.swift
//  OneHourWalker
//
//  Created by Matthew Maher on 2/18/16.
//  Copyright © 2016 Matt Maher. All rights reserved.
//
import HealthKit
import UIKit
import CoreLocation

class TimerViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var milesLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var walkButton: UIButton!
    @IBOutlet weak var cycleButton: UIButton!
    
    var zeroTime = TimeInterval()
    var timer : Timer = Timer()
    
    var id = 1 // identify Walk+Run and Cycling, id = 1 means Walk+Run is clicked, on the other hand, Cycling is clicked
    
    let locationManager = CLLocationManager()
    var startLocation: CLLocation!
    var lastLocation: CLLocation!
    var distanceTraveled = 0.0
    
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
        getHealthKitPermission()
    }
    
    var height: HKQuantitySample?
    
    func getHealthKitPermission() {
        
        // Seek authorization in HealthKitManager.swift.
        healthManager.authorizeHealthKit { (authorized,  error) -> Void in
            if authorized {
                
                // Get and set the user's height.
                self.setHeight()
            } else {
                if error != nil {
                    print(error!)
                }
                print("Permission denied.")
            }
        }
        setHeight()
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
            let lastDistance = lastLocation.distance(from: locations.last as! CLLocation)
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
