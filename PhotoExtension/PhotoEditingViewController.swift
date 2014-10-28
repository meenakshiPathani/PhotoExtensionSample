//
//  PhotoEditingViewController.swift
//  PhotoExtension
//
//  Created by Meenakshi  on 28/10/14.
//  Copyright (c) 2014 Mindfire Solutions. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class PhotoEditingViewController: UIViewController, PHContentEditingController {

	@IBOutlet var editingImageView: UIImageView?
	@IBOutlet var slider: UISlider?
	
	//	var loadingView: LoadingView?
	
	var context: CIContext!
	var filter: CIFilter!
	var beginImage: CIImage!
	
	var input: PHContentEditingInput?
	
	let formatIdentifier = "com.mindfire.PhotoExtensionSample"
	let formatVersion    = "1.0"
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@IBAction func sliderValueChanged(sender: UISlider){
		
		let sliderValue = sender.value
		
		filter.setValue(sliderValue, forKey: kCIInputIntensityKey)
		let outputImage = filter.outputImage
		editingImageView?.image = UIImage(CIImage: outputImage)
	}
	
	// MARK: - PHContentEditingController
	
	func canHandleAdjustmentData(adjustmentData: PHAdjustmentData?) -> Bool {
		// Inspect the adjustmentData to determine whether your extension can work with past edits.
		// (Typically, you use its formatIdentifier and formatVersion properties to do this.)
		
		return adjustmentData?.formatIdentifier == formatIdentifier &&
			adjustmentData?.formatVersion == formatVersion
		
		//        return false
	}
	
	func startContentEditingWithInput(contentEditingInput: PHContentEditingInput?, placeholderImage: UIImage) {
		// Present content for editing, and keep the contentEditingInput for use when closing the edit session.
		// If you returned YES from canHandleAdjustmentData:, contentEditingInput has the original image and adjustment data.
		// If you returned NO, the contentEditingInput has past edits "baked in".
		input = contentEditingInput
		
		beginImage = CIImage(image: input?.displaySizeImage)
		filter = CIFilter(name: "CISepiaTone")
		filter.setValue(beginImage, forKey: kCIInputImageKey)
		
		if let adjustmentData = contentEditingInput?.adjustmentData {
			let value = NSKeyedUnarchiver.unarchiveObjectWithData(adjustmentData.data) as NSNumber
			filter.setValue(value, forKey: kCIInputIntensityKey)
			slider?.value = value.floatValue
		}
		else {
			filter.setValue(0.5, forKey: kCIInputIntensityKey)
		}
		
		let outputImage : CIImage = filter.outputImage
		editingImageView?.image = UIImage(CIImage: outputImage)
	}
	
	func finishContentEditingWithCompletionHandler(completionHandler: ((PHContentEditingOutput!) -> Void)!) {
		// Update UI to reflect that editing has finished and output is being rendered.
		
		// Render and provide output on a background queue.
		dispatch_async(dispatch_get_global_queue(CLong(DISPATCH_QUEUE_PRIORITY_DEFAULT), 0)) {
			// Create editing output from the editing input.
			let output = PHContentEditingOutput(contentEditingInput: self.input)
			
			let archivedData = NSKeyedArchiver.archivedDataWithRootObject(self.filter.valueForKey(kCIInputIntensityKey))
			let newAdjustmentData = PHAdjustmentData(formatIdentifier: self.formatIdentifier,
				formatVersion: self.formatVersion,
				data: archivedData)
			output.adjustmentData = newAdjustmentData
			
			// Write the JPEG Data
			let fullSizeImage = CIImage(contentsOfURL: self.input?.fullSizeImageURL)
			UIGraphicsBeginImageContext(fullSizeImage.extent().size);
			self.filter.setValue(fullSizeImage, forKey: kCIInputImageKey)
			UIImage(CIImage: self.filter.outputImage).drawInRect(fullSizeImage.extent())
			let outputImage = UIGraphicsGetImageFromCurrentImageContext()
			let jpegData = UIImageJPEGRepresentation(outputImage, 1.0)
			UIGraphicsEndImageContext()
			
			jpegData.writeToURL(output.renderedContentURL, atomically: true)
			
			// Call completion handler to commit edit to Photos.
			completionHandler?(output)
			
			// Clean up temporary files, etc.
		}
	}
	
	var shouldShowCancelConfirmation: Bool {
		// Determines whether a confirmation to discard changes should be shown to the user on cancel.
		// (Typically, this should be "true" if there are any unsaved changes.)
		return true
	}
	
	func cancelContentEditing() {
		// Clean up temporary files, etc.
		// May be called after finishContentEditingWithCompletionHandler: while you prepare output.
	}
	
}
