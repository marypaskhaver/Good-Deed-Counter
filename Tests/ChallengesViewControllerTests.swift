//
//  ChallengesViewControllerTests.swift
//  Good Deed CounterTests
//
//  Created by Mary Paskhaver on 7/14/20.
//  Copyright © 2020 Nostaw. All rights reserved.
//

import XCTest
import CoreData

@testable import Good_Deed_Counter

class ChallengesViewControllerTests: XCTestCase {
    var ddvc: DisplayDeedsViewController!
    var cvc: ChallengesViewController!
    
    lazy var managedObjectModel: NSManagedObjectModel = MockDataModelObjects().managedObjectModel
    lazy var mockPersistentContainer: NSPersistentContainer = MockDataModelObjects().persistentContainer
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        ddvc = MockDataModelObjects().createDisplayDeedsViewController()
        
        cvc = storyboard.instantiateViewController(identifier: "ChallengesViewController") as? ChallengesViewController
        cvc.cdm = ddvc.dataSource.cdm
        cvc.loadViewIfNeeded()
        cvc.dataSource.cdm = ddvc.dataSource.cdm
        cvc.setTotalDeedsDone()
        cvc.dataSource.loadAchievements()
        cvc.dailyGoalProgressView.cdm = ddvc.dataSource.cdm
        DeedAchievements.cdm = ddvc.dataSource.cdm
        initDeedStubs()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        ddvc.dataSource = nil
        ddvc = nil
        cvc.dataSource = nil
        cvc = nil
        flushDeedData()
    }
    
    // MARK: - Needed funcs
    func addDeed(withTitle title: String, date: Date) {
        let deed = ddvc.dataSource.cdm.insertDeed(title: title, date: date)
        ddvc.dataSource.deeds.append(deed!)
        ddvc.dataSource.saveDeeds()
        
        cvc.setTotalDeedsDone()
    }
    
    func initDeedStubs() {
        // Put fake items in the "database"
        addDeed(withTitle: "A", date: Date())
        addDeed(withTitle: "B", date: Date())
        addDeed(withTitle: "C", date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
    }
    
    func flushDataForEntity(withName name: String) {
        let fetchRequest2: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: name)
        
        let objs2 = try! mockPersistentContainer.viewContext.fetch(fetchRequest2)

        for case let obj as NSManagedObject in objs2 {
            mockPersistentContainer.viewContext.delete(obj)
        }
        
        try! mockPersistentContainer.viewContext.save()
    }
    
    func flushDeedData() {
        flushDataForEntity(withName: "Deed")
        flushDataForEntity(withName: "DailyChallenge")
        flushDataForEntity(withName: "Streak")
        flushDataForEntity(withName: "Achievement")
    }
    
    func testDailyProgressViewDailyGoalValueSame() {
        XCTAssert(cvc.dailyChallenge.dailyGoal == cvc.dailyGoalProgressView.getDailyGoalValue())
    }
    
    func testDailyGoalProgressViewGetsDeedsDoneToday() {
        XCTAssert(cvc.dailyGoalProgressView.getCountOfDeedsDoneToday() == 2)
    }
    
    func testDailyProgressViewValueUpdates() {
        cvc.stepper.value = 3
        cvc.stepperValueChanged(UIStepper()) // progressView and dailyChallenge.dailyGoal updated

        let stepperVal = cvc.stepper.value
        let progressView = cvc.dailyGoalProgressView
                
        // Deeds done today will be equal to 2, was set in initDeedStubs
        XCTAssert(progressView?.progress == Float(2 / stepperVal))
    }
    
    func testAchievementsLoaded() {
        for (achievementIndex, achievement) in cvc.dataSource.achievements.enumerated() {
            let indexPath = IndexPath(row: achievementIndex, section: 0)
            let cell: ChallengeTableViewCell = cvc.tableView.cellForRow(at: indexPath) as! ChallengeTableViewCell
            
            XCTAssertTrue(cell.challengeDescriptionLabel.text == achievement.title)
        }
    }
    
    func testTotalDeedsDoneCorrect() {
        XCTAssert(ddvc.dataSource.deeds.count == cvc.totalDeedsDone)
    }
    
    func testAchievementsProgressUpdates() {
        for (achievementIndex, achievement) in cvc.dataSource.achievements.enumerated() {
            let indexPath = IndexPath(row: achievementIndex, section: 0)
            let cell: ChallengeTableViewCell = cvc.tableView.cellForRow(at: indexPath) as! ChallengeTableViewCell

            if achievement.identifier == "deedAchievement" {
                print(cell.subtitleLabel.text)
                XCTAssertTrue(cell.subtitleLabel.text == "\(cvc.totalDeedsDone) / \(achievement.goalNumber)")
            }
        }
        
        addDeed(withTitle: "1", date: Date())
        cvc.setTotalDeedsDone()
        
        for (achievementIndex, achievement) in cvc.dataSource.achievements.enumerated() {
            let indexPath = IndexPath(row: achievementIndex, section: 0)
            let cell: ChallengeTableViewCell = cvc.tableView.cellForRow(at: indexPath) as! ChallengeTableViewCell

            if achievement.identifier == "deedAchievement" {
                print(cell.subtitleLabel.text)
                XCTAssertTrue(cell.subtitleLabel.text == "\(cvc.totalDeedsDone) / \(achievement.goalNumber)")
            }
        }
    }
    
    func testTableViewMovesBasedOnDailyChallenge() {
        let originalTableViewYPos: CGFloat = 0.263 * cvc.view.frame.height
        let amountToMoveTableViewDownBy = -0.122 * cvc.view.frame.height
        
        cvc.revealDailyGoalRelatedItemsIfNeeded()
        XCTAssert(roundToTenThousandths(num: cvc.tableView.frame.origin.y) == roundToTenThousandths(num: originalTableViewYPos))

        cvc.dailyChallenge.dailyGoal = 1
        cvc.revealDailyGoalRelatedItemsIfNeeded()
        XCTAssert(roundToTenThousandths(num: cvc.tableView.frame.origin.y) == roundToTenThousandths(num: originalTableViewYPos + amountToMoveTableViewDownBy))
    }
    
    func roundToTenThousandths(num: CGFloat) -> CGFloat {
        return CGFloat(round(10000 * (num) / 10000))
    }

}