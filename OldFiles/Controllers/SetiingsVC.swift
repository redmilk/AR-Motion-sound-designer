import UIKit

protocol SettingsDelegate {
    func toggleConfiguration()
    func toggleZoneUtility()
    func toggleZoneForcePlay()
    func toggleDrawSkeleton()
    func toggleBeat()
    func toggleBigSquares()
    func toggleHeadphones()
    func toggleAverageDots()
}

class SettingsVC: UIViewController {
    
    // MARK: - View
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var closeButton: UIButton!
    
    //MARK: - Variables
    var delegate: SettingsDelegate?
    
    //MARK: - VC cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Delegates
        tableView.dataSource = self
        tableView.delegate = self
        
        configureUI()
        registerCells()
        
        // Load settings if it's empty
        if Constant.allSettings.count == 0 {
            Constant.allSettings = setupAllSettings()
        }

    }
    
    func configureUI() {
        tableView.isUserInteractionEnabled = true
        tableView.separatorStyle = .singleLine
    }
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    func registerCells() {
        tableView.register(SettingsTableViewCellWithSwitcher.self, forCellReuseIdentifier: "settingCellSwitcher")
        tableView.register(SettingsTableViewCellWithSlider.self, forCellReuseIdentifier: "settingCellSlider")
    }
}

extension SettingsVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        SettingOptionType.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if Constant.allSettings[indexPath.row].cellType == .switcher {
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingCellSwitcher") as! SettingsTableViewCellWithSwitcher
            cell.viewModel = (Constant.allSettings[indexPath.row], indexPath.row)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingCellSlider") as! SettingsTableViewCellWithSlider
            cell.viewModel = (Constant.allSettings[indexPath.row], indexPath.row)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if Constant.allSettings[indexPath.row].cellType == .switcher {
            return 60.0
        } else {
            return 125.0
        }
    }
}

// MARK: - SettingsOptions

extension SettingsVC {
    
    private func setupAllSettings() -> [SettingsOption] {
        
        SettingOptionType.allCases.map { optionType -> SettingsOption in
            var option = SettingsOption(optionType, false, {}, cellType: .switcher)
            
            switch optionType {
            case .toggleConfiguration:
                option.run = delegate?.toggleConfiguration
            case .zoneUtility:
                option.run = delegate?.toggleZoneUtility
            case .zoneForcePlay:
                option.run = delegate?.toggleZoneForcePlay
                option.isOn = false
            case .drawSkeleton:
                option.run = delegate?.toggleDrawSkeleton
                option.isOn = false
            case .playBeat:
                option.run = delegate?.toggleBeat
                option.isOn = true
            case .bigSquares:
                option.run = delegate?.toggleBigSquares
                option.isOn = false
            case .headphones:
                option.run = delegate?.toggleHeadphones
                option.isOn = UserDefaults.standard.bool(forKey: "enableHeadphones")
            case .averageDots:
                option.run = delegate?.toggleAverageDots
                option.isOn = UserDefaults.standard.bool(forKey: "averageDots")
            }
            return option
        }
    }
}

struct SettingsOption {
    
    enum CellType {
        case switcher
        case slider
    }
    
    var isOn: Bool?
    
    var maxValue: Float?
    var minValue: Float?
    var lastFloatValue: Float?
    
    var type: SettingOptionType
    var run: (() -> Void)?
    var runWithValue: ((Float) -> Void)?
    var cellType: CellType
    
    init(_ type: SettingOptionType, _ isOn: Bool?, _ run: (() -> Void)?, cellType: CellType) {
        self.type = type
        self.isOn = isOn
        self.run = run
        self.cellType = cellType
    }
}

enum SettingOptionType: String, CaseIterable {
    case toggleConfiguration = "Изменить настройку (OFF=zone, ON=movement)"
    case zoneUtility = "Переключить настройку (OFF=dot, ON=line)"
    case zoneForcePlay = "Повторять звук до окончания"
    case drawSkeleton = "В(ы)ключить скелет"
    case playBeat = "В(ы)ключить бит"
    case bigSquares = "Большие квадраты"
    case headphones = "Наушники"
    case averageDots = "Сглаживать точки по среднем значении"
}
