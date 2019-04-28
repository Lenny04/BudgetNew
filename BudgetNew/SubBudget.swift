//
//  SubBudget.swift
//  BudgetNew
//
//  Created by linoj ravindran on 28/12/2018.
//  Copyright © 2018 linoj ravindran. All rights reserved.
//

import UIKit

class SubBudget {
    var subBudgetName = "", keyID = "", symbol = ""
    var moneyLeft = 0, moneyTotal = 0, moneySpent = 0
    init(subBudgetName: String, keyID: String, symbol: String, moneyLeft: Int, moneySpent: Int, moneyTotal: Int)
    {
        self.subBudgetName = subBudgetName
        self.keyID = keyID
        self.symbol = symbol
        self.moneyLeft = moneyLeft
        self.moneySpent = moneySpent
        self.moneyTotal = moneyTotal
    }
    public func getSubBudgetName() -> String {
        return subBudgetName
    }
    public func setSubBudgetName(a: String){
        subBudgetName = a
    }
    public func getKeyID() -> String {
        return keyID
    }
    public func setKeyID(b: String){
        keyID = b
    }
    public func getSymbol() -> String {
        return symbol
    }
    public func setSymbol(c: String){
        symbol = c
    }
    public func getMoneyLeft() -> Int {
        return moneyLeft
    }
    public func setMoneyLeft(d: Int){
        moneyLeft = d
    }
    public func getMoneySpent() -> Int {
        return moneySpent
    }
    public func setMoneySpent(e: Int){
        moneySpent = e
    }
    public func getMoneyTotal() -> Int {
        return moneyTotal
    }
    public func setMoneyTotal(f: Int){
        moneyTotal = f
    }
}
