
typealias StorablesFactory = (Int)->Storable

protocol Storable {
    var age: Int { get }
    static var name: String { get }
    init(age: Int)
    func resolve(with other:Storable) -> Self
}

extension Storable {
    func resolve(with other:Storable) -> Self {
        return self
    }
}

struct Person: Storable, Equatable {
    var age: Int = 0
    init(age: Int) {
        self.age = age
    }
    static var name: String { return "Person" }
}

struct Child: Storable, Equatable {
    let age: Int = 0
    init(age: Int) {
    }
    static var name: String { return "Child" }
}

func == (left: Person, right: Person) -> Bool {
    return left.age == right.age
}

func == (left: Child, right: Child) -> Bool {
    return left.age == right.age
}

class Storage {
    var factoryForName = [String:StorablesFactory]()

    func register(type:Storable.Type) {
        factoryForName[type.name] = type.init
    }
    
    func makeValue(forTypeName type: String, age: Int) -> Storable {
        return factoryForName[type]!(age)
    }
}

let storage = Storage()
storage.register(type: Person.self)
storage.register(type: Child.self)

var p = storage.makeValue(forTypeName: "Person", age: 20)
p.age

var c = storage.makeValue(forTypeName: "Child", age: 1)
c.age
