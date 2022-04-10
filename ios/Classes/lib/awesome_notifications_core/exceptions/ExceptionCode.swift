public enum ExceptionCode {

    static let CODE_UNKNOWN_EXCEPTION = "UNKNOWN_EXCEPTION"
    static let CODE_INITIALIZATION_EXCEPTION = "INITIALIZATION_EXCEPTION"
    static let CODE_MISSING_ARGUMENTS = "MISSING_ARGUMENTS"
    static let CODE_INVALID_ARGUMENTS = "INVALID_ARGUMENTS"
    static let CODE_INSUFFICIENT_PERMISSIONS = "INSUFFICIENT_PERMISSIONS"
    static let CODE_SHARED_PREFERENCES_NOT_AVAILABLE = "SHARED_PREFERENCES_NOT_AVAILABLE"
    static let CODE_INVALID_IMAGE = "INVALID_IMAGE"
    static let CODE_CLASS_NOT_FOUND = "CLASS_NOT_FOUND"
    static let CODE_BACKGROUND_EXECUTION_EXCEPTION = "BACKGROUND_EXECUTION_EXCEPTION"
    static let CODE_NOTIFICATION_THREAD_EXCEPTION = "NOTIFICATION_THREAD_EXCEPTION"
    static let CODE_PAGE_NOT_FOUND = "PAGE_NOT_FOUND"
    static let CODE_EVENT_EXCEPTION = "EVENT_EXCEPTION"

    static let DETAILED_UNEXPECTED_ERROR = "unexpectedError"
    static let DETAILED_REQUIRED_ARGUMENTS = "arguments.required"
    static let DETAILED_CLASS_NOT_FOUND = "class.notFound"
    static let DETAILED_INVALID_ARGUMENTS = "arguments.invalid"
    static let DETAILED_PAGE_NOT_FOUND = "pageNotFound"
    static let DETAILED_INITIALIZATION_FAILED = "initialization"
    static let DETAILED_SHARED_PREFERENCES = "sharedPreferences"
    static let DETAILED_INSUFFICIENT_PERMISSIONS = "insufficientPermissions"
    static let DETAILED_INSUFFICIENT_REQUIREMENTS = "insufficientRequirements"
}