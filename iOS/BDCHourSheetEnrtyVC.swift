//
//  BDCHourSheetEnrtyVC.swift
//  BridgeClock
//1620
//  Created by Sinson.m on 21/02/18.
//  Copyright © 2018 Bridge. All rights reserved.
//

import UIKit
import SVProgressHUD


class BDCHourSheetEnrtyVC:BDCBaseVC,UIPickerViewDelegate,UIPickerViewDataSource,UITextFieldDelegate,UITextViewDelegate {
    
    
    @IBOutlet weak var switchValueChanged: UISwitch!
    
    @IBOutlet weak var addButton: UIButton!
    var viewKeyboardAccessory = UIView()
    var buttonNext = UIButton()
    var doneToolbar = UIToolbar()
    
    var projectID : Int?
    
     var projectIndex : Int?
    
    var isSwitchOnOrOff : Int?
    
    var stringDate : String?
    
    var descriptionTextStr: String?
    
    var hourObj : HourDetails?
    
    var isUpdateHourSheet : Bool?
    
    @IBOutlet weak var topView: UIView!
    
    @IBOutlet weak var switchExtraHour: UISwitch!
    @IBOutlet weak var projectTextField: MyTextField!
    
    @IBOutlet weak var activityTextField: MyTextField!
    
    @IBOutlet weak var hoursTextField: MyTextField!
    
    @IBOutlet weak var descriptionTextField: UITextView!
    
    let pickerViewProjects = UIPickerView()
    let pickerViewActivities = UIPickerView()
    let pickerViewHours = UIPickerView()
    
    let hoursAPIManager = BDCHoursAPIManager()
    
    var arrayProjectDetails : Array<Project_list>?
    var arrayProjects : Array<Project>?
    var arrayActivityDetails : Array<Activity>?
    var arrayPickerViewHours = ["0", "0.5", "1","1.5", "2", "2.5","3", "3.5", "4","4.5", "5", "5.5","6","6.5", "7","7.5", "8", "8.5","9", "9.5", "10","10.5", "11", "11.5","12"]
    
    var attributedStringPicker : NSAttributedString?

    override func viewDidLoad() {
        super.viewDidLoad()
        
     
        projectTextField.setValue(UIColor.white, forKeyPath: "_placeholderLabel.textColor")
        activityTextField.setValue(UIColor.white, forKeyPath: "_placeholderLabel.textColor")
        hoursTextField.setValue(UIColor.white, forKeyPath: "_placeholderLabel.textColor")
        self.topView.backgroundColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.2)
        switchExtraHour.onTintColor = UIColor(red: 66/255, green: 194/255, blue: 172/255, alpha: 1.0)
        
        projectTextField.delegate = self
        activityTextField.delegate = self
        projectTextField.delegate = self
        
        projectTextField.layer.borderWidth = 1.0
        activityTextField.layer.borderWidth = 1.0
        hoursTextField.layer.borderWidth = 1.0
        
        
        projectTextField.layer.cornerRadius = 5.0
        activityTextField.layer.cornerRadius = 5.0
        hoursTextField.layer.cornerRadius = 5.0
        
        let myColor = UIColor.white
        projectTextField.layer.borderColor =  myColor.cgColor
        activityTextField.layer.borderColor =  myColor.cgColor
        hoursTextField.layer.borderColor =  myColor.cgColor
        
        pickerViewProjects.delegate = self
        pickerViewProjects.dataSource = self
        
        pickerViewActivities.delegate = self
        pickerViewHours.delegate = self
        
        pickerViewActivities.backgroundColor =  UIColor(red: 239/255, green: 239/255, blue: 239/255, alpha: 1.0)
        pickerViewProjects.backgroundColor =   UIColor(red: 239/255, green: 239/255, blue: 239/255, alpha: 1.0)
        pickerViewHours.backgroundColor =   UIColor(red: 239/255, green: 239/255, blue: 239/255, alpha: 1.0)
        
        descriptionTextField.text = "Description"
  
        descriptionTextField.layer.borderWidth = 1.0
        descriptionTextField.layer.cornerRadius = 3.0
        descriptionTextField.textColor = UIColor.white
        descriptionTextField.layer.borderColor = UIColor.white.withAlphaComponent(1.0).cgColor
        descriptionTextField.delegate = self
         isSwitchOnOrOff = 0
        
        if self.isUpdateHourSheet! {
            self.addButton.setTitle("Update", for: .normal)
            activityTextField.text = hourObj?.activity
            hoursTextField.text = "\(hourObj?.hours ?? 0)"
            descriptionTextField.text = hourObj?.description
            self.projectID = hourObj?.proj_id
            if(hourObj?.extra_work == 1){
            self.switchExtraHour.isOn = true
            }else {
                 self.switchExtraHour.isOn = false
            }
        }
       
        
        
        self.addDoneButtonOnKeyboard()
        
        self.getProjectDetails()

        // Do any additional setup after loading the view.
        
