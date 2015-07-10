//
//  async.swift
//  swiftiandispatch
//
//  Created by Guillaume Lessard on 2014-08-16.
//  Copyright (c) 2014 Guillaume Lessard. All rights reserved.
//

import Dispatch

/**
  Utility shortcuts for Grand Central Dispatch

  Example:
  async { println("In the background") }

  That is simply a shortcut for
  dispatch_async(dispatch_get_global_queue(qos_class_self(), 0)) { println("In the background") }

  Much more economical, much less noisy.

  A queue or a qos_class_t can be provided as a parameter in addition to the closure.
  When none is supplied, the global queue at the current qos class will be used.
  In all cases, a dispatch_group_t may be associated with the block to be executed.
*/

// MARK: Asynchronous tasks (straight dispatch_async and dispatch_group_async shortcuts)

public func async(task: () -> ())
{
  dispatch_async(dispatch_get_global_queue(qos_class_self(), 0), task)
}

public func async(group group: dispatch_group_t, task: () -> ())
{
  dispatch_group_async(group, dispatch_get_global_queue(qos_class_self(), 0), task)
}

public func async(qos: qos_class_t, task: () -> ())
{
  dispatch_async(dispatch_get_global_queue(qos, 0), task)
}

public func async(qos: qos_class_t, group: dispatch_group_t, task: () -> ())
{
  dispatch_group_async(group, dispatch_get_global_queue(qos, 0), task)
}

public func async(queue: dispatch_queue_t, task: () -> ())
{
  dispatch_async(queue, task)
}

public func async(queue: dispatch_queue_t, group: dispatch_group_t, task: () -> ())
{
  dispatch_group_async(group, queue, task)
}

// MARK: Asynchronous tasks with return values.

public func async<T>(task: () -> T) -> Deferred<T>
{
  return async(dispatch_get_global_queue(qos_class_self(), 0), task: task)
}

public func async<T>(group group: dispatch_group_t, task: () -> T) -> Deferred<T>
{
  return async(dispatch_get_global_queue(qos_class_self(), 0), group: group, task: task)
}

public func async<T>(qos: qos_class_t, task: () -> T) -> Deferred<T>
{
  return async(dispatch_get_global_queue(qos, 0), task: task)
}

public func async<T>(qos: qos_class_t, group: dispatch_group_t, task: () -> T) -> Deferred<T>
{
  return async(dispatch_get_global_queue(qos, 0), group: group, task: task)
}

public func async<T>(queue: dispatch_queue_t, task: () -> T) -> Deferred<T>
{
  return Deferred(queue: queue, task: task)
}

public func async<T>(queue: dispatch_queue_t, group: dispatch_group_t, task: () -> T) -> Deferred<T>
{
  return Deferred(queue: queue, group: group, task: task)
}
