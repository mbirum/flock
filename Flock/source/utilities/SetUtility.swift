
import Foundation
import SwiftUI

class SetUtility {
    
    static func isSetComplete<T>(set: Set<T>, referenceSet: Set<T>, exception: T) -> Bool {
        return areSetsComplete(set1: set, set2: Set<T>(), referenceSet: referenceSet, exception: exception)
    }
    
    static func doSetsOverlap<T>(set1: Set<T>, set2: Set<T>, exception: T) -> Bool {
        for val1 in set1 {
            for val2 in set2 {
                if val1 == exception && val2 == exception {
                    continue
                }
                if val1 == val2 {
                    return true
                }
            }
        }
        return false
    }
    
    static func areSetsComplete<T>(set1: Set<T>, set2: Set<T>, referenceSet: Set<T>, exception: T) -> Bool {
        // sets cant share values
        if doSetsOverlap(set1: set1, set2: set2, exception: exception) {
            return false
        }
        
        var combinedSet: Set<T> = Set()
        for val1 in set1 { combinedSet.insert(val1) }
        for val2 in set2 { combinedSet.insert(val2) }
        
        // combined set has to match reference set
        if combinedSet.count != referenceSet.count {
            return false
        }
        
        // each value in reference has to be found in combined set
        for ref in referenceSet {
            var found = false
            for val in combinedSet {
                if val == ref {
                    found = true
                    break
                }
            }
            if !found {
                return false
            }
        }
        
        return true
    }

}
