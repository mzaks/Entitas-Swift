//
//  UniqueEntityExtensions.swift
//  Entitas
//
//  Created by Maxim Zaks on 06.10.16.
//  Copyright © 2016 Maxim Zaks. All rights reserved.
//

import Foundation

public extension Context {
    /// Query for an entity by matcher which should be unique in the context
    /// Asserts if there is more than one entity matching the matcher.
    public func uniqueEntity(matcher : Matcher) -> Entity? {
        let group = self.entityGroup(matcher)
        if group.count > 1 {
            assertionFailure("Found \(group.count) entites for matcher \(matcher)")
            
        }
        return group.sortedEntities.first
    }
    
    /// Query for a component which should be unique in the context.
    /// Uses uniqueEntity under the hood and unpacks the component.
    public func uniqueComponent<C:Component>(ct:C.Type) -> C? {
        return uniqueEntity(Matcher.All(ct.cId))?.get(ct)
    }
    
    /// uses uniqueComponent under the hood. Checks if the result is not nil.
    public func hasUniqueComponent<C:Component>(ct:C.Type) -> Bool {
        return uniqueComponent(ct) != nil
    }
    
    /// If the entity with the given component type already exists. Will overwrite it with given instance.
    /// Other wise will create a new entity and add given component ot it.
    /// Uses uniqueEntity under the hood.
    public func setUniqueEntityWith(c : Component) -> Entity {
        if let e = uniqueEntity(Matcher.All(c.cId)) {
            return e.set(c, overwrite: true)
        } else {
            return createEntity().set(c)
        }
    }
    
    // If there is unique entity for the given matcher. It will be destroyed.
    public func destroyUniqueEntity(matcher : Matcher) {
        if let e = uniqueEntity(matcher) {
            destroyEntity(e)
        }
    }
}
