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
  let propagationTestCount = 10_000

  func testPerformancePropagationTime()
  {
    let iterations = propagationTestCount
    let ref = Date.distantPast

    measureMetrics(XCTestCase.defaultPerformanceMetrics, automaticallyStartMeasuring: false) {
      let (trigger, first) = TBD<(Int, Date, Date)>.CreatePair(qos: .userInitiated)
      var dt = first
      for _ in 0...iterations
      {
        dt = dt.map {
          (i, tic, toc) in
          tic == ref ? (0, Date(), ref) : (i+1, tic, Date())
        }
      }

      self.startMeasuring()
      trigger.determine(value: (0, ref, ref))
      let (iterations, tic, toc) = try! dt.get()
      self.stopMeasuring()

      let interval = toc.timeIntervalSince(tic)
      // print("\(round(Double(interval*1e9)/Double(iterations))/1000) µs per message")
      _ = interval/Double(iterations)
    }
  }

  func testPerformanceNotificationTime()
  {
    let iterations = propagationTestCount

    measure {
      let (trigger, start) = TBD<Date>.CreatePair(queue: DispatchQueue(label: "", qos: .userInitiated))
      for _ in 0..<iterations
      {
        start.notify { deferred in _ = deferred.value! }
      }

      let dt = start.map { start in Date().timeIntervalSince(start) }
      trigger.determine(value: Date())

      let interval = try! dt.get()
      // print("\(round(Double(interval*1e9)/Double(iterations))/1000) µs per notification")
      _ = interval
    }
  }


  func testPerformanceNotificationCreationTime()
  {
    let iterations = propagationTestCount

    measureMetrics(XCTestCase.defaultPerformanceMetrics, automaticallyStartMeasuring: false) {
      _ = TBD<Int>(qos: .userInitiated) {
        t in
        self.startMeasuring()
        for _ in 0...iterations
        {
          t.notify { outcome in _ = outcome.value }
        }
        self.stopMeasuring()

        t.determine(value: 1)
      }

    }
  }
}
