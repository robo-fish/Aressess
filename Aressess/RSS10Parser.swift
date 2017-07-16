//
//  RSS10Parser.swift
//  Aressess
//
//  Created by Kai Özer on 8/11/14.
//  Copyright (c) 2014, 2017 Kai Özer. All rights reserved.
//

import Foundation

private let RDFNamespace = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
private let RSS10Namespace = "http://purl.org/rss/1.0/"

/// Parses XML in the RSS 1.0 format
class RSS10Parser : Parser
{
  var channel : RSSChannel?
  private var currentItem : RSSItem?
  private var isRDF = false
  private var waitingForChannelTitle = false
  private var waitingForItemTitle = false
  private var waitingForItemLink = false
  private var waitingForItemDescription = false

  override init()
  {
  }

  override func parsingStartsElementWithName(_ name: String, namespaceURI: String?, attributes: [String:String])
  {
    if (namespaceURI != nil) && ((namespaceURI == RDFNamespace) || (namespaceURI == RSS10Namespace))
    {
      switch name.lowercased()
      {
        case "rdf":
          isRDF = true
        case "channel":
          if isRDF && (channel == nil)
          {
            channel = RSSChannel()
          }
        case "item":
          if channel != nil
          {
            currentItem = RSSItem()
          }
        case "title":
          if currentItem != nil
          {
            currentItem?.title = ""
            waitingForItemTitle = true
          }
          else if channel != nil
          {
            channel?.title = ""
            waitingForChannelTitle = true
          }
        case "description":
          if currentItem != nil
          {
            currentItem?.description = ""
            waitingForItemDescription = true
          }
        case "link":
          if currentItem != nil
          {
            currentItem?.link = ""
            waitingForItemLink = true
          }
        default: break
      }
    }
  }

  override func parsingEndsElementWithName(_ name: String, namespaceURI: String!)
  {
    if (namespaceURI != nil) && ((namespaceURI == RDFNamespace) || (namespaceURI == RSS10Namespace))
    {
      switch name
      {
        case "rdf":
          isRDF = false
        case "channel":
          waitingForChannelTitle = false
        case "item":
          if isRDF && (currentItem != nil)
          {
            channel?.items.append(currentItem!)
            currentItem = nil
          }
        case "title":
          waitingForItemTitle = false
          waitingForChannelTitle = false
        case "description":
          waitingForItemDescription = false
        case "link":
          waitingForItemLink = false
        default:break
      }
    }
  }

  override func parsingFindsString(_ string: String)
  {
    if currentItem != nil
    {
      if waitingForItemDescription
      {
        currentItem?.description += string
      }
      else if waitingForItemTitle
      {
        currentItem?.title += string
      }
      else if waitingForItemLink
      {
        currentItem?.link += string
      }
    }
    else if waitingForChannelTitle && (channel != nil)
    {
      channel?.title += string
    }
  }
}
