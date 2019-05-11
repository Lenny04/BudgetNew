//
//  BudgetNewTests.swift
//  BudgetNewTests
//
//  Created by linoj ravindran on 27/12/2018.
//  Copyright © 2018 linoj ravindran. All rights reserved.
//

import XCTest
import Firebase
import FirebaseDatabase
import FirebaseFirestore
@testable import BudgetNew

class BudgetNewTests: XCTestCase {
    var ref: DocumentReference!
    var db = Firestore.firestore()
    var currentKey = ""
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    func testAddExpense() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        var result = false
        self.ref = self.db.collection("Budget/ycnFyYE4zoBGwmlHIqCy/Expenses").addDocument(data: [
            "Name": "Test",
            "Amount": 0,
            "Date": "01/01/2018",
            "SubBudgetKeyID": "1234"
            ])
        print("Method: \(result)")
//        self.db.collection("Budget/ycnFyYE4zoBGwmlHIqCy/Expenses").document("TestID").setData(["Name": "Test",
//                                                                                                  "Amount": 0,
//                                                                                                  "Date": "01/01/2018",
//                                                                                                  "SubBudgetKeyID": "1234"])
        
        let docRef = db.collection("Budget/ycnFyYE4zoBGwmlHIqCy/Expenses").whereField("SubBudgetKeyID", isEqualTo: "1234").addSnapshotListener { (querySnapshot, err) in
            if err != nil {
                //print("Error getting documents: \(err)")
            }
            else {
                result = true
                print("Result: \(result)")
                querySnapshot?.documentChanges.forEach { diff in
                    print("ID: \(diff.document.documentID)")
                    self.currentKey = diff.document.documentID
                }
            }
        }
        
//        let docRef = db.collection("Budget/ycnFyYE4zoBGwmlHIqCy/Expenses").document("TestID")
//
//        docRef.getDocument { (document, error) in
//            if let document = document, document.exists {
//                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
//                print("Document data: \(dataDescription)")
//                result = true
//            } else {
//                print("Document does not exist")
//            }
//        }
        XCTAssertEqual(result, true, "Fejl i tilføjelse af udgift")
        
    }
    func testDeletionOfExpense(){
        var deletion = false
        self.db.collection("Budget/ycnFyYE4zoBGwmlHIqCy/Expenses").document("TestID").delete() { err in
            if let err = err {
                //print("Error removing document: \(err)")
            }
            else {
                deletion = true
            }
            XCTAssertEqual(deletion, true, "Fejl i sletning af udgift")
        }
    }
    func testAddSubBudget() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        self.ref = self.db.collection("Budget/ycnFyYE4zoBGwmlHIqCy/SubBudgets").addDocument(data: [
            "Name": "SubBudget",
            "MoneyTotal": 0,
            "MoneyLeft": 0,
            "MoneySpent": 0,
            "Symbol": "Symbol"
            ])
    }

}
