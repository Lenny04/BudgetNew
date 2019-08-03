//
//  SubBudgets.swift
//  BudgetNew
//
//  Created by linoj ravindran on 11/02/2019.
//  Copyright © 2019 linoj ravindran. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseFirestore

class SubBudgetsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, UISearchBarDelegate {
    var ref: DocumentReference!
    lazy var db = Firestore.firestore()
    var quoteListenerExpenses: ListenerRegistration!
    var quoteListenerSubBudgets: ListenerRegistration!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var searchbar: UISearchBar!
    var budget = Budget(budgetName: "", keyID: "", moneyLeft: 0, moneyTotal: 0)
    var subBudget = SubBudget(subBudgetName: "", keyID: "", symbol: "", moneyLeft: 0, moneySpent: 0, moneyTotal: 0)
    var subBudgetDetails = [String](), subBudgetExpenses = [Expense](), filteredExpenses = [Expense](), subBudgets = [SubBudget](),
    expenses = [Expense]()
    var twoDimensionArray = [[AnyObject]]()
    var currentIndex = 0
    var categoriesPickerView = UIPickerView(), datePicker = UIDatePicker()
    var categoriesToolBar = UIToolbar()
    var categoriesCancelButton = UIBarButtonItem(), categoriesDoneButton = UIBarButtonItem(), filterBarButtonItem = UIBarButtonItem()
    var flexSpace = UIBarButtonItem(), toolbarButtons = [UIBarButtonItem]()
    var categoriesTextfield = UITextField(), dateTextfield = UITextField()
    let filter_off = UIImage(named: "Filter_off_30px"), filter_on = UIImage(named: "Filter_on_30px")
    var isSearching = false
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.isToolbarHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        
        // Tableview settings
        tableView.delegate = self
        tableView.dataSource = self
        
