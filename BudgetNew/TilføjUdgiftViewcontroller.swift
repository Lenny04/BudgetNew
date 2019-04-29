//
//  TilføjUdgiftViewcontroller.swift
//  BudgetNew
//
//  Created by linoj ravindran on 08/02/2019.
//  Copyright © 2019 linoj ravindran. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseFirestore
import DropDown

class TilføjUdgiftViewcontroller: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    var ref: DocumentReference!
    lazy var db = Firestore.firestore()
    var quoteListenerSubBudget: ListenerRegistration!
    var quoteListenerCategories: ListenerRegistration!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var amountText: UITextField!
    @IBOutlet weak var txtDatePicker: UITextField!
    @IBOutlet weak var categoryPicker: UIPickerView!
    var newCategoriesPickerView = UIPickerView()
    let datePicker = UIDatePicker()
    var newCategoriesToolBar = UIToolbar()
    var newSubCancelButton = UIBarButtonItem(), newSubDoneButton = UIBarButtonItem(), flexSpace = UIBarButtonItem()
    var budget = Budget(budgetName: "", keyID: "", moneyLeft: 0, moneyTotal: 0)
    var subBudgets = [SubBudget](), newCategories = [SubBudget]()
    var newCategoriesTextfield = UITextField()
    @IBOutlet weak var categoryButton: UIButton!
    var currentIndex = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        self.categoryPicker.delegate = self
        self.categoryPicker.dataSource = self
        self.categoryPicker.tag = 1
        datePicker.tag = 2
        newCategoriesPickerView.delegate = self
        newCategoriesPickerView.dataSource = self
        newCategoriesPickerView.tag = 3
        //datePicker.addTarget(self, action: #selector(ViewController.datePickerValueChanged), for: UIControl.Event.valueChanged)
        UIGraphicsBeginImageContext(self.view.frame.size)
        UIImage(named: "Blurred_blue")?.draw(in: self.view.bounds)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        self.view.backgroundColor = UIColor(patternImage: image)
        amountText.keyboardType = UIKeyboardType.numberPad
        newCategoriesToolBar = UIToolbar(frame: CGRect(x: 0, y: 40, width: self.view.frame.width, height: self.view.frame.height/15))
        newSubCancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(TilføjUdgiftViewcontroller.subTappedToolBarBtn))
        newSubDoneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(TilføjUdgiftViewcontroller.subDonePressed))
        flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        
        self.quoteListenerSubBudget = self.db.collection("Budget/\(self.budget.getKeyID())/SubBudgets").addSnapshotListener { (querySnapshot, err) in
            if err != nil {
                //print("Error getting documents: \(err)")
            }
            else {
                querySnapshot?.documentChanges.forEach { diff in
                    if (diff.type == .added){
                        self.subBudgets.append(SubBudget(subBudgetName: "", keyID: diff.document.documentID, symbol: "", moneyLeft: 0, moneySpent: 0, moneyTotal: 0))
                        let value1 = diff.document.data() as NSDictionary
                        for (key, value) in value1 {
                            let notenu = key as! String
                            switch notenu{
                            case "Name":
                                self.subBudgets[self.subBudgets.count-1].setSubBudgetName(a: value as! String)
                                break
                            case "Symbol":
                                self.subBudgets[self.subBudgets.count-1].setSymbol(c: value as! String)
                                break
                            case "MoneyLeft":
                                self.subBudgets[self.subBudgets.count-1].setMoneyLeft(d: value as! Int)
                                break
                            case "MoneySpent":
                                self.subBudgets[self.subBudgets.count-1].setMoneySpent(e: value as! Int)
                                break
                            case "MoneyTotal":
                                self.subBudgets[self.subBudgets.count-1].setMoneyTotal(f: value as! Int)
                                break
                            default: break
                            }
                        }
                        // print("Document added in firestore")
                    }
                    if(diff.type == .modified) {
                        //print("Modified the document in firestore")
                        let value1 = diff.document.data() as NSDictionary
                        let changedIndex = self.subBudgets.index(where: {$0.getKeyID() == diff.document.documentID})
                        for (key, value) in value1 {
                            let notenu = key as! String
                            if(notenu == "Name"){
                                self.subBudgets[changedIndex!].setSubBudgetName(a: value as! String)
                            }
                            else if(notenu == "Symbol"){
                                self.subBudgets[changedIndex!].setSymbol(c: value as! String)
                            }
                            else if(notenu == "MoneyLeft"){
                                self.subBudgets[changedIndex!].setMoneyLeft(d: value as! Int)
                            }
                            else if(notenu == "MoneySpent"){
                                self.subBudgets[changedIndex!].setMoneySpent(e: value as! Int)
                            }
                            else if(notenu == "MoneyTotal"){
                                self.subBudgets[changedIndex!].setMoneyTotal(f: value as! Int)
                            }
                        }
                    }
                    if(diff.type == .removed) {
                        //print("Document removed from firestore")
                    }
                }
            }
            self.subBudgets.sort {$0.getSubBudgetName() < $1.getSubBudgetName()}
            self.newCategories.sort {$0.getSubBudgetName() < $1.getSubBudgetName()}
            self.newCategorySelection()
            self.showDatePicker()
            self.showNewCategoriesPicker()
            self.categoryPicker.reloadAllComponents()
            self.nameText.autocapitalizationType = .sentences
            self.quoteListenerCategories = self.db.collection("Budget/\(self.budget.getKeyID())/Categories").addSnapshotListener { (querySnapshot2, err) in
                if err != nil {
                }
                else {
                    querySnapshot2?.documentChanges.forEach { diff in
                        if (diff.type == .added){
                            if(self.newCategories.contains(where: {$0.getKeyID() == diff.document.documentID}) == false){
                                self.newCategories.append(SubBudget(subBudgetName: "", keyID: diff.document.documentID, symbol: "", moneyLeft: 0, moneySpent: 0, moneyTotal: 0))
                                let value1 = diff.document.data() as NSDictionary
                                for (key, value) in value1 {
                                    let notenu = key as! String
                                    switch notenu{
                                    case "Name":
                                        self.newCategories[self.newCategories.count-1].setSubBudgetName(a: value as! String)
                                        break
                                    case "Symbol":
                                        self.newCategories[self.newCategories.count-1].setSymbol(c: value as! String)
                                        break
                                    default: break
                                    }
                                }
                                // print("Document: \(self.list[self.list.count-1].getItemDescription()), added in firestore")
                            }
                            else{
                                
                            }
                        }
                        if(diff.type == .modified) {
                            //print("Modified the document in firestore")
                            let value1 = diff.document.data() as NSDictionary
                            let changedIndex = self.newCategories.index(where: {$0.getKeyID() == diff.document.documentID})
                            for (key, value) in value1 {
                                let notenu = key as! String
                                if(notenu == "Name"){
                                    self.newCategories[changedIndex!].setSubBudgetName(a: value as! String)
                                }
                                else if(notenu == "Symbol"){
                                    self.newCategories[changedIndex!].setSymbol(c: value as! String)
                                }
                            }
                        }
                        if(diff.type == .removed) {
                            //print("Document removed from firestore")
                        }
                    }
                }
                for item in self.subBudgets{
                    for item2 in self.newCategories{
                        if(item.getSymbol() == item2.getSymbol()){
                            let duplicateIndex = self.newCategories.firstIndex(where: {$0.getSymbol() == item2.getSymbol()})
                            self.newCategories.remove(at: duplicateIndex!)
                        }
                    }
                }
                self.subBudgets.sort {$0.getSubBudgetName() < $1.getSubBudgetName()}
                self.newCategories.sort {$0.getSubBudgetName() < $1.getSubBudgetName()}
                self.newCategorySelection()
            }
        }
        //nameText.becomeFirstResponder()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TilføjUdgiftViewcontroller.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    
    func showDatePicker(){
        //Formate Date
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "da_DK")
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        txtDatePicker.text = formatter.string(from: self.datePicker.date)
        
        //ToolBar
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(donedatePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelDatePicker))
        toolbar.setItems([cancelButton,spaceButton,doneButton], animated: false)
        txtDatePicker.inputAccessoryView = toolbar
        txtDatePicker.inputView = datePicker
    }
    
    @objc func donedatePicker(){
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        txtDatePicker.text = formatter.string(from: datePicker.date)
        self.view.endEditing(true)
    }
    
    @objc func cancelDatePicker(){
        self.view.endEditing(true)
    }
    @objc func datePickerValueChanged(sender:UIDatePicker){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        txtDatePicker.text = dateFormatter.string(from: sender.date)
    }
    @IBAction func tilbageTilGraf(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
    @IBAction func tilføjUdgift(_ sender: UIButton) {
        let expenseSubBudgetKeyID = subBudgets[categoryPicker.selectedRow(inComponent: 0)].getKeyID()
        let expenseAmount = Int(amountText.text!)!
        let subbudgetIndex = self.subBudgets.firstIndex(where: {$0.getKeyID() == expenseSubBudgetKeyID})
        self.ref = self.db.collection("Budget/\(self.budget.getKeyID())/Expenses").addDocument(data: [
            "Name": nameText.text!,
            "Amount": Int(amountText.text!)!,
            "Date": txtDatePicker.text!,
            "SubBudgetKeyID": expenseSubBudgetKeyID
        ])
        let updatedSpent = self.subBudgets[subbudgetIndex!].getMoneySpent() + expenseAmount

    self.db.collection("Budget/\(self.budget.getKeyID())/SubBudgets").document(self.subBudgets[subbudgetIndex!].getKeyID()).updateData(["Name" : self.subBudgets[subbudgetIndex!].getSubBudgetName(), "Symbol" : self.subBudgets[subbudgetIndex!].getSymbol(), "MoneyLeft" : self.subBudgets[subbudgetIndex!].getMoneyTotal() - updatedSpent, "MoneySpent" : updatedSpent, "MoneyTotal" : self.subBudgets[subbudgetIndex!].getMoneyTotal()])
        
        let updatedLeft = self.budget.getMoneyLeft() - expenseAmount
        
        self.db.collection("Budget").document(self.budget.getKeyID()).updateData(["Name" : self.budget.getBudgetName(), "MoneyLeft" : updatedLeft, "MoneyTotal" : self.budget.getMoneyTotal()])
        { err in
            if err != nil {
                //print("Error adding document: \(err)")
            } else {
                //print("Document added with ID: \(self.ref!.documentID)")
            }
        }
        navigationController?.popToRootViewController(animated: true)
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        if(pickerView.tag == 1){
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 350, height: 30))
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 30))
            label.text = "\(self.subBudgets[row].getSymbol()) \(self.subBudgets[row].getSubBudgetName())"
            label.textAlignment = .center
            label.textColor = UIColor.black
            label.font = UIFont(name: "Avenir-Book", size: 20)
            if(subBudgets[row].getSubBudgetName() == "Ny kategori"){
                label.backgroundColor = UIColor.orange
                label.layer.masksToBounds = true
                label.layer.cornerRadius = 15
            }
            view.addSubview(label)
            return view
        }
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 350, height: 30))
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 30))
        label.text = "\(self.newCategories[row].getSymbol()) \(self.newCategories[row].getSubBudgetName())"
        label.textAlignment = .center
        label.textColor = UIColor.black
        label.font = UIFont(name: "Avenir-Book", size: 20)
        view.addSubview(label)
        return view
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if(pickerView.tag == 1){
            return subBudgets.count
        }
        return newCategories.count
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currentIndex = row
        if(pickerView.tag == 1){
            if(subBudgets[row].getSubBudgetName() == "Ny kategori"){
                let alert = UIAlertController(title: "Ny kategori", message: "Opret ny kategori!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Opret", style: .default, handler: { action in
                    if let expenseSubBudgetName = alert.textFields![0].text {
                        if expenseSubBudgetName.isEmpty {
                            let alert = UIAlertController(title: "Fejl", message: "Mangler titel til udgift", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {(_: UIAlertAction!) in
                            }))
                            self.present(alert, animated: true, completion: nil)
                            self.categoryPicker.selectRow(0, inComponent: 0, animated: true)
                        }
                        else{
                            let expenseSubBudget = alert.textFields![1].text!
                            let indexStartOfText = expenseSubBudget.index(expenseSubBudget.startIndex, offsetBy: 2)
                            let category = String(expenseSubBudget[expenseSubBudget.startIndex])
                            self.ref = self.db.collection("Budget/\(self.budget.getKeyID())/SubBudgets").addDocument(data: [
                                "Name": alert.textFields![0].text!,
                                "MoneyTotal": 0,
                                "MoneyLeft": 0,
                                "MoneySpent": 0,
                                "Symbol": category
                            ]) { err in
                                if err != nil {
                                    //print("Error adding document: \(err)")
                                } else {
                                    //print("Document added with ID: \(self.ref!.documentID)")
                                    let subBudgetIndex = self.subBudgets.firstIndex(where: {$0.getSymbol() == category})
                                    self.categoryPicker.selectRow(subBudgetIndex!, inComponent: 0, animated: true)
                                }
                            }
                        }
                    }
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                    self.categoryPicker.selectRow(0, inComponent: 0, animated: true)
                }))
                alert.addTextField(configurationHandler: { textField in
                    textField.placeholder = "Kategori navn"
                    textField.autocapitalizationType = .sentences
                })
                alert.addTextField(configurationHandler: { textFieldNewCategories in
                    textFieldNewCategories.text = "\(self.newCategories[0].getSymbol()) \(self.newCategories[0].getSubBudgetName())"
                    textFieldNewCategories.inputView = self.newCategoriesPickerView
                    textFieldNewCategories.inputAccessoryView = self.newCategoriesToolBar
                    self.newCategoriesTextfield = textFieldNewCategories
                })
                self.present(alert, animated: true)
            }
        }
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if(pickerView.tag == 1){
            return "\(self.subBudgets[row].getSymbol()) \(self.subBudgets[row].getSubBudgetName())"
        }
        return "\(self.newCategories[row].getSymbol()) \(self.newCategories[row].getSubBudgetName())"
    }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30
    }
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    @objc func subDonePressed(sender: UIBarButtonItem) {
        self.newCategoriesTextfield.text = "\(self.newCategories[currentIndex].getSymbol()) \(self.newCategories[currentIndex].getSubBudgetName())"
        newCategoriesTextfield.resignFirstResponder()
    }
    
    @objc func subTappedToolBarBtn(sender: UIBarButtonItem) {
        newCategoriesTextfield.resignFirstResponder()
    }
    func showNewCategoriesPicker(){
        self.newCategoriesToolBar.layer.position = CGPoint(x: self.view.frame.width/2, y: self.view.frame.height-20.0)
        self.newCategoriesToolBar.setItems([self.newSubCancelButton, self.flexSpace,self.newSubDoneButton], animated: true)
    }
    func newCategorySelection(){
        if(!self.subBudgets.contains(where: { $0.getSubBudgetName() == "Ny kategori" })){
            self.subBudgets.append(SubBudget(subBudgetName: "Ny kategori", keyID: "", symbol: "\u{2795}", moneyLeft: 0, moneySpent: 0, moneyTotal: 0))
        }
        else if(self.subBudgets.contains(where: { $0.getSubBudgetName() == "Ny kategori" })){
            let newCategoryIndex = self.subBudgets.index(where: {$0.getSubBudgetName() ==
                "Ny kategori"})
            self.subBudgets.remove(at: newCategoryIndex!)
            self.subBudgets.append(SubBudget(subBudgetName: "Ny kategori", keyID: "", symbol: "\u{2795}", moneyLeft: 0, moneySpent: 0, moneyTotal: 0))
        }
    }
}
