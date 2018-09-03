//: try!Swift NYC 2018
/// Pre-conference Workshops
/// Function Composition with Stephen Celis

import UIKit

// Basic functions
func incr(_ x: Int) -> Int {
    return x + 1
}

func square(_ x: Int) -> Int {
    return x * x
}

// Not very readable
let incrThenSquare = { square(incr($0)) }

// Let's compose a new operator to do this
precedencegroup FunctionalApplication {
    associativity: left
    higherThan: AssignmentPrecedence
}

infix operator |>: FunctionalApplication

func |> <A, B>(_ lhs: A, _ rhs: (A) -> B) -> B {
    return rhs(lhs)
}

3 |> incr |> square

// And another operator to do some composition
precedencegroup FunctionComposition {
    associativity: left
    higherThan: FunctionalApplication
}

infix operator >>>: FunctionComposition

func >>> <A, B, C>(_ lhs: @escaping (A) -> B, _ rhs: @escaping (B) -> C) -> (A) -> C {
    return { rhs(lhs($0)) }
}

// And then try it out
let coolIncrThenSquare = incr >>> square

2 |> coolIncrThenSquare
(1...10).map(coolIncrThenSquare) // Same as the line below ↙️
(1...10).map(incr >>> square) // Same as above line ↖️

// CHALLENGE: recreate `map` as a free function
func mapGenerator<A, B>(_ f: @escaping(A) -> B) -> (([A]) -> [B]) {
    return { $0.map(f) } // Kinda cheating 😁
}

let mapInts = mapGenerator(incr >>> square)

mapInts(Array(0...10))

// Cool, let's do `filter`
func filterGenerator<A>(_ f: @escaping (A) -> Bool) -> ([A]) -> [A] {
    return { $0.filter(f) }
}

let filterEven = filterGenerator({ $0 % 2 == 0 })

filterEven(Array(0...10))

// Then mix n match!
let superAwesomeFunction = mapInts >>> filterEven
let isEven = { $0 % 2 == 0 }
Array(0...20) |> mapInts >>> filterGenerator(isEven)


// Moving on...
let pair = (42, "Hello World!")

func incrFirst(_ pair: (Int, String)) -> (Int, String) {
    return (incr(pair.0), pair.1)
}

incrFirst(pair)

func mapPairGenerator1<A, B, C>(_ f: @escaping (A) -> B) -> ((A, C)) -> (B, C) {
    return { (f($0.0), $0.1) }
}

func mapPairGenerator2<A, B, C>(_ f: @escaping (A) -> B) -> ((C, A)) -> (C, B) {
    return { ($0.0, f($0.1)) }
}

// Let's try something with Tuples, because we all love Tuples
let nested = ("Hello", (42, "World")) // How can we compose a function to increament the `42` in there?

nested |> (mapPairGenerator1 >>> mapPairGenerator2)(incr) // cool, but reads right to left 😞

// Let's add another operator
infix operator <<<: FunctionComposition

func <<< <A, B, C>(_ lhs: @escaping (B) -> C, _ rhs: @escaping (A) -> B) -> (A) -> C {
    return { lhs(rhs($0)) }
}

nested |> (mapPairGenerator2 <<< mapPairGenerator1)(incr) // Slightly more readable ✌️

// Moving on to more advanced composition (using Keypaths)
struct User {
    var name: String
    var location: String
    var age: Int
}

var user = User(name: "John Doe", location: "NYC", age: 59)

// Keypath refresher:
user[keyPath: \User.name] = "Jane Doe"

// Ok, it's hitting the fan!
func propertySetterGenerator<R, V>(keyPath: WritableKeyPath<R, V>) -> (@escaping (V) -> V) -> ((R) -> R) {
    return { transform in
        return { r in
            var root = r
            root[keyPath: keyPath] = transform(root[keyPath: keyPath])
            return root
        }
    }
}

let userAgeSetter = propertySetterGenerator(keyPath: \User.age)
let userAgeIncreamenter = userAgeSetter(incr)

let userNameSetter = propertySetterGenerator(keyPath: \User.name)
let userNameScreamer = userNameSetter({ $0.uppercased() })

let superDuperUserFunc = userNameScreamer <<< userAgeIncreamenter // Don't freak out; with or without KeyPaths, these are still 2x single argument funcitons that we can compose using our heavy-duty new operator, so we're composing them!
let superedDuperedUser = superDuperUserFunc(user) // Note that `user`'s age is 59, and name is `Jane Doe`

superedDuperedUser.name // Ladies & Gents: JANE DOE ...
superedDuperedUser.age // ... is now 60! 🕺💃
