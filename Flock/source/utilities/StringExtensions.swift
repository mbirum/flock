
import Foundation

extension String {
   subscript(_ characterIndex: Int) -> Character {
      return self[index(startIndex, offsetBy: characterIndex)]
   }
}
