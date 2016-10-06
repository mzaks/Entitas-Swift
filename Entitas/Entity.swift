//
//  Entity.swift
//  Entitas
//
//  Created by Maxim Zaks on 08.12.14.
//  Copyright (c) 2014 Maxim Zaks. All rights reserved.
//

import Foundation

/// ComponentId identifies the type of a component.
public typealias ComponentId = ObjectIdentifier

/// A ghost protocol which identifies a struct as a component.
/// We suggest to use structs for component representation as component should be immutable value objects.
public protocol Component {}

/// Protocol extension which returns component id.
extension Component {
    public static var cId : ComponentId { return ObjectIdentifier(self)}
    public var cId : ComponentId { return ObjectIdentifier(type(of: self))}
}

/// Protocol extension which returns matcher for given component.
extension Component {
    public static var matcher : Matcher { return Matcher.all(cId)}
}

/// A protocol which should be implemented by a class monitoring entity changes.
protocol EntityChangedListener : class {
    func componentAdded(_ entity: Entity, component: Component)
    func componentRemoved(_ entity: Entity, component: Component)
}


public func == (lhs: Entity, rhs: Entity) -> Bool {
    return lhs.creationIndex == rhs.creationIndex && lhs.mainListener === rhs.mainListener && type(of: lhs) === type(of: rhs)
}

/// Entity can be seen as a bag of components.
/// It is managed by a context and also created by a context instance.
/// For querying a group of entities please have a look at Group class.
/// You can observe entity changes by implementing EntityChangedListener protocol.
public final class Entity : Equatable, CustomDebugStringConvertible {
    fileprivate var _components : [ComponentId:Component]
    let mainListener : EntityChangedListener
    public let creationIndex : Int
    
    init(listener : EntityChangedListener, creationIndex : Int) {
        _components = [:]
        mainListener = listener
        self.creationIndex = creationIndex
    }
    
    /// This method adds a component to the entity.
    /// When the entity already has component of the given type and overwrite parameter was not set to true, "Illegal overwrite error" will be raised.
    /// This precaution is defined, because it proved to help find bugs during development.
    /// When you overwrite a component, the old component will be first removed from the entity and than the new component will be added. This mechanism ensures that observers get full picture. This is also why component should be immutable.
    @discardableResult public func set(_ c:Component, overwrite:Bool = false) -> Entity {
        let componentId = c.cId
        let contains = _components[componentId] != nil
        
        if contains && !overwrite {
            assertionFailure("Illegal overwrite error")
        }
        
        if contains {
            self.removeComponent(componentId)
        }
        
        _components[componentId] = c;
        mainListener.componentAdded(self, component:c)
        return self
    }
    
    /// Returns an optional value for component type.
    public func get<C:Component>(_ ct:C.Type) -> C? {
        let componentName = ct.cId
        if let c = _components[componentName] {
            return c as? C
        }
        return nil
    }

    /// Checks if entity already has a component of following component type.
    public func has<C:Component>(_ ct:C.Type) -> Bool {
        return hasComponent(ct.cId)
    }
    
    func hasComponent(_ cId:ComponentId) -> Bool {
        return _components[cId] != nil
    }
    
    /// Removes a component from the entity. If the entity doesn't have a component of this type, nothing happens.
    public func remove<C:Component>(_ ct:C.Type) {
        removeComponent(ct.cId)
    }
    
    func removeComponent(_ componentId:ComponentId) {
        if _components.index(forKey: componentId) == nil {
            return
        }
        
        if let component = _components.removeValue(forKey: componentId) {
            mainListener.componentRemoved(self, component: component)
        }
    }

    func removeAllComponents(){
        for (id, _) in _components {
            removeComponent(id)
        }
    }
    
    public var components : [ComponentId:Component] {
        get {
            return _components
        }
    }
    
    public var debugDescription: String {
        let components = _components.values.flatMap({$0})
        let contextId = ObjectIdentifier(mainListener).hashValue
        return "Entity(\(creationIndex))@\(contextId): \(components)"
    }

    /// Detach creates a DetachedEntity struct which can be changed without informing the managing context about the changes.
    /// This is meant for multithreading, when you need to make heavy computations on a secondary thread and than sync back the changes to the entity on the main thread.
    /// Important to note that detached entity is not aware of changes that might happen to the entity after it was created. Therefore on sync, detached entity might overwrite the changes which happened to the entity between 'detach' and 'sync' calls.
    /// As DetachEntity is a struct, every call of this getter will create a new instance. It is up to you to make sure that you don't have concurrent detached entities.
    public var detach : DetachedEntity {
        get {
            return DetachedEntity(entity: self, components: components, changedComponents: [:])
        }
    }
}

/// Detached entity is meant to be used in multithreading scenario. Please have a look at detach method on Enitty class.
public struct DetachedEntity {
    fileprivate let entity : Entity
    fileprivate var components : [ComponentId:Component]
    fileprivate var changedComponents : [ComponentId:Bool] = [:]
    
    public mutating func set(_ c:Component, overwrite:Bool = false) {
        let componentId = c.cId
        
        if components[componentId] != nil && !overwrite {
            assertionFailure("Illegal overwrite error")
        }
        
        components[componentId] = c;
        changedComponents[componentId] = true
    }
    
    public func get<C:Component>(_ ct:C.Type) -> C? {
        if let c = components[ct.cId] {
            return c as? C
        }
        return nil
    }
    
    public func has<C:Component>(_ ct:C.Type) -> Bool {
        return components[ct.cId] != nil
    }
    
    public mutating func remove<C:Component>(_ ct:C.Type) {
        let componentId : ComponentId = ct.cId
        if components.index(forKey: componentId) == nil {
            return
        }
        
        components.removeValue(forKey: componentId)
        changedComponents[componentId] = true
    }
    
    /// Sync will go through all changed components and set or remove components from the managed entity instance accordingly to the changes.
    /// As detached entity was meant to be used in multithreading scenario, the syncing is done asynchronously on a special queue. You can specify the queue as you wish. Default is main queue.
    public mutating func sync(
                    onQueue queue : DispatchQueue = DispatchQueue.main) {
        let localComponets = components
        let keys = changedComponents.keys
        let localEntity = entity
        queue.async {
            for key in keys {
                if let component = localComponets[key] {
                    _ = localEntity.set(component, overwrite:true)
                } else {
                    localEntity.removeComponent(key)
                }
            }
        }
        changedComponents.removeAll(keepingCapacity: false)
    }
}
