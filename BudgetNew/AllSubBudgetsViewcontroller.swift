//
//  AllSubBudgetsViewcontroller.swift
//  BudgetNew
//
//  Created by linoj ravindran on 05/03/2019.
//  Copyright © 2019 linoj ravindran. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseFirestore

class AllSubBudgetsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var ref: DocumentReference!
    lazy var db = Firestore.firestore()
    var quoteListener: ListenerRegistration!
    var quoteListener2: ListenerRegistration!
    @IBOutlet var tableView: UITableView!
    var budget = Budget(budgetName: "", keyID: "", moneyLeft: 0, moneyTotal: 0)
    var subBudgets = [SubBudget]()
    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        tableView.delegate = self
        tableView.dataSource = self
        self.quoteListener = self.db.collection("Budget/\(self.budget.getKeyID())/SubBudgets").addSnapshotListener { (querySnapshot, err) in
            if err != nil {
                //                print("Error getting documents: \(err)")
            }
            else if(querySnapshot?.documents == []){
                let alert = UIAlertController(title: "Nyt kategori", message: "Opret ny kategori!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Opret", style: .default, handler: { action in
                    let expenseSubBudget = alert.textFields![2].text!
                    let indexStartOfText = expenseSubBudget.index(expenseSubBudget.startIndex, offsetBy: 2)
                    let category = String(expenseSubBudget[expenseSubBudget.startIndex])
                    self.ref = self.db.collection("Budget/\(self.budget.getKeyID())/SubBudgets").addDocument(data: [
                        "Name": alert.textFields![0].text!,
                        "MoneyTotal": Int(alert.textFields![1].text!)!,
                        "MoneyLeft": Int(alert.textFields![1].text!)!,
                        "MoneySpent": 0,
                        "Symbol": category
                    ]) { err in
                        if err != nil {
                            //print("Error adding document: \(err)")
                        } else {
                            //print("Document added with ID: \(self.ref!.documentID)")
                        }
                    }
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addTextField(configurationHandler: { textField in
                    textField.placeholder = "Kategori navn"
                    textField.autocapitalizationType = .sentences
                })
                alert.addTextField(configurationHandler: { textField1 in
                    textField1.placeholder = "Tilrådighed"
                    textField1.keyboardType = UIKeyboardType.numberPad
                })
                alert.addTextField { (textField2) in
                    textField2.text = ""
                }
                self.present(alert, animated: true)
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
                        self.subBudgets.sort {$0.getSubBudgetName() < $1.getSubBudgetName()}
                        self.tableView.reloadData()
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
                            self.tableView.reloadData()
                        }
                        self.subBudgets.sort {$0.getSubBudgetName() < $1.getSubBudgetName()}
                    }
                    if(diff.type == .removed) {
                        //print("Document removed from firestore")
                        self.tableView.reloadData()
                    }
                }
                self.tableView.reloadData()
            }
            self.quoteListener2 = self.db.collection("Budget/").addSnapshotListener { (querySnapshot, err) in
                if err != nil {
                    //print("Error getting documents: \(err)")
                }
                else {
                    querySnapshot?.documentChanges.forEach { diff in
                        if (diff.type == .added){
                            // print("Added")
                            self.budget = Budget(budgetName: "", keyID: diff.document.documentID, moneyLeft: 0, moneyTotal: 0)
                            let valueDictionary = diff.document.data() as NSDictionary
                            for (key, value) in valueDictionary {
                                let notenu = key as! String
                                switch notenu{
                                case "Name":
                                    self.budget.setBudgetName(a: value as! String)
                                    break
                                case "MoneyLeft":
                                    self.budget.setMoneyLeft(e: value as! Int)
                                    break
                                case "MoneyTotal":
                                    self.budget.setMoneyTotal(f: value as! Int)
                                    break
                                default:
                                    break
                                }
                            }
                        }
                        if(diff.type == .modified){
                            let valueDictionary = diff.document.data() as NSDictionary
                            for (key, value) in valueDictionary {
                                let notenu = key as! String
                                if(notenu == "Name"){
                                    self.budget.setBudgetName(a: value as! String)
                                }
                                else if(notenu == "MoneyLeft"){
                                    self.budget.setMoneyLeft(e: value as! Int)
                                }
                                else if(notenu == "MoneyTotal"){
                                    self.budget.setMoneyTotal(f: value as! Int)
                                }
                            }
                        }
                        if(diff.type == .removed){
                            //print("Removed")
                        }
                    }
                }
                self.tableView.reloadData()
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell2") as! Cell2
        //        cell?.textLabel?.text = objectsArray[indexPath.section].sectionObjects[indexPath.row]
        //        return cell!
        if (indexPath.section == 0) {
            if(indexPath.row == 0){
                cell.title.text = "Brugt:"
                cell.amount.text = "\(budget.getMoneyTotal() - budget.getMoneyLeft())"
            }
            else if(indexPath.row == 1){
                cell.title.text = "Tilrådighed:"
                cell.amount.text = "\(budget.getMoneyLeft())"
            }
            else if(indexPath.row == 2){
                cell.title.text = "Total:"
                cell.amount.text = "\(budget.getMoneyTotal())"
            }
        }
        else if(indexPath.section == 1){
            if(subBudgets.isEmpty == true){
                cell.title.text = "Ingen kategorier"
                cell.amount.text = ""
                cell.last.text = ""
                
            }
            else{
                cell.title.text = "\(subBudgets[indexPath.row].getSymbol()) \(subBudgets[indexPath.row].getSubBudgetName())"
                cell.amount.text = "\(subBudgets[indexPath.row].getMoneySpent())"
            }
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        }
        return subBudgets.count
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        
        //        objectsArray[section].sectionName
        label.text = section == 0 ? "  Detaljer" : "  Kategorier"
        label.backgroundColor = UIColor(red: 0.5451, green: 0.6157, blue: 0.7647, alpha: 1.0)
        label.textColor = UIColor.white
        return label
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.section == 0){
            tableView.deselectRow(at: indexPath, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if(indexPath.section == 1){
            if editingStyle == .delete {
                let deletedSubBudgetKey = self.subBudgets[indexPath.row].getKeyID()
                let deletedSubBudgetAmount = self.subBudgets[indexPath.row].getMoneySpent()
                self.db.collection("Budget/\(self.budget.getKeyID())/SubBudgets").document(deletedSubBudgetKey).delete() { err in
                    if let err = err {
                        //print("Error removing document: \(err)")
                    }
                    else {
                        self.db.collection("Budget").document(self.budget.getKeyID()).updateData(["Name" : self.budget.getBudgetName(), "MoneyLeft" : self.budget.getMoneyLeft() + deletedSubBudgetAmount, "MoneyTotal" : self.budget.getMoneyTotal()])
                        
                        let subBudgetKeyID = self.subBudgets.index(where: {$0.getKeyID() == deletedSubBudgetKey})
                        self.db.collection("Budget/\(self.budget.getKeyID())/Expenses").whereField("SubBudgetKeyID", isEqualTo: deletedSubBudgetKey).getDocuments() {(querySnapshot, err) in
                            if let err = err {
                                //print("Error getting documents: \(err)")
                            }
                            else{
                                for document in querySnapshot!.documents {
                                    document.reference.delete()
                                }
                            }
                        }
                        self.subBudgets.remove(at: indexPath.row)
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    @objc func longPress(_ guesture: UILongPressGestureRecognizer) {
        if guesture.state == UIGestureRecognizer.State.began {
            let point = guesture.location(in: tableView)
            let indexPath = tableView.indexPathForRow(at: point)
            if(indexPath != nil && indexPath?.section == 1 && indexPath?.row == 2){
                let editInfo = UIAlertController(title: nil, message: "Detaljer", preferredStyle: UIAlertController.Style.alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: { (action) -> Void in
                    
                })
                let saveAction = UIAlertAction(title: "Gem", style: .default, handler: { (action) -> Void in
                    if(!(editInfo.textFields![0].text?.isEmpty)!){
                        let changedTotalMoney = Int(editInfo.textFields![0].text!)
                        self.db.collection("Budget").document(self.budget.getKeyID()).updateData(["Name" : self.budget.getBudgetName(), "MoneyLeft" : self.budget.getMoneyLeft() + (changedTotalMoney!-self.budget.getMoneyTotal()), "MoneyTotal" : changedTotalMoney!])
                        self.tableView.reloadData()
                    }
                })
                editInfo.addTextField { (textField0) in
                    textField0.text = "\(self.budget.getMoneyTotal() - self.budget.getMoneyLeft())"
                    textField0.keyboardType = .numberPad
                }
            }
        }
    }
}

