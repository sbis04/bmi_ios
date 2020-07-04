//
//  BMICalculatorUITests.swift
//  BMICalculatorUITests
//
//  Created by Souvik Biswas on 04/07/20.
//  Copyright © 2020 Souvik Biswas. All rights reserved.
//

import XCTest

class BMICalculatorUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        app = XCUIApplication()
        app.activate()
    }

    func testCalculatorButtons() {
        let calculateButton = app.buttons["CALCULATE"]
        let recalculateButton = app.buttons["RECALCULATE"]
        
        let heightLabel = app.staticTexts["1.5m"]
        let weightLabel = app.staticTexts["100Kg"]
        let bmiLabel = app.staticTexts["44.4"]
        
        calculateButton.tap()
        
        if calculateButton.isSelected {
            XCTAssertTrue(heightLabel.exists)
            XCTAssertFalse(weightLabel.exists)
        
            calculateButton.tap()
            
            XCTAssertTrue(bmiLabel.exists)
            
        } else if recalculateButton.isSelected {
            XCTAssertTrue(bmiLabel.exists)

            recalculateButton.tap()
            XCTAssertTrue(heightLabel.exists)
            XCTAssertFalse(weightLabel.exists)
        }
        
    }
    
}
