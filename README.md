# 🔴 This Repository is deprecated!!!

New version can be found here:
https://github.com/mzaks/EntitasKit

---


# Entitas
Entity System Lib implemented in Swift

# Overview
```
+------------------+
|     Context      |
|------------------|
|    e       e     |      +-----------+
|        e     e---|----> |  Entity   |
|  e        e      |      |-----------|
|     e  e       e |      | Component |
| e            e   |      |           |      +-----------+
|    e     e       |      | Component-|----> | Component |
|  e    e     e    |      |           |      |-----------|
|    e      e    e |      | Component |      |   Data    |
+------------------+      +-----------+      +-----------+
  |
  |
  |     +-------------+  Groups:
  |     |      e      |  Subsets of entities
  |     |   e     e   |  for blazing fast querying
  +---> |        +------------+
        |     e  |    |       |
        |  e     | e  |  e    |
        +--------|----+    e  |
                 |     e      |
                 |  e     e   |
                 +------------+
```
# Different language?
Entitas is also available in
- [C#](https://github.com/sschmid/Entitas-CSharp)
- [Objective-C](https://github.com/wooga/entitas)
- [Clojure](https://github.com/mhaemmerle/entitas-clj)
- [Haskell](https://github.com/mhaemmerle/entitas-haskell)
- [Erlang](https://github.com/mhaemmerle/entitas_erl)
- [Go](https://github.com/wooga/go-entitas)
