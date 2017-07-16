//
//  AressessTests.swift
//  AressessTests
//
//  Created by Kai Özer on 7/17/14.
//  Copyright (c) 2014, 2017 Kai Özer. All rights reserved.
//

import UIKit
import XCTest
import Aressess

class AressessTests: XCTestCase
{
    
  override func setUp()
  {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown()
  {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testRSSExample1()
  {
    let feedSource = _loadFeedFromFile("Example-RSS2.0-1")
    XCTAssert(feedSource != nil, "Error loading the feed source")
    if let feed = feedSource
    {
      XCTAssert(!feed.isEmpty, "Unexpected empty feed")
      let parser = RSSParser()
      parser.parse(feed, encoding:String.Encoding.utf8)
      XCTAssert(parser.channel != nil, "Expected a valid channel")
      if let channel = parser.channel
      {
        XCTAssertEqual(channel.items.count, 2, "Expected two items")
        XCTAssertEqual(channel.items[0].title, "RSS Tutorial", "expected another title")
        XCTAssertEqual(channel.items[1].title, "XML Tutorial", "expected another title")
      }
    }
  }

  func testRSSExample2()
  {
    let feedSource = _loadFeedFromFile("Example-RSS2.0-2")
    XCTAssert(feedSource != nil, "Error loading the feed source")
    if let feed = feedSource
    {
      XCTAssert(!feed.isEmpty, "Unexpected empty feed")
      let parser = RSSParser()
      parser.parse(feed, encoding:String.Encoding.utf8)
      XCTAssert(parser.channel != nil, "Expected a valid channel")
      if let channel = parser.channel
      {
        XCTAssertEqual(channel.items.count, 12, "Expected two items")
        XCTAssertEqual(channel.items[4].title, "Virgin America is a low-cost airline making its money from high-priced tickets", "expected another title")
//        XCTAssertEqual(channel.items[1].title.text, "XML Tutorial", "expected another title")
      }
    }
  }

  func testAtomExample1()
  {
    let feedSource = _loadFeedFromFile("Example-Atom-1")
    XCTAssert(feedSource != nil, "Error loading the feed source")
    if let feedXML = feedSource
    {
      XCTAssert(!feedXML.isEmpty, "Unexpected empty feed")
      let parser = AtomParser()
      parser.parse(feedXML, encoding:String.Encoding.utf8)
      XCTAssert(parser.feed != nil, "Expected a valid Atom feed")
      if let feed = parser.feed
      {
        XCTAssertEqual(feed.entries.count,1,"Expected 1 feed entry")
        XCTAssertTrue(feed.entries[0].title != nil, "Entry has no title")
        if let title = feed.entries[0].title
        {
          XCTAssert(title == "Atom-Powered Robots Run Amok", "title does not match");
        }
        else
        {
        }
      }
    }
  }

  func testAtomExample2()
  {
    let feedSource = _loadFeedFromFile("Example-Atom-2")
    XCTAssert(feedSource != nil, "Error loading the feed source")
    if let feedXML = feedSource
    {
      XCTAssert(!feedXML.isEmpty, "Unexpected empty feed")
      let parser = AtomParser()
      parser.parse(feedXML, encoding:String.Encoding.utf8)
      XCTAssert(parser.feed != nil, "Expected a valid Atom feed")
      if let feed = parser.feed
      {
        XCTAssertEqual(feed.entries.count,10,"Expected 10 feed entries")
      }
    }
  }

  func testAtomExample3()
  {
    let feedSource = _loadFeedFromFile("Example-Atom-3")
    XCTAssert(feedSource != nil, "Error loading the feed source")
    if let feedXML = feedSource
    {
      XCTAssert(!feedXML.isEmpty, "Unexpected empty feed")
      let parser = AtomParser()
      parser.parse(feedXML, encoding:String.Encoding.utf8)
      XCTAssert(parser.feed != nil, "Expected a valid Atom feed")
      if let feed = parser.feed
      {
        XCTAssertEqual(feed.entries.count,40,"Expected 10 feed entries")
        let item = feed.entries[3]
        if let title = item.title
        {
          XCTAssertEqual(title, "HSTS: Google führt Liste von reinen HTTPS-Seiten", "expected different title")
        }
      }
    }
  }

  func testPerformanceExample()
  {
    // This is an example of a performance test case.
    self.measure()
    {
      // Put the code you want to measure the time of here.
    }
  }


  //MARK: Private


  fileprivate func _loadFeedFromFile(_ fileName: String) -> String?
  {
    var result : String? = nil
    if let resourceLocation = Bundle(for:AressessTests.self).url(forResource:fileName, withExtension:"xml")
    {
      do
      {
        let fileContent = try String(contentsOf:resourceLocation, encoding:String.Encoding.utf8)
        //print(fileContent)
        result = fileContent
      }
      catch let error as NSError
      {
        print(error.localizedDescription)
      }
    }
    return result
  }

}
