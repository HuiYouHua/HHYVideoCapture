//
//  ViewController.swift
//  HHYVideoCapture
//
//  Created by 华惠友 on 2020/3/25.
//  Copyright © 2020 com.development. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    fileprivate lazy var session: AVCaptureSession = AVCaptureSession()
    fileprivate var videoOutput: AVCaptureVideoDataOutput?
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
    fileprivate var videoInput: AVCaptureDeviceInput?
    fileprivate var movieOutput: AVCaptureMovieFileOutput?
    
    fileprivate var encoder: VideoEncoder = VideoEncoder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1.初始化视频的输入&输出
        setupVideoInputOutput()
        
        // 2.初始化音频的输入&输出
        setupAudioInputOutput()
        
        // 3.初始化一个预览图层
        setupPreviewLayer()
        
    }
}

extension ViewController {
    @IBAction func startCapture(_ sender: UIButton) {
        session.startRunning()
        // 录制视频,并写入文件
//        setupMovieFileOutput()
        
        guard let previewLayer = previewLayer else {
            return
        }
        view.layer.insertSublayer(previewLayer, at: 0)
    }
    
    @IBAction func stopCapture(_ sender: UIButton) {
        encoder.endEncode()
        movieOutput?.stopRecording()
        session.stopRunning()
        previewLayer?.removeFromSuperlayer()
    }
    
    @IBAction func rorateCamera(_ sender: UIButton) {
        // 1.取出之前镜头的方向
        guard let videoInput = videoInput else { return }
        let position: AVCaptureDevice.Position = videoInput.device.position == .front ? .back : .front
        guard let devices = AVCaptureDevice.devices() as? [AVCaptureDevice] else { return }
        guard let device = devices.filter({ $0.position == position }).first else { return }
        guard let newInput = try? AVCaptureDeviceInput(device: device) else { return }
        
        // 2.移除之前的input, 添加新的input
        session.beginConfiguration()
        session.removeInput(videoInput)
        if session.canAddInput(newInput) {
            session.addInput(newInput)
            self.videoInput = newInput
        }
        session.commitConfiguration()
        
    }
    
}

extension ViewController {
    fileprivate func setupVideoInputOutput() {
        // 1.添加视频的输入
        guard let devices = AVCaptureDevice.devices() as? [AVCaptureDevice] else { return }
        guard let device = devices.filter({ $0.position == .front }).first else { return }
        /**
         //AVCaptureDeviceType 种类
         AVCaptureDeviceTypeBuiltInMicrophone //创建麦克风
         AVCaptureDeviceTypeBuiltInWideAngleCamera //创建广角相机
         AVCaptureDeviceTypeBuiltInTelephotoCamera //创建比广角相机更长的焦距。只有使用 AVCaptureDeviceDiscoverySession 可以使用
         AVCaptureDeviceTypeBuiltInDualCamera //创建变焦的相机，可以实现广角和变焦的自动切换。使用同AVCaptureDeviceTypeBuiltInTelephotoCamera 一样。
         AVCaptureDeviceTypeBuiltInDuoCamera //iOS 10.2 被 AVCaptureDeviceTypeBuiltInDualCamera 替换
         */
        
        /**
         AVCaptureDevicePositionUnspecified = 0, //不确定
         AVCaptureDevicePositionBack        = 1,//后置
         AVCaptureDevicePositionFront       = 2,//前置
         // 如果初始的 AVMediaType 是 AVMediaTypeVideo 表示前置和后置摄像头
         */
//        guard let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInDualCamera, for: AVMediaType.video, position: .front) else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        self.videoInput = input
        
        // 2.添加视频的输出
        let output = AVCaptureVideoDataOutput()
        let queue = DispatchQueue.global()
        output.setSampleBufferDelegate(self, queue: queue)
        videoOutput = output
        

        
        // 3.添加输入&输出
        addInputOutputToSession(input, output)
        
        // 4.设置录制方向, 必须在添加输入输出之后设置,否则connection没有对象
        let connection = output.connection(with: .video)
        connection?.videoOrientation = .portrait
        
    }
    
    fileprivate func setupAudioInputOutput() {
        // 1.创建输入
        guard let device = AVCaptureDevice.default(for: .audio) else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        // 2.创建输出
        let output = AVCaptureAudioDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global())

        // 3.添加输入&输出
        addInputOutputToSession(input, output)
    }
    
    private func addInputOutputToSession(_ input: AVCaptureInput, _ output: AVCaptureOutput) {
        session.beginConfiguration()
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
    }
    
    fileprivate func setupPreviewLayer() {
        // 1.创建预览图层
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        // 2.设置preview的属性
        previewLayer.frame = view.bounds
    
        // 3.将图层添加到控制器的view的layer中
        self.previewLayer = previewLayer
    }
    
    fileprivate func setupMovieFileOutput() {
        // 1.创建写入文件的输出
        let fileOutput = AVCaptureMovieFileOutput()
        self.movieOutput = fileOutput
        
        let connection = fileOutput.connection(with: .video)
        connection?.automaticallyAdjustsVideoMirroring = true
        
        if session.canAddOutput(fileOutput) {
            session.addOutput(fileOutput)
        }
        
        // 2.直接开始写入文件
        let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/abc.mp4"
        let fileURL = URL(fileURLWithPath: filePath)
        fileOutput.startRecording(to: fileURL, recordingDelegate: self)
    }
}

// MARK: - 视频采集代理
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        encoder.encode(sampleBuffer)
        if videoOutput?.connection(with: .video) == connection {
            print("采集到一帧**视频数据**")
        } else {
            print("采集到一帧##音频数据##")
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if videoOutput?.connection(with: .video) == connection {
            print("丢弃的一帧**视频数据**")
        } else {
            print("丢弃的一帧##音频数据##")
        }
    }
}

// MARK: - 通过代理监听写入文件,以及结束写入文件
extension ViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("开始写入")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("结束写入")
    }
}
