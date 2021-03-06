//
//  DisplayDeedsViewControllerTests.swift
//  Good Deed CounterTests
//
//  Created by Mary Paskhaver on 7/19/20.
//  Copyright © 2020 Nostaw. All rights reserved.
//

import XCTest
import CoreData

@testable import Deedy

class DisplayDeedsViewControllerTests: XCTestCase {
    var ddvc: DisplayDeedsViewController!
    var advc: AddDeedViewController!
    
    let dateHandler = DateHandler()
    
    lazy var managedObjectModel: NSManagedObjectModel = MockDataModelObjects().managedObjectModel
    lazy var mockPersistentContainer: NSPersistentContainer = MockDataModelObjects().persistentContainer
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        ddvc = MockDataModelObjects().createDisplayDeedsViewController()
        
        advc = storyboard.instantiateViewController(identifier: "AddDeedViewController") as? AddDeedViewController
        advc.loadViewIfNeeded()

        initDeedStubs()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        ddvc.dataSource = nil
        ddvc = nil
        advc = nil
        flushDeedData()
    }
    
    // MARK: - Needed funcs
    func addDeed(withTitle title: String, date: Date) {
        let deed = ddvc.dataSource.cdm.insertDeed(title: title, date: date)
        ddvc.dataSource.deeds.append(deed!)
        ddvc.dataSource.saveDeeds()

        // Split deeds into proper sections
        ddvc.updateSections()
    }
    
    func initDeedStubs() {
        // Put fake items in the "database"
        addDeed(withTitle: "A", date: dateHandler.currentDate() as Date)
        addDeed(withTitle: "B", date: dateHandler.currentDate() as Date)
        addDeed(withTitle: "C", date: dateHandler.currentDate() as Date)
        addDeed(withTitle: "D", date: dateHandler.currentDate() as Date)
        addDeed(withTitle: "E", date: dateHandler.currentDate() as Date)
    }
    
    func flushDeedData() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Deed")
        
        let objs = try! mockPersistentContainer.viewContext.fetch(fetchRequest)

        for case let obj as NSManagedObject in objs {
            mockPersistentContainer.viewContext.delete(obj)
        }
        
        try! mockPersistentContainer.viewContext.save()
    }
    
    // MARK: - Tests for ViewController
    func testSectionDeedsEqualToVCDeeds() {
        let calendar = Calendar.current

        var sumDeeds = 0

        let today = dateHandler.currentDate() as Date
        addDeed(withTitle: "A", date: today)
        
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)
        addDeed(withTitle: "B", date: tomorrow!)
        addDeed(withTitle: "C", date: tomorrow!)

        for section in ddvc.dataSource.sections {
            sumDeeds += section.deeds.count
        }

        XCTAssertEqual(ddvc.dataSource.deeds.count, sumDeeds)
    }

    func testDeedLabelUpdates() {
        XCTAssert(ddvc.totalDeedsLabel != nil)
        XCTAssert(ddvc.totalDeedsLabel.text != nil)
        
        XCTAssertEqual(ddvc.totalDeedsLabel.text, String(5))

        addDeed(withTitle: "A", date: dateHandler.currentDate() as Date)
        ddvc.updateSections()
        
        XCTAssertEqual(ddvc.totalDeedsLabel.text, String(6))
    }
    
    func testIfDeedsDisplayInTableView() {
        let calendar = Calendar.current

        let today = dateHandler.currentDate() as Date
        addDeed(withTitle: "A", date: today)
        
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)
        addDeed(withTitle: "B", date: tomorrow!)
        addDeed(withTitle: "C", date: tomorrow!)

        if !ddvc.dataSource.deeds.isEmpty {
            XCTAssertTrue(ddvc.dataSource.sections.count > 0)
        }
        
        ddvc.tableView.reloadData()

        for (sectionIndex, section) in ddvc.dataSource.sections.enumerated() {
            for (deedIndex, deed) in section.deeds.enumerated() {
                let indexPath = IndexPath(row: deedIndex, section: sectionIndex)
                let cell: DeedTableViewCell = ddvc.tableView.cellForRow(at: indexPath) as! DeedTableViewCell
                
                XCTAssertTrue(cell.deedDescriptionLabel.text == deed.title)
            }
        }
    }
    
    func testSearchBarSetsDataSourceDeeds() {
        // In initDeedStubs, a deed with the title "A" was created. Now I make 2 deeds with "a" or "A" in their titles.
        addDeed(withTitle: "abacadae", date: dateHandler.currentDate() as Date)
        addDeed(withTitle: "bbbbAAA", date: dateHandler.currentDate() as Date)

        let searchBar = UISearchBar()
        searchBar.text = "A"
        ddvc.searchBarSearchButtonClicked(searchBar)
        
        // From the initDeedStubs method and my call to addDeed above, there should be 3 deeds with "A" or "a" in their titles that show/are in ddvc.dataSource.deeds.
        XCTAssert(ddvc.dataSource.deeds.count == 3)
        
        for deed in ddvc.dataSource.deeds {
            let text: String = searchBar.text!
            
            let deedContainsSearchBarTextLowercased = deed.title!.contains(text.lowercased())
            let deedContainsSearchBarTextUppercased = deed.title!.contains(text.uppercased())

            XCTAssert(deedContainsSearchBarTextLowercased || deedContainsSearchBarTextUppercased)
        }
        
        searchBar.text = "Aa"
        ddvc.searchBarSearchButtonClicked(searchBar)
        XCTAssert(ddvc.dataSource.deeds.count == 1)
        
        for deed in ddvc.dataSource.deeds {
            let text: String = searchBar.text!
            
            let deedContainsSearchBarTextLowercased = deed.title!.contains(text.lowercased())
            let deedContainsSearchBarTextUppercased = deed.title!.contains(text.uppercased())

            XCTAssert(deedContainsSearchBarTextLowercased || deedContainsSearchBarTextUppercased)
        }
    }
    
    func testSearchBarCancelReloadsOriginalDeeds() {
        // In initDeedStubs, a deed with the title "A" was created. Now I make 2 deeds with "a" or "A" in their titles.
        addDeed(withTitle: "abacadae", date: dateHandler.currentDate() as Date)
        addDeed(withTitle: "bbbbAAA", date: dateHandler.currentDate() as Date)

        let searchBar = UISearchBar()
        searchBar.text = "A"
        ddvc.searchBarSearchButtonClicked(searchBar)
              
        // From the initDeedStubs method and my call to addDeed above, there should be 3 deeds with "A" or "a" in their titles that show/are in ddvc.dataSource.deeds.
        XCTAssert(ddvc.dataSource.deeds.count == 3)
              
        for deed in ddvc.dataSource.deeds {
            let text: String = searchBar.text!
          
            let deedContainsSearchBarTextLowercased = deed.title!.contains(text.lowercased())
            let deedContainsSearchBarTextUppercased = deed.title!.contains(text.uppercased())

            XCTAssert(deedContainsSearchBarTextLowercased || deedContainsSearchBarTextUppercased)
        }
        
        ddvc.searchBar(UISearchBar(), textDidChange: "")
        print(ddvc.dataSource.deeds.count)
        XCTAssert(ddvc.dataSource.deeds.count == 7) // Initial amount in initDeedStubs + 2 deeds added at top of method
    }
    
    func testShowingTutorialDisablesBarButtons() {
        XCTAssertTrue(ddvc.navigationItem.leftBarButtonItem!.isEnabled)
        
        for item in ddvc.navigationItem.rightBarButtonItems! {
            XCTAssertTrue(item.isEnabled)
        }

        ddvc.showTutorial()

        XCTAssertFalse(ddvc.navigationItem.leftBarButtonItem!.isEnabled)
        
        for item in ddvc.navigationItem.rightBarButtonItems! {
            XCTAssertFalse(item.isEnabled)
        }
    }

}
