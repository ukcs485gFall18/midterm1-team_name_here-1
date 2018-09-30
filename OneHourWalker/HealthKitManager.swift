//
//  HealthKitManager.swift
//  OneHourWalker
//
//  Created by Matthew Maher on 2/23/16.
//  Copyright © 2016 Matt Maher. All rights reserved.
//

import Foundation
import HealthKit
import UIKit

class HealthKitManager {
    
    let healthKitStore: HKHealthStore = HKHealthStore()
    
    @available(iOS 9.3, *)
    func authorizeHealthKit(completion: ((_ success: Bool, _ error: NSError?) -> Void)!) {
        
        // State the health data type(s) we want to read from HealthKit.
        let healthDataToRead = Set(arrayLiteral: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!, HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!, HKObjectType.activitySummaryType()) //Added request for access to activeEnergy Burned
        
        // State the health data type(s) we want to write from HealthKit.
        let healthDataToWrite = Set(arrayLiteral: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!)
        
        // Just in case OneHourWalker makes its way to an iPad...
        if !HKHealthStore.isHealthDataAvailable() {
            print("Can't access HealthKit.")
        }
        
        // Request authorization to read and/or write the specific data.
        healthKitStore.requestAuthorization(toShare: healthDataToWrite, read: healthDataToRead) { success, error in
            guard error == nil, success else {
                print(error!);return
            }
            //You can start using HealthKit data
        }
    }
    
    func getHeight(sampleType: HKSampleType , completion: ((HKSample?, NSError?) -> Void)!) {
        
        // Predicate for the height query
        let distantPastHeight = NSDate.distantPast as NSDate
        let currentDate = NSDate()
        let lastHeightPredicate = HKQuery.predicateForSamples(withStart: distantPastHeight as Date, end: currentDate as Date, options:[])
        
        // Get the single most recent height
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        // Query HealthKit for the last Height entry.
        let heightQuery = HKSampleQuery(sampleType: sampleType, predicate: lastHeightPredicate, limit: 1, sortDescriptors: [sortDescriptor]) { (sampleQuery, results, error ) -> Void in
            
            if let queryError = error {
                completion?(nil, queryError as NSError)
                return
            }
            
            // Set the first HKQuantitySample in results as the most recent height.
            let lastHeight = results!.first
            
            if completion != nil {
                completion(lastHeight, nil)
            }
        }
        
        // Time to execute the query.
        self.healthKitStore.execute(heightQuery)
    }
    
    @available(iOS 9.3, *)
    func getEnergyBurned(completion: ((Double?, Double?, NSError?) -> Void)!) {
        /* @description: get EnergyBurned from HealthKit
         * @author: Darren Powers
         * Note: Information for collecting this data from https://crunchybagel.com/accessing-activity-rings-data-from-healthkit/
         * accessed on 9/29/2018 by Darren Powers
         */
        
        // Build predicate for EnergyBurned query
        let calendar = Calendar.autoupdatingCurrent
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        dateComponents.calendar = calendar
        
        let predicate = HKQuery.predicateForActivitySummary(with: dateComponents)
        print(predicate)
        
        let EBQuery = HKActivitySummaryQuery(predicate: predicate) { (EBQuery, summaries, error) in
            if let queryError = error {
                completion?(nil, nil, queryError as NSError)
                print("ERROR")
                return
            }
            var energyUnit:HKUnit
            var energy:Double = 0
            var goal:Double = 0
            
            for summary in summaries! {
                energyUnit = HKUnit.kilocalorie()
                print("EnergyUnit: \(energyUnit)")
                energy = summary.activeEnergyBurned.doubleValue(for: energyUnit)
                print("Energy: \(energy)")
                goal = summary.activeEnergyBurnedGoal.doubleValue(for: energyUnit)
                print("Goal: \(goal)")
                
            }
            // Set the first HKQuantitySample in results as the most recent height.
            print(summaries)
            if completion != nil {
                // Format calories as "kilocalories" (which are what we think of as 'calories'
                completion?(energy as Double, goal as Double, nil)
            }
        }
        //Execute query
        self.healthKitStore.execute(EBQuery)
        print("This Worked")
    
    }
    
    func saveDistance(distanceRecorded: Double, date: NSDate ) {
        
        // Set the quantity type to the running/walking distance.
        let distanceType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)
        
        // Set the unit of measurement to miles.
        let distanceQuantity = HKQuantity(unit: HKUnit.mile(), doubleValue: distanceRecorded)
        
        // Set the official Quantity Sample.
        let distance = HKQuantitySample(type: distanceType!, quantity: distanceQuantity, start: date as Date, end: date as Date)
        
        // Save the distance quantity sample to the HealthKit Store.
        healthKitStore.save(distance, withCompletion: { (success, error) -> Void in
            if( error != nil ) {
                print(error!)
            } else {
                print("The distance has been recorded! Better go check!")
            }
        })
    }
}
