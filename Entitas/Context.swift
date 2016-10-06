//
//  Context.swift
//  Entitas
//
//  Created by Maxim Zaks on 21.12.14.
//  Copyright (c) 2014 Maxim Zaks. All rights reserved.
//

typealias System = ()->()

/// Context is the central piece of Entitas framework.
/// It manages the entities and groups of entities, keeping every thing up to date.
open class Context : EntityChangedListener, CustomDebugStringConvertible {
    
    fileprivate var _entities : [Int:Entity] = [:]
    fileprivate var _entityCreationIndex = 0
    fileprivate var _groupLookupByMatcher : [Matcher:Group] = [:]
    fileprivate var _groupsLookupByAnyId : [ComponentId:[Group]] = [:]
    fileprivate var _groupsLookupByAllId : [ComponentId:[Group]] = [:]
    
    /// Simple and empty init method.
    public init(){}
    
    /// Hard resets of context.
    /// Deletes all references to entities and groups.
    /// Sets entity creation index back to 0.
    /// Currently no observer will be notified about the reset.
    open func reset(){
        _entities.removeAll(keepingCapacity: false)
        _entityCreationIndex = 0
        _groupLookupByMatcher.removeAll(keepingCapacity: false)
        _groupsLookupByAnyId.removeAll(keepingCapacity: false)
        _groupsLookupByAllId.removeAll(keepingCapacity: false)
    }
    
    /// The only way for creation of an entity.
    /// This way the entity is managed by the context and gets it creation index.
    /// The entity will communicate every change to the managing context.
    open func createEntity() -> Entity {
        let e = Entity(listener: self, creationIndex: _entityCreationIndex)
        _entities[e.creationIndex] = e
        _entityCreationIndex += 1
        return e
    }
    
    /// The only way to get a group. The groups are cached so if you will call this method with the same matcher multiple times you will get the same instance of the group.
    open func entityGroup(_ matcher : Matcher) -> Group {
        if let group = _groupLookupByMatcher[matcher] {
            return group
        }
        
        let group = Group(matcher: matcher)
        _groupLookupByMatcher[matcher] = group;
        fillGroupWithEntities(group)
        
        switch group.matcher.type{
        case .any : addGroupToLoockupByAnyId(group)
        case .all : addGroupToLoockupByAllId(group)
        }
        
        return group
    }
    
    /// When you destroy an entity, the entity will remove all its components and by that it will also leave all the groups accordingly.
    /// It will inform observers that it was destroyed.
    /// Be caution about destroying entities. Most of the time flagging an entity with a component can do the job and is more appropriate according to data consistency.
    open func destroyEntity(_ entity : Entity) {
        _entities.removeValue(forKey: entity.creationIndex)
        entity.removeAllComponents()
    }
    
    /// Register system if you want it to appear in debug context
    func registerSystem(_ name :String, system : @escaping System) -> System {
        return system
    }
    
    
    func fillGroupWithEntities(_ group : Group){
        for e in _entities.values {
            if group.matcher.isMatching(e){
                group.addEntity(e)
            }
        }
    }
    
    func addGroupToLoockupByAnyId(_ group : Group) {
        for cid in group.matcher.componentIds {
            var groups : [Group] = []
            if let _groups = _groupsLookupByAnyId[cid]{
                groups = _groups
            }
            
            groups.append(group)
            _groupsLookupByAnyId[cid] = groups
        }
    }
    
    func addGroupToLoockupByAllId(_ group : Group) {
        for cid in group.matcher.componentIds {
            var groups : [Group] = []
            if let _groups = _groupsLookupByAllId[cid]{
                groups = _groups
            }
            
            groups.append(group)
            _groupsLookupByAllId[cid] = groups
        }
    }
        
    func componentAdded(_ entity: Entity, component: Component) {
        
        let componentId = component.cId
        
        if let groups = _groupsLookupByAnyId[componentId]{
            for group in groups{
                group.addEntity(entity)
            }
        }
        if let groups = _groupsLookupByAllId[componentId]{
            for group in groups{
                if group.matcher.isMatching(entity){
                    group.addEntity(entity)
                }
            }
        }
    }
    
    func componentRemoved(_ entity: Entity, component: Component) {
        
        let componentId = component.cId
        
        if let groups = _groupsLookupByAllId[componentId]{
            for group in groups{
                if !group.matcher.isMatching(entity){
                    group.removeEntity(entity, withRemovedComponent: component)
                }
            }
        }
        if let groups = _groupsLookupByAnyId[componentId]{
            for group in groups{
                if !group.matcher.isMatching(entity){
                    group.removeEntity(entity, withRemovedComponent: component)
                }
            }
        }
    }
    
    var numberOfGroups:Int{
        return _groupLookupByMatcher.count
    }
    
    open var debugDescription: String {
        let entities = _entities.values.flatMap({$0.debugDescription})
        
        return entities.joined(separator: "\n")
    }
}
