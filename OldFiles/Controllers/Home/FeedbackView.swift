
import UIKit

class FeedbackView: UIView {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    var controller: UIViewController?
    var feedbackEnter = false
        
    func start() {
        
        textView.backgroundColor = .white
        textView.textColor = .black
        textView.layer.masksToBounds = true
        textView.layer.cornerRadius = 15
        textView.delegate = self
        sendButton.layer.cornerRadius = 15
        
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview!.topAnchor),
            bottomAnchor.constraint(equalTo: superview!.bottomAnchor),
            leadingAnchor.constraint(equalTo: superview!.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview!.trailingAnchor),
        ])
        
        JiggleAnalytics.logAmplitudeEvent("Feedback Start")
        show(true, completion: nil)
    }
    
    @IBAction func sendButtonTapped(_ sender: Any) {
        let parameters = ["text" : textView!.text]

        let url = URL(string: "http://104.248.30.185:3000/feedback")!
        
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
        }

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Thanks!", message: "Feedback sent", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    self.show(false, completion: {
                        self.removeFromSuperview()
                    })
                }))
                JiggleAnalytics.logAmplitudeEvent("Feedback Sent")
                self.controller?.present(alert, animated: true, completion: nil)
            }
        })
        task.resume()
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        JiggleAnalytics.logAmplitudeEvent("Feedback Cancel")
        show(false, completion: {
            self.removeFromSuperview()
        })
    }
    
}

extension FeedbackView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if !feedbackEnter {
            JiggleAnalytics.logAmplitudeEvent("Feedback Enter")
            feedbackEnter = true
        }
    }
}
