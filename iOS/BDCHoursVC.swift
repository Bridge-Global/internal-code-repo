//
//  BDCHoursVC.swift
//  BridgeClock
//
//  Created by Praveen on 1/25/18.
//  Copyright © 2018 Bridge. All rights reserved.
//

import UIKit
import SVProgressHUD
import FoldingTabBar

class BDCHoursVC: BDCBaseVC , UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout ,UITableViewDelegate,UITableViewDataSource,YALTabBarDelegate {
    
    let loginAPIManager = BDCLoginAPIManager()
    let hoursAPIManager =  BDCHoursAPIManager()
    var arrayWeekReports : Array<WeekReport>?
    var arrayHourReports : Array<HourDetails>?
    
    var firstLoad : Bool?
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var viewEmpty: UIView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var tableView : UITableView!
    
      let reuseIdentifier = "cell"
      var items = ["1", "2", "3", "4", "5", "6", "7"]
      var days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
      var indexpath : Int = -1
      var currentIndexpath : Int = -1
      var deleteIndexpath : Int = -1
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = false
        tableView.tableFooterView = UIView()
    
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.basicViewLayOutSetUp()
        
        self.getUserWeeklyHourSheetAPI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - View Basic SetUp
    
    func basicViewLayOutSetUp(){
        
        self.firstLoad = true
        
        self.topView.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.2)
        
        self.indexpath = -1
        self.currentIndexpath = -1
        
