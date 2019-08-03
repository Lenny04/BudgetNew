//
//  ViewController.swift
//  BudgetNew
//
//  Created by linoj ravindran on 27/12/2018.
//  Copyright © 2018 linoj ravindran. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseFirestore
import Charts
import DropDown

class BarChartViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, ChartViewDelegate, UIViewControllerTransitioningDelegate {
    var ref: DocumentReference!
    lazy var db = Firestore.firestore()
    var quoteListenerBudget: ListenerRegistration!
    var quoteListenerSubBudget: ListenerRegistration!
    @IBOutlet var barChart: BarChartView!
    @IBOutlet var moneyLeftLabel: UILabel!
    @IBOutlet var moneyLeftLabelText: UILabel!
    var budget = Budget(budgetName: "", keyID: "", moneyLeft: 0, moneyTotal: 0)
    var subBudgets = [SubBudget](), barChartList = [BarChartDataEntry](), expenses = [Expense]()
    var subBudgetPickerView = UIPickerView(), datePickerView = UIDatePicker()
    var pickOption = ["Husleje", "Hobby", "Fest", "Shopping", "Mad", "Ny kategori"]
    var symbols = ["\u{1F3E0}", "\u{26BD}", "\u{1F37B}", "\u{1F6CD}", "\u{1F956}", "\u{2795}"]
    var subBudgetToolBar = UIToolbar(), dateToolBar = UIToolbar(), subBudgetTextfield = UITextField(), dateTextfield = UITextField()
    var subCancelButton = UIBarButtonItem(), subDoneButton = UIBarButtonItem(), dateCancelButton = UIBarButtonItem()
    var dateDoneButton = UIBarButtonItem(), flexSpace = UIBarButtonItem()
    var selectedSubBudget = "", dropDownList = DropDown()
    let dropdownArrow = UIImage(named: "DropdownSymbol_20px")
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (self.isMovingFromParent) {
            UIDevice.current.setValue(Int(UIInterfaceOrientation.portrait.rawValue), forKey: "orientation")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.isToolbarHidden = true
        //self.updateChart()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        canRotate()
        barChart.chartDescription?.enabled = false
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        barChart.delegate = self
        barChart.legend.form = .none
        barChart.legend.font = UIFont(name: "HelveticaNeue-Light", size: 20.0)!
        barChart.legend.yOffset = 30
        barChart.doubleTapToZoomEnabled = false
        barChart.pinchZoomEnabled = true
        subBudgetPickerView.delegate = self
        subBudgetPickerView.dataSource = self
        subBudgetPickerView.tag = 1
        datePickerView.tag = 2
        datePickerView.datePickerMode = .date
        datePickerView.addTarget(self, action: #selector(BarChartViewController.datePickerValueChanged), for: UIControl.Event.valueChanged)
        subBudgetToolBar = UIToolbar(frame: CGRect(x: 0, y: 40, width: self.view.frame.width, height: self.view.frame.height/15))
        subCancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(BarChartViewController.subTappedToolBarBtn))
        subDoneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(BarChartViewController.subDonePressed))
        dateToolBar = UIToolbar(frame: CGRect(x: 0, y: 40, width: self.view.frame.width, height: self.view.frame.height/15))
        dateCancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(BarChartViewController.dateTappedToolBarBtn))
        dateDoneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(BarChartViewController.dateDonePressed))
        flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        
        let testFrame = CGRect(x: 0, y: 0, width: 180, height: 40)
        let buttonView: UIView = UIView(frame: testFrame)
        let button1 =  UIButton(type: UIButton.ButtonType.custom) as UIButton
        button1.frame = CGRect(x: 30, y: 0, width: 120, height: 40)
        button1.setTitleColor(UIColor.black, for: UIControl.State.normal)
        button1.setTitle("April", for: UIControl.State.normal)
        button1.setImage(dropdownArrow, for: UIControl.State.normal)
        
        button1.titleEdgeInsets = UIEdgeInsets(top: 0, left: -button1.imageView!.frame.size.width, bottom: 0, right: button1.imageView!.frame.size.width)
        button1.imageEdgeInsets = UIEdgeInsets(top: 0, left: button1.titleLabel!.frame.size.width+5, bottom: 0, right: -button1.titleLabel!.frame.size.width)
        
        button1.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        buttonView.addSubview(button1)
        self.navigationItem.titleView = buttonView
        dropDownList.anchorView = buttonView
        dropDownList.dataSource = ["Januar", "Februar", "Marts", "April", "Maj", "Juni", "Juli", "August", "September", "Oktober", "November", "December"]
        dropDownList.direction = .bottom
        dropDownList.bottomOffset = CGPoint(x: 40, y:(dropDownList.anchorView?.plainView.bounds.height)!)
        dropDownList.selectionAction = { [unowned self] (index: Int, item: String) in
            //print("Selected item: \(item) at index: \(index)")
            button1.setTitle("\(item)", for: UIControl.State.normal)
            button1.titleEdgeInsets = UIEdgeInsets(top: 0, left: -button1.imageView!.frame.size.width, bottom: 0, right: button1.imageView!.frame.size.width)
            button1.imageEdgeInsets = UIEdgeInsets(top: 0, left: button1.titleLabel!.frame.size.width+5, bottom: 0, right: -button1.titleLabel!.frame.size.width)
        }
        dropDownList.selectRow(3)
        DropDown.appearance().cornerRadius = 10
        dropDownList.offsetFromWindowBottom = 360
        dropDownList.width = 100
        quoteListenerBudget = db.collection("Budget/").addSnapshotListener { (querySnapshot, err) in
            if err != nil {
                //print("Error getting documents: \(err)")
            }
            else if(querySnapshot?.documents == []){
                let alert = UIAlertController(title: "Nyt budget", message: "Da du ikke har et budget, skal du lave et nyt!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Opret", style: .default, handler: { action in
                    self.ref = self.db.collection("Budget").addDocument(data: [
                        "Name": alert.textFields![0].text!,
                        "MoneyLeft": Int(alert.textFields![1].text!)!,
                        "MoneyTotal": Int(alert.textFields![1].text!)!
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
                    textField.placeholder = "Budget navn"
                    textField.autocapitalizationType = .sentences
                })
                alert.addTextField(configurationHandler: { textField1 in
                    textField1.placeholder = "Beløb"
                    textField1.keyboardType = UIKeyboardType.numberPad
                })
                self.present(alert, animated: true)
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
                                //print("Name: \(value as! String)")
                                self.budget.setBudgetName(a: value as! String)
                                break
                            case "MoneyLeft":
                                //print("MoneyLeft: \(value as! Int)")
                                self.budget.setMoneyLeft(e: value as! Int)
                                break
                            case "MoneyTotal":
                                //print("MoneyTotal: \(value as! Int)")
                                self.budget.setMoneyTotal(f: value as! Int)
                                break
                            default:
                                self.updateChart()
                                break
                            }
                        }
                        //self.generatePieChart()
                        // GET SUBBUDGET
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
                        self.subBudgets.sort {$0.getSubBudgetName() < $1.getSubBudgetName()}
                        self.updateChart()
                    }
                    if(diff.type == .removed){
                        //print("Removed")
                        self.updateChart()
                    }
                }
            }
            self.updateChart()
            self.quoteListenerSubBudget = self.db.collection("Budget/\(self.budget.getKeyID())/SubBudgets").addSnapshotListener { (querySnapshot, err) in
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
                        textField2.text = "\(self.symbols[0]) \(self.pickOption[0])"
                        textField2.inputView = self.subBudgetPickerView
                        self.subBudgetToolBar.layer.position = CGPoint(x: self.view.frame.width/2, y: self.view.frame.height-20.0)
                        self.subBudgetTextfield = textField2
                        self.subBudgetToolBar.setItems([self.subCancelButton, self.flexSpace,self.subDoneButton], animated: true)
                        textField2.inputAccessoryView = self.subBudgetToolBar
                    }
                    self.present(alert, animated: true)
                }
                else {
                    querySnapshot?.documentChanges.forEach { diff in
                        if (diff.type == .added){
                            if(!self.subBudgets.contains(where: { $0.getKeyID() == diff.document.documentID })){
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
                                    default:
                                        self.updateChart()
                                        break
                                    }
                                }
                                self.generatePieChart()
                            }
                            //print("Document: \(self.list[self.list.count-1].getItemDescription()), added in firestore")
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
                            self.subBudgets.sort {$0.getSubBudgetName() < $1.getSubBudgetName()}
                            self.generatePieChart()
                        }
                        if(diff.type == .removed) {
                            //print("Document removed from firestore")
                            let subBudgetToRemoveIndex = self.subBudgets.index(where: { $0.getKeyID() == diff.document.documentID })
                            if(subBudgetToRemoveIndex != nil){
                                self.subBudgets.remove(at: subBudgetToRemoveIndex!)
                                self.generatePieChart()
                            }
                        }
                    }
                }
            }
            self.navigationController?.isToolbarHidden = true
        }
        // Do any additional setup after loading the view, typically from a nib.
    }
    func generatePieChart(){
        barChartList = [BarChartDataEntry]()
        for index in 0..<self.subBudgets.count {
            let udgift = BarChartDataEntry(x: Double(index), y: Double(subBudgets[index].getMoneySpent()))
            
            
            barChartList.append(udgift)
        }
        updateChart()
    }
    func updateChart(){
        barChart.noDataText = "Har brug for data"
        let chartDataSet = BarChartDataSet(entries: barChartList, label: nil)
        let chartData = BarChartData(dataSet: chartDataSet)
        barChart.data = chartData
        chartDataSet.colors = ChartColorTemplates.colorful()
        barChart.xAxis.labelPosition = .bottom
        barChart.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        let xaxis = barChart.xAxis
        xaxis.drawGridLinesEnabled = false
        xaxis.granularity = 1
        //xaxis.valueFormatter = IndexAxisValueFormatter(values: ["\u{1F3E0}", "\u{26BD}", "\u{1F37B}", "\u{1F6CD}", "\u{1F956}", "\u{2795}"])
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickOption.count
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        subBudgetTextfield.text = "\(symbols[row]) \(pickOption[row])"
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(symbols[row]) \(pickOption[row])"
    }
    @objc func subDonePressed(sender: UIBarButtonItem) {
        subBudgetTextfield.resignFirstResponder()
    }
    
    @objc func subTappedToolBarBtn(sender: UIBarButtonItem) {
        subBudgetTextfield.resignFirstResponder()
    }
    @objc func dateDonePressed(sender: UIBarButtonItem) {
        dateTextfield.resignFirstResponder()
    }
    
    @objc func dateTappedToolBarBtn(sender: UIBarButtonItem) {
        dateTextfield.resignFirstResponder()
    }
    @objc func datePickerValueChanged(sender:UIDatePicker){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        dateTextfield.text = dateFormatter.string(from: sender.date)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "tilføjUdgift") {
            if let destinationVC = segue.destination as? TilføjUdgiftViewcontroller{
                destinationVC.budget = budget
            }
        }
        if(segue.identifier == "subBudget"){
            if let destinationVC = segue.destination as? SubBudgetsViewController{
                let subBudgetToSegue = subBudgets.first(where: { $0.getKeyID() == selectedSubBudget })
                destinationVC.subBudget = subBudgetToSegue!
                destinationVC.budget = budget
                destinationVC.subBudgets = subBudgets
                destinationVC.navigationItem.title = "\(subBudgetToSegue!.getSymbol())  \(subBudgetToSegue!.getSubBudgetName())"
            }
        }
        if(segue.identifier == "allSubBudgets"){
            if let destinationVC = segue.destination as? AllSubBudgetsViewController{
                destinationVC.navigationItem.title = "Budget"
                destinationVC.budget = budget
                
            }
        }
    }
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        selectedSubBudget = subBudgets[Int(highlight.x)].getKeyID()
        performSegue(withIdentifier: "subBudget", sender: self)
    }
    @objc func buttonAction(){
        dropDownList.show()
    }
    @objc func canRotate() -> Void {}
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        barChart.autoresizingMask = UIView.AutoresizingMask(rawValue: UIView.AutoresizingMask.RawValue(UInt8(UIView.AutoresizingMask.flexibleWidth.rawValue) | UInt8(UIView.AutoresizingMask.flexibleHeight.rawValue)))
    }
}
