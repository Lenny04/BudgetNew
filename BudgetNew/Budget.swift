//
//  Budget.swift
//  BudgetNew
//
//  Created by linoj ravindran on 28/12/2018.
//  Copyright © 2018 linoj ravindran. All rights reserved.
//

import UIKit

class Budget {
    var budgetName = "", keyID = ""
    var moneyLeft = 0, moneyTotal = 0
    init(budgetName: String, keyID: String, moneyLeft: Int, moneyTotal: Int)
    {
        self.budgetName = budgetName
        self.keyID = keyID
        self.moneyLeft = moneyLeft
        self.moneyTotal = moneyTotal
    }
    public func getBudgetName() -> String {
        return budgetName
    }
    public func setBudgetName(a: String){
        budgetName = a
    }
    public func getKeyID() -> String {
        return keyID
    }
    public func setKeyID(c: String){
        keyID = c
    }
    public func getMoneyLeft() -> Int {
        return moneyLeft
    }
    public func setMoneyLeft(e: Int){
        moneyLeft = e
    }
    public func getMoneyTotal() -> Int {
        return moneyTotal
    }
    public func setMoneyTotal(f: Int){
        moneyTotal = f
    }
}