        collectionView.setNeedsLayout()
        collectionView.layoutIfNeeded()
        self.collectionView.backgroundColor = UIColor(red: 94.0/255.0, green: 91.0/255.0, blue: 149.0/255.0, alpha: 1)
    }
    
    // MARK: - Get Hoursheet API Call

    func getUserWeeklyHourSheetAPI(){
        
        SVProgressHUD.show()
        
        let defaults = UserDefaults.standard
        let userId = defaults.integer(forKey: "UserId")
        defaults.synchronize()
        
        let parameters:[String:Any]  = [
            "id":userId
        ]
        
        let headers:[String:String] = [
            "Content-Type":"application/json"
        ]
        
        loginAPIManager.getUserWeeklyHourSheetCallBackAPI(headers:
            headers, parameters: parameters, completion: { (responseDictionary) in
                
                let statusCode = responseDictionary ["status"] as! Int
                
                if statusCode == 1{
                    
                    if (responseDictionary["data"] != nil) {
                        
                        let userDictionary = responseDictionary["data"] as! NSDictionary
                        
                        if (userDictionary["weekReport"] != nil) {
                           SVProgressHUD.dismiss()
                            self.arrayWeekReports = WeekReport.modelsFromDictionaryArray(array: userDictionary["weekReport"] as! NSArray)
                            
                         
                            self.collectionView.reloadData()
                            
                            
                            unowned let unownedSelf = self
                            
                            let deadlineTime = DispatchTime.now() + .seconds(1)
                            DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
                                unownedSelf.tableView.reloadData()
                            })
                            
                           
                        }
                    }
            
                }else{
                    
                    let message = responseDictionary ["message"] as! NSString
                    
                    let alert = UIAlertController(title: "Error!", message:message as String , preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                }
                
        }) { (error) in
            
            SVProgressHUD.dismiss()
            let alert = UIAlertController(title: "Error!", message:error.localizedDescription , preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       // return self.items.count
      
        return self.arrayWeekReports?.count ?? 0
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! MyCollectionViewCell
        
        let weekObj = arrayWeekReports?[indexPath.item]
        
        let fullDate    = self.dateFormat(startDate: (weekObj?.date)!)
        
        if fullDate == getCurrentDate(){
            if(self.firstLoad!){
                self.firstLoad = false
            self.indexpath = indexPath.row
            self.currentIndexpath = indexPath.row
              
        collectionView.scrollToItem(at: IndexPath(item: indexpath, section: 0), at: .centeredHorizontally, animated: true)
            }
            
            if(self.arrayWeekReports?[self.currentIndexpath].hourDetails?.count == 0){
                self.tableView.isHidden = true
            }else{
                self.tableView.isHidden = false
            }
        }
        
        let fullDateArr = fullDate.components(separatedBy: " ")
        
        let monthName    = fullDateArr[0]
        let day = fullDateArr[1]
      
        cell.lblDate.text =   day
        cell.lblMonth.text = monthName
        cell.lblDay.text = self.days[indexPath.item]
       
        // Use the outlet in our custom class to get a reference to the UILabel in the cell

        if(self.indexpath == indexPath.row){
            cell.backgroundColor =  UIColor(red: 66/255, green: 194/255, blue: 172/255, alpha: 1.0) // make cell more visible in our example project
        }else{
            cell.backgroundColor = UIColor.white // make cell more visible in our example project
        }
        
        cell.layer.borderColor = UIColor.black.cgColor
        cell.layer.borderWidth = 0
        cell.layer.cornerRadius = 5
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        
        self.indexpath = indexPath.row
        self.currentIndexpath =  indexPath.row
        collectionView.reloadData()
        print("You selected cell #\(indexPath.item)!")
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.red

        self.tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.arrayWeekReports?[self.currentIndexpath].hourDetails?.count ?? 0
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BDCHourCellIdentifier", for: indexPath) as! BDCHourCell
        let weekObj = arrayWeekReports?[self.currentIndexpath]
        self.arrayHourReports = weekObj?.hourDetails
        let hourObj = arrayHourReports?[indexPath.item]
         //cell.backgroundColor =  UIColor(red: 70/255, green: 48/255, blue: 89/255, alpha: 0.8)
        cell.lblHour.text = String(format:"%.1f", (hourObj?.hours)!)
        cell.lblActivity.text = hourObj?.activity
        cell.lblProject.text = hourObj?.description
        if(hourObj?.extra_work == 1){
            cell.imgExtraHour.isHidden = false
        }else{
              cell.imgExtraHour.isHidden = true
        }
       // cell.backgroundColor =  UIColor.white
       // cell.selectionStyle = .none
        
       
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        let hourObj = arrayHourReports?[indexPath.item]
        let hourSheetVC = self.storyboard?.instantiateViewController(withIdentifier: "HourSheet") as! BDCHourSheetEnrtyVC
        hourSheetVC.isUpdateHourSheet = true
        hourSheetVC.hourObj = hourObj
        hourSheetVC.projectIndex = indexPath.row
        self.present(hourSheetVC, animated: true, completion: nil)
        
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            
             let hourObj = arrayHourReports?[indexPath.item]
            self.deleteIndexpath = indexPath.row
            self.deleteReportAPI(reportId: (hourObj?.id!)!)
         
        }
    }
    
    // MARK: - Date Workouts
    
    func dateFormat(startDate: String)-> String{
        let dateFormatterStartDate = DateFormatter()
        dateFormatterStartDate.dateFormat = "yyyy-MM-dd"
        let startDateEvt = dateFormatterStartDate.date(from:startDate)!
        dateFormatterStartDate.dateFormat = "MMM dd"
        let startDateString = dateFormatterStartDate.string(from:startDateEvt)
        return startDateString
    }
    
    func getCurrentDate() -> String{
    
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        let result = formatter.string(from: date)
        return result
    }
    
    
    func monthNum(month: String) -> Int {
        
        switch month {
        case "Jan":
            return 1
        case "Feb":
            return 2
        case "Mar":
            return 3
        case "Apr":
            return 4
        case "May":
            return 5
        case "Jun":
            return 6
        case "Jul":
            return 7
        case "Aug":
            return 8
        case "Sep":
            return 9
        case "Oct":
            return 10
        case "Nov":
            return 11
        case "Dec":
            return 12
        default:
            return 0
        }
        
    }
    
    // MARK: - UITabbar Select Right Item
    
    func tabBarDidSelectExtraRightItem(_ tabBar: YALFoldingTabBar){
        
        
        let weekObj = arrayWeekReports?[currentIndexpath]
        let fullDate    = self.dateFormat(startDate: (weekObj?.date)!)
        let fullDateArr : [String] = fullDate.components(separatedBy: " ")
        let currentDate = getCurrentDate()
        let currentDateArr : [String] = currentDate.components(separatedBy: " ")
        
        
        
      
        if(self.monthNum(month:currentDateArr[0]) < self.monthNum(month: fullDateArr[0])){
            let alert = UIAlertController(title: "BridgeClock", message:"You cannot enter data for future dates!" as String , preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }else if(Int(currentDateArr[1])! < Int(fullDateArr[1])! && self.monthNum(month:currentDateArr[0]) == self.monthNum(month: fullDateArr[0])){
            let alert = UIAlertController(title: "BridgeClock", message:"You cannot enter data for future dates!" as String , preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }else{
            print("Kool")
        }
        
        
        let hourSheetVC = self.storyboard?.instantiateViewController(withIdentifier: "HourSheet") as! BDCHourSheetEnrtyVC
        // let weekObj = arrayWeekReports?[currentIndexpath]
        hourSheetVC.stringDate = weekObj?.date
        hourSheetVC.isUpdateHourSheet = false
        self.present(hourSheetVC, animated: true, completion: nil)
       
    }
    
    // MARK: - API Callback to Delete
    
    func deleteReportAPI(reportId: Int){
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.clear)
        
        let parameters:[String:String]  = [
            "report_id": String(reportId)
        ]
        
        let headers:[String:String] = [
            "Content-Type":"application/json"
        ]
        
        
        hoursAPIManager.deleteWeeklyHourSheetCallBackAPI(headers:
            headers, parameters: parameters, completion: { (responseDictionary) in
                
               // print(responseDictionary)
                SVProgressHUD.dismiss()
                let statusCode = responseDictionary ["status"] as! Int
                
                if statusCode == 1{
                    self.arrayWeekReports?[self.currentIndexpath].hourDetails?.remove(at: self.deleteIndexpath)
                    //self.arrayHourReports?.remove(at: self.deleteIndexpath)
                    self.tableView.reloadData()
                    
                         let message = responseDictionary ["message"] as! NSString
                    let alert = UIAlertController(title: "Success!", message:message as String , preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                    
                    
                }else{
                    
                    let message = responseDictionary ["message"] as! NSString
                    
                    let alert = UIAlertController(title: "Error!", message:message as String , preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                }
                
        }) { (error) in
            
            SVProgressHUD.dismiss()
            let alert = UIAlertController(title: "Error!", message:error.localizedDescription , preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        }
        
        
    }
   
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
