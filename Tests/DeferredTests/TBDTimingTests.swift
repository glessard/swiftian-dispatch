//
//  TBDTimingTests.swift
//  deferred
//
//  Created by Guillaume Lessard on 29/04/2016.
//  Copyright © 2016 Guillaume Lessard. All rights reserved.
//

import XCTest
import Foundation
import Dispatch

import deferred


class TBDTimingTests: XCTestCase
{
  func testPerformancePropagationTime()
  {
    measure {
      let iterations = 10_000
      let ref = Date.distantPast

      let first = TBD<(Int, Date, Date)>(qos: .userInitiated)
      var dt: Deferred = first
      for _ in 0...iterations
      {
        dt = dt.map {
          (i, tic, toc) in
          tic == ref ? (0, Date(), ref) : (i+1, tic, Date())
        }
      }

      try! first.determine( (0, ref, ref) )

      switch dt.result
      {
      case let .value(iterations, tic, toc):
        let interval = toc.timeIntervalSince(tic)
        // print("\(round(Double(interval*1e9)/Double(iterations))/1000) µs per message")
        _ = interval/Double(iterations)
        break
        
      default: XCTFail()
      }
    }
  }

  func testPerformanceNotificationTime()
  {
    measure {
      let iterations = 10_000

      let start = TBD<Date>(queue: DispatchQueue(label: "", qos: .userInitiated))
      for _ in 0..<iterations
      {
        start.notify { _ in }
      }

      let dt = start.map { start in Date().timeIntervalSince(start) }
      try! start.determine(Date())

      switch dt.result
      {
      case .value(let interval):
        // print("\(round(Double(interval*1e9)/Double(iterations))/1000) µs per notification")
        _ = interval
        break
        
      default: XCTFail()
      }
    }
  }
  
}
