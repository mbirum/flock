
import Foundation

class OptimizationContext {
    var type: OptimizationType
    
    init(type: OptimizationType) {
        self.type = type
    }
    
    func isSuggestedType() -> Bool {
        return self.type == .suggested
    }
    
    func isSpecifiedType() -> Bool {
        return self.type == .specified
    }
}

enum OptimizationType {
    case suggested
    case specified
}
