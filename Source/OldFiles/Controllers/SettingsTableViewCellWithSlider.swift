import UIKit

final class SettingsTableViewCellWithSlider: UITableViewCell {

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private var currentValueLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private var slider: UISlider = {
        let slider = UISlider()
        return slider
    }()
        
    var viewModel: (option: SettingsOption?, index: Int)? {
        didSet {
            titleLabel.text = viewModel?.option?.type.rawValue
            slider.minimumValue = viewModel?.option?.minValue ?? 0.01
            slider.maximumValue = viewModel?.option?.maxValue ?? 1
            slider.value = viewModel?.option?.lastFloatValue ?? slider.minimumValue
            currentValueLabel.text = "Current Value: \(slider.value)"
            adoptLayout()
            layoutIfNeeded()
        }
    }
 
    private func adoptLayout() {
        accessoryView = slider
        slider.addTarget(self, action: #selector(controlToggle), for: .valueChanged) // for button add touch inside
        
        // Setup titleLabel
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            titleLabel.heightAnchor.constraint(equalToConstant: 48),
            titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -25),
            titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 25)
        ])
        
        // value label
        addSubview(currentValueLabel)
        currentValueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            currentValueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            currentValueLabel.heightAnchor.constraint(equalToConstant: 24),
            currentValueLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            currentValueLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])
        
        // Setup slider
        addSubview(slider)
        slider.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            slider.topAnchor.constraint(equalTo: currentValueLabel.bottomAnchor, constant: 5),
            slider.heightAnchor.constraint(equalToConstant: 24),
            slider.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])
    }
    
    @objc func controlToggle() {
        viewModel?.option?.runWithValue?(slider.value)
        currentValueLabel.text = "Current Value: \(slider.value)"
        guard let index = viewModel?.index else { return }
        Constant.allSettings[index].lastFloatValue = slider.value
    }
}
