
import UIKit
import AVFoundation
import Accelerate


class _TViewController: UIViewController,AVAudioRecorderDelegate {
    //こいつが音源
    
    var playSong:AVAudioPlayer!
    var timer: NSTimer!
    var timeCountTimer: NSTimer!
    let photos = ["Kiki17", "Kiki18", "Kiki19","Kiki20","Kiki21","08531cedbc172968acd38e7fa2bfd2e0"]
    var count = 1
    var timeCount = 1
    var songData:NSURL!//結合させる
    var audioEngine: AVAudioEngine!
    var player: AVAudioPlayerNode!
    var averagePower:Float32 = 0
    var songFile:NSURL!
    let mixerMeter = MixerMeter()
    var iyahon:NSURL!
    let recordSetting : [String : AnyObject] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVNumberOfChannelsKey: 1 ,
        AVSampleRateKey: 44100
    ]

    
    @IBOutlet weak var recButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nami1: UIProgressView!
    @IBOutlet weak var nami2: UIProgressView!
    @IBOutlet weak var nami3: UIProgressView!
    @IBOutlet weak var byou: UILabel!
    @IBOutlet weak var recImage: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recImage!.layer.cornerRadius = 37
        recImage!.clipsToBounds = true
        
    }
    
    /// Audio Session Route Change : ルートが変化した(ヘッドセットが抜き差しされた)
    func audioSessionRouteChanged(notification: NSNotification) {
        let reasonObj = notification.userInfo![AVAudioSessionRouteChangeReasonKey] as! NSNumber
        if let reason = AVAudioSessionRouteChangeReason(rawValue: reasonObj.unsignedLongValue) {
            switch reason {
            case .NewDeviceAvailable:
                // 新たなデバイスのルートが使用可能になった
                // （ヘッドセットが差し込まれた）
                
                
                break
            case .OldDeviceUnavailable:
                self.timeCountTimer.invalidate()
                self.timer.invalidate()
                audioEngine.mainMixerNode.removeTapOnBus(0)
                audioEngine.stop()
                let deleteSong = try!AVAudioRecorder(URL: iyahon,settings:recordSetting)
                deleteSong.deleteRecording()
                self.dismissViewControllerAnimated(true, completion: nil)
                break
            default:
                break
            }
        }
    }
    
    //音源消す
    func applicationWillResignActive(notification: NSNotification) {
        print("applicationWillResignActive!")
        if ( self.timer != nil) {
            self.timer.invalidate()
        }
        if ( self.timeCountTimer != nil) {
            self.timeCountTimer.invalidate()
        }
        if ( audioEngine != nil ) {
            if ( audioEngine.running ) {
                audioEngine.mainMixerNode.removeTapOnBus(0)
                audioEngine.stop()
            }
        }
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
       self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(UIApplicationDelegate.applicationWillResignActive(_:)),
            name:UIApplicationWillResignActiveNotification,
            object: nil
        )
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @IBAction func rec(sender: AnyObject) {
        if count == 1{
            recButton!.enabled = false
            let image:UIImage! = UIImage(named: photos[0])
            imageView.image = image
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(_TViewController.nextPage), userInfo: nil, repeats: true )
        }else if count == 5{
            self.timeCountTimer.invalidate()
            self.timer.invalidate()
            audioEngine.mainMixerNode.removeTapOnBus(0)
            audioEngine.stop()
            nextGamenn()
        }
    }
    
    func nextGamenn(){
        let playviewcontroller = self.storyboard?.instantiateViewControllerWithIdentifier("Play2") as! Play2ViewController
        playviewcontroller.songData2 = songFile
        playviewcontroller.songData = self.songData
        self.presentViewController(playviewcontroller, animated: true, completion: nil)
    }
    
    
    func nextPage (sender:NSTimer){
        
        var image:UIImage! = UIImage(named: photos[1])
        if count == 1{
            imageView.image = image;
            count += 1
        }else if count == 2{
            image = UIImage(named: photos[2])
            imageView.image = image
            count += 1
        }else if count == 3{
            image = UIImage(named: photos[3])
            imageView.image = image
            count += 1
        }else if count == 4{
            image = UIImage(named: photos[4])
            imageView.image = image
            count += 1
        }else if count == 5{
            image = UIImage(named: photos[5])
            imageView.image = image
            play()
            self.timer.invalidate()
            self.timer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: self, selector: #selector(_TViewController.levelTimerCallback), userInfo: nil, repeats: true)
            self.timeCountTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(_TViewController.recordLimits), userInfo: nil, repeats: true)
            sender.invalidate()
            recButton!.setImage(UIImage(named: "Kiki28"), forState: UIControlState.Normal)
            recButton!.layer.cornerRadius = 37
            recButton!.clipsToBounds = true
            recButton!.enabled = true
            
        }
        
    }
    
    
    func play() {
        //ヘッドセットの抜き差しを検出するようにします
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(audioSessionRouteChanged(_:)), name: AVAudioSessionRouteChangeNotification, object: nil);
        let documentDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        let filePath2 = NSURL(fileURLWithPath: documentDir + "/sample.m4a")
        songFile = filePath2
        if let url = songData {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
                try audioSession.setActive(true)
                
                let audioFile = try AVAudioFile(forReading: url)
                
                
                audioEngine = AVAudioEngine()
                mixerMeter.mixer = audioEngine.mainMixerNode
                mixerMeter.setMeteringEnabled(true)
                player = AVAudioPlayerNode()
                audioEngine.attachNode(player)
                let mixer = audioEngine.mainMixerNode
                
                audioEngine.connect(player, to: mixer, fromBus: 0, toBus: 0, format: player.outputFormatForBus(0))
                let inputNode = audioEngine.inputNode!
                let format = AVAudioFormat(commonFormat: .PCMFormatFloat32  , sampleRate: 44100, channels: 1 , interleaved: true)
                audioEngine.connect(inputNode, to: mixer, fromBus: 0, toBus: 1, format: format)
                
                player.scheduleFile(audioFile, atTime: nil) {
                    print("complete")
                }
                
                let recordSetting : [String : AnyObject] = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVNumberOfChannelsKey: 2 ,
                    AVSampleRateKey: 44100
                ]
                let audioFile2 = try AVAudioFile(forWriting: filePath2, settings: recordSetting)
                mixer.installTapOnBus(0, bufferSize: 4096, format: mixer.outputFormatForBus(0)) { (buffer, when) in
                    do {
                        try audioFile2.writeFromBuffer(buffer)
                    } catch let error {
                        print("audioFile2.writeFromBuffer error:", error)
                    }
                }
                try audioEngine.start()
                player.play()
            } catch let error {
                print(error)
            }
        } else {
            print("File not found")
        }
        iyahon = songFile
    }
    
    func levelTimerCallback() {
        mixerMeter.updateMeters()
        let dB = mixerMeter.averagePowerForChannel0
        let atai = max(0, (dB + 77)) / 77
        nami1.progress = atai
        nami2.progress = atai
        nami3.progress = atai
    }
    
    
    
    func stop() {
        audioEngine.mainMixerNode.removeTapOnBus(0)
        self.audioEngine.stop()
    }
    
       func recordLimits(){
        let minuteCount = timeCount / 60
        let secondCount = timeCount % 60
        if secondCount <= 9 {
            byou.text = String(format: "%d:0%d", minuteCount, secondCount)
        }else if secondCount >= 10 {
            byou.text = String(format: "%d:%d", minuteCount, secondCount)
        }
        if timeCount == 360{
            self.timeCountTimer.invalidate()
            self.timer.invalidate()
            stop()
            nextGamenn()
        }else{
             timeCount += 1
        }
    }
    
    
    @IBAction func back(sender: AnyObject) {
        timer?.invalidate()
        timeCountTimer?.invalidate()
        audioEngine?.mainMixerNode.removeTapOnBus(0)
        audioEngine?.stop()
        self.dismissViewControllerAnimated(true, completion: nil)

    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    
    
    
}




