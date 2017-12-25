//
//  ImageUtils.swift
//  FXKit
//
//  Created by Kai Oezer on 7/20/14.
//  Copyright (c) 2014, 2017 Kai Oezer. All rights reserved.
//

#if os(iOS)
  import UIKit
#else
  import Cocoa
#endif
import QuartzCore


private let ImageUtilsContext = CIContext(options:nil)


public class ImageUtils
{
  //MARK: Public

  /// - returns: An image like the input image but with modified brightness
  public class func newImageFromImage(_ image:UIImage, withBrightnessChange deltaBrightness : CGFloat) -> UIImage?
  {
    if let adjustedImage = _CIImageFromImage(image, brightness:deltaBrightness, blurRadius:0)
    {
      return _newImageFromCIImage(adjustedImage)
    }
    return nil
  }


  public class func newImageFromImage(_ image:UIImage, withBlurRadius blurRadius : CGFloat) -> UIImage?
  {
    if let blurredImage = _CIImageFromImage(image, brightness:0, blurRadius:blurRadius)
    {
      return _newImageFromCIImage(blurredImage)
    }
    return nil
  }


  public class func newImageFromImage(_ image:UIImage, brightnessChange:CGFloat, blurRadius:CGFloat) -> UIImage?
  {
    if let processedImage = _CIImageFromImage(image, brightness:brightnessChange, blurRadius:blurRadius)
    {
      return _newImageFromCIImage(processedImage)
    }
    return nil
  }


  public class func newColorInvertedImageFromImage(_ image:UIImage) -> UIImage?
  {
    guard let colorInvertedCIImage = _colorInvertedCIImageFromImage(image) else { return nil }
    return _newImageFromCIImage(colorInvertedCIImage)
  }


  public class func imageFromImage(_ image:UIImage, resizedTo size : CGSize) -> UIImage
  {
    #if os(iOS)
      UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
      image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
      let newImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext();
      return newImage!
    #else
      return image
    #endif
  }


  //MARK: Private


  class func _colorInvertedCIImageFromImage(_ image:UIImage) -> CIImage?
  {
    #if os(iOS)
      let inputImage = image.ciImage
    #else
      let inputImage = CIImage(data:image.tiffRepresentation!)
    #endif
    guard let filter = CIFilter(name:"CIColorInvert") else { return inputImage }
    filter.setDefaults()
    filter.setValue(inputImage, forKey:"inputImage")
    return filter.value(forKey: "outputImage") as? CIImage
  }


  class func _CIImageFromImage(_ image:UIImage, brightness:CGFloat, blurRadius:CGFloat) -> CIImage?
  {
    #if os(iOS)
      guard let input : CIImage = image.ciImage ?? ((image.cgImage == nil) ? CIImage(cgImage:image.cgImage!) : nil) else { return nil }
    #else
      guard let input : CIImage = CIImage(data:image.tiffRepresentation!) else { return nil }
    #endif

    var result : CIImage? = nil

    if brightness != 0.0
    {
      if let filter = CIFilter(name:"CIColorControls")
      {
        filter.setValue(input, forKey:kCIInputImageKey)
        let clampedBrightness = max( -1.0, min(1.0, brightness) );
        filter.setValue(clampedBrightness, forKey:kCIInputBrightnessKey)
        result = filter.outputImage
      }
    }

    if blurRadius > 0.0
    {
      if let filter = CIFilter(name:"CIGaussianBlur")
      {
        filter.setValue(input, forKey:kCIInputImageKey)
        filter.setValue(blurRadius, forKey:kCIInputRadiusKey)
        result = filter.outputImage
      }
    }

    return result
  }


  class func _newImageFromCIImage(_ ciImage:CIImage) -> UIImage?
  {
    #if os(iOS)
      #if false
        return UIImage(CIImage:ciImage) // This is less performant because each time a new CIContext is created under the hood.
      #else
        let cgImage = ImageUtilsContext.createCGImage(ciImage, from:ciImage.extent)
        return UIImage(cgImage:cgImage!)
      #endif
    #else
      let imageSize = ciImage.extent.size
      let image = NSImage(size:imageSize)
      image.lockFocus()

      // The software renderer prevents leaks
      let contextPointer : UnsafeMutablePointer<Void> = NSGraphicsContext.current()!.graphicsPort
      let context = Unmanaged<CGContext>.fromOpaque(UnsafePointer(contextPointer)).takeUnretainedValue()

      let renderOptions = [kCIContextUseSoftwareRenderer : true]
      let ciContext = CIContext(cgContext:context, options:renderOptions)
      let imageFrame : CGRect = ciImage.extent
      ciContext.draw(ciImage, in:CGRect(x: 0, y: 0, width: imageFrame.size.width, height: imageFrame.size.height), from:imageFrame)

      image.unlockFocus()
      return image
    #endif
  }
}