        // Category pickerview settings
        categoriesPickerView.delegate = self
        categoriesPickerView.dataSource = self
        categoriesPickerView.tag = 1
        categoriesPickerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 180)
        categoriesToolBar = UIToolbar(frame: CGRect(x: 0, y: 40, width: self.view.frame.width, height: self.view.frame.height/15))
        categoriesCancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(SubBudgetsViewController.subTappedToolBarBtn))
        categoriesDoneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(SubBudgetsViewController.subDonePressed))
        flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        
        // Date pickerview settings
        datePicker.tag = 2
        //datePicker.addTarget(self, action: #selector(SubBudgetsViewController.datePickerValueChanged), for: UIControl.Event.valueChanged)
        
        self.quoteListenerExpenses = self.db.collection("Budget/\(self.budget.getKeyID())/Expenses").whereField("SubBudgetKeyID", isEqualTo: subBudget.getKeyID()).addSnapshotListener { (querySnapshot, err) in
            if err != nil {
                //print("Error getting documents: \(err)")
            }
            else if(querySnapshot?.documents == []){
                //  If there are no expenses in this subbudget
                self.subBudgetExpenses.append(Expense(expenseName: "Ingen udgifter i denne kategori", keyID: "", amount: 0, date: "", subBudget: ""))
                self.tableView.reloadData()
            }
            else {
                // There are expenses in this subbudget
                querySnapshot?.documentChanges.forEach { diff in
                    if (diff.type == .added){
                        self.subBudgetExpenses.append(Expense(expenseName: "", keyID: diff.document.documentID, amount: 0, date: "", subBudget: ""))
                        let value1 = diff.document.data() as NSDictionary
                        for (key, value) in value1 {
                            let notenu = key as! String
                            switch notenu{
                            case "Name":
                            self.subBudgetExpenses[self.subBudgetExpenses.count-1].setExpenseName(a: value as! String)
                                break
                            case "Amount":
                            self.subBudgetExpenses[self.subBudgetExpenses.count-1].setAmount(d: value as! Int)
                                break
                            case "Date":
                                self.subBudgetExpenses[self.subBudgetExpenses.count-1].setDate(b: value as! String)
                                break
                            case "SubBudgetKeyID":
                            self.subBudgetExpenses[self.subBudgetExpenses.count-1].setSubBudgetKeyID(e: value as! String)
                                break
                            default: break
                            }
                        }
                        self.tableView.reloadData()
                        //print("Document added in firestore")
                    }
                    if(diff.type == .modified) {
                        //print("Modified the document in firestore")
                        let value1 = diff.document.data() as NSDictionary
                        let changedIndex = self.subBudgetExpenses.index(where: {$0.getKeyID() == diff.document.documentID})
                        for (key, value) in value1 {
                            let notenu = key as! String
                            if(notenu == "Name"){
                                self.subBudgetExpenses[changedIndex!].setExpenseName(a: value as! String)
                            }
                            else if(notenu == "Amount"){
                                self.subBudgetExpenses[changedIndex!].setAmount(d: value as! Int)
                            }
                            else if(notenu == "Date"){
                                self.subBudgetExpenses[changedIndex!].setDate(b: value as! String)
                            }
                            else if(notenu == "SubBudgetKeyID"){
                                self.subBudgetExpenses[changedIndex!].setSubBudgetKeyID(e: value as! String)
                            }
                        }
                        self.tableView.reloadData()
                        self.subBudgetExpenses.sort {$0.getExpenseName() < $1.getExpenseName()}
                    }
                    if(diff.type == .removed) {
                        self.tableView.reloadData()
                        //print("Document removed from firestore")
                    }
                }
                self.tableView.reloadData()
            }
            self.showCategoriesPicker()
            self.showDatePicker()
            self.categoriesPickerView.reloadAllComponents()
            self.tableView.reloadData()
            self.quoteListenerSubBudgets = self.db.collection("Budget/\(self.budget.getKeyID())/SubBudgets").whereField("Symbol", isEqualTo: self.subBudget.getSymbol()).addSnapshotListener { (querySnapshot, err) in
                if err != nil {
                    //print("Error getting documents: \(err)")
                }
                else {
                    querySnapshot?.documentChanges.forEach { diff in
                        if (diff.type == .added){
                            self.subBudget.setKeyID(b: diff.document.documentID)
                            let value1 = diff.document.data() as NSDictionary
                            for (key, value) in value1 {
                                let notenu = key as! String
                                switch notenu{
                                case "Name":
                                    self.subBudget.setSubBudgetName(a: value as! String)
                                    break
                                case "Symbol":
                                    self.subBudget.setSymbol(c: value as! String)
                                    break
                                case "MoneyLeft":
                                    self.subBudget.setMoneyLeft(d: value as! Int)
                                    break
                                case "MoneySpent":
                                    self.subBudget.setMoneySpent(e: value as! Int)
                                    break
                                case "MoneyTotal":
                                    self.subBudget.setMoneyTotal(f: value as! Int)
                                    break
                                default:
                                    self.tableView.reloadData()
                                    break
                                }
                            }
                            self.tableView.reloadData()
                            //print("Document added in firestore")
                        }
                        if(diff.type == .modified) {
                            //print("Modified the document in firestore")
                            let value1 = diff.document.data() as NSDictionary
                            for (key, value) in value1 {
                                let notenu = key as! String
                                if(notenu == "Name"){
                                    self.subBudget.setSubBudgetName(a: value as! String)
                                }
                                else if(notenu == "Symbol"){
                                    self.subBudget.setSymbol(c: value as! String)
                                }
                                else if(notenu == "MoneyLeft"){
                                    self.subBudget.setMoneyLeft(d: value as! Int)
                                }
                                else if(notenu == "MoneySpent"){
                                    self.subBudget.setMoneySpent(e: value as! Int)
                                }
                                else if(notenu == "MoneyTotal"){
                                    self.subBudget.setMoneyTotal(f: value as! Int)
                                }
                            }
                            self.tableView.reloadData()
                        }
                        if(diff.type == .removed) {
                            //print("Document removed from firestore")
                            self.tableView.reloadData()
                        }
                    }
                }
                self.showCategoriesPicker()
                self.showDatePicker()
                self.categoriesPickerView.reloadAllComponents()
                self.tableView.reloadData()
            }
        }
        tableView.reloadData()
        self.navigationController?.isToolbarHidden = false
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        tableView.addGestureRecognizer(longPressRecognizer)
        self.categoriesPickerView.reloadAllComponents()
        filterBarButtonItem = UIBarButtonItem(image: filter_off, style: .done, target: self, action: #selector(filter))
        //self.navigationItem.rightBarButtonItem  = filterBarButtonItem
        toolbarButtons.append(filterBarButtonItem)
        toolbarButtons.append(flexSpace)
        toolbarButtons.append(UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addBudgetExpense)))
        self.toolbarItems = toolbarButtons
        searchbar.delegate = self
        searchbar.returnKeyType = UIReturnKeyType.done
        searchbar.placeholder = "Søg efter en udgift"
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! Cell
        if (indexPath.section == 0) {
            if(indexPath.row == 0){
                cell.title.text = "Brugt:"
                cell.amount.text = "\(self.subBudget.getMoneySpent())"
            }
        }
        else if(indexPath.section == 1){
            if(subBudgetExpenses[0].getExpenseName() == "Ingen udgifter i denne kategori"){
                cell.title.text = subBudgetExpenses[indexPath.row].getExpenseName()
                cell.amount.text = ""
                cell.last.text = ""
            }
            else{
                if(isSearching == true){
                    cell.title.text = filteredExpenses[indexPath.row].getExpenseName()
                    cell.amount.text = "\(filteredExpenses[indexPath.row].getAmount())"
                }
                else{
                    cell.title.text = subBudgetExpenses[indexPath.row].getExpenseName()
                    cell.amount.text = "\(subBudgetExpenses[indexPath.row].getAmount())"
                }
            }
        }
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        else if(section == 1){
            if isSearching == true {
                return filteredExpenses.count
            }
        }
        return self.subBudgetExpenses.count
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.text = section == 0 ? "  Kategori Detaljer" : "  Udgifter"
        label.backgroundColor = UIColor(red: 0.5451, green: 0.6157, blue: 0.7647, alpha: 1.0)
        label.textColor = UIColor.white
        return label
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var alertController = UIAlertController()
        if(indexPath.section == 1){
            alertController = isSearching ? UIAlertController(title: "Info", message: "Udgift: \(filteredExpenses[indexPath.row].getExpenseName()) \n Beløb: \(filteredExpenses[indexPath.row].getAmount()) kr. \n Dato: \(filteredExpenses[indexPath.row].getDate())", preferredStyle: .alert) : UIAlertController(title: "Info", message: "Udgift: \(subBudgetExpenses[indexPath.row].getExpenseName()) \n Beløb: \(subBudgetExpenses[indexPath.row].getAmount()) kr. \n Dato: \(subBudgetExpenses[indexPath.row].getDate())", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(defaultAction)
            self.present(alertController, animated: true, completion: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if(indexPath.section == 1){
            if editingStyle == .delete {
                let currentKey = isSearching ? self.filteredExpenses[indexPath.row].getKeyID() : self.subBudgetExpenses[indexPath.row].getKeyID()
                let amount = isSearching ? self.filteredExpenses[indexPath.row].getAmount() : self.subBudgetExpenses[indexPath.row].getAmount()
                let updatedSpent = self.subBudget.getMoneySpent() - amount
                let deletedExpenseAmount = isSearching ? self.filteredExpenses[indexPath.row].getAmount() : self.subBudgetExpenses[indexPath.row].getAmount()
                self.db.collection("Budget/\(self.budget.getKeyID())/Expenses").document(currentKey).delete() { err in
                    if err != nil {
                        //print("Error removing document: \(err)")
                    }
                    else {
                    self.db.collection("Budget/\(self.budget.getKeyID())/SubBudgets").document(self.subBudget.getKeyID()).updateData(["Name" : self.subBudget.getSubBudgetName(), "Symbol" : self.subBudget.getSymbol(), "MoneyLeft" : self.subBudget.getMoneyLeft() + deletedExpenseAmount, "MoneySpent" : updatedSpent, "MoneyTotal" : self.subBudget.getMoneyTotal()])
                        let updatedLeftInBudget = self.budget.getMoneyLeft() + deletedExpenseAmount
                        self.db.collection("Budget").document(self.budget.getKeyID()).updateData(["Name" : self.budget.getBudgetName(), "MoneyLeft" : updatedLeftInBudget, "MoneyTotal" : self.budget.getMoneyTotal()])
                        if self.isSearching {
                            self.filteredExpenses.remove(at: indexPath.row)
                        }
                        else{
                            self.subBudgetExpenses.remove(at: indexPath.row)
                        }
                        
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                        tableView.reloadData()
                    }
                }
            }
        }
    }
    @objc func longPress(_ guesture: UILongPressGestureRecognizer) {
        if guesture.state == UIGestureRecognizer.State.began {
            let point = guesture.location(in: tableView)
            let indexPath = tableView.indexPathForRow(at: point)
            if(indexPath != nil && indexPath?.section == 1){
                currentIndex = indexPath!.row
                let editInfo = UIAlertController(title: nil, message: "Detaljer", preferredStyle: UIAlertController.Style.alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: { (action) -> Void in
                    
                })
                let saveAction = UIAlertAction(title: "Gem", style: .default, handler: { (action) -> Void in
                    if(!(editInfo.textFields![0].text?.isEmpty)! && !(editInfo.textFields![1].text?.isEmpty)! &&
                        !(editInfo.textFields![2].text?.isEmpty)! &&
                       !(editInfo.textFields![3].text?.isEmpty)!){
                        //No textfields are empty
                        let characterSetNotAllowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz,.-<>$§!#€%&/()=?`^*¨'")
                        if(!(editInfo.textFields![1].text?.isEmpty)! && editInfo.textFields![1].text?.rangeOfCharacter(from: characterSetNotAllowed) == nil){
                            //The amount textfield doesnt contain special characters
                            let changedName = editInfo.textFields![0].text
                            let changedAmount = Int(editInfo.textFields![1].text!)
                            let previousAmount = Int(self.subBudgetExpenses[(indexPath?.row)!].getAmount())
                            let amountDifference = changedAmount! - previousAmount
                            let changedDate = String(editInfo.textFields![2].text!)
                            let changedSubbudgetText = editInfo.textFields![3].text
                            let changedSubbudgetArray : [String] = changedSubbudgetText!.components(separatedBy: " ")
                            let changedSubbudgetIcon = changedSubbudgetArray[0]
                            var changedSubbudgetKeyID = ""
                            let id = self.subBudgetExpenses[indexPath!.row].getKeyID()
                            for sub in self.subBudgets{
                                if(sub.getSymbol() == changedSubbudgetIcon){
                                    changedSubbudgetKeyID = sub.getKeyID()
                                }
                            }
                            self.db.collection("Budget/\(self.budget.getKeyID())/Expenses").document(id).updateData(["Name" : changedName!, "Amount" : changedAmount!, "Date": changedDate, "SubBudgetKeyID" : changedSubbudgetKeyID])
                            let updatedSpent = self.subBudget.getMoneySpent() + amountDifference
                            
                            self.db.collection("Budget/\(self.budget.getKeyID())/SubBudgets").document(self.subBudget.getKeyID()).updateData(["Name" : self.subBudget.getSubBudgetName(), "Symbol" : self.subBudget.getSymbol(), "MoneyLeft" : self.subBudget.getMoneyTotal() - updatedSpent, "MoneySpent" : updatedSpent, "MoneyTotal" : self.subBudget.getMoneyTotal()])
                            
                            let updatedLeft = self.budget.getMoneyLeft() - amountDifference
                            
                            self.db.collection("Budget").document(self.budget.getKeyID()).updateData(["Name" : self.budget.getBudgetName(), "MoneyLeft" : updatedLeft , "MoneyTotal" : self.budget.getMoneyTotal()])
                            
                            self.tableView.reloadData()
                        }
                        else{
                            let alertController = UIAlertController(title: "Fejl", message: "Beløbet må kun indeholde tal!", preferredStyle: .alert)
                            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alertController.addAction(defaultAction)
                            self.present(alertController, animated: true, completion: nil)
                        }
                    }
                    else{
                        let alertController = UIAlertController(title: "Fejl", message: "Udfyld venligst alle felter!", preferredStyle: .alert)
                        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(defaultAction)
                        self.present(alertController, animated: true, completion: nil)
                    }
                })
                
                editInfo.addTextField { (textField0) in
                    textField0.text = self.isSearching ? String(self.filteredExpenses[(indexPath?.row)!].getExpenseName()) : String(self.subBudgetExpenses[(indexPath?.row)!].getExpenseName())
                    textField0.autocapitalizationType = .sentences
                }
                editInfo.addTextField { (textField1) in
                    textField1.text = self.isSearching ? String(self.filteredExpenses[(indexPath?.row)!].getAmount()) : String(self.subBudgetExpenses[(indexPath?.row)!].getAmount())
                    textField1.keyboardType = .numberPad
                }
                editInfo.addTextField { (textField2) in
                    textField2.text = self.isSearching ? String(self.filteredExpenses[(indexPath?.row)!].getDate()) : String(self.subBudgetExpenses[(indexPath?.row)!].getDate())
                    textField2.inputView = self.datePicker
                    self.dateTextfield = textField2
                    let toolbar = UIToolbar()
                    toolbar.sizeToFit()
                    let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(SubBudgetsViewController.donedatePicker))
                    let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
                    let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(SubBudgetsViewController.cancelDatePicker))
                    toolbar.setItems([cancelButton,spaceButton,doneButton], animated: false)
                    textField2.inputAccessoryView = toolbar
                }
                editInfo.addTextField { (textField3) in
                    var index = 0
                    if(self.isSearching == true){
                        for item in self.subBudgets{
                            if(item.getKeyID() == self.filteredExpenses[self.currentIndex].getSubBudgetKeyID()){
                                index = self.subBudgets.firstIndex(where: {$0.getSubBudgetName() == item.getSubBudgetName()})!
                            }
                        }
                    }
                    else{
                        for item in self.subBudgets{
                            if(item.getKeyID() == self.subBudgetExpenses[self.currentIndex].getSubBudgetKeyID()){
                                index = self.subBudgets.firstIndex(where: {$0.getSubBudgetName() == item.getSubBudgetName()})!
                            }
                        }
                    }
                    
                    textField3.text = "\(self.subBudgets[index].getSymbol()) \(self.subBudgets[index].getSubBudgetName())"
                    textField3.inputView = self.categoriesPickerView
                    textField3.inputAccessoryView = self.categoriesToolBar
                    self.categoriesTextfield = textField3
                    self.categoriesPickerView.selectRow(index, inComponent: 0, animated: true )
                }
                
                editInfo.addAction(cancelAction)
                editInfo.addAction(saveAction)
                self.present(editInfo, animated: true, completion: nil)
            }
            else{
                let alertController = UIAlertController(title: "Fejl", message: "Du har ikke valgt en udgift!", preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    func showCategoriesPicker(){
        self.categoriesToolBar.layer.position = CGPoint(x: self.view.frame.width/2, y: self.view.frame.height-20.0)
        self.categoriesToolBar.setItems([self.categoriesCancelButton, self.flexSpace,self.categoriesDoneButton], animated: true)
    }
    @objc func subDonePressed(sender: UIBarButtonItem) {
        categoriesTextfield.text = "\(subBudgets[currentIndex].getSymbol()) \(subBudgets[currentIndex].getSubBudgetName())"
        categoriesTextfield.resignFirstResponder()
    }
    
    @objc func subTappedToolBarBtn(sender: UIBarButtonItem) {
        categoriesTextfield.resignFirstResponder()
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return subBudgets.count
    }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 350, height: 30))
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 30))
            label.text = "\(self.subBudgets[row].getSymbol()) \(self.subBudgets[row].getSubBudgetName())"
            label.textAlignment = .center
            label.textColor = UIColor.black
            label.font = UIFont(name: "Avenir-Book", size: 20)
            view.addSubview(label)
            return view
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if(pickerView.tag == 1){
            currentIndex = row
        }
    }
    @objc func filter(){
        let optionMenu = UIAlertController(title: nil, message: "Filtrer efter", preferredStyle: .actionSheet)
        
        let dateFilter = UIAlertAction(title: "Dato", style: .default, handler: { (action) -> Void in
            self.isSearching = true
            self.filteredExpenses.sort {$0.getDate() < $1.getDate()}
            self.filterBarButtonItem.image = self.filter_on
        })
        
        let amountFilter = UIAlertAction(title: "Beløb", style: .default, handler: { (action) -> Void in
            self.isSearching = true
            self.filteredExpenses.sort {$0.getAmount() < $1.getAmount()}
            self.filterBarButtonItem.image = self.filter_on
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(action) -> Void in
            self.isSearching = false
            self.subBudgetExpenses.sort {$0.getExpenseName() < $1.getExpenseName()}
            self.filterBarButtonItem.image = self.filter_off
        })
        optionMenu.addAction(dateFilter)
        optionMenu.addAction(amountFilter)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }
    @objc func datePickerValueChanged(sender:UIDatePicker){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        dateTextfield.text = dateFormatter.string(from: sender.date)
    }
    func showDatePicker(){
        //Formate Date
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "da_DK")
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        dateTextfield.text = formatter.string(from: self.datePicker.date)
    }
    @objc func donedatePicker(){
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        dateTextfield.text = formatter.string(from: datePicker.date)
        dateTextfield.resignFirstResponder()
    }
    
    @objc func cancelDatePicker(){
        dateTextfield.resignFirstResponder()
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if(searchBar.text == nil || searchBar.text == ""){
            isSearching = false
            view.endEditing(true)
            tableView.reloadData()
        }
        else{
            isSearching = true
            filteredExpenses = subBudgetExpenses.filter({$0.getExpenseName().lowercased().contains(searchBar.text!.lowercased())})
            tableView.reloadData()
        }
    }
    @objc func addBudgetExpense(){
        let alertController = UIAlertController(title: "Tilføj Udgift", message: "", preferredStyle: UIAlertController.Style.alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {
            (action : UIAlertAction!) -> Void in })
        let saveAction = UIAlertAction(title: "Tilføj", style: UIAlertAction.Style.default, handler: { alert -> Void in
            let characterSetNotAllowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz,.-<>$§!#€%&/()=?`^*¨'")
            if(!(alertController.textFields![0].text?.isEmpty)! && !(alertController.textFields![1].text?.isEmpty)! &&
                !(alertController.textFields![2].text?.isEmpty)! && alertController.textFields![1].text?.rangeOfCharacter(from: characterSetNotAllowed) == nil){
                let expenseSubBudgetKeyID = self.subBudget.getKeyID()
                let expenseAmount = Int(alertController.textFields![1].text!)!
                self.ref = self.db.collection("Budget/\(self.budget.getKeyID())/Expenses").addDocument(data: [
                    "Name": alertController.textFields![0].text!,
                    "Amount": Int(alertController.textFields![1].text!)!,
                    "Date": self.dateTextfield.text!,
                    "SubBudgetKeyID": expenseSubBudgetKeyID
                    ])
                
                let updatedSpent = self.subBudget.getMoneySpent() + expenseAmount
                
                self.db.collection("Budget/\(self.budget.getKeyID())/SubBudgets").document(self.subBudget.getKeyID()).updateData(["Name" : self.subBudget.getSubBudgetName(), "Symbol" : self.subBudget.getSymbol(), "MoneyLeft" : self.subBudget.getMoneyTotal() - updatedSpent, "MoneySpent" : updatedSpent, "MoneyTotal" : self.subBudget.getMoneyTotal()])
                
                let updatedLeft = self.budget.getMoneyLeft() - expenseAmount
                
                self.db.collection("Budget").document(self.budget.getKeyID()).updateData(["Name" : self.budget.getBudgetName(), "MoneyLeft" : updatedLeft, "MoneyTotal" : self.budget.getMoneyTotal()])
                { err in
                    if err != nil {
                        //print("Error adding document: \(err)")
                    } else {
                        //print("Document added with ID: \(self.ref!.documentID)")
                        self.subBudgetExpenses.sort {$0.getExpenseName() < $1.getExpenseName()}
                        self.tableView.reloadData()
                    }
                }
            }
            else{
                print("Fejl")
            }
        })
        alertController.addTextField { (textField0) in
            textField0.placeholder = "Titel"
            textField0.autocapitalizationType = .sentences
        }
        alertController.addTextField { (textField1) in
            textField1.placeholder = "Beløb"
            textField1.keyboardType = .numberPad
        }
        alertController.addTextField { (textField2) in
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            textField2.text = formatter.string(from: self.datePicker.date)
            textField2.inputView = self.datePicker
            self.dateTextfield = textField2
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(SubBudgetsViewController.donedatePicker))
            let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
            let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(SubBudgetsViewController.cancelDatePicker))
            toolbar.setItems([cancelButton,spaceButton,doneButton], animated: false)
            textField2.inputAccessoryView = toolbar
        }
        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}
