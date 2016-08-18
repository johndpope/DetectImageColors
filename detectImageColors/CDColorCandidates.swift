import Cocoa

public struct ColorCandidates {
    public var primary: NSColor?
    public var secondary: NSColor?
    public var detail: NSColor?
    public var background: NSColor?
    public var backgroundIsDark: Bool?
    public var backgroundIsBlackOrWhite: Bool?
    
    public var JSONData: Data {
        return try! JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
    }
    
    private var dictionary: [String : [String : AnyObject]] {
        guard let primary = getRGBColor(from: self.primary),
            let alternative = getRGBColor(from: self.secondary),
            let detail = getRGBColor(from: self.detail),
            let background = getRGBColor(from: self.background) else {
                return [:]
        }
        var dic = [String:[String:AnyObject]]()
        dic["main"] = getDictionaryComponents(for: primary)
        dic["alternative"] = getDictionaryComponents(for: alternative)
        dic["detail"] = getDictionaryComponents(for: detail)
        dic["background"] = getDictionaryComponents(for: background)
        dic["settings"] = getDictionarySettings()
        return dic
    }
    
    private func getRGBColor(from color: NSColor?) -> NSColor? {
        return color?.usingColorSpaceName(NSCalibratedRGBColorSpace)
    }
    
    private func getDictionaryComponents(for color: NSColor) -> [String:AnyObject] {
        return ["red": color.redComponent as AnyObject,
                "green": color.greenComponent as AnyObject,
                "blue": color.blueComponent as AnyObject,
                "css": color.componentsCSS()!.css as AnyObject]
    }
    
    private func getDictionarySettings() -> [String:AnyObject] {
        return ["EnsureContrastedColorCandidates": CDSettings.ensureContrastedColorCandidates as AnyObject,
                "ThresholdDistinctColor": CDSettings.thresholdDistinctColor as AnyObject,
                "ContrastRatio": CDSettings.contrastRatio as AnyObject,
                "ThresholdNoiseTolerance": CDSettings.thresholdNoiseTolerance as AnyObject,
                "ThresholdFloorBrightness": CDSettings.thresholdFloorBrightness as AnyObject,
                "ThresholdMinimumSaturation": CDSettings.thresholdMinimumSaturation as AnyObject]
    }
}
