
import Foundation

class OptimizationRequestQueue {
    var queue: [OptimizationRequest] = []
    
    func clear() -> Void {
        self.queue = []
    }
    
    func isEmpty() -> Bool {
        return self.queue.isEmpty
    }
    
    func pop() -> OptimizationRequest? {
        guard let uFirst = self.queue.first else { return nil }
        self.queue.remove(at: 0)
        return uFirst
    }
    
    func getNext() -> OptimizationRequest? {
        return self.queue.first
    }
    
    func add(_ request: OptimizationRequest) -> Void {
        self.queue.append(request)
    }
}
