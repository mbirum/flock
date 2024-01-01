
import Foundation

extension TimeInterval {
    func toString() -> String {
        var string = ""
        let timeInMinutes = self / 60.0
        let timeInHours = timeInMinutes / 60.0
        let days = Int(floor(timeInHours / 24.0))
        let hours = Int(floor(timeInHours.truncatingRemainder(dividingBy: 24)))
        let minutes = Int(floor(timeInMinutes.truncatingRemainder(dividingBy: 60)))
        if days > 0 {
            string += "\(days)d "
        }
        if hours > 0 {
            string += "\(hours)h "
        }
        if minutes > 0 {
            string += "\(minutes)m"
        }
        return string
    }
}
