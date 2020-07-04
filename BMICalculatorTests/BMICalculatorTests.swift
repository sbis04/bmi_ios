//
//  BMICalculatorTests.swift
//  BMICalculatorTests
//
//  Created by Souvik Biswas on 03/07/20.
//  Copyright © 2020 Souvik Biswas. All rights reserved.
//

import XCTest
@testable import BMI_Calculator


class BMICalculatorTests: XCTestCase {
    var sut: CalculatorBrain!
    
    override func setUp() {
        super.setUp()
        sut = CalculatorBrain()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testBMIClculatorInitialResults() {
        let bmiValue = sut.getBMIValue()
        let advice = sut.getAdvice()
        let color = sut.getColor()
        
        XCTAssertEqual(bmiValue, "0.0", "Correct initial BMI value")
        XCTAssertEqual(advice, "No advice", "Correct initial advice")
        XCTAssertEqual(color, UIColor.white, "Correct initial color")
    }
    
    func testBMICalculatorFitResults() {
        sut.calculateBMI(65, 1.62)
        let bmiValue = sut.getBMIValue()
        let advice = sut.getAdvice()
        let color = sut.getColor()
        
        XCTAssertEqual(bmiValue, "24.8", "Correct fit BMI value")
        XCTAssertEqual(advice, "Fit as a fiddle!", "Correct fit advice")
        XCTAssertEqual(color, #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1), "Correct fit color")
        
    }
    
    func testBMICalculatorEatMoreResults() {
        sut.calculateBMI(40, 1.50)
        let bmiValue = sut.getBMIValue()
        let advice = sut.getAdvice()
        let color = sut.getColor()
        
        XCTAssertEqual(bmiValue, "17.8", "Correct eat more BMI value")
        XCTAssertEqual(advice, "Eat more pies!", "Correct eat more advice")
        XCTAssertEqual(color, #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1), "Correct eat more color")
        
    }
    
    func testBMICalculatorEatLessResults() {
        sut.calculateBMI(100, 1.50)
        let bmiValue = sut.getBMIValue()
        let advice = sut.getAdvice()
        let color = sut.getColor()
        
        XCTAssertEqual(bmiValue, "44.4", "Correct eat less BMI value")
        XCTAssertEqual(advice, "Eat less pies!", "Correct eat less advice")
        XCTAssertEqual(color, #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1), "Correct eat less color")
        
    }

}
