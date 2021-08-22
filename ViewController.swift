//
//  ViewController.swift
//  WTFlower
//
//  Created by  Stepanok Ivan on 21.08.2021.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import AlamofireImage


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var textLabel: UILabel!
    
    
    let wikipediaURl = "https://ru.wikipedia.org/w/api.php"


    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
           // imageView.image = userPickedImage
            
            if let ciimage = CIImage(image: userPickedImage) {
                detectFlower(image: ciimage)
            } else {
                print("Не удалось преобразовать изображение в CIImage")
            }
            
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    
    
    
    
    
    
    @IBAction func cameraPressed(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    
    
    func detectFlower(image: CIImage) {
        //var res = ""
        do {
            let model = try VNCoreMLModel(for: FlowerClassifier().model)
            let request = VNCoreMLRequest(model: model) { (request, error) in
                let results = request.results as! [VNClassificationObservation]
                print(results[0].identifier)
                let res = results[0].identifier
                // Пишем каждое слово с большой буквы
                
                let translate = TranslateRU()
                let trans = translate.translate(input: res)
                self.requestInfo(flowerName: trans)
                self.navigationItem.title = trans.capitalized
                print(res)
            }
            let handler = VNImageRequestHandler(ciImage: image)
            try handler.perform([request])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    func requestInfo(flowerName: String) {
        
        
/* Парсинг запроса https://en.wikipedia.org/w/api.php?
         format=json
         &action=query
         &prop=extracts
         &exintro=
         &explaintext=
         &redirects=1
         &indexpageids
         &titles=Маргаритка%20многолетняя
        
*/
              let parameters : [String:String] = [
              "format" : "json",
              "action" : "query",
              "prop" : "extracts|pageimages",
                "pithumbsize" : "1000",
              "exintro" : "",
              "explaintext" : "",
                "titles" : flowerName,
              "indexpageids" : "",
              "redirects" : "1",
              ]
        
        
        // Запрос формируется из ссылки, метода и параметров. Забираем текст.
        AF.request(wikipediaURl , method: .get, parameters: parameters).responseJSON { (response) in
            
            
            // Проверка на результативность
            switch response.result {
            case .success:
                print("Hi")
                // Преобразование в JSON формат JSON(response.data)
                //print(JSON(response.data))
                let flowerJSON = JSON(response.data as Any)
                if let pageid = flowerJSON["query"]["pageids"][0].string {
                    let result = flowerJSON["query"]["pages"][pageid]["extract"].string
                    if let image = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].url {
                        self.textLabel.text = result
                        
                        
                        // Загрузка изображения через AlamofireImage
                        
                        self.imageView.af.setImage(withURL: image)
                        
                        // Загрузка изображения через расширение
                        //   self.imageView.load(url: result)
                        
                        print(pageid)
                        print(result)
                    }
                    
                } else {
                    self.textLabel.text = "Ничего не найдено"
                }
            case .failure:
                print("Всё пропало")
            }
        }
    }
}


// Расширение, которое позволяет грузить изображение по ссылке. Добавляет функцию load к imageView

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
