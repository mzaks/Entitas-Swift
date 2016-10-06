//
//  DebugContext.swift
//  Entitas
//
//  Created by Maxim Zaks on 30.01.15.
//  Copyright (c) 2015 Maxim Zaks. All rights reserved.
//

import Foundation

/// Debug context is a subclass of context which will protocol every change happening to entities or groups.
public class DebugContext : Context {
    
    let creationTime : CFAbsoluteTime
    var entityCreationTimeDeltas : [Int:CFAbsoluteTime] = [:]
    public var printFunction : (String) -> ()
    let ignore : Set<ComponentId>
    
    private var stateChange = false
    
    public init(printFunction : (String) -> (), ignore: Set<ComponentId> = []){
        creationTime = CFAbsoluteTimeGetCurrent()
        self.printFunction = printFunction
        self.ignore = ignore
        super.init()
    }
    
    public override func createEntity() -> Entity {
        let e = super.createEntity()
        entityCreationTimeDeltas[e.creationIndex] = deltaTime
        printFunction("Entity: \(e.creationIndex) created. (\(entityCreationTimeDeltas[e.creationIndex]!))")
        stateChange = true
        return e
    }
    
    public override func destroyEntity(entity : Entity) {
        super.destroyEntity(entity)
        printFunction("Entity: \(entity.creationIndex) destroyed. Age: (\(entityAge(entity)) (\(deltaTime))")
        stateChange = true
    }
    
//    public override func entityGroup(matcher : Matcher) -> Group {
//        let group = super.entityGroup(matcher)
//        printFunction("Group: \(matcher.matcherKey) requested. (\(numberOfGroups)) (\(deltaTime))")
//        return group
//    }
    
    override func registerSystem(name :String, system : System) -> System {
        return { [self]
            if self.stateChange {
                self.printFunction("-------- Changes were applied outside system loop")
                self.stateChange = false
            }
            let time = CFAbsoluteTimeGetCurrent()
            system()
            if self.stateChange {
                self.printFunction("-------- did execute \(name) : in \((CFAbsoluteTimeGetCurrent() - time)*1000)")
                self.stateChange = false
            }
        }
    }
    
    override func componentAdded(entity: Entity, component: Component) {
        super.componentAdded(entity, component: component)
        
        guard !ignore.contains(component.cId) else {
            return
        }
        
        if let _component : CustomDebugStringConvertible = component as? CustomDebugStringConvertible {
            printFunction("Entity: \(entity.creationIndex) added Component: \(_component.debugDescription). (\(deltaTime))")
        } else {
            printFunction("Entity: \(entity.creationIndex) added Component: (\(component)) (\(deltaTime))")
        }
        stateChange = true
    }
    
    override func componentRemoved(entity: Entity, component: Component) {
        super.componentRemoved(entity, component: component)
        
        guard !ignore.contains(component.cId) else {
            return
        }
        
        if let _component : CustomDebugStringConvertible = component as? CustomDebugStringConvertible {
            printFunction("Entity: \(entity.creationIndex) removed Component: \(_component.debugDescription). (\(deltaTime))")
        } else {
            printFunction("Entity: \(entity.creationIndex) removed Component: (\(component)) (\(deltaTime))")
        }
        stateChange = true
    }
    
    var deltaTime : CFAbsoluteTime
    {
        return CFAbsoluteTimeGetCurrent() - creationTime
    }
    
    func entityAge(e: Entity )->CFAbsoluteTime{
        return CFAbsoluteTimeGetCurrent() - entityCreationTimeDeltas[e.creationIndex]!
    }
    
}
