//
//  ViewController.swift
//  VideoCapture
//
//  Created by GS on 2017/10/30.
//  Copyright © 2017年 Demo. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    //创建一个视频队列
    fileprivate lazy var videoQueue = DispatchQueue.global()
    //创建一个音频队列
    fileprivate lazy var audioQueue = DispatchQueue.global()
    
    //懒加载session
    fileprivate lazy var session: AVCaptureSession = AVCaptureSession()
    fileprivate lazy var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
    
    //当前的镜头
    fileprivate var videoInput: AVCaptureDeviceInput?
    //视频链接
    fileprivate var videoOutput: AVCaptureVideoDataOutput?
    
    fileprivate var movieOutput: AVCaptureMovieFileOutput?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

//MARK: - 视频的开始和停止采集
extension ViewController {
    
    //开始采集
    @IBAction func startCapture() {
        //1.设置视频的输入&输出
        setUpVideo()
        
        //2.设置音频的输入输出
        setUpAudio()
        
        //3.添加写入文件的output
        let movieOutput = AVCaptureMovieFileOutput()
        session.addOutput(movieOutput)
        self.movieOutput = movieOutput
        
        //4.设置写入的稳定性
        let connection = movieOutput.connection(with: .video)
        connection?.preferredVideoStabilizationMode = .auto
        
        //5.给用户看到一个预览图层(可选)
        //        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        
        //6.开始采集
        session.startRunning()
        
        //7.开始讲采集到的画面写入到文件中
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/abc.mp4"
        let url = URL(fileURLWithPath: path)
        movieOutput.startRecording(to: url, recordingDelegate: self)
        
    }
    
    //结束采集
    @IBAction func stopCapture() {
        
        //停止录制
        movieOutput?.stopRecording()
        
        session.stopRunning()
        previewLayer.removeFromSuperlayer()
    }
    
    //切换镜头
    @IBAction func switcfScene() {
        
        //1.获取之前的镜头
        guard var position = videoInput?.device.position else { return }
        
        //2.获取当前应该显示的镜头
        position = position == .front ? .back : .front
        
        //3.根据当前镜头创建Device
        let devices  = AVCaptureDevice.devices(for: .video)
        guard let device = devices.filter({ $0.position == position }).first else { return }
        
        //4.根据新的Device创建新的Input
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else { return }
        
        //5.在session中切换Input
        session.beginConfiguration()  //开始配置
        session.removeInput(self.videoInput!)
        session.addInput(videoInput)
        session.commitConfiguration()   //提交配置
        self.videoInput = videoInput
        
        
    }
}

//MARK: - 设置Video
extension ViewController {
    //设置视频
    fileprivate func setUpVideo() {
        
        //0.创建捕捉会话
        //        let session = AVCaptureSession()
        //        self.session = session
        
        //1.给捕捉会话设置输入源(摄像头)
        let devices = AVCaptureDevice.devices(for: .video)
        
        //1.1拿到前置摄像头
        /*
         /／方法一：
         let device = devices.filter { (device: AVCaptureDevice) -> Bool in
         return device.position == .front
         }.first
         ／／方法二：
         var device: AVCaptureDevice!
         for d in devices {
         if d.position == .front { //前置摄像头
         device = d
         break
         }
         }
         */
        guard let device = devices.filter({ $0.position == .front }).first else { return }
        
        //1.2通过device创建AVCaptureInput对象 (try? 对异常进行处理)
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else { return }
        self.videoInput = videoInput
        
        //1.3将input添加到会话中
        session.addInput(videoInput)
        
        //2.给捕捉会话设置输出源
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue) //代理
        session.addOutput(videoOutput)
        
        //3.获取video对应的output
        self.videoOutput = videoOutput
    }
    
    //设置音频
    fileprivate func setUpAudio() {
        //1设置音频的输入(话筒)
        //1.1获取话筒
        guard let device = AVCaptureDevice.default(for: .audio) else { return }
        
        //1.2通过device创建AVCaptureInput对象
        guard let audioInput = try? AVCaptureDeviceInput(device: device) else { return }
        
        //1.3将input添加到会话中
        session.addInput(audioInput)
        
        //2.给捕捉会话设置输出源
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: audioQueue) //代理
        session.addOutput(audioOutput)
        
    }
    
}

//MARK: - 获取数据
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection == videoOutput?.connection(with: .video) {
            //            print("已经采集到视频画面")
        } else {
            //            print("已经采集到音频画面")
        }
    }
}

//
extension ViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("开始写入文件")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("结束写入文件")
    }
}

