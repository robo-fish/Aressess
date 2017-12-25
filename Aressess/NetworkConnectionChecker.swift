//
//  NetworkConnectionChecker.swift
//  Aressess
//
//  Created by Kai Oezer on 12/23/17.
//  Copyright © 2017 Kai Oezer. All rights reserved.
//

import Foundation
import CoreFoundation
import SystemConfiguration

class NetworkConnectionChecker
{
  private var _handler : ConnectionCheckHandler
  private var _checkedHost : String?
  fileprivate var _reachability : SCNetworkReachability?

  typealias ConnectionCheckHandler = (_ : String?, _ : Bool)->()

  init(handler : @escaping ConnectionCheckHandler)
  {
    _handler = handler
  }

  func checkConnection(to hostAddress:String)
  {
    _checkedHost = hostAddress
    guard let data = _checkedHost?.data(using: String.Encoding.utf8) else { notifyThatTheHostIsReachable(false); return }
    data.withUnsafeBytes { byteData in
      _reachability = SCNetworkReachabilityCreateWithName(nil, byteData)
    }
    _startCheckOfReachability(self)
  }

  func checkConnectionToInternet()
  {
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    zeroAddress.sin_family = sa_family_t(AF_INET)
    _checkConnection(toAddress: &zeroAddress)
  }

  func checkConnectionToWiFi()
  {
    var localWifiAddress = sockaddr_in()
    localWifiAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    localWifiAddress.sin_family = sa_family_t(AF_INET)

    // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0.
    // Converted to network byte order, IN_LINKLOCALNETNUM becomes 0xA9FE0000
    localWifiAddress.sin_addr.s_addr = 0xA9FE0000
    _checkConnection(toAddress: &localWifiAddress)
  }

  func stopChecking()
  {
    if let reachability = _reachability
    {
      if !SCNetworkReachabilityUnscheduleFromRunLoop(reachability, RunLoop.current.getCFRunLoop(), CFRunLoopMode.defaultMode.rawValue)
      {
        DebugLog("Could not unschedule the reachability check.")
      }
    }
    _reachability = nil
  }

  private func _checkConnection(toAddress hostAddress : inout sockaddr_in)
  {
    _checkedHost = nil
    withUnsafePointer(to: &hostAddress) {
      $0.withMemoryRebound(to: sockaddr.self, capacity:1) {
        _reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, $0)
      }
    }
    _startCheckOfReachability(self)
  }

  func notifyThatTheHostIsReachable(_ isReachable : Bool)
  {
    _handler(_checkedHost, isReachable)
  }
}

fileprivate var _instance : NetworkConnectionChecker?
fileprivate let _lock = NSLock()

fileprivate func _startCheckOfReachability(_ instance : NetworkConnectionChecker)
{
  guard _lock.try() else { return }
  guard let reachability = instance._reachability else { instance.notifyThatTheHostIsReachable(false); _lock.unlock(); return }
  _instance = instance
  withUnsafePointer(to: &_instance!) { ptr in
    var context = SCNetworkReachabilityContext(version: 0, info:UnsafeMutableRawPointer(mutating:ptr), retain: nil, release: nil, copyDescription: nil)
    if !SCNetworkReachabilitySetCallback(reachability, reachabilityCallback, &context) { instance.notifyThatTheHostIsReachable(false); _lock.unlock(); return }
    if !SCNetworkReachabilityScheduleWithRunLoop(reachability, RunLoop.current.getCFRunLoop(), CFRunLoopMode.defaultMode.rawValue) { instance.notifyThatTheHostIsReachable(false); _lock.unlock(); return }
  }
}

fileprivate func reachabilityCallback(target : SCNetworkReachability, flags : SCNetworkReachabilityFlags, info : UnsafeMutableRawPointer?)
{
  guard let objectPtr = info else { return }
  let checker = objectPtr.assumingMemoryBound(to: NetworkConnectionChecker.self).pointee
  var canConnect : Bool = flags.contains(SCNetworkReachabilityFlags.reachable)
    || flags.contains(SCNetworkReachabilityFlags.transientConnection)
    || flags.contains(SCNetworkReachabilityFlags.connectionRequired)
    || flags.contains(SCNetworkReachabilityFlags.connectionOnTraffic)
  #if os(iOS)
    canConnect = canConnect || flags.contains(SCNetworkReachabilityFlags.isWWAN)
  #endif
  checker.notifyThatTheHostIsReachable(canConnect)
}


