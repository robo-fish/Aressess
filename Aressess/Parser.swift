//
//  Parser.swift
//  Aressess
//
//  Created by Kai Oezer on 8/1/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import Foundation

open class Parser : NSObject, XMLParserDelegate
{
  open func parse(_ xmlText:String, encoding:String.Encoding)
  {
    if let xmlData = xmlText.data(using: encoding)
    {
      parsingWillStart()
      let parser = XMLParser(data:xmlData)
      parser.shouldProcessNamespaces = true
      parser.delegate = self
      parser.parse()
      parsingDidEnd()
    }
  }

  func parsingWillStart()
  {
    // To be overridden. Optional.
  }

  func parsingDidEnd()
  {
    // To be overridden. Optional.
  }

  func parsingStartsElementWithName(_ name: String, namespaceURI: String?, attributes: [String : String])
  {
    assert(false, "To be overridden.")
  }

  func parsingEndsElementWithName(_ name: String, namespaceURI: String!)
  {
    assert(false, "To be overridden.")
  }

  func parsingFindsString(_ string: String)
  {
    assert(false, "To be overridden.")
  }

  //MARK: NSXMLParserDelegate

  open func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String : String])
  {
    parsingStartsElementWithName(elementName, namespaceURI:namespaceURI, attributes:attributes)
  }

  open func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?)
  {
    parsingEndsElementWithName(elementName, namespaceURI:namespaceURI)
  }

  open func parser(_ parser: XMLParser, foundCharacters string: String)
  {
    parsingFindsString(string)
  }

//  public func parser(parser: NSXMLParser, foundCDATA CDATABlock: NSData)
//  {
//
//  }

}
