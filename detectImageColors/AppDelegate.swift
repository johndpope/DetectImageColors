//
//  AppDelegate.swift
//  detectImageColors

// DEMO APP

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var appController: AppController!

    func applicationWillFinishLaunching(notification: NSNotification) {
        window.setFrameUsingName("DetectImageColorsDemo")
        window.title = "DetectImageColors"
        window.backgroundColor = NSColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        NSUserDefaults.standardUserDefaults().setObject(getDefaultSettings(), forKey: "defaultSettings")
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        window.saveFrameUsingName("DetectImageColorsDemo")
        saveNamedColors()
    }

    private func saveNamedColors() {
        if let path = appController.getJSONFilePath() {
            do {
                let enc = try NSJSONSerialization.dataWithJSONObject(appController.namedColors, options: NSJSONWritingOptions.PrettyPrinted)
                if enc.writeToFile(path, atomically: false) == false {
                    NSLog("%@", "Error while writing JSON file")
                }
            } catch let error as NSError {
                print(error)
            }
        }
    }

    private func getDefaultSettings() -> NSDictionary {
        return ["ThresholdDistinctColor": CDSettings.ThresholdDistinctColor, "ThresholdNoiseTolerance": CDSettings.ThresholdNoiseTolerance, "ThresholdMinimumSaturation": CDSettings.ThresholdMinimumSaturation, "ThresholdFloorBrightness": CDSettings.ThresholdFloorBrightness, "ContrastRatio": CDSettings.ContrastRatio]
    }

}

