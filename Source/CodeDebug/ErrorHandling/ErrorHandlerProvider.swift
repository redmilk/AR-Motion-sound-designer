//
//  ErrorHandlerProvidable.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 07.12.2021.
//

import Foundation

protocol ErrorHandlerProvider {
    @discardableResult
    func handleError(_ error: Error) -> (error: JiggleError, message: String)
}

extension ErrorHandlerProvider {
    @discardableResult
    func handleError(_ error: Error) -> (error: JiggleError, message: String) {
        guard let customError = error as? JiggleError else {
            let errorMessage = JiggleError.undefined(error).errorMessage
            Logger.log(errorMessage, type: .errorDescription)
            return (error: JiggleError.undefined(error), message: errorMessage)
        }
        let errorMessage = customError.errorMessage
        Logger.log(errorMessage, type: .errorDescription)
        return (error: customError, message: errorMessage)
    }
}
