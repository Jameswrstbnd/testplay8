import Foundation
import UIKit

extension NSAttributedString {
    func heightWithConstrainedWidth(_ width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)

        return ceil(boundingBox.height)
    }

    func widthWithConstrainedHeight(_ height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)

        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)

        return ceil(boundingBox.width)
    }
}

extension String {
    func heightWithConstrainedWidth(_ width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)

        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return boundingBox.height
    }

    func widthWithConstrainedHeight(_ height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)

        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return boundingBox.width
    }

    // MARK: - sub String
    func substringToIndex(_ index:Int) -> String {
        let start = self.index(startIndex, offsetBy: index)
        return String(self[..<start])
    }
    func substringFromIndex(_ index:Int) -> String {
        let start = self.index(startIndex, offsetBy: index)
        return String(self[start...])
    }
    func substringWithRange(_ range:Range<Int>) -> String {
        let start = self.index(self.startIndex, offsetBy: range.lowerBound)
        let end = self.index(self.startIndex, offsetBy: range.upperBound)
        return String(self[start...end])
    }
    
    subscript(index:Int) -> Character{
        return self[self.index(self.startIndex, offsetBy: index)]
    }
    subscript(range:Range<Int>) -> String {
        let start = self.index(self.startIndex, offsetBy: range.lowerBound)
        let end = self.index(self.startIndex, offsetBy: range.upperBound)
        return String(self[start..<end])
    }
    
    
    // MARK: - replace
    func replaceCharactersInRange(_ range:Range<Int>, withString: String!) -> String {
        let result:NSMutableString = NSMutableString(string: self)
        result.replaceCharacters(in: NSRange(range), with: withString)
        return result as String
    }
    
    func length() -> Int {
        return self.count
    }
    
    func masked (_ start: Int, end: Int) -> String {
        let len = self.length()
        var s = self.substringToIndex(start)
        for _ in 1...(len-(start+end)) {
            s += "*"
        }
        s += self.substringFromIndex(len-end)
        
        return s
    }

    /// Create `Data` from hexadecimal string representation
    ///
    /// This takes a hexadecimal representation and creates a `Data` object. Note, if the string has any spaces or non-hex characters (e.g. starts with '<' and with a '>'), those are ignored and only hex characters are processed.
    ///
    /// - returns: Data represented by this hexadecimal string.

    func dataFromHexadecimalString() -> Data? {
        var data = Data(capacity: self.count / 2)

        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, options: [], range: NSMakeRange(0, self.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }

        return data
    }

    func hexIntValue() -> UInt64 {
        guard let data = self.dataFromHexadecimalString() else { return 0 }

        var r: UInt64 = 0
        for b in data {
            r <<= 8
            r |= UInt64(b)
        }

        return r
    }
}

extension Date {
    var year: Int {
        return NSCalendar.current.component(.year, from: self)
    }
    var month: Int {
        return NSCalendar.current.component(.month, from: self)
    }
    var day: Int {
        return NSCalendar.current.component(.day, from: self)
    }
    var hour: Int {
        return NSCalendar.current.component(.hour, from: self)
    }
    var minute: Int {
        return NSCalendar.current.component(.minute, from: self)
    }
    var second: Int {
        return NSCalendar.current.component(.second, from: self)
    }

    public func toString(_ dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style, relativeDate: Bool = false) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = dateStyle
        dateFormatter.timeStyle = timeStyle
        dateFormatter.doesRelativeDateFormatting = relativeDate
        return dateFormatter.string(from: self)
    }
}


extension Data {

    /// Create hexadecimal string representation of `Data` object.
    ///
    /// - returns: `String` representation of this `Data` object.

    func toHexString() -> String {
        return map { String(format: "%02x", $0) }
            .joined(separator: "")
    }
    
    func getBytes() -> [UInt8]! {
        // create array of appropriate length:
        var array = [UInt8](repeating: 0, count: self.count)
        
        // copy bytes into array
        (self as NSData).getBytes(&array, length:self.count)
        
        return array
    }
}


extension NSData {

    /// Create hexadecimal string representation of `Data` object.
    ///
    /// - returns: `String` representation of this `Data` object.

    func toHexString() -> String {
        return (self as Data).toHexString();
    }

    func getBytes() -> [UInt8]! {
        return (self as Data).getBytes();
    }
}


extension Sequence where Iterator.Element == UInt8 {
    func someMessage(){
        print("UInt8 Array")
    }
}


extension Array {
    func subArray(_ start: Int, end: Int) -> [Element] {
        var r = [Element]()
        for i in 0..<end {
            r.append(self[start+i])
        }
        return r
    }
    
    func toHexString() -> String {
        
        let string = NSMutableString(capacity: count * 2)
        
        if self.first is UInt8 {
            var byteArray = self.map { $0 as! UInt8 }
            for i in 0 ..< count {
                string.appendFormat("%02X", byteArray[i])
            }
        }
        return string as String
    }
    
    func getNSData() -> Data {
        let data = Data(buffer: UnsafeBufferPointer(start: self, count: self.count))

        return data
    }
    
}

extension Float {
    func format(_ f: String) -> String {
        return NSString(format: "%\(f)f" as NSString, self) as String
    }
}

extension Int {
    func format(_ f: String) -> String {
        return NSString(format: "%\(f)d" as NSString, self) as String
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}

extension UIImage {
    static func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0);
        UIGraphicsBeginImageContext(rect.size);
        let context = UIGraphicsGetCurrentContext();

        context?.setFillColor(color.cgColor);
        context?.fill(rect);

        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return image!;
    }
}

extension String {
    func stringByAppendingPathComponent(_ path: String) -> String {
        let nsSt = self as NSString
        return nsSt.appendingPathComponent(path)
    }
}

extension UIViewController {
    static var alert: UIAlertController? = nil

    func showMessage(_ title: String, message: String)
    {
        DispatchQueue.main.async {
            if UIViewController.alert != nil {
                UIViewController.alert?.dismiss(animated: false, completion: nil)
                UIViewController.alert = nil
            }

            UIViewController.alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)

            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                (result : UIAlertAction) -> Void in
                print("OK")
            }

            UIViewController.alert!.addAction(okAction)
            self.present(UIViewController.alert!, animated: true, completion: nil)
        }
    }

    func showError(_ operation: String, error: NSError?)
    {
        if (error != nil)
        {
            showMessage("Error", message: "\(operation) failed with error: \(error!.localizedDescription)!")
        }else
        {
            showMessage("Error", message: "\(operation) failed!")
        }
    }

}

extension UIViewController {
    class func instantiateFromStoryboard(_ name: String = "Main") -> Self {
        return instantiateFromStoryboardHelper(name)
    }

    fileprivate class func instantiateFromStoryboardHelper<T>(_ name: String) -> T {
        let storyboard = UIStoryboard(name: name, bundle: nil)
        let identifier = String(describing: self)
        let controller = storyboard.instantiateViewController(withIdentifier: identifier) as! T
        return controller
    }
}

extension UIStoryboard {
    func instantiateVC<T: UIViewController>() -> T? {
        // get a class name and demangle for classes in Swift
        if let name = NSStringFromClass(T.self).components(separatedBy: ".").last {
            return instantiateViewController(withIdentifier: name) as? T
        }
        return nil
    }
}

class Utils: NSObject {
    
}
