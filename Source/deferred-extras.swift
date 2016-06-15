//
//  deferred-extras.swift
//  async-deferred
//
//  Created by Guillaume Lessard on 2015-07-13.
//  Copyright © 2015 Guillaume Lessard. All rights reserved.
//

import Dispatch

/*
  Definitions that rely on or extend Deferred, but do not need the fundamental, private stuff.
*/

// MARK: minimum delay until a `Deferred` has a value

extension Deferred
{
  /// Return a `Deferred` whose determination will occur at least `µs` microseconds from the time of evaluation.
  /// - parameter µs: a number of microseconds
  /// - returns: a `Deferred` reference

  public final func delay(µs: Int) -> Deferred
  {
    return delay64(ns: Int64(µs)*1000)
  }

  /// Return a `Deferred` whose determination will occur at least `ms` milliseconds from the time of evaluation.
  /// - parameter ms: a number of milliseconds
  /// - returns: a `Deferred` reference

  public final func delay(ms: Int) -> Deferred
  {
    return delay64(ns: Int64(ms)*1_000_000)
  }

  /// Return a `Deferred` whose determination will occur at least a number of seconds from the time of evaluation.
  /// - parameter seconds: a number of seconds as a `Double` or `NSTimeInterval`
  /// - returns: a `Deferred` reference

  public final func delay(seconds s: Double) -> Deferred
  {
    return delay64(ns: Int64(s*1e9))
  }

  /// Return a `Deferred` whose determination will occur at least `ns` nanoseconds from the time of evaluation.
  /// - parameter ns: a number of nanoseconds
  /// - returns: a `Deferred` reference

  public final func delay(ns: Int) -> Deferred
  {
    return delay64(ns: Int64(ns))
  }

  private func delay64(ns: Int64) -> Deferred
  {
    if ns < 0 { return self }
    return Delayed(source: self, until: DispatchTime(DispatchTime.now().rawValue + UInt64(max(ns,0))))
  }
}

extension DispatchTime
{
  // FIXME: eliminate this workaround
  public init(_ rawValue: dispatch_time_t)
  {
    self.rawValue = rawValue
  }
}


// MARK: maximum time until a `Deferred` becomes determined

private let DefaultTimeoutMessage = "Operation timed out"

extension Deferred
{
  /// Return a `Deferred` whose determination will occur at most `µs` microseconds from the time of evaluation.
  /// If `self` has not become determined after the timeout delay, the new `Deferred` will be canceled.
  /// - parameter µs: a number of microseconds
  /// - parameter reason: the reason for the cancelation if the operation times out. Defaults to "Operation timed out".
  /// - returns: a `Deferred` reference

  public final func timeout(µs: Int, reason: String = DefaultTimeoutMessage) -> Deferred
  {
    return timeout64(ns: Int64(max(µs,0))*1000, reason: reason)
  }

  /// Return a `Deferred` whose determination will occur at most `ms` milliseconds from the time of evaluation.
  /// If `self` has not become determined after the timeout delay, the new `Deferred` will be canceled.
  /// - parameter ms: a number of milliseconds
  /// - parameter reason: the reason for the cancelation if the operation times out. Defaults to "Operation timed out".
  /// - returns: a `Deferred` reference

  public final func timeout(ms: Int, reason: String = DefaultTimeoutMessage) -> Deferred
  {
    return timeout64(ns: Int64(max(ms,0))*1_000_000, reason: reason)
  }

  /// Return a `Deferred` whose determination will occur at most a number of seconds from the time of evaluation.
  /// If `self` has not become determined after the timeout delay, the new `Deferred` will be canceled.
  /// - parameter seconds: a number of seconds as a `Double` or `NSTimeInterval`
  /// - parameter reason: the reason for the cancelation if the operation times out. Defaults to "Operation timed out".
  /// - returns: a `Deferred` reference

  public final func timeout(seconds s: Double, reason: String = DefaultTimeoutMessage) -> Deferred
  {
    return timeout64(ns: Int64(max(s*1e9,0)), reason: reason)
  }

  /// Return a `Deferred` whose determination will occur at most `ns` nanoseconds from the time of evaluation.
  /// If `self` has not become determined after the timeout delay, the new `Deferred` will be canceled.
  /// - parameter ns: a number of nanoseconds
  /// - parameter reason: the reason for the cancelation if the operation times out. Defaults to "Operation timed out".
  /// - returns: a `Deferred` reference

  public final func timeout(ns: Int, reason: String = DefaultTimeoutMessage) -> Deferred
  {
    return timeout64(ns: Int64(max(ns,0)), reason: reason)
  }

  private func timeout64(ns: Int64, reason: String) -> Deferred
  {
    if self.isDetermined { return self }
    if ns > 0
    {
      return Timeout(source: self, deadline: DispatchTime(DispatchTime.now().rawValue + UInt64(max(ns,0))), reason: reason)
    }
    return Mapped(source: self, result: Result.error(DeferredError.canceled(reason)))
  }
}

extension Deferred
{
  // MARK: onValue: execute a task when (and only when) a computation succeeds

  /// Enqueue a closure to be performed asynchronously, if and only if after `self` becomes determined with a value
  /// The closure will be enqueued on the global queue with the requested quality of service.
  /// - parameter qos: the QOS class at which to execute the transform; defaults to the QOS class of this Deferred's queue.
  /// - parameter task: the closure to be enqueued

