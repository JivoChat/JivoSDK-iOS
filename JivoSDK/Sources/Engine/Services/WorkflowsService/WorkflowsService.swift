//
//  WorkflowsService.swift
//  JivoSDK
//
//  Created by Anton Karpushko on 20.11.2020.
//  Copyright © 2020 jivosite.mobile. All rights reserved.
//

import Foundation

protocol IWorkflowsService {
    func scheduleWorkflow(_ workflow: AnyWorkflow) -> AnyWorkflow?
}

class WorkflowsService: IWorkflowsService {
    
    // MARK: - Private properties
    
    private let workflowsQueue = OperationQueue()
    
    // MARK: - Init
    
    init() {
        workflowsQueue.maxConcurrentOperationCount = 1
    }
    
    // MARK: - Public methods
    
    func scheduleWorkflow(_ workflow: AnyWorkflow) -> AnyWorkflow? {
        for operation in workflowsQueue.operations {
            guard let w = operation as? AnyWorkflow else {
                operation.cancel()
                assertionFailure()
                continue
            }
            
            guard w.type == workflow.type else {
                continue
            }
            
            if w.isExecuting {
                return w
            }
            else {
                w.cancel()
                break
            }
        }
        
        if let operation = workflow as? Operation {
            workflowsQueue.addOperation(operation)
        }
        
        return workflow
    }
}
