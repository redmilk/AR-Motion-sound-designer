
import Foundation

final class FileUploader: NSObject {
    
    let df: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ssZ"
        return dateFormatter
    }()
    
    private lazy var urlSession = URLSession(
        configuration: .default
    )
    
    func uploadTestVideo(at videoURL: URL,
                         to targetURL: URL,
                         completion: @escaping ((Result<Void, Error>) -> Void)) {
        
        let boundary = "Boundary-\(UUID().uuidString)"
        
        var request = URLRequest(url: targetURL)
        request.httpMethod = "POST"
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let httpBody = NSMutableData()
        
        var videoData: Data?
        do {
            videoData = try Data(contentsOf: videoURL.absoluteURL)
        } catch let error {
            print(error)
            videoData = nil
            return
        }
        
        if let data = videoData {
            
            let strDate = df.string(from: Date())
            
            httpBody.append(self.convertFileData(fieldName: "file", fileName: "\(strDate).mov", mimeType: "video/mov", fileData: data, using: boundary))
        }
        
        httpBody.appendString("--\(boundary)--")
        
        request.httpBody = httpBody as Data
        
        let task = urlSession.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
        
        task.resume()
        
    }
    
    private func convertFileData(fieldName: String, fileName: String, mimeType: String, fileData: Data, using boundary: String) -> Data {
        let data = NSMutableData()
        
        data.appendString("--\(boundary)\r\n")
        data.appendString("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        data.appendString("Content-Type: \(mimeType)\r\n\r\n")
        data.append(fileData)
        data.appendString("\r\n")
        
        return data as Data
    }
    
}
