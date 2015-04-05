//
//  ColorTunes.swift
//  colortunes
//
//  Adapted & Created by ERIC DEJONCKHEERE on 03/04/2015.
//  Copyright (c) 2015 Eric Dejonckheere. All rights reserved.
//
// Original code (Objective-C) by PanicSoftware

import Cocoa

let kColorThresholdMinimumPercentage = 0.01  // original 0.01
let kColorThresholdMinimumSaturation: CGFloat = 0.15 // original: 0.15
let kColorThresholdMaximumNoise = 2

class ColorTunes: NSObject {

    var scaledSize: NSSize
    var scaledImage: NSImage?
    var backgroundColorCandidate: NSColor?
    var primaryColorCandidate: NSColor?
    var secondaryColorCandidate: NSColor?
    var detailColorCandidate: NSColor?

    init(image: NSImage, size: NSSize) {
        self.scaledSize = size
        super.init()
        let temp = self.scaledImage(image, scaledSize: size)
        self.scaledImage = temp
    }

    func startAnalyze(scaledImage: NSImage) {
        self.analyzeImage(scaledImage)
    }

    func getColorElements() -> (primary: NSColor, secondary: NSColor, detail: NSColor, background: NSColor) {
        return (primaryColorCandidate!, secondaryColorCandidate!, detailColorCandidate!, backgroundColorCandidate!)
    }



//    func getEdgeColorAndImageColorSet(anImage: NSImage) -> (NSColor, NSCountedSet) {
//
//    }

    func rescueNilColor(colorName: String, hasDarkBackground: Bool) -> NSColor {
        NSLog("%@", "missed \(colorName)")
        if hasDarkBackground {
            return NSColor.whiteColor()
        } else {
            return NSColor.blackColor()
        }
    }

//    func rescueNilColors() -> (NSColor, NSColor, NSColor) {
//
//    }

    func analyzeImage(anImage: NSImage) {
        var (backgroundColor, imageColors) = findEdgeColor(anImage)
        var darkBackground = backgroundColor!.isMostlyDarkColor()
        var textColors = findTextColors(imageColors, backgroundColor: backgroundColor!)
        if textColors.primary == nil {
            textColors.primary = rescueNilColor("primary", hasDarkBackground: darkBackground)
        }
        if textColors.secondary == nil {
            textColors.secondary = rescueNilColor("secondary", hasDarkBackground: darkBackground)
        }
        if textColors.detail == nil {
            textColors.detail = rescueNilColor("detail", hasDarkBackground: darkBackground)
        }

        var tprim = textColors.primary!.colorUsingColorSpaceName(NSCalibratedRGBColorSpace)
        var tsec = textColors.secondary!.colorUsingColorSpaceName(NSCalibratedRGBColorSpace)
        if tprim! == tsec! {
            if darkBackground {
                textColors.secondary = textColors.primary!.darkerColor()
            } else {
                textColors.secondary = textColors.primary!.lighterColor()
            }
        }
        var tdet = textColors.detail!.colorUsingColorSpaceName(NSCalibratedRGBColorSpace)
        if tprim! == tdet! {
            if darkBackground {
                textColors.detail = textColors.secondary!.darkerColor()
            } else {
                textColors.detail = textColors.secondary!.lighterColor()
            }
        }

        self.backgroundColorCandidate = backgroundColor!
        self.primaryColorCandidate = textColors.primary!
        self.secondaryColorCandidate = textColors.secondary!
        self.detailColorCandidate = textColors.detail!
    }



    private func findTextColors(colors: NSCountedSet?, backgroundColor: NSColor) -> (primary: NSColor?, secondary: NSColor?, detail: NSColor?) {
        var primaryColor: NSColor?
        var secondaryColor: NSColor?
        var detailColor: NSColor?
        var enumerator = colors!.objectEnumerator()
        var curColor = enumerator.nextObject() as? NSColor
        var sortedColors = NSMutableArray(capacity: colors!.count)
        var findDarkTextColor = !backgroundColor.isMostlyDarkColor()
        while curColor != nil {
            curColor = curColor!.sameOrWithMinimumSaturation(kColorThresholdMinimumSaturation)
            if curColor!.isMostlyDarkColor() == findDarkTextColor {
                var colorCount = colors!.countForObject(curColor!)
                if colorCount <= kColorThresholdMaximumNoise {
                    curColor = enumerator.nextObject() as? NSColor
                    continue
                }
                println(colorCount)
                var container = PCCountedColor(color: curColor!, count: colorCount)
                sortedColors.addObject(container)
            }
            curColor = enumerator.nextObject() as? NSColor
        }
        sortedColors.sortUsingSelector("compare:")
        for cc in sortedColors {
            var curContainer = cc as! PCCountedColor
            curColor = curContainer.color
            if primaryColor == nil {
                if curColor!.contrastsWith(backgroundColor) {
                    primaryColor = curColor
                }
            } else if secondaryColor == nil {
                if primaryColor!.isNotDistinctFrom(curColor!) || curColor!.doesNotContrastWith(backgroundColor) {
                    secondaryColor = curColor
                }
            } else if detailColor == nil {
                if secondaryColor!.isNotDistinctFrom(curColor!) || primaryColor!.isNotDistinctFrom(curColor!) || curColor!.doesNotContrastWith(backgroundColor) {
                    continue
                }
                detailColor = curColor
                break
            }
        }
        return (primaryColor, secondaryColor, detailColor)
    }

