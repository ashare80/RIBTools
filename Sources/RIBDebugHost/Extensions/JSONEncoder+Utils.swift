//
//  JSONEncoder+Utils.swift
//  
//
//  Created by Adam Share on 8/12/20.
//

import Foundation

extension JSONEncoder {
    func encodeString<T>(_ value: T?, encoding: String.Encoding = .utf8) -> String? where T : Encodable {
        guard let value = value,
            let data = try? encode(value) else { return nil }
        return String(data: data, encoding: encoding)
    }
}
