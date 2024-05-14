//
// Copyright (c) Vatsal Manot
//

import Diagnostics
import Foundation
import Runtime
@_spi(Internal) import Swallow

public struct _TypeSerializingAnyCodable: CustomDebugStringConvertible {
    private enum _Error: Swift.Error {
        case nonNilValueWithNonCodableType(value: Any, type: Any.Type)
        case attemptedToDecodeFromNonCodableType(Any.Type)
        case attemptedToEncodeUnsupportedType(Any.Type)
        case attemptedToDecodeUnsupportedType(Any.Type)
    }
    
    package let declaredTypeRepresentation: _SerializedTypeIdentity?
    package let typeRepresentation: _SerializedTypeIdentity
    package let data: (any Codable)?
    
    public var description: String {
        if let data {
            return String(describing: data)
        } else {
            return "null"
        }
    }
    
    public var debugDescription: String {
        let data = self.data.map({ String(describing: $0) }) ?? "(null)"
        
        return "_TypeSerializingAnyCodable(\(data))"
    }
    
    public init(_data data: any Codable) {
        assert(!(data is _TypeSerializingAnyCodable))
        
        self.declaredTypeRepresentation = nil
        self.typeRepresentation = _SerializedTypeIdentity(of: data)
        self.data = data
    }
    
    public init<T>(
        _ data: T,
        declaredAs declaredType: Any.Type?
    ) throws {
        var data = Optional(_unwrapping: data)
        
        if data is Codable && !(type(of: data) is Codable.Type) {
            data = try _openExistentialAndCast(data, to: Codable.self)
        }
        
        declaredTypeRepresentation = declaredType.map({ _SerializedTypeIdentity(from: $0 )}) ?? _SerializedTypeIdentity(from: T.self)
        typeRepresentation = .init(of: data)
        
        let type = try typeRepresentation.resolveType()
        
        if let data = data {
            if type is Codable.Type {
                self.data = try cast(data, to: Codable.self)
            } else if let data = data as? any _UnsafeSerializationRepresentable {
                self.data = try data._unsafeSerializationRepresentation
            } else {
                throw _Error.nonNilValueWithNonCodableType(value: data, type: type)
            }
        } else {
            self.data = nil
        }
    }
    
    public init<T>(
        _ data: T
    ) throws {
        try self.init(data, declaredAs: nil)
    }
    
    public init<T: Codable>(
        _ data: T
    ) {
        self.init(_data: data)
    }
}

extension _TypeSerializingAnyCodable {
    public func decode<T>(_ type: T.Type = T.self) throws -> T {
        if let type = type as? any _UnwrappableTypeEraser.Type {
            func _decodeAsAny<A>(_ type: A.Type) throws -> Any {
                return try self._decode(type)
            }
            
            let _result: Any = try _openExistential(type._opaque_UnwrappedBaseType, do: _decodeAsAny)
            
            return try cast(type.init(_opaque_erasing: _result), to: T.self)
        } else {
            return try _decode(type)
        }
    }
    
