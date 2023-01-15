import Flutter
import UIKit
import AVFoundation
import MediaPlayer

public class SwiftAudioPickerPlugin: NSObject, FlutterPlugin, MPMediaPickerControllerDelegate {
    
    var _viewController : UIViewController?
    var _audioPickerController : MPMediaPickerController?
    var _flutterResult : FlutterResult?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "audio_picker", binaryMessenger: registrar.messenger())
        let viewController = UIApplication.shared.delegate?.window??.rootViewController
        let instance = SwiftAudioPickerPlugin(viewController: viewController)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    init(viewController: UIViewController?) {
        super.init()
        self._viewController = viewController
    }
    
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if(call.method == "pick_audio"){
            
            _flutterResult = result
            openAudioPicker(multiple:false)
        }
        if(call.method == "pick_audio_multiple") {

            _flutterResult = result
            openAudioPicker(multiple:true)
        }
    }

    enum ExportError: Error {
        case unableToCreateExporter
    }
    
    public func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        mediaPicker.dismiss(animated: true, completion: nil)

        let count = mediaItemCollection.count;
        if (count == 1) {
            let mediaItem = mediaItemCollection.items.first
            if (mediaItem?.assetURL != nil) {
                self._flutterResult?(mediaItem?.assetURL?.absoluteString)
            }
        }
        else {
            var pathList:[String] = []

            for (index, item) in mediaItemCollection.items.enumerated() {
                pathList.append(mediaItemCollection.items[index].assetURL?.absoluteString ?? "")
            }
            self._flutterResult?(pathList)
        }
        
    }
    
    public func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController)
    {   _flutterResult?(nil)
        _flutterResult = nil
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    func openAudioPicker(multiple: Bool) {
        _audioPickerController = MPMediaPickerController.self(mediaTypes:MPMediaType.music)
        _audioPickerController?.delegate = self
        _audioPickerController?.showsCloudItems = false
        _audioPickerController?.allowsPickingMultipleItems = multiple
        _audioPickerController?.modalPresentationStyle = UIModalPresentationStyle.currentContext
        _viewController?.present(_audioPickerController!, animated: true, completion: nil)
    }
    
}