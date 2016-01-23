//
//  AppDelegate.swift
//  RoadClocker
//
//  Created by Zvi Band on 12/27/15.
//  Copyright © 2015 skeevisarts. All rights reserved.
//

import UIKit
import CoreLocation

var driveDatabase = [[String:Double]]()
var beaconInRange = false
var beaconInRange2 = false
var beaconStartTimestamp = NSDate.timeIntervalSinceReferenceDate()

var timer = NSTimer()
var elapsedTime: NSTimeInterval = -1


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?

    
    var locationManager = CLLocationManager()
    
    
    //I was hoping that you could just find all beacons, and choose which one you not. Nope.
    //So this is hardcoded, and any beacons we use in the future will have to have this UUID.
    let BEACON_UUID = "10CAE1B7-3F02-4936-BDBB-2D3F93A02EE0"
    let BEACON_MAJOR = 1
    let BEACON_MINOR = 1
    

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        application.registerUserNotificationSettings(settings)
        locationManager = CLLocationManager()
        locationManager.delegate = self;
        locationManager.requestAlwaysAuthorization()
        beaconSearch()
        return true;
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    
    func beaconSearch(){
        if (CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedAlways) {
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = false
        let beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString:BEACON_UUID)!, identifier: "primaryBeacon")
        beaconRegion.notifyEntryStateOnDisplay = true
        beaconRegion.notifyOnEntry = true
        beaconRegion.notifyOnExit = true
        locationManager.startMonitoringForRegion(beaconRegion)
        locationManager.startUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        print("Fired up. Searching")
    }
    
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("IN RANGE")
        let notification = UILocalNotification()
        notification.alertBody = "Drive Started. We'll keep track of the time!"
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
        setBackgroundColor("Immediate")
        beaconInRange = true
        beaconStartTimestamp = NSDate.timeIntervalSinceReferenceDate()
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "updateTime", userInfo: nil, repeats: true)

    }
    
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("NOT IN RANGE")
        setBackgroundColor("Gone")
        if(beaconInRange){
            beaconInRange = false
            timer.invalidate()
            let startTime =  NSDate().timeIntervalSince1970
            let timeElapsed = NSDate.timeIntervalSinceReferenceDate() - beaconStartTimestamp
            driveDatabase.insert(["startTime":startTime, "timeElapsed":timeElapsed], atIndex: 0)
            let notification = UILocalNotification()
            notification.alertBody = "Drive Completed. Total time \(prettyPrintElapsedTime(timeElapsed))"
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
            mainWindow().savePreviousDrives()
        }
        mainWindow().tableView.reloadData()
    }
    
    
    func nameForProximity(proximity: CLProximity) -> String {
        switch proximity {
        case .Unknown:
            return "Unknown"
        case .Immediate:
            return "Immediate"
        case .Near:
            return "Near"
        case .Far:
            return "Far"
        }
    }
    
    func mainWindow() -> ViewController{
        let viewController:ViewController = window!.rootViewController as! ViewController
        return viewController
    }
    
    func updateTime() {
        let currentTime = NSDate.timeIntervalSinceReferenceDate()
        elapsedTime = currentTime - beaconStartTimestamp
        let viewController:ViewController = window!.rootViewController as! ViewController
        viewController.tableView!.reloadData()
    }
    
    
    func prettyPrintElapsedTime(elapsedTimeToDisplay: NSTimeInterval) ->String
    {
        var elapsedTimeToDisplay2 = elapsedTimeToDisplay
        let hours = UInt8(elapsedTimeToDisplay / 3600.0)
        elapsedTimeToDisplay2 -= (NSTimeInterval(hours) * 3600)
        let minutes = UInt8(elapsedTimeToDisplay2 / 60.0)
        elapsedTimeToDisplay2 -= (NSTimeInterval(minutes) * 60)
        let seconds = UInt8(elapsedTimeToDisplay2)
        elapsedTimeToDisplay2 -= NSTimeInterval(seconds)
        let strHours = String(format: "%02d", hours)
        let strMinutes = String(format: "%02d", minutes)
        let strSeconds = String(format: "%02d", seconds)
        return ("\(strHours):\(strMinutes):\(strSeconds)")
        
    }
    
    
    func setBackgroundColor(location: String){
        print("COLOR")
        
        let viewController:ViewController = window!.rootViewController as! ViewController
        let view = viewController.view

        
        switch location{
        case "Immediate":
            print("IMMEDIATE")
            view.backgroundColor = UIColor(red: 41/255, green: 128/255, blue: 185/255, alpha: 1.0)
        case "Near":
            print("NEAR")
            view.backgroundColor = UIColor(red: 41/255, green: 128/255, blue: 185/255, alpha: 1.0)
        case "Far":
            print("FAR")
            view.backgroundColor = UIColor(red: 41/255, green: 128/255, blue: 185/255, alpha: 1.0)
        case "Gone":
            print("GONE")
            view.backgroundColor = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1.0)
        default:
            print("DEFAULT")
            view.backgroundColor = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1.0)
        }
        
    }
    

    


}

