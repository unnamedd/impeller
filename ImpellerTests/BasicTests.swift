//
//  ImpellerTests.swift
//  ImpellerTests
//
//  Created by Drew McCormack on 08/12/2016.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

import XCTest
@testable import Impeller

class BasicTests: XCTestCase {
    
    var respository: MemoryRepository!
    
    override func setUp() {
        respository = MemoryRepository()
    }
    
    func testSave() {
        var person = Person()
        person.name = "Bob"
        person.age = 10
        person.tags.append("Tag")
        
        respository.save(&person)
        
        XCTAssertEqual(person.name, "Bob")
        XCTAssertEqual(person.age, 10)
        XCTAssertEqual(person.tags, ["Tag"])
    }
    
    func testFetch() {
        var person = Person()
        person.name = "Bob"
        person.age = 10
        person.tags = ["tag"]
        
        respository.save(&person)
        
        let fetchedPerson:Person? = respository.fetchValue(identifiedBy: person.metadata.uniqueIdentifier)
        XCTAssertEqual(fetchedPerson!.name, "Bob")
        XCTAssertEqual(fetchedPerson!.age, 10)
        XCTAssertEqual(fetchedPerson!.tags, ["tag"])
    }
    
    func testUpdateBumpsVersion() {
        var person = Person()
        person.name = "Bob"
        person.age = 10
        XCTAssertEqual(person.metadata.version, 0)

        respository.save(&person)
        XCTAssertEqual(person.metadata.version, 0)
        
        person.name = "Dave"
        respository.save(&person)
        XCTAssertEqual(person.metadata.version, 1)
    }
    
    func testSaveWithNoChangeDoesNotChangeMetadata() {
        var person = Person()
        person.name = "Bob"
        person.age = 10
        respository.save(&person)
        
        let metadata = person.metadata
        respository.save(&person)
        XCTAssertEqual(metadata, person.metadata)
    }
    
    func testStoringNilProperty() {
        var person = Person()
        person.name = "Bob"
        person.age = nil
        respository.save(&person)
        
        let fetchedPerson:Person? = respository.fetchValue(identifiedBy: person.metadata.uniqueIdentifier)
        XCTAssertNil(fetchedPerson!.age)
    }
    
    func testParentWithChild() {
        var parent = Parent()
        parent.child.age = 10
        respository.save(&parent)

        let fetchedChild:Child! = respository.fetchValue(identifiedBy: parent.child.metadata.uniqueIdentifier)
        XCTAssertEqual(fetchedChild.age, 10)

        let fetchedParent:Parent! = respository.fetchValue(identifiedBy: parent.metadata.uniqueIdentifier)
        XCTAssertEqual(fetchedParent.child.age, 10)
    }
    
    func testChangingChildInrespositoryChangesFetchedParent() {
        var parent = Parent()
        parent.child.age = 10
        respository.save(&parent)
        
        var child:Child? = respository.fetchValue(identifiedBy: parent.child.metadata.uniqueIdentifier)
        child!.age = 20
        respository.save(&child!)
        
        XCTAssertEqual(parent.child.age, 10)
        XCTAssertEqual(child!.age, 20)

        let fetchedParent:Parent! = respository.fetchValue(identifiedBy: parent.metadata.uniqueIdentifier)
        XCTAssertEqual(fetchedParent.child.age, 20)
    }
    
    func testChangingChildButSavingParent() {
        var parent = Parent()
        parent.child.age = 10
        respository.save(&parent)
        XCTAssertEqual(parent.child.age, 10)

        parent.child.age = 20
        XCTAssertEqual(parent.child.age, 20)

        respository.save(&parent)
        XCTAssertEqual(parent.child.age, 20)

        let child:Child? = respository.fetchValue(identifiedBy: parent.child.metadata.uniqueIdentifier)
        XCTAssertEqual(child!.age, 20)
    }
    
    func testResolvingConflicts() {
        var child = Child()
        child.age = 10
        respository.save(&child)
    
        // Update and set metadata to preceed respositoryd value
        child.age = 20
        child.metadata.timestamp -= 1.0
        child.metadata.version += 1
        respository.save(&child)
        
        // Ensure the respositoryd values survive, due to having more recent timestamp
        XCTAssertEqual(child.age, 10)
        
        // Now set to later timestamp and save
        child.age = 20
        child.metadata.timestamp += 1.0
        child.metadata.version += 1
        respository.save(&child)
        
        // Ensure the respositoryd values are updated
        XCTAssertEqual(child.age, 20)
    }
    
    func testArrayOfChildObjects() {
        var parent = Parent()
        var child1 = Child() ; child1.age = 10
        var child2 = Child() ; child2.age = 12
        parent.children = [child1, child2]
        respository.save(&parent)
        
        let fetchedParent:Parent? = respository.fetchValue(identifiedBy: parent.metadata.uniqueIdentifier)
        XCTAssertEqual(fetchedParent!.children.count, 2)
        
        let fetchedChild2 = fetchedParent?.children[1]
        XCTAssertEqual(fetchedChild2!.age, 12)
    }
}



