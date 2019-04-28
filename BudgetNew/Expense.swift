//
//  Expense.swift
//  BudgetNew
//
//  Created by linoj ravindran on 28/12/2018.
//  Copyright © 2018 linoj ravindran. All rights reserved.
//

import UIKit

class Expense {
    var expenseName = "", keyID = "", date = "", subBudget = ""
    var amount = 0
    init(expenseName: String, keyID: String, amount: Int, date: String, subBudget: String)
    {
        self.expenseName = expenseName
        self.keyID = keyID
        self.amount = amount
        self.date = date
        self.subBudget = subBudget
    }
    public func getExpenseName() -> String {
        return expenseName
    }
    public func setExpenseName(a: String){
        expenseName = a
    }
    public func getKeyID() -> String {
        return keyID
    }
    public func setKeyID(c: String){
        keyID = c
    }
    public func getAmount() -> Int {
        return amount
    }
    public func setAmount(d: Int){
        amount = d
    }
    public func getDate() -> String {
        return date
    }
    public func setDate(b: String){
        date = b
    }
    public func getSubBudgetKeyID() -> String {
        return subBudget
    }
    public func setSubBudgetKeyID(e: String){
        subBudget = e
    }
}
