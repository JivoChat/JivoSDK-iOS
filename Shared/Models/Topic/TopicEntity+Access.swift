//
//  TopicEntity+Access.swift
//  App
//

import Foundation

extension TopicEntity {
    var id: Int {
        return Int(m_id)
    }
    
    var title: String {
        return m_title.jv_orEmpty
    }
    
    var createdAt: Date {
        return m_created_at ?? .distantPast
    }
    
    var parent: TopicEntity? {
        return m_parent
    }
    
    func jv_constructPath(includingSelf: Bool) -> [TopicEntity] {
        let parentPath = parent?.jv_constructPath(includingSelf: true) ?? .jv_empty
        let selfPath = includingSelf ? [self] : .jv_empty
        return parentPath + selfPath
    }
}
