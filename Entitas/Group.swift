//
//  Group.swift
//  Entitas
//
//  Created by Maxim Zaks on 21.12.14.
//  Copyright (c) 2014 Maxim Zaks. All rights reserved.
//

/// A protocol which lets you monitor a group for changes
public protocol GroupObserver : class {
    func entityAdded(_ entity : Entity)
    func entityRemoved(_ entity : Entity, withRemovedComponent removedComponent : Component)
}

/// A group contains all entities which apply to a certain matcher.
/// Groups are created through Context.entityGroup method.
/// Groups are always up to date.
/// Groups are internally cached in Context class, so you don't have to be concerned about caching them your self, just call Context.entityGroup method when you need it.
open class Group {
    
    open let matcher : Matcher
    fileprivate var _entities : [Int:Entity] = [:]
    fileprivate var _sortedEntities : [Entity]?
    fileprivate var _observers : [GroupObserver] = []
    
    init(matcher : Matcher){
        self.matcher = matcher
    }
    
    func addEntity(_ e : Entity) {
        if let _ = _entities[e.creationIndex] {
            return;
        }
        _entities[e.creationIndex] = e
        _sortedEntities = nil
        for listener in _observers {
            listener.entityAdded(e)
        }
    }
    
    func removeEntity(_ e : Entity, withRemovedComponent removedComponent : Component) {
        guard let _ = _entities.removeValue(forKey: e.creationIndex) else {
            return
        }
        _sortedEntities = nil
        for listener in _observers {
            listener.entityRemoved(e, withRemovedComponent: removedComponent)
        }
    }

    open var count : Int{
        get {
            return _entities.count
        }
    }
    
    /// Returns an array of entities sorted by entity creation index
    open var sortedEntities: [Entity] {
        get {
            if let sortedEntities = _sortedEntities {
                return sortedEntities
            }
            
            let sortedKeys = _entities.keys.sorted(by: <)
            var sortedEntities : [Entity] = []
            for key in sortedKeys {
                sortedEntities.append(_entities[key]!)
            }
            _sortedEntities = sortedEntities
            return _sortedEntities!
        }
    }
    
    /// Returns unsorted array of entities, the order is non deterministic
    open var unsortedEntities : [Entity] {
        return _entities.values.lazy.map({$0})
    }
    
    open func addObserver(_ observer : GroupObserver) {
        _observers.append(observer)
    }
    
    open func removeObserver(_ observer : GroupObserver) {
        var index : Int? = nil
        for (_index, _observer) in _observers.enumerated() {
            if _observer === observer {
                index = _index
                break
            }
        }
        
        if let observerIndex = index {
            _observers.remove(at: observerIndex)
        }
    }
    
    open func removeAllListeners() {
        _observers.removeAll(keepingCapacity: false)
    }
}


extension Group : Sequence {
    
    public func makeIterator() -> AnyIterator<Entity> {
        let values = Array<Entity>(_entities.values)
        
        var nextIndex = 0
        
        return AnyIterator<Entity> {
            if(values.count <= nextIndex){
                return nil
            }
            let value = values[nextIndex]
            nextIndex += 1
            return value
        }
    }
    
//    public func without(matcher : Matcher) -> AnySequence<Entity> {
//        return AnySequence(_entities.values.filter{
//            matcher.isMatching($0)
//        })
//    }
}
