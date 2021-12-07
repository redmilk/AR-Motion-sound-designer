import UIKit

class SoundPickerVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var zone: Zone?
    var output: (() -> Void)?
    var selectedFileName: String = ""
    
    var fileNames: [String] = []
    var fileURLs: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadSounds()
        setupTableView()
    }
    
    func loadSounds() {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil)

            let mp3Files = directoryContents.filter { $0.pathExtension == "mp3" || $0.pathExtension == "wav" }
            fileURLs = mp3Files
            Zone.allCases.forEach { zone in
                guard let bundle = Bundle.main.path(forResource: zone.rawValue, ofType: "wav") else { return }
                let soundFileNameURL = URL(fileURLWithPath: bundle)
                fileURLs.append(soundFileNameURL)
            }
            guard let bundle = Bundle.main.path(forResource: "beat", ofType: "wav") else { return }
            let soundFileNameURL = URL(fileURLWithPath: bundle)
            fileURLs.append(soundFileNameURL)
            
            let mp3FileNames = mp3Files.map { $0.lastPathComponent }
            fileNames = mp3FileNames
            fileNames.sort(by: { $0 < $1 })
        } catch {
            print(error)
        }
    }
    
    @IBAction func didTapCloseButton(_ sender: Any) {
        dismiss(animated: true)
    }
}

private extension SoundPickerVC {
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SoundCell")
    }
}

extension SoundPickerVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SoundCell", for: indexPath) as UITableViewCell
        if #available(iOS 14.0, *) {
            var content = cell.defaultContentConfiguration()
            content.text = fileNames[indexPath.row]
            cell.contentConfiguration = content
        } else {
            cell.textLabel?.text = fileNames[indexPath.row]
        }
        cell.accessoryType = selectedFileName == fileNames[indexPath.row] ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let soundFileName = fileNames[indexPath.row]
        if let zone = zone {
            UserDefaults.standard.set(soundFileName, forKey: zone.keyValue)
        } else {
            UserDefaults.standard.set(soundFileName, forKey: "backgroundBeatFileName")
            output?()
        }
        dismiss(animated: true, completion: nil)
    }
}
