//
//  ViewController.swift
//  Weather_App
//
//  Created by Donal O'Shea on 13/03/2019.
//  Copyright © 2019 Menishi. All rights reserved.
//

import UIKit


extension String
{
    // Extension to String class helps extract required data from the HTML data using regex
    // and convert it to an attributed string
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
    
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
    
    func weatherTDExtract(city:String) -> [String]
    {
        // Extract required weather table cell for today
        if let regex = try? NSRegularExpression(pattern: "<td class=\"b-forecast__table-description-cell--js\".+\(city) weather today.+?</td>", options: .caseInsensitive) {
            let string = self as NSString
            
            return regex.matches(in: self, options: [], range: NSRange(location: 0, length: string.length)).map {
                string.substring(with: $0.range)
            }
        }
        
        return []
    }
    
    func weatherToday(city:String) -> [String]
    {
        // Extract todays weather summary from the tabel cell
        if let regex = try? NSRegularExpression(pattern: "<span class=\"phrase\">.+</span>", options: .caseInsensitive) {
            let string = self as NSString;
            
            return regex.matches(in: self, options: [], range: NSRange(location: 0, length: string.length)).map {
                string.substring(with: $0.range)
            }
        }
        
        return []
    }
}

// Begin View Controller


class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var cityFieldEntry: UITextField!
    @IBOutlet weak var outputLabel: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    @IBAction func retrieveWeather(_ sender: Any) {
        // Trigger on submit button push
        if var city = self.cityFieldEntry.text {
            city = city.trimmingCharacters(in: .whitespacesAndNewlines);
            
            // Pattern match the entered city with URL of weather forecast website.
            let url = URL(string:"https://www.weather-forecast.com/locations/" + city.replacingOccurrences(of: " ", with: "-") + "/forecasts/latest")!;
            
            let urlRequest = URLRequest(url:url);

            let task = URLSession.shared.dataTask(with: urlRequest) {
                data, response, error in
                
                if error != nil {
                    print("error!");
                } else if let unwrappedData = data {
                    let dataString = String(data: unwrappedData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue));
                    
                    // Run main thread syncronisation to update UI
                    DispatchQueue.main.sync(execute: {
                        // Check if the city data was found
                        if dataString!.weatherTDExtract(city: city) != [] {
                            let extractedData = dataString!.weatherTDExtract(city: city)[0].weatherToday(city: city)[0];

                            self.outputLabel.attributedText = extractedData.htmlToAttributedString;
                            
                            // Use keyword matching to extract some basic information from the summary,
                            // use this to determine the background image.
                            if extractedData.lowercased().contains("rain") {
                                self.backgroundImage.image = UIImage(named: "rain.jpg");
                            } else if extractedData.lowercased().contains("fog") {
                                self.backgroundImage.image = UIImage(named: "foggy.jpg");
                            } else if extractedData.lowercased().contains("sun") || extractedData.lowercased().contains("warm") {
                                self.backgroundImage.image = UIImage(named: "sunny.jpg");
                            } else if extractedData.lowercased().contains("wind") || extractedData.lowercased().contains("gale") {
                                self.backgroundImage.image = UIImage(named: "wind.jpg");
                            }
                        } else {
                            self.outputLabel.text = "No such city. Try again";
                        }
                    })
                }
            }
            task.resume();
            
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Disable keyboard on touch outside text or keyboard area.
        self.view.endEditing(true)
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Disable keyboard on return key press.
        self.cityFieldEntry.resignFirstResponder()
        
        return true
        
    }
    
}
