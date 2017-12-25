//
//  FeedLoader.swift
//  Aressess
//
//  Created by Kai Oezer
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

import Foundation

private enum MIMEType : String
{
  case RSS = "application/rss+xml"
  case Atom = "application/atom+xml"
  case GenericXML = "application/xml"
  func description() -> String { return self.rawValue }
}

private let AllowedFeedTextEncodings = [String.Encoding.utf8, String.Encoding.isoLatin1 /*ISO-8859-1*/]


protocol FeedLoaderDelegate
{
  func handleLoadedFeedForLoader(_ loader:FeedLoader)
  func handleErrorMessage(_ message:String, forLoader loader:FeedLoader)
}


class FeedLoader : NSObject, URLSessionDelegate
{
  var feedAddress : URL? = nil
  var news = [News]()
  var delegate : FeedLoaderDelegate? = nil
  var handledResponse = false
  lazy var _connectionChecker = NetworkConnectionChecker(handler: { (hostName : String?, isConnected : Bool) in
    if !isConnected
    {
      self.delegate?.handleErrorMessage(String(format:LocString("CannotReachHost"), hostName ?? ""), forLoader:self)
    }
  })

  init(feed : Feed)
  {
    feedAddress = feed.location
    super.init()
  }

  /// - parameter delegate: the object that will be notified via the FeedLoaderDelegate protocol after all news items are loaded.
  func loadNewsWithDelegate(_ delegate: FeedLoaderDelegate)
  {
    news.removeAll()
    handledResponse = false
    self.delegate = delegate
    if let address = _convertAddressToHttp(feedAddress), let host = address.host
    {
      _connectionChecker.checkConnection(to: host)
      var request = URLRequest(url:address)
      request.addValue("utf-8", forHTTPHeaderField:"Accept-Charset")
      let session = URLSession(configuration: URLSessionConfiguration.default)
      let task = session.dataTask(with: request, completionHandler: {
        (data : Data?, response : URLResponse?, error : Error?) in
        if (!self.handledResponse) && (data != nil) && (data!.count > 0)
        {
          self.handledResponse = true
          for encoding in AllowedFeedTextEncodings
          {
            if let data_ = data, let receivedContent = String(data:data_, encoding:encoding)
            {
              //println("\(receivedContent)")
              self._handleDownloadCompleted(receivedContent, URLresponse:response, encoding:encoding)
              break
            }
          }
        }
      })
      task.resume()
    }
  }

  //MARK: NSURLSessionDelegate



  //MARK: Private

  private func _handleDownloadCompleted(_ content:String, URLresponse response:URLResponse?, encoding:String.Encoding)
  {
    let MIMETypeString = response?.mimeType
    let referencedFeedLocation = _referencedFeedLocation(content as NSString)
    if referencedFeedLocation == nil
    {
      _parseResponse(content, forMIMEType:(MIMETypeString != nil ? MIMEType(rawValue:MIMETypeString!) : nil), encoding:encoding)
      delegate?.handleLoadedFeedForLoader(self)
    }
    else if delegate != nil
    {
      feedAddress = referencedFeedLocation
      DispatchQueue.main.async(execute: {self.loadNewsWithDelegate(self.delegate!)})
    }
  }

  private func _referencedFeedLocation(_ response:NSString) -> URL?
  {
    let prefixForRefreshURL = "<meta http-equiv=\"refresh\" content=\""
    let refreshPrefixRange : NSRange = response.range(of: prefixForRefreshURL)
    if refreshPrefixRange.location != NSNotFound
    {
      let urlStartMarker = "url="
      let urlStartMarkerSearchStartLocation = refreshPrefixRange.location + refreshPrefixRange.length
      let urlStartMarkerRange = response.range(of: urlStartMarker, options:[], range:NSMakeRange(urlStartMarkerSearchStartLocation, response.length - urlStartMarkerSearchStartLocation), locale:nil)
      if urlStartMarkerRange.location != NSNotFound
      {
        let urlEndMarker = "\""
        let urlEndMarkerSearchStartLocation = urlStartMarkerRange.location + urlStartMarkerRange.length
        let refreshURLEndMarkerRange = response.range(of: urlEndMarker, options:[], range:NSMakeRange(urlEndMarkerSearchStartLocation, response.length - urlEndMarkerSearchStartLocation), locale:nil)
        if refreshURLEndMarkerRange.location != NSNotFound
        {
          let referencedURLString = response.substring(with: NSMakeRange(urlEndMarkerSearchStartLocation, refreshURLEndMarkerRange.location - urlEndMarkerSearchStartLocation))
          return URL(string:referencedURLString)
        }
      }
    }
    return nil
  }

  private func _parseResponse(_ response:String, forMIMEType type: MIMEType?, encoding:String.Encoding)
  {
    let mimeType = type ?? MIMEType.RSS
    if mimeType == .RSS
    {
      _parseRSSResponse(response, encoding: encoding)
    }
    else if mimeType == .Atom
    {
      _parseAtomResponse(response, encoding: encoding)
    }
    else
    {
      _tryParseRSSOrAtom(response, encoding: encoding)
    }
  }

  private func _parseRSSResponse(_ response: String, encoding: String.Encoding)
  {
    let rssParser = RSSParser()
    rssParser.parse(response, encoding:encoding)
    if let channel = rssParser.channel
    {
      for item in channel.items
      {
        news.append(News(title:item.title, summary:"", content:item.description, link:item.link))
      }
    }
  }

  private func _parseAtomResponse(_ response: String, encoding: String.Encoding)
  {
    let parser = AtomParser()
    parser.parse(response, encoding:encoding)
    if let feed = parser.feed
    {
      for entry in feed.entries
      {
        if let newsTitle = entry.title
        {
          news.append(News(title:newsTitle, summary:entry.summary ?? "", content:entry.content ?? "", link:entry.link ?? ""))
        }
      }
    }
  }

  private func _tryParseRSSOrAtom(_ response: String, encoding: String.Encoding)
  {
    let rssParser = RSSParser()
    rssParser.parse(response, encoding: encoding)
    if let channel = rssParser.channel
    {
      for item in channel.items
      {
        news.append(News(title:item.title, summary:"", content:item.description, link:item.link))
      }
    }
    else
    {
      let atomParser = AtomParser()
      atomParser.parse(response, encoding: encoding)
      if let feed = atomParser.feed
      {
        for entry in feed.entries
        {
          if let newsTitle = entry.title
          {
            news.append(News(title:newsTitle, summary:entry.summary ?? "", content:entry.content ?? "", link:entry.link ?? ""))
          }
        }
      }
    }
  }

  private func _dealWithServerForwarding()
  {
    /* Example in Java how to deal with 301 Moved Permanently response.
    Just follow the redirect based on the "Location" HTTP header
    URL hh= new URL("http://hh.ru");
    URLConnection connection = hh.openConnection();
    String redirect = connection.getHeaderField("Location");
    if (redirect != null){ connection = new URL(redirect).openConnection(); }
    BufferedReader in = new BufferedReader(new InputStreamReader(connection.getInputStream()));
    */
  }

  private func _convertAddressToHttp(_ address:URL?) -> URL?
  {
    if address?.scheme?.lowercased() == "feed"
    {
      let path = address!.path
      if !path.isEmpty
      {
        var components = URLComponents()
        components.scheme = "http"
        components.host = address!.host
        components.path = path
        return components.url
      }
    }
    return address
  }
}