    private func findEdgeColor(image: NSImage) -> (NSColor?, NSCountedSet?) {
        var imageRep = image.representations.last as! NSBitmapImageRep
        if !imageRep.isKindOfClass(NSBitmapImageRep) {
            return (nil, nil)
        }
        var pixelsWide = imageRep.pixelsWide
        var pixelsHigh = imageRep.pixelsHigh
        var colors = NSCountedSet(capacity: pixelsWide * pixelsHigh)
        var leftEdgeColors = NSCountedSet(capacity: pixelsHigh)
        var x: NSInteger = 0
        var y: NSInteger = 0
        while x < pixelsWide {
            while y < pixelsHigh {
                var color = imageRep.colorAtX(x, y: y)
                if x == 0 {
                    leftEdgeColors.addObject(color!)
                }
                colors.addObject(color!)
                y++
            }
            x++
        }
        var enumerator = leftEdgeColors.objectEnumerator()
        var curColor = enumerator.nextObject() as? NSColor
        var sortedColors = NSMutableArray(capacity: leftEdgeColors.count)
        while curColor != nil {
            var colorCount = leftEdgeColors.countForObject(curColor!)
            var randomColorsThreshold = NSInteger(Double(pixelsHigh) * kColorThresholdMinimumPercentage)
            var container = PCCountedColor(color: curColor!, count: colorCount)
            sortedColors.addObject(container)
            curColor = enumerator.nextObject() as? NSColor
            //            println(curColor)
        }
        //        println(sortedColors.count)
        sortedColors.sortUsingSelector("compare:")
        var proposedEdgeColor: PCCountedColor?
        if sortedColors.count > 0 {
            proposedEdgeColor = (sortedColors.objectAtIndex(0) as! PCCountedColor)
            // want to choose color over black/white so we keep looking
            if proposedEdgeColor!.color.isMostlyBlackOrWhite() {
                var i: NSInteger = 0
                while i < sortedColors.count {
                    var nextProposedColor = sortedColors.objectAtIndex(i) as! PCCountedColor
                    // make sure the second choice color is 30% as common as the first choice
                    if (Double(nextProposedColor.count) / Double(proposedEdgeColor!.count)) > 0.3 {
                        if nextProposedColor.color.isNotMostlyBlackOrWhite() {
                            proposedEdgeColor = nextProposedColor
                            break
                        }
                    } else {
                        // reached color threshold less than 40% of the original proposed edge color so bail
                        break
                    }
                    i++
                }
            }
        }
        return (proposedEdgeColor!.color, colors)
    }

    private func scaledImage(image: NSImage, scaledSize: NSSize) -> NSImage {
        var imageSize = image.size
        var squareImage = NSImage(size: NSMakeSize(imageSize.width, imageSize.width))
        var scaledImage = NSImage(size: scaledSize)
        var drawRect: NSRect?

        // make the image square
        if imageSize.height > imageSize.width {
            drawRect = NSMakeRect(0, imageSize.height - imageSize.width, imageSize.width, imageSize.width)
        } else {
            drawRect = NSMakeRect(0, 0, imageSize.height, imageSize.height)
        }

        squareImage.lockFocus()
        image.drawInRect(NSMakeRect(0, 0, imageSize.width, imageSize.height), fromRect: drawRect!, operation: NSCompositingOperation.CompositeSourceOver, fraction: 1.0)
        squareImage.unlockFocus()

        // scale the image to the desired size
        scaledImage.lockFocus()
        squareImage.drawInRect(NSMakeRect(0, 0, scaledSize.width, scaledSize.height), fromRect: NSZeroRect, operation: NSCompositingOperation.CompositeSourceOver, fraction: 1.0)
        scaledImage.unlockFocus()

        // convert back to readable bitmap data
        var cgImage = scaledImage.CGImageForProposedRect(nil, context: nil, hints: nil)
        var bitmapRep = NSBitmapImageRep(CGImage: cgImage!.takeRetainedValue())
        var finalImage = NSImage(size: scaledImage.size)
        finalImage.addRepresentation(bitmapRep)

        return finalImage
    }

}




