        self.hideKeyboard()
    }
    
    func hideKeyboard()
    {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard))
        
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard()
    {
        self.view.endEditing(true)
    }
    
    func addDoneButtonOnKeyboard()
    {
        doneToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let myColor = UIColor(red: 63/255, green: 43/255, blue: 80/255, alpha: 1.0)
        done.tintColor? = myColor
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
    
    }
    
    @objc func doneButtonAction()
    {
        projectTextField.resignFirstResponder()
        activityTextField.resignFirstResponder()
        hoursTextField.resignFirstResponder()
    }

    
   
    
    func getProjectDetails(){
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.clear)
        
        let defaults = UserDefaults.standard
        let userId = defaults.integer(forKey: "UserId")
        defaults.synchronize()
        
        let parameters:[String:String]  = [
            "id": String(userId)
        ]
        
        let headers:[String:String] = [
            "Content-Type":"application/json"
        ]
        
        hoursAPIManager.getActiveProjectsCallBackAPI(headers:
            headers, parameters: parameters, completion: { (responseDictionary) in
                
               // print(responseDictionary)
                
                let statusCode = responseDictionary ["status"] as! Int
                
                if statusCode == 1{
                    
                    if (responseDictionary["data"] != nil) {
                        
                        let projectDictionary = responseDictionary["data"] as! NSDictionary
                        
                        if (projectDictionary["project_list"] != nil) {
                            self.getActivityDetails()
                           // SVProgressHUD.dismiss()
                            self.arrayProjectDetails = Project_list.modelsFromDictionaryArray(array: projectDictionary["project_list"] as! NSArray)
                             if self.isUpdateHourSheet! {
                            //let projectObj1 = self.arrayProjectDetails?[self.projectIndex!]
                                
                                for item in self.arrayProjectDetails! {
                                     let projectObj = item
                                    if(self.hourObj?.proj_id == projectObj.project_id){
                                        self.projectTextField.text = projectObj.project?.name
                                    }
                                    //print("Found \(item)")
                                }
                               
//
                            //self.projectTextField.text = projectObj?.project?.name
                            }
                          
                           
                            print(self.arrayProjectDetails ?? 0)
                           
                            
                        }
                    }
                    
                }else{
                    SVProgressHUD.dismiss()
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
    
    func getActivityDetails(){
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.clear)
        
        let defaults = UserDefaults.standard
        let userId = defaults.integer(forKey: "UserId")
        defaults.synchronize()
        
        
        let parameters:[String:String]  = [
            "id": String(userId)
        ]
        
        let headers:[String:String] = [
            "Content-Type":"application/json"
        ]
        
        hoursAPIManager.getActivitiesCallBackAPI(headers:
            headers, parameters: parameters, completion: { (responseDictionary) in
                
                //print(responseDictionary)
                
                let statusCode = responseDictionary ["status"] as! String
                
                if statusCode == "1"{
                    
                    if (responseDictionary["data"] != nil) {
                        
                        let projectDictionary = responseDictionary["data"] as! NSDictionary
                        
                        if (projectDictionary["activity"] != nil) {
                            SVProgressHUD.dismiss()
                            self.arrayActivityDetails = Activity.modelsFromDictionaryArray(array: projectDictionary["activity"] as! NSArray)
                           // print(self.arrayActivityDetails ?? 0)
                            
                        }
                    }
                    
                }else{
                    SVProgressHUD.dismiss()
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
    
    // MARK: - UITextViewDelegate
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if isUpdateHourSheet == true{
            
        }else{
            if textView.textColor == UIColor.white {
                textView.text = nil
                textView.textColor = UIColor.white
            }
        }
        
        
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Description"
            textView.textColor = UIColor.white
        }
    }
    
    // MARK: - UITextfieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
       
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if textField == projectTextField {
            
            let projectObj = arrayProjectDetails?[0]
            projectTextField.text = projectObj?.project?.name
            projectID = projectObj?.project_id
           // print(projectID!)
            projectTextField.inputView = pickerViewProjects
            projectTextField.inputAccessoryView = doneToolbar
            
        }else if textField == activityTextField{
            
            let projectObj = arrayActivityDetails?[0]
            activityTextField.text = projectObj?.name
            textField.inputView = pickerViewActivities
            activityTextField.inputAccessoryView = doneToolbar
            
            
        }else if textField == hoursTextField{
            
            let projectObj = arrayPickerViewHours[0]
            hoursTextField.text = projectObj
            textField.inputView = pickerViewHours
            hoursTextField.inputAccessoryView = doneToolbar
        }
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField){
        
        
    }
    
    // MARK: - Picker View data source
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
        // return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        
        if pickerView == pickerViewProjects {
            
            let projectObj = arrayProjectDetails?[row]
            
            let prj = projectObj?.project?.name
            
            attributedStringPicker = NSAttributedString(string: prj!, attributes: [NSAttributedStringKey.foregroundColor : UIColor.black])
            
            return attributedStringPicker
            
        }else if pickerView == pickerViewActivities{
            
            let projectObj = arrayActivityDetails?[row]
            
            attributedStringPicker = NSAttributedString(string: (projectObj?.name!)!, attributes: [NSAttributedStringKey.foregroundColor : UIColor.black])
            
            return attributedStringPicker
            
        }else{
            
            attributedStringPicker = NSAttributedString(string: arrayPickerViewHours[row], attributes: [NSAttributedStringKey.foregroundColor : UIColor.black])
            return attributedStringPicker
        }
        
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if pickerView == pickerViewProjects {
            return arrayProjectDetails!.count
        }else if pickerView == pickerViewActivities{
            return arrayActivityDetails!.count
        }else{
            return arrayPickerViewHours.count
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if pickerView == pickerViewProjects {
            
            let projectObj = arrayProjectDetails?[row]
            
            let prj = projectObj?.project?.name
            
            return prj
            
        }else if pickerView == pickerViewActivities{
            
            let projectObj = arrayActivityDetails?[row]
            return projectObj?.name
            
        }else{
            return arrayPickerViewHours[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if pickerView == pickerViewProjects {
            let projectObj = arrayProjectDetails?[row]
            projectTextField.text = projectObj?.project?.name
            projectID = projectObj?.project_id
            //print(projectID!)
        }else if pickerView == pickerViewActivities{
            let activity = arrayActivityDetails?[row]
            activityTextField.text = activity?.name
        }else{
            hoursTextField.text = arrayPickerViewHours[row]
        }
        
    }
    
    // MARK: - Callback API's
    
    func addHoursAPI(){
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.clear)
        
        let defaults = UserDefaults.standard
        let userId = defaults.integer(forKey: "UserId")
        defaults.synchronize()
        
        if descriptionTextField.text == "Description" {
            descriptionTextStr = ""
        }else{
            descriptionTextStr = descriptionTextField.text
        }
        
        let parameters:[String:Any]  = [
            "user_id":userId,
            "report_date":stringDate!,
            "hours":hoursTextField.text!,
            "proj_id":projectID!,
            "activity":activityTextField.text!,
            "description":descriptionTextStr!,
            "extra_work":isSwitchOnOrOff!
        ]
        
        let headers:[String:String] = [
            "Content-Type":"application/json"
        ]
        
        hoursAPIManager.getAddReportCallBackAPI(headers:
            headers, parameters: parameters, completion: { (responseDictionary) in
                
              //  print(responseDictionary)
                
                let statusCode = responseDictionary ["status"] as! Int
                
                if statusCode == 1{
                    
                    SVProgressHUD.dismiss()
                    
                    self.projectTextField.text = ""
                    self.activityTextField.text = ""
                    self.hoursTextField.text = ""
                    self.self.descriptionTextField.text = ""
                    self.switchExtraHour.isOn = false
                    
                    
                    let message = responseDictionary ["message"] as! NSString
                    
                    let alert = UIAlertController(title: "Success", message:message as String , preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                }else{
                    SVProgressHUD.dismiss()
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
    
    func updateAPI(){
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.clear)
        
        if descriptionTextField.text == "Description" {
            descriptionTextStr = ""
        }else{
            descriptionTextStr = descriptionTextField.text
        }
        
        let parameters:[String:Any]  = [
            "report_id":hourObj?.id! ?? 0,
            "report_date":hourObj?.report_date! ?? 0,
            "hours":hoursTextField.text!,
            "proj_id":projectID!,
            "activity":activityTextField.text!,
            "description":descriptionTextStr!,
            "extra_work":isSwitchOnOrOff!
        ]
        
        let headers:[String:String] = [
            "Content-Type":"application/json"
        ]
        
        hoursAPIManager.getUpdateReportCallBackAPI(headers:
            headers, parameters: parameters, completion: { (responseDictionary) in
                
                print(responseDictionary)
                 SVProgressHUD.dismiss()
                
                
                let statusCode = responseDictionary ["status"] as! Int
                
                if statusCode == 1{
                    
                    SVProgressHUD.dismiss()
                    
                    let message = responseDictionary ["message"] as! NSString
                    
                    let alertController = UIAlertController(title: "BridgeClock", message: message as String, preferredStyle: .alert)
                 
                    let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
                        self.dismiss(animated: true) {
                            
                        }
                    }
                    alertController.addAction(OKAction)
                    
                    self.present(alertController, animated: true, completion:nil)
                    
                }else{
                    SVProgressHUD.dismiss()
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

    // MARK: - Button Actions
    
    @IBAction func AddHoursButtonAction(_ sender: Any) {
        
        
        if  ((projectTextField.text?.count)! > 0)  && ((activityTextField.text?.count)! > 0)  && ((hoursTextField.text?.count)! > 0){
            
            if isUpdateHourSheet == true{
                 self.updateAPI()
            }else{
                 self.addHoursAPI()
            }
            
        }else{
            
            let alert = UIAlertController(title: "BridgeClock", message:"Please fill all the mandatory fields." , preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        }
    }
    
    
    @IBAction func addCancelButtonAction(_ sender: Any) {
        
        self.dismiss(animated: true) {
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    @IBAction func switchAction(_ sender: UISwitch) {
        
        if sender.isOn {
            isSwitchOnOrOff = 1
        }else{
            isSwitchOnOrOff = 0
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

class MyTextField: UITextField {
    
    let padding = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5);
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
}