    public func decodeNil() -> Bool {
        if let data {
            if _isValueNil(data) {
                assertionFailure()
                
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
    
    public func decode() throws -> Codable? {
        data
    }
    
    private func _decode<T>(_ type: T.Type = T.self) throws -> T {
        if data == nil, let type = type as? any OptionalProtocol.Type {
            let resolvedType = try typeRepresentation.resolveType()
            
            if _unwrappedType(from: type) == resolvedType {
                return try cast(type.init(nilLiteral: ()), to: T.self)
            }
        }
        
        if let data = data.flatMap({ $0 as? T }) {
            return data
        } else if !(type is any _UnsafeSerializationRepresentable.Type) {
            do {
                return try cast(data, to: type)
            } catch {
                let resolvedType = try typeRepresentation.resolveType()
                
                if (resolvedType is any _UnsafeSerializationRepresentable.Type) {
                    do {
                        return try _attemptStructuralDecode(T.self)
                    } catch(_) {
                        throw error
                    }
                } else {
                    throw error
                }
            }
        } else if let type = type as? any _UnsafeSerializationRepresentable.Type {
            do {
                return try cast(type.init(_opaque_unsafeSerializationRepresentation: data.unwrap()), to: T.self)
            } catch {
                guard data != nil else {
                    throw error
                }
                
                do {
                    return try _attemptStructuralDecode(T.self)
                } catch(_) {
                    throw error
                }
            }
        } else {
            throw _Error.attemptedToDecodeUnsupportedType(type)
        }
    }
    
    private func _attemptStructuralDecode<T>(_ type: T.Type) throws -> T {
        let data = try self.data.unwrap()
        let encoded = try ObjectEncoder().encode(data)
        let decoded = try ObjectDecoder().decode(try cast(type, to: (any Decodable.Type).self), from: encoded)
        
        return try cast(decoded, to: T.self)
    }
}

// MARK: - Conformances

extension _TypeSerializingAnyCodable: Codable {
    public enum CodingKeys: String, CodingKey {
        case declaredTypeRepresentation
        case typeRepresentation
        case data
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.declaredTypeRepresentation = _expectNoThrow {
            try container.decodeIfPresent(
                _SerializedTypeIdentity.self,
                forKey: .declaredTypeRepresentation
            )
        }
        self.typeRepresentation = try container.decode(
            _SerializedTypeIdentity.self,
            forKey: .typeRepresentation
        )
        
        let resolvedDeclaredType: Any.Type? = try? self.declaredTypeRepresentation?.resolveType()
        let resolvedType: Any.Type = try self.typeRepresentation.resolveType()
        
        func decodeData(from type: Any.Type) throws -> (any Codable)? {
            if let dataType = type as? Codable.Type {
                if type == resolvedDeclaredType {
                    let _container = try decoder
                        ._hidingCodingKey(CodingKeys.declaredTypeRepresentation)
                        .container(keyedBy: CodingKeys.self)
                    
                    do {
                        return try _container.decode(dataType, forKey: .data)
                    } catch {
                        return try container.decode(dataType, forKey: .data)
                    }
                } else {
                    return try container.decode(dataType, forKey: .data)
                }
            } else if let type = type as? any _UnsafeSerializationRepresentable.Type {
                return try type._opaque_decodeUnsafeSerializationRepresentation(from: decoder)
            } else if type == Any.self, !container.allKeys.contains(.data) {
                return nil
            } else {
                if try container.decodeNil(forKey: .data) {
                    return nil
                } else {
                    throw _Error.attemptedToDecodeFromNonCodableType(resolvedType)
                }
            }
        }
         
        var data: (any Codable)? = try decodeData(from: resolvedType)
        
        if let resolvedDeclaredType {
            if let _data = data, let declaredType = resolvedDeclaredType as? (any _UnwrappableTypeEraser.Type), let erasedData = try? declaredType.init(_opaque_erasing: _data) as? (any Codable) {
                data = erasedData
            }
        }
        
        self.data = data
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(declaredTypeRepresentation, forKey: .declaredTypeRepresentation)
        try container.encode(typeRepresentation, forKey: .typeRepresentation)
        
        if let data {
            try container.encode(data, forKey: .data)
        }
    }
}

extension _TypeSerializingAnyCodable: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.typeRepresentation == rhs.typeRepresentation else {
            return false
        }
        
        if let lhs = lhs.data as? any Equatable, let rhs = rhs.data as? any Equatable {
            return lhs.eraseToAnyEquatable() == rhs.eraseToAnyEquatable()
        } else {
            return lhs.data.map({ AnyCodable($0) }) == rhs.data.map({ AnyCodable($0) } )
        }
    }
}

extension _TypeSerializingAnyCodable: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(typeRepresentation)
        
        if let data = data as? any Hashable {
            hasher.combine(data)
        } else {
            hasher.combine(data.map({ AnyCodable(lazy: $0) }))
        }
    }
}
