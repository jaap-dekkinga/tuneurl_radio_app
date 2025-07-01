import Foundation
import FRadioPlayer
import TuneURL
import AVKit

protocol RadioManagerObserver: AnyObject {
    
    func radioManager(_ manager: RadioManager, playerStateDidChange state: FRadioPlayer.State)
    
    func radioManager(_ manager: RadioManager, playbackStateDidChange state: FRadioPlayer.PlaybackState)
    
    func radioManager(_ manager: RadioManager, metadataDidChange metadata: FRadioPlayer.Metadata?)
    
    func radioManager(_ manager: RadioManager, artworkDidChange artworkURL: URL?)
}

class RadioManager: NSObject {
    
    static let shared = RadioManager()
    
    private let player = FRadioPlayer.shared
    private var observers = [ObjectIdentifier : Observation]()
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 0
        return URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: .main
        )
    }()
    private var currentRequestTask: URLSessionDataTask?
    private var mediaDataChunks = [Data]()
    
    private var parsingWorkItem: DispatchWorkItem?
    private weak var currentOpenMatchController: InterestViewController?
    
    override init() {
        super.init()
        player.addObserver(self)
    }
    
    // MARK: - Properties
    var radioURL: URL? {
        get { player.radioURL }
        set {
            print("🔥 Setting radio URL to \(String(describing: newValue))")
            player.radioURL = newValue
            startParsing()
        }
    }
    
    // MARK: - Getters
    var state: FRadioPlayer.State {
        player.state
    }
    
    var isPlaying: Bool {
        player.isPlaying
    }
    
    var playbackState: FRadioPlayer.PlaybackState {
        player.playbackState
    }
    
    var currentMetadata: FRadioPlayer.Metadata? {
        player.currentMetadata
    }
    
    var currentArtworkURL: URL? {
        player.currentArtworkURL
    }
    
    // MARK: - Controls
    func setup() {
        FRadioPlayer.shared.isAutoPlay = true
        FRadioPlayer.shared.enableArtwork = true
        FRadioPlayer.shared.artworkAPI = iTunesAPI(artworkSize: 600)
    }
    
    func togglePlaying() {
        player.togglePlaying()
        startParsing()
    }
    
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    func stop() {
        player.stop()
        stopParsing()
    }
}

extension RadioManager: FRadioPlayerObserver {
    
    struct Observation {
        weak var observer: RadioManagerObserver?
    }
    
    func addObserver(_ observer: RadioManagerObserver) {
        let id = ObjectIdentifier(observer)
        observers[id] = Observation(observer: observer)
    }
    
    func removeObserver(_ observer: RadioManagerObserver) {
        let id = ObjectIdentifier(observer)
        observers.removeValue(forKey: id)
    }
    
    func radioPlayer(_ player: FRadioPlayer, playerStateDidChange state: FRadioPlayer.State) {
        observers.values.forEach {
            $0.observer?.radioManager(self, playerStateDidChange: state)
        }
    }
    
    func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlayer.PlaybackState) {
        observers.values.forEach {
            $0.observer?.radioManager(self, playbackStateDidChange: state)
        }
    }
    
    func radioPlayer(_ player: FRadioPlayer, metadataDidChange metadata: FRadioPlayer.Metadata?) {
        observers.values.forEach {
            $0.observer?.radioManager(self, metadataDidChange: metadata)
        }
    }
    
    func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
        observers.values.forEach {
            $0.observer?.radioManager(self, artworkDidChange: artworkURL)
        }
    }
}

extension RadioManager: URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
    
    func startParsing() {
        stopParsing()
        
        currentRequestTask = session.dataTask(with: radioURL!)
        currentRequestTask?.resume()
        
        scheduleParsingTask()
    }
    
    func scheduleParsingTask() {
        let newTask = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            guard !self.mediaDataChunks.isEmpty else { return }
            // TODO: possible race condition because mediaDataChunks may being modified while this task runs
            let data = self.mediaDataChunks.reduce(Data(), +)
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("parsing_audio_chunk.mp3")
            do {
                try data.write(to: fileURL)
                
                var parsed = false
                Detector.processAudio(for: fileURL) { [weak self] matches in
                    let uniqueMatches = matches.uniqueBy(key: { $0.id })
//                    #if DEBUG
                    print("------------------------------------------------")
                    for match in uniqueMatches {
                        print("TuneURL active:")
                        print("\tname: \(match.name)")
                        print("\tdescription: \(match.description)")
                        print("\tid: \(match.id)")
                        print("\tinfo: \(match.info)")
                        print("\tmatchPercentage: \(match.matchPercentage)")
                        print("\ttime: \(match.time)")
                        print("\ttype: \(match.type)")
                        print("----------------")
                    }
                    print("------------------------------------------------")
//                    #endif
                    
                    let bestMatch = uniqueMatches.max(by: { $0.matchPercentage < $1.matchPercentage })
                    if let bestMatch {
                        DispatchQueue.main.async {
                            self?.openMatch(bestMatch)
                        }
                    }
                    
                    try? FileManager.default.removeItem(at: fileURL)
                    if !parsed {
                        parsed = true
                        self?.scheduleParsingTask()
                    }
                }
            } catch {
                print("Error writing data to file: \(error)")
                self.scheduleParsingTask()
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 2, execute: newTask)
        parsingWorkItem = newTask
    }
    
    func stopParsing() {
        parsingWorkItem?.cancel()
        
        currentRequestTask?.cancel()
        currentRequestTask = nil
        mediaDataChunks.removeAll()
    }
    
    func openMatch(_ match: Match) {
        guard currentOpenMatchController == nil else {
            print("A match is already open.")
            return
        }
        let viewController = InterestViewController.create(with: match, wasUserInitiated: false)
        (UIApplication.shared.delegate as! AppDelegate).window?.rootViewController?.present(viewController, animated: true)
        currentOpenMatchController = viewController
    }
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        mediaDataChunks.append(data)
        while mediaDataChunks.reduce(0, { $0 + $1.count }) > 250_000 {
            mediaDataChunks.removeFirst()
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("Task completed with error: \(String(describing: error))")
        stopParsing()
    }
}

extension RadioManagerObserver {
    
    func radioManager(_ manager: RadioManager, playerStateDidChange state: FRadioPlayer.State) { }
    
    func radioManager(_ manager: RadioManager, playbackStateDidChange state: FRadioPlayer.PlaybackState) { }
    
    func radioManager(_ manager: RadioManager, metadataDidChange metadata: FRadioPlayer.Metadata?) { }
    
    func radioManager(_ manager: RadioManager, artworkDidChange artworkURL: URL?) { }
}
