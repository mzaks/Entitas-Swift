//
//  DebugContext.swift
//  Entitas
//
//  Created by Maxim Zaks on 30.01.15.
//  Copyright (c) 2015 Maxim Zaks. All rights reserved.
//

import Foundation

/// Debug context is a subclass of context which will protocol every change happening to entities or groups.
open class DebugContext : Context {
    
    let creationTime : CFAbsoluteTime
    var entityCreationTimeDeltas : [Int:CFAbsoluteTime] = [:]
    open var printFunction : (String) -> ()
    let ignore : Set<ComponentId>
    
    fileprivate var stateChange = false
    
    public init(printFunction : @escaping (String) -> (), ignore: Set<ComponentId> = []){
        creationTime = CFAbsoluteTimeGetCurrent()
        self.printFunction = printFunction
        self.ignore = ignore
        super.init()
    }
    
    open override func createEntity() -> Entity {
        let e = super.createEntity()
        entityCreationTimeDeltas[e.creationIndex] = deltaTime
        printFunction("Entity: \(e.creationIndex) created. (\(entityCreationTimeDeltas[e.creationIndex]!))")
        stateChange = true
        return e
    }
    
    open override func destroyEntity(_ entity : Entity) {
        super.destroyEntity(entity)
        printFunction("Entity: \(entity.creationIndex) destroyed. Age: (\(entityAge(entity)) (\(deltaTime))")
        stateChange = true
    }
    
    override func registerSystem(_ name :String, system : @escaping System) -> System {
        return { 
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
    
    override func componentAdded(_ entity: Entity, component: Component) {
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
    
    override func componentRemoved(_ entity: Entity, component: Component) {
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
    
    func entityAge(_ e: Entity )->CFAbsoluteTime{
        return CFAbsoluteTimeGetCurrent() - entityCreationTimeDeltas[e.creationIndex]!
    }
    
}
