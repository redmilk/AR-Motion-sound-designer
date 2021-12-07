import UIKit

final class SettingsTableViewCellWithSwitcher: UITableViewCell {

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    var switcher: UISwitch = {
        let switcher = UISwitch()
        return switcher
    }()
        
    var viewModel: (option: SettingsOption, index: Int)? {
        didSet {
            titleLabel.text = viewModel?.option.type.rawValue
            switcher.isOn = Constant.allSettings[viewModel?.index ?? 0].isOn ?? false
            adoptLayout()
            layoutIfNeeded()
        }
    }
 
    private func adoptLayout() {
        
        accessoryView = switcher
        switcher.addTarget(self, action: #selector(controlToggle), for: .valueChanged) // for button add touch inside
                
        // Setup switcher
        addSubview(switcher)
        switcher.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            switcher.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.20),
            switcher.centerYAnchor.constraint(equalTo: centerYAnchor),
            switcher.rightAnchor.constraint(equalTo: rightAnchor, constant: -25)
        ])
        
        // Setup titleLabel
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.heightAnchor.constraint(equalToConstant: 48),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.rightAnchor.constraint(equalTo: switcher.leftAnchor, constant: -25),
            titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 25)
        ])
    }
    
    @objc func controlToggle() {
        viewModel?.option.run?()
        guard let index = viewModel?.index, let _ = Constant.allSettings[index].isOn else { return }
        Constant.allSettings[index].isOn!.toggle()
    }
}
