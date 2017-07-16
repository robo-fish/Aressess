//
//  RSSParser.swift
//  Aressess
//
//  Created by Kai Özer on 8/11/14.
//  Copyright (c) 2014, 2017 Kai Özer. All rights reserved.
//

import Foundation
import FXKit

/// Detects the RSS format and selects one of the concrete RSS parsers to actually do the parsing.
public class RSSParser : Parser
{
  private var internalParser : Parser?

  public var channel : RSSChannel?
  {
    if internalParser is RSS10Parser
    {
      return (internalParser as! RSS10Parser).channel
    }
    else if internalParser is RSS20Parser
    {
      return (internalParser as! RSS20Parser).channel
    }
    return nil
  }

  public override init()
  {

  }

  //MARK: Parser overrides

  override func parsingWillStart()
  {
    internalParser = nil
  }

  override func parsingDidEnd()
  {
    internalParser?.parsingDidEnd()
  }

  override func parsingStartsElementWithName(_ name: String, namespaceURI: String?, attributes: [String : String])
  {
    if internalParser == nil
    {
      if name.lowercased() == "rss"
      {
        if attributes["version"] == "2.0"
        {
          internalParser = RSS20Parser()
        }
      }
      else if name.lowercased() == "rdf"
      {
        internalParser = RSS10Parser()
      }
      else
      {
        DebugLog("Encountered unknown root element \"\(name)\" in feed.")
      }
      internalParser?.parsingWillStart()
    }
    internalParser?.parsingStartsElementWithName(name, namespaceURI:namespaceURI, attributes:attributes)
  }

  override func parsingEndsElementWithName(_ name: String, namespaceURI: String!)
  {
    internalParser?.parsingEndsElementWithName(name, namespaceURI:namespaceURI)
  }

  override func parsingFindsString(_ string: String)
  {
    internalParser?.parsingFindsString(string)
  }

}
