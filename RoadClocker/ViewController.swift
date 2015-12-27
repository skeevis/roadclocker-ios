//
//  ViewController.swift
//  RoadClocker
//
//  Created by Zvi Band on 12/27/15.
//  Copyright © 2015 skeevisarts. All rights reserved.
//

import UIKit
import CoreLocation


class ViewController: UIViewController,CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate {

    let locationManager = CLLocationManager()

    
    //I was hoping that you could just find all beacons, and choose which one you not. Nope.
    //So this is hardcoded, and any beacons we use in the future will have to have this UUID.
    let BEACON_UUID = "10CAE1B7-3F02-4936-BDBB-2D3F93A02EE0"
    let BEACON_MAJOR = 1
    let BEACON_MINOR = 1
    
    var beaconInRange = false
    var beaconStartTimestamp = NSDate.timeIntervalSinceReferenceDate()

    var timer = NSTimer()
    var elapsedTime: NSTimeInterval = -1
    
    var driveDatabase = [[String:Double]]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self;
        locationManager.requestAlwaysAuthorization()
        beaconSearch()
        getPreviousDrives()
        tableView.reloadData()
        tableView.rowHeight = 60
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.separatorInset = UIEdgeInsetsZero
        setBackgroundColor("Gone")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    


    func beaconSearch(){
        if (CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedAlways) {
            locationManager.requestAlwaysAuthorization()
        }
        let beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString:BEACON_UUID)!, identifier: "primaryBeacon")
        locationManager.startRangingBeaconsInRegion(beaconRegion)
        print("Fired up. Searching")
    }
    
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        let knownBeacons = beacons.filter{ $0.proximity != CLProximity.Unknown }
        print(knownBeacons)
        if(knownBeacons.count > 0 && !beaconInRange)
        {
            print("Beacon is now \(nameForProximity(knownBeacons.first!.proximity))")
            beaconInRange = true
            beaconStartTimestamp = NSDate.timeIntervalSinceReferenceDate()
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "updateTime", userInfo: nil, repeats: true)
            setBackgroundColor(nameForProximity(knownBeacons.first!.proximity))
        }
        else if(knownBeacons.count > 0)
        {
            print("Beacon is now \(nameForProximity(knownBeacons.first!.proximity))")
            beaconInRange = true
            setBackgroundColor(nameForProximity(knownBeacons.first!.proximity))
        }
        else if(beaconInRange){
            print("No beacon in range anymore")
            beaconInRange = false
            timer.invalidate()
            let startTime =  NSDate().timeIntervalSince1970
            let timeElapsed = NSDate.timeIntervalSinceReferenceDate() - beaconStartTimestamp
            driveDatabase.insert(["startTime":startTime, "timeElapsed":timeElapsed], atIndex: 0)
            savePreviousDrives()
            print(driveDatabase)
            
            setBackgroundColor("Gone")
            let notification = UILocalNotification()
            notification.alertBody = "Drive Over."
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
            tableView.reloadData()
        }
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
    func updateTime() {
        
        let currentTime = NSDate.timeIntervalSinceReferenceDate()

        
        elapsedTime = currentTime - beaconStartTimestamp
        
        tableView.reloadData()
        
        //bunch of fucking failures here. I want to blow my brains out with this shit.
        
//        if(self.tableView.indexPathsForVisibleRows?.count > 0){
//            tableView.reloadRowsAtIndexPaths([self.tableView.indexPathsForVisibleRows!.last!], withRowAnimation: UITableViewRowAnimation.None)
//        }
//
//let indexPath = NSIndexPath(forRow: 0, inSection: 0)
//        let indices = self.tableView.indexPathsForVisibleRows
//        print(indices)
//        if(indices?.first?.row == 0)
//        {
//
//            
//        }
//        if(beaconInRange && tableView.numberOfSections > 0 && tableView.numberOfRowsInSection(1) > 0){
//            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
//        }
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
        switch location{
            case "Immediate":
                self.view.backgroundColor = UIColor(red: 41/255, green: 128/255, blue: 185/255, alpha: 1.0)
            case "Near":
                self.view.backgroundColor = UIColor(red: 41/255, green: 128/255, blue: 185/255, alpha: 1.0)
            case "Far":
                self.view.backgroundColor = UIColor(red: 41/255, green: 128/255, blue: 185/255, alpha: 1.0)
            case "Gone":
                self.view.backgroundColor = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1.0)
            default:
                self.view.backgroundColor = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1.0)
        }

    }
    
    

    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return (beaconInRange ? 1 : 0) + driveDatabase.count
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete{
            let rowToDelete = (beaconInRange ? -1 : 0) + indexPath.row
            driveDatabase.removeAtIndex(rowToDelete)
            savePreviousDrives()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if(beaconInRange && indexPath.row == 0)
        {
            return UITableViewCellEditingStyle.None
        }
        else
        {
            return UITableViewCellEditingStyle.Delete
        }
    }
    
     func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
     {
        var cell:TrackerTableViewCell =  tableView.dequeueReusableCellWithIdentifier("timeTrackerCell") as! TrackerTableViewCell
        var timeStamp = ""
        var timeElapsedString = ""
        var totalTimeElapsed = 0.0
        if(beaconInRange && indexPath.row == 0){
            //This is the active drive
            cell.backgroundColor = UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: 1.0)
            timeStamp = "Now"
            timeElapsedString = prettyPrintElapsedTime(elapsedTime)
            totalTimeElapsed = (elapsedTime / 3600.0)
        }
        else
        {
            var ind = beaconInRange ? (indexPath.row - 1 ): indexPath.row
            var dictObject = driveDatabase[ind]
            var startTime = NSDate(timeIntervalSince1970: dictObject["startTime"]!)
            cell.backgroundColor = UIColor.clearColor()
            let formatter = NSDateFormatter()
            formatter.dateStyle = NSDateFormatterStyle.MediumStyle
            formatter.timeStyle = NSDateFormatterStyle.ShortStyle
            timeStamp = formatter.stringFromDate(startTime)
            timeElapsedString = prettyPrintElapsedTime(NSTimeInterval(dictObject["timeElapsed"]!))
            totalTimeElapsed = NSTimeInterval(dictObject["timeElapsed"]!) / 3600.0
        }
        
        cell.labelView.text = "\(timeStamp): \(timeElapsedString)"
        cell.progressBar.progress = Float(totalTimeElapsed)
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        cell.layoutMargins = UIEdgeInsetsZero
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsetsMake(0.0, cell.frame.size.width, 0.0, 0.0)
        cell.labelView.textColor = UIColor(red:236/255, green: 240/255, blue: 241/255, alpha:1.0)
        cell.progressBar.layer.cornerRadius = 7
        cell.progressBar.clipsToBounds = true
        
        return cell
    }
    
    func getPreviousDrives()
    {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        var retArray = defaults.objectForKey("driveDatabase")
        if(retArray != nil){
            driveDatabase = retArray as! [[String:Double]]
        }
        else
        {
          driveDatabase = [[String:Double]]()
          defaults.setValue(driveDatabase, forKey: "driveDatabase")
        }
        //for debugging locally
        //driveDatabase = [["timeElapsed": 16.9998490214348, "startTime": 1451241623.74958], ["timeElapsed": 12.9996680021286, "startTime": 1451241589.31375], ["timeElapsed": 9.99890094995499, "startTime": 1451241572.31298], ["timeElapsed": 6.99492001533508, "startTime": 1451241557.31374]]
        defaults.synchronize()
    }
    
    func savePreviousDrives()
    {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(driveDatabase, forKey: "driveDatabase")
        defaults.synchronize()
    }
    
    
    
}

