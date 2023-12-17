//
// Copyright (c) Vatsal Manot
//

import Foundation
@_spi(Internal) import Swallow

protocol _UnsafeSerializationRepresentable {
    associatedtype _UnsafeSerializationRepresentation: Codable & Hashable
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation { get throws }
    
    init(_unsafeSerializationRepresentation: _UnsafeSerializationRepresentation) throws
}

// MARK: - Extensions

extension _UnsafeSerializationRepresentable {
    static var _opaque_UnsafeSerializationRepresentation: Codable.Type {
        _UnsafeSerializationRepresentation.self
    }
    
    static func _opaque_decodeThroughUnsafeSerializationRepresentation(
        from decoder: Decoder
    ) throws -> Self {
        try Self(_unsafeSerializationRepresentation: try _UnsafeSerializationRepresentation(from: decoder))
    }
    
    static func _opaque_decodeUnsafeSerializationRepresentation(
        from decoder: Decoder
    ) throws -> _UnsafeSerializationRepresentation {
        try _UnsafeSerializationRepresentation(from: decoder)
    }
    
    init(_opaque_unsafeSerializationRepresentation x: Any) throws {
        try self.init(_unsafeSerializationRepresentation: try cast(x))
    }
}

// MARK: - Implemented Conformances

extension HeterogeneousDictionary: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = [_UnsafelySerializedKeyValuePair]
    
    public struct _UnsafelySerializedKeyValuePair: Hashable, Codable {
        public enum CodingKeys: String, CodingKey {
            case key
            case value
        }
        
        @_UnsafelySerialized
        public var key: any HeterogeneousDictionaryKey.Type
        @_UnsafelySerialized
        public var value: Any
        
        public init(
            key: any HeterogeneousDictionaryKey.Type,
            value: Any
        ) {
            self.key = key
            self.value = value
        }
        
        public init<T>(
            key: AnyHeterogeneousDictionaryKey,
            value: T
        ) throws {
            self.key = try cast(key.base)
            self.value = value
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self._key = try container.decode(forKey: .key)
            
            func decodeValue<Value>(_: Value.Type) throws -> Any {
                try container.decode(_UnsafelySerialized<Value>.self, forKey: .value).wrappedValue
            }
            
            self.value = try _openExistential(_key.wrappedValue._opaque_Value.self, do: decodeValue)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(_key, forKey: .key)
            try container.encode(_value, forKey: .value)
        }
    }

    var _unsafeSerializationRepresentation: [_UnsafelySerializedKeyValuePair] {
        get throws {
            try map {
                try _UnsafelySerializedKeyValuePair(key: $0.key, value: $0.value)
            }
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: [_UnsafelySerializedKeyValuePair]
    ) throws {
        self.init(_unsafeStorage: representation._mapToDictionary(
            key: {
                AnyHeterogeneousDictionaryKey(base: $0.key)
            },
            value: {
                $0.value
            }
        ))
    }
}

extension Array: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = [_TypeSerializingAnyCodable]
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            try map({ try _TypeSerializingAnyCodable($0) })
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: _UnsafeSerializationRepresentation
    ) throws {
        self = try representation.lazy.map({ try $0.decode(Element.self) })
    }
}

extension _BagOfExistentials: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = Array<_TypeSerializingAnyCodable>
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            try map({ try _TypeSerializingAnyCodable($0) })
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: _UnsafeSerializationRepresentation
    ) throws {
        try self.init(representation.map({ try $0.decode(Element.self) }))
    }
}

extension Dictionary: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = [_TypeSerializingAnyCodable: _TypeSerializingAnyCodable]
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            try mapKeysAndValues(
                { try _TypeSerializingAnyCodable($0) },
                { try _TypeSerializingAnyCodable($0) }
            )
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: _UnsafeSerializationRepresentation
    ) throws {
        self = try representation.mapKeysAndValues(
            { try $0.decode(Key.self) },
            { try $0.decode(Value.self) }
        )
    }
}

extension _ExistentialSet: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = Set<_TypeSerializingAnyCodable>
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            try Set(lazy.map({ try _TypeSerializingAnyCodable($0) }))
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: _UnsafeSerializationRepresentation
    ) throws {
        try self.init(representation.map({ try $0.decode(Element.self) }))
    }
}

extension _HashableExistentialArray: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = Array<_TypeSerializingAnyCodable>
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            try map({ try _TypeSerializingAnyCodable($0) })
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: _UnsafeSerializationRepresentation
    ) throws {
        try self.init(representation.map({ try $0.decode(Element.self) }))
    }
}

extension IdentifierIndexingArray: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = Array<_TypeSerializingAnyCodable>

    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            try map({ try _TypeSerializingAnyCodable($0) })
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: _UnsafeSerializationRepresentation
    ) throws {
        throw Never.Reason.unavailable
    }
}

extension Optional: _UnsafeSerializationRepresentable where Wrapped: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = Optional<Wrapped._UnsafeSerializationRepresentation>
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            try map({ try $0._unsafeSerializationRepresentation })
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: _UnsafeSerializationRepresentation
    ) throws {
        self = try representation.map({ try Wrapped(_unsafeSerializationRepresentation: $0) })
    }
}

extension Result: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = Result<_TypeSerializingAnyCodable, Erroneous<_TypeSerializingAnyCodable>>._CodableRepresentation
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            try .init(
                from: self
                    .mapSuccess({ try _TypeSerializingAnyCodable($0) })
                    .mapFailure({ try Erroneous(_TypeSerializingAnyCodable($0)) })
            )
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: _UnsafeSerializationRepresentation
    ) throws {
        self = try Result<_TypeSerializingAnyCodable, Erroneous<_TypeSerializingAnyCodable>>(representation)
            .mapSuccess({ try $0.decode(Success.self) })
            .mapFailure({ try $0.value.decode(Failure.self) })
    }
}

extension Set: _UnsafeSerializationRepresentable {
    typealias _UnsafeSerializationRepresentation = Set<_TypeSerializingAnyCodable>
    
    var _unsafeSerializationRepresentation: _UnsafeSerializationRepresentation {
        get throws {
            try .init(lazy.map({ try _TypeSerializingAnyCodable($0) }))
        }
    }
    
    init(
        _unsafeSerializationRepresentation representation: _UnsafeSerializationRepresentation
    ) throws {
        try self.init(representation.lazy.map({ try $0.decode(Element.self) }))
    }
}
