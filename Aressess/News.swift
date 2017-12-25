//
//  News.swift
//  Aressess
//
//  Created by Kai Oezer on 7/18/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import Foundation


private var webCharacters = Dictionary<String,Character>() // maps web character to UTF-8 codeunit


class News : NSObject
{
  var title : String
  var summary : String
  var content : String
  var link : String
  var hasBeenRead : Bool = false

  init(title:String, summary:String, content:String, link:String = "")
  {
    self.title = title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    self.summary = summary
    self.content = content
    self.link = link
    super.init()
    _convertWebCharacters()
  }

  // convert
  private func _convertWebCharacters()
  {
    if webCharacters.isEmpty
    {
      //News._loadWebCharacters()
      News._loadWebCharactersFast()
      //println(webCharacters.description)
    }
    title = _checkAndReplaceCharactersInString(title)
    //_checkAndReplaceCharacters(&summary)
  }

  private func _checkAndReplaceCharactersInString(_ string : String) -> String
  {
    var output = string
    for (sequence,webchar) in webCharacters
    {
      output = output.replacingOccurrences(of: sequence, with:String(webchar))
    }
    return output
  }

  /**
    Loads the set of HTML5 named characters that was obtained from http://www.w3.org/TR/html5/entities.json and explained in http://www.w3.org/TR/html5/syntax.html#named-character-references
    Incurs significant performance hit.
  */
  private class func _loadWebCharacters()
  {
    if let entitiesDefinitionFileLocation = Bundle.main.url(forResource:"entities", withExtension:"json")
    {
      do
      {
        let entitiesDefinition = try NSString(contentsOf:entitiesDefinitionFileLocation, encoding:String.Encoding.ascii.rawValue)
        if let entitiesData = entitiesDefinition.data(using: String.Encoding.ascii.rawValue)
        {
          let jsonDict = try JSONSerialization.jsonObject(with: entitiesData, options:JSONSerialization.ReadingOptions(rawValue: 0))
          if let dict = jsonDict as? [String:NSDictionary?]
          {
            for (key, values) in dict
            {
              if key.hasSuffix(";")
              {
                if let valuesDict = values as? [String:AnyObject]!
                {
                  if let codepoints : AnyObject = valuesDict["codepoints"]
                  {
                    if let cps = codepoints as? [NSNumber]
                    {
                      if !cps.isEmpty
                      {
                        let x = cps[0].int64Value
                        webCharacters[key] = Character(UnicodeScalar(UInt32(x))!)
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      catch let error as NSError
      {
        print("Error while loading web characters table. \(error.localizedDescription)")
      }
      catch _
      {
        print("Error while loading web characters table.")
      }
    }
  }

  /// Loads only the most common used web characters
  private class func _loadWebCharactersFast()
  {
    webCharacters["&amp;"]  = "\u{0026}" // &
    webCharacters["&#38;"]  = "\u{0026}" // &
    webCharacters["&Ouml;"] = "\u{00d6}" // Ö
    webCharacters["&#214;"] = "\u{00d6}" // Ö
    webCharacters["&ouml;"] = "\u{00f6}" // ö
    webCharacters["&#246;"] = "\u{00f6}" // ö
    webCharacters["&UUml;"] = "\u{00dc}" // Ü
    webCharacters["&#220;"] = "\u{00dc}" // Ü
    webCharacters["&uuml;"] = "\u{00fc}" // ü
    webCharacters["&#252;"] = "\u{00fc}" // ü
    webCharacters["&Auml;"] = "\u{00c4}" // Ä
    webCharacters["&#196;"] = "\u{00c4}" // Ä
    webCharacters["&auml;"] = "\u{00e4}" // ã
    webCharacters["&#228;"] = "\u{00e4}" // ã
    webCharacters["&rarr;"] = "\u{2192}" // →
    webCharacters["&larr;"] = "\u{2190}" // ←
    webCharacters["&apos;"] = "\u{002f}" // '
    webCharacters["&quot;"] = "\u{0022}" // "
    webCharacters["&#8216;"] = "\u{2018}" // ‘
    webCharacters["&#8217;"] = "\u{2019}" // ’
    webCharacters["&lsquo;"] = "\u{2018}" // ‘
    webCharacters["&rsquo;"] = "\u{2019}" // ’
    webCharacters["&nbsp;"] = " "
    webCharacters["&#160;"] = " "
    webCharacters["&mdash;"] = "\u{2014}"
    webCharacters["&#8212;"] = "\u{2014}"
    webCharacters["&eacute;"] = "\u{00E9}"// é
    webCharacters["&#233;"] = "\u{00E9}"  // é
    webCharacters["&Eacute;"] = "\u{00C9}"// É
    webCharacters["&#201;"] = "\u{00C9}"  // É
    
    //webCharacters["&;"] = "\u{}"
  }

}


func == (left : News, right : News) -> Bool
{
  return left.link == right.link
}

func != (left:News, right:News) -> Bool
{
  return left.link != right.link
}
