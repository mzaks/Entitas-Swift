//
//  Matcher.swift
//  Entitas
//
//  Created by Maxim Zaks on 21.12.14.
//  Copyright (c) 2014 Maxim Zaks. All rights reserved.
//

public func == (lhs: Matcher, rhs: Matcher) -> Bool {
    return lhs.componentIds == rhs.componentIds && lhs.type == rhs.type
}

/// Matcher is used to identify if an entity has the desired components.
public struct Matcher : Hashable {
    
    public let componentIds : Set<ComponentId>
    public enum MatcherType{
        case all, any
    }
    
    public let type : MatcherType
    
    public static func all(_ componentIds : ComponentId...) -> Matcher {
        return Matcher(componentIds: componentIds, type: .all)
    }
    
    public static func any(_ componentIds : ComponentId...) -> Matcher {
        
        return Matcher(componentIds: componentIds, type: .any)
    }
    
    init(componentIds : [ComponentId], type : MatcherType) {
        self.componentIds = Set(componentIds)
        self.type = type
    }
    
    public func isMatching(_ entity : Entity) -> Bool {
        switch type {
        case .all : return isAllMatching(entity)
        case .any : return isAnyMatching(entity)
        }
    }
    
    func isAllMatching(_ entity : Entity) -> Bool {
        for cid in componentIds {
            if(!entity.hasComponent(cid)){
                return false
            }
        }
        return true
    }
    
    func isAnyMatching(_ entity : Entity) -> Bool {
        for cid in componentIds {
            if(entity.hasComponent(cid)){
                return true
            }
        }
        return false
    }
    
    public var hashValue: Int {
        get {
            return componentIds.hashValue
        }
    }
    
}

func allOf(_ componentIds : ComponentId...) -> AllOfMatcher {
    return AllOfMatcher(allOf: Set(componentIds))
}

func anyOf(_ componentIds : ComponentId...) -> AnyOfMatcher {
    return AnyOfMatcher(allOf: [], anyOf: Set(componentIds))
}


public protocol _Matcher : Hashable {
    func isMatching(_ entity : Entity) -> Bool
}

public func == (lhs: AllOfMatcher, rhs: AllOfMatcher) -> Bool {
    return lhs.allOf == rhs.allOf
}

public struct AllOfMatcher : _Matcher {
    
    fileprivate let allOf : Set<ComponentId>
    
    fileprivate init(allOf : Set<ComponentId>){
        self.allOf = allOf
    }
    
    public func anyOf(_ componentIds : ComponentId...) -> AnyOfMatcher {
        return AnyOfMatcher(allOf: self.allOf, anyOf: Set(componentIds))
    }
    
    public func noneOf(_ componentIds : ComponentId...) -> NoneOfMatcher {
        return NoneOfMatcher(allOf: self.allOf, anyOf: [], noneOf: Set(componentIds))
    }
    
    public func isMatching(_ entity: Entity) -> Bool {
        return isAllMatching(entity, componentIds: allOf)
    }
    
    public var hashValue: Int {
        return allOf.hashValue
    }
}

public func == (lhs: AnyOfMatcher, rhs: AnyOfMatcher) -> Bool {
    return lhs.allOf == rhs.allOf && lhs.anyOf == rhs.anyOf
}

public struct AnyOfMatcher : _Matcher {
    
    fileprivate let allOf : Set<ComponentId>
    fileprivate let anyOf : Set<ComponentId>
    
    fileprivate init(allOf : Set<ComponentId>, anyOf : Set<ComponentId>){
        self.allOf = allOf
        self.anyOf = anyOf
    }
    
    public func noneOf(_ componentIds : ComponentId...) -> NoneOfMatcher {
        return NoneOfMatcher(allOf: self.allOf, anyOf: self.anyOf, noneOf: Set(componentIds))
    }
    
    public func isMatching(_ entity: Entity) -> Bool {
        return isAllMatching(entity, componentIds: allOf) && isAnyMatching(entity, componentIds: anyOf)
    }
    
    public var hashValue: Int {
        return allOf.hashValue ^ anyOf.hashValue
    }
}

public func == (lhs: NoneOfMatcher, rhs: NoneOfMatcher) -> Bool {
    return lhs.allOf == rhs.allOf && lhs.anyOf == rhs.anyOf && lhs.noneOf == rhs.noneOf
}

public struct NoneOfMatcher : _Matcher {
    fileprivate let allOf : Set<ComponentId>
    fileprivate let anyOf : Set<ComponentId>
    fileprivate let noneOf : Set<ComponentId>
    
    fileprivate init(allOf : Set<ComponentId>, anyOf : Set<ComponentId>, noneOf : Set<ComponentId>){
        self.allOf = allOf
        self.anyOf = anyOf
        self.noneOf = noneOf
    }
    
    public func isMatching(_ entity: Entity) -> Bool {
        return isAllMatching(entity, componentIds: allOf) && isAnyMatching(entity, componentIds: anyOf) && isNoneMatching(entity, componentIds: noneOf)
    }
    
    public var hashValue: Int {
        return allOf.hashValue ^ anyOf.hashValue ^ noneOf.hashValue
    }
}

private func isAllMatching(_ entity : Entity, componentIds : Set<ComponentId>) -> Bool {
    if componentIds.isEmpty {
        return true
    }
    for cid in componentIds {
        if(!entity.hasComponent(cid)){
            return false
        }
    }
    return true
}

private func isAnyMatching(_ entity : Entity, componentIds : Set<ComponentId>) -> Bool {
    if componentIds.isEmpty {
        return true
    }
    
    for cid in componentIds {
        if(entity.hasComponent(cid)){
            return true
        }
    }
    return false
}

private func isNoneMatching(_ entity : Entity, componentIds : Set<ComponentId>) -> Bool {
    for cid in componentIds {
        if(entity.hasComponent(cid)){
            return false
        }
    }
    return true
}
