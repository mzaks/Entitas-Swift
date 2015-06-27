//
//  SampleComponents.swift
//  Entitas
//
//  Created by Maxim Zaks on 08.12.14.
//  Copyright (c) 2014 Maxim Zaks. All rights reserved.
//
import Entitas


struct FlagComponent : Component {}


struct NameComponent : Component {
    let name : String
}

struct AgeComponent : Component {
    let age : Int
}

struct ResourcesComponent : Component {
    let resources : [String: Int]
}

struct PositionComponent : Component {
    let x, y : Int
}