  public func onValue(qos: DispatchQoS = .unspecified, task: (Value) -> Void)
  {
    notify(qos: qos) { if case let .value(v) = $0 { task(v) } }
  }

  // MARK: onError: execute a task when (and only when) a computation fails

  /// Enqueue a closure to be performed asynchronously, if and only if after `self` becomes determined with an error
  /// The closure will be enqueued on the global queue with the requested quality of service.
  /// - parameter qos: the QOS class at which to execute the transform; defaults to the QOS class of this Deferred's queue.
  /// - parameter task: the closure to be enqueued

  public func onError(qos: DispatchQoS = .unspecified, task: (ErrorProtocol) -> Void)
  {
    notify(qos: qos) { if case let .error(e) = $0 { task(e) } }
  }
}

// MARK: map: asynchronously transform a `Deferred` into another

extension Deferred
{
  /// Enqueue a transform to be computed asynchronously after `self` becomes determined.
  /// - parameter qos: the QOS class at which to execute the transform; defaults to the QOS class of this Deferred's queue.
  /// - parameter transform: the transform to be performed
  /// - returns: a `Deferred` reference representing the return value of the transform

  public func map<Other>(qos: DispatchQoS = .unspecified, transform: (Value) throws -> Other) -> Deferred<Other>
  {
    return Mapped<Other>(qos: qos, source: self, transform: transform)
  }

  /// Enqueue a transform to be computed asynchronously after `self` becomes determined.
  /// - parameter qos: the QOS class at which to execute the transform; defaults to the queue's QOS class.
  /// - parameter transform: the transform to be performed
  /// - returns: a `Deferred` reference representing the return value of the transform

  public func map<Other>(qos: DispatchQoS = .unspecified, transform: (Value) -> Result<Other>) -> Deferred<Other>
  {
    return Mapped<Other>(qos: qos, source: self, transform: transform)
  }
}

// MARK: flatMap: asynchronously transform a `Deferred` into another

extension Deferred
{
  /// Enqueue a transform to be computed asynchronously after `self` becomes determined.
  /// - parameter qos: the QOS class at which to execute the transform; defaults to the QOS class of this Deferred's queue.
  /// - parameter transform: the transform to be performed
  /// - returns: a `Deferred` reference representing the return value of the transform

  public func flatMap<Other>(qos: DispatchQoS = .unspecified, transform: (Value) -> Deferred<Other>) -> Deferred<Other>
  {
    return Bind<Other>(qos: qos, source: self, transform: transform)
  }

  /// Enqueue a transform to be computed asynchronously if and when `self` becomes determined with an error.
  /// - parameter qos: the QOS class at which to execute the transform; defaults to the QOS class of this Deferred's queue.
  /// - parameter transform: the transform to be performed
  /// - returns: a `Deferred` reference representing the return value of the transform

  public func recover(qos: DispatchQoS = .unspecified, transform: (ErrorProtocol) -> Deferred<Value>) -> Deferred<Value>
  {
    return Bind(qos: qos, source: self, transform: transform)
  }
}

// MARK: apply: asynchronously transform a `Deferred` into another

extension Deferred
{
  /// Enqueue a transform to be computed asynchronously after `self` and `transform` become determined.
  /// - parameter qos: the QOS class at which to execute the transform; defaults to the QOS class of this Deferred's queue.
  /// - parameter transform: the transform to be performed, wrapped in a `Deferred`
  /// - returns: a `Deferred` reference representing the return value of the transform

  public func apply<Other>(qos: DispatchQoS = .unspecified, transform: Deferred<(Value) -> Result<Other>>) -> Deferred<Other>
  {
    return Applicator<Other>(qos: qos, source: self, transform: transform)
  }

  /// Enqueue a transform to be computed asynchronously after `self` and `transform` become determined.
  /// - parameter qos: the QOS class at which to execute the transform; defaults to the QOS class of this Deferred's queue.
  /// - parameter transform: the transform to be performed, wrapped in a `Deferred`
  /// - returns: a `Deferred` reference representing the return value of the transform

  public func apply<Other>(qos: DispatchQoS = .unspecified, transform: Deferred<(Value) throws -> Other>) -> Deferred<Other>
  {
    return Applicator<Other>(qos: qos, source: self, transform: transform)
  }

  /// Adaptor made desirable by insufficient covariance from throwing to non-throwing closure types. (radar 22013315)
  /// (i.e. if the difference between the type signature of two closures is whether they throw,
  /// the non-throwing one should be usable anywhere the throwing one can.)
  /// Can hopefully be removed later.
  ///
  /// Enqueue a transform to be computed asynchronously after `self` and `transform` become determined.
  /// - parameter qos: the QOS class at which to execute the transform; defaults to the QOS class of this Deferred's queue.
  /// - parameter transform: the transform to be performed, wrapped in a `Deferred`
  /// - returns: a `Deferred` reference representing the return value of the transform

  public final func apply<Other>(qos: DispatchQoS = .unspecified, transform: Deferred<(Value) -> Other>) -> Deferred<Other>
  {
    let retransform = transform.map(qos: qos) { transform in { v throws in transform(v) } }
    return Applicator<Other>(qos: qos, source: self, transform: retransform)
  }
}
