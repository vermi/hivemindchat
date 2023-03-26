import UIKit

class JSONActivityItemSource: NSObject, UIActivityItemSource {
    let jsonFilename: String
    let jsonData: Data

    init(jsonFilename: String, jsonData: Data) {
        self.jsonFilename = jsonFilename
        self.jsonData = jsonData
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return jsonData
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return jsonData
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return jsonFilename
    }

    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "public.json"
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, filenameForActivityType activityType: UIActivity.ActivityType?) -> String {
        return jsonFilename
    }
}
