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
    let datePicker = UIDatePicker()
    var budget = Budget(budgetName: "", keyID: "", moneyLeft: 0, moneyTotal: 0)
    var subBudgets = [SubBudget]()
    var currentIndex = 0
    var isEmoji = BooleanLiteralType()
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        self.categoryPicker.delegate = self
        self.categoryPicker.dataSource = self
        self.categoryPicker.tag = 1
        datePicker.tag = 2
        //datePicker.addTarget(self, action: #selector(ViewController.datePickerValueChanged), for: UIControl.Event.valueChanged)
        UIGraphicsBeginImageContext(self.view.frame.size)
        UIImage(named: "Blurred_blue")?.draw(in: self.view.bounds)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        self.view.backgroundColor = UIColor(patternImage: image)
        amountText.keyboardType = UIKeyboardType.numberPad
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
                        let changedIndex = self.subBudgets.firstIndex(where: {$0.getKeyID() == diff.document.documentID})
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
            self.newCategorySelection()
            self.showDatePicker()
            self.categoryPicker.reloadAllComponents()
            self.nameText.autocapitalizationType = .sentences
            self.quoteListenerCategories = self.db.collection("Budget/\(self.budget.getKeyID())/Categories").addSnapshotListener { (querySnapshot2, err) in
                if err != nil {
                }
                else {
                    querySnapshot2?.documentChanges.forEach { diff in
                        if (diff.type == .added){
                            
                        }
                        if(diff.type == .modified) {
                            //print("Modified the document in firestore")
                            
                        }
                        if(diff.type == .removed) {
                            //print("Document removed from firestore")
                        }
                    }
                }
                self.subBudgets.sort {$0.getSubBudgetName() < $1.getSubBudgetName()}
                self.newCategorySelection()
            }
        }
        //nameText.becomeFirstResponder()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TilføjUdgiftViewcontroller.dismissKeyboard))
        view.addGestureRecognizer(tap)
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        amountText.addTarget(self, action: #selector(TilføjUdgiftViewcontroller.amountValueDidChange), for: .editingChanged)
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
        label.textAlignment = .center
        label.textColor = UIColor.black
        label.font = UIFont(name: "Avenir-Book", size: 20)
        view.addSubview(label)
        return view
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return subBudgets.count
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currentIndex = row
        if(pickerView.tag == 1){
            if(subBudgets[row].getSubBudgetName() == "Ny kategori"){
                let alert = UIAlertController(title: "Ny kategori", message: "Opret ny kategori!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Opret", style: .default, handler: { action in
                    self.ref = self.db.collection("Budget/\(self.budget.getKeyID())/SubBudgets").addDocument(data: [
                        "Name": alert.textFields![0].text!,
                        "MoneyTotal": 0,
                        "MoneyLeft": 0,
                        "MoneySpent": 0,
                        "Symbol": alert.textFields![1].text!
                    ]) { err in
                        if err != nil {
                            //print("Error adding document: \(err)")
                        } else {
                            //print("Document added with ID: \(self.ref!.documentID)")
                            let subBudgetIndex = self.subBudgets.firstIndex(where: {$0.getSymbol() == alert.textFields![1].text!})
                            self.categoryPicker.selectRow(subBudgetIndex!, inComponent: 0, animated: true)
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
                    textFieldNewCategories.placeholder = "Emoji for kategori"
                    textFieldNewCategories.addTarget(self, action: #selector(TilføjUdgiftViewcontroller.alertTextFieldDidChange),
                                                     for: .editingChanged)
                })
                alert.actions[0].isEnabled = false
                self.present(alert, animated: true)
            }
        }
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(self.subBudgets[row].getSymbol()) \(self.subBudgets[row].getSubBudgetName())"
    }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30
    }
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    func newCategorySelection(){
        if(!self.subBudgets.contains(where: { $0.getSubBudgetName() == "Ny kategori" })){
            self.subBudgets.append(SubBudget(subBudgetName: "Ny kategori", keyID: "", symbol: "\u{2795}", moneyLeft: 0, moneySpent: 0, moneyTotal: 0))
        }
        else if(self.subBudgets.contains(where: { $0.getSubBudgetName() == "Ny kategori" })){
            let newCategoryIndex = self.subBudgets.firstIndex(where: {$0.getSubBudgetName() ==
                "Ny kategori"})
            self.subBudgets.remove(at: newCategoryIndex!)
            self.subBudgets.append(SubBudget(subBudgetName: "Ny kategori", keyID: "", symbol: "\u{2795}", moneyLeft: 0, moneySpent: 0, moneyTotal: 0))
        }
    }
    @objc func alertTextFieldDidChange(sender : UITextField){
        let alertController = self.presentedViewController as? UIAlertController
        let emoji = sender.text!
//        for scalar in emoji.unicodeScalars {
//            isEmoji = scalar.properties.isEmoji
//        }
        let submitAction = alertController?.actions[0]
        submitAction?.isEnabled = emoji.containsEmoji() && emoji.count == 1 && !(alertController?.textFields?[0].text!.isEmpty)!
    }
    @objc func amountValueDidChange(){
        self.navigationItem.rightBarButtonItem?.isEnabled = !nameText.text!.isEmpty && !amountText.text!.isEmpty && !txtDatePicker.text!.isEmpty && categoryPicker.selectedRow(inComponent: 0) != categoryPicker.numberOfRows(inComponent: 0)
    }
}

extension String {
    func containsEmoji() -> Bool {
        var result = false
        for scalar in self.unicodeScalars {
            switch scalar.value {
            case 0x1F600...0x1F64F:
                result = true
            case 0x1F300...0x1F5FF:
                result = true
            case 0x1F680...0x1F6FF:
                result = true
            case 0x2600...0x26FF:
                result = true
            case 0x2700...0x27BF:
                result = true
            default: ()
            }
        }
        return result
    }
}
