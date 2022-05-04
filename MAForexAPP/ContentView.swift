//
//  ContentView.swift
//  ForexAPP
//
//  Created by user217190 on 5/2/22.
//

import SwiftUI
import Foundation

public struct Data: Decodable
{
    let base: String?
    let date: String?
    let success: Bool?
    let rates: [String: Rates]?
}


public struct Rates: Decodable
{
    let start_rate: Double?
    let end_rate: Double?
    let change: Double?
    let change_pct: Double?
}


let json = """
{
    "base": "EUR",
    "date": "2022-04-14",
    "rates":{
        "USD":
            {
                "change": 0.1,
                "change_pct": 0.2676868,
                "end_rate": 0.3,
                "start_rate": 0.4
            },
        "CAD":
            {
                "change": -0.11,
                "change_pct": 0.22213124,
                "end_rate": 0.33,
                "start_rate": 0.44
             }

            },
    "success":true
}
"""

public final class WebService : NSObject
{
    var semaphore = DispatchSemaphore(value: 0)
    let defaults = UserDefaults.standard
    var result = "no result"
    var urlEUR: String = ""
    var urlUSD: String = ""
    var urlGBP: String = ""
    var decodedEUR: Data?
    var decodedUSD: Data?
    var decodedGBP: Data?
    let EURSymbols = "USD,JPY,GBP,AUD,CAD,NZD,CHF,HKD"
    let USDSymbols =  "JPY,CAD,CHF"
    let GBPSymbols = "USD,JPY,AUD,CAD,CHF,HKD"
    
    public enum Base
    {
        case EUR, USD, GBP
    }
    
    public override init()
    {
        super.init()
        urlUSD = "https://api.apilayer.com/fixer/fluctuation?symbols=" + self.USDSymbols + "&base=USD"
        urlEUR = "https://api.apilayer.com/fixer/fluctuation?symbols=" + self.EURSymbols + "&base=EUR"
        urlGBP = "https://api.apilayer.com/fixer/fluctuation?symbols=" + self.GBPSymbols + "&base=GBP"
        
        let _eur = defaults.string(forKey: "EURData")
        if (_eur != nil)
        {
            let data = _eur!.data(using: .utf8)!
            let _decoded = try! JSONDecoder().decode(Data.self, from: data)
            self.decodedEUR = _decoded
        }
        let _gbp = defaults.string(forKey: "GBPData")
        if (_gbp != nil)
        {
            let data = _gbp!.data(using: .utf8)!
            let _decoded = try! JSONDecoder().decode(Data.self, from: data)
            self.decodedGBP = _decoded
        }
        let _usd = defaults.string(forKey: "USDData")
        if(_usd != nil)
        {
            let data = _usd!.data(using: .utf8)!
            let _decoded = try! JSONDecoder().decode(Data.self, from: data)
            self.decodedUSD = _decoded
        }
        MakeDataRequest(url: urlEUR, base: Base.EUR)
        MakeDataRequest(url: urlUSD, base: Base.USD)
        MakeDataRequest(url: urlGBP, base: Base.GBP)
        SetData()
    }
    
    public func MakeDataRequest(url: String, base: Base)
    {
        semaphore = DispatchSemaphore(value: 0)
        var request = URLRequest(url: URL(string: url)!,timeoutInterval: Double.infinity)
        
        
        request.httpMethod = "GET"
        request.addValue("jaB6SfQA5PjWvDjvdBAnZx5zTu9stKD8", forHTTPHeaderField: "apikey")
        let task = URLSession.shared.dataTask(with: request)
        {
            data, response, error in
          guard let data = data else {
            print(String(describing: error))
            return
          }
            
            self.result = String(data: data, encoding: .utf8)!
            switch (base)
            {
            case Base.EUR:
                do {
                    let _eur = try? JSONDecoder().decode(Data.self, from: data)
                    if (_eur!.success != nil && _eur!.success!)
                    {
                        self.decodedEUR = _eur
                        self.defaults.set(self.result, forKey: "EURData")
                    }
                    
                }
            case Base.USD:
                do {
                    let _usd = try? JSONDecoder().decode(Data.self, from: data)
                    if (_usd!.success != nil && _usd!.success!)
                    {
                        self.decodedUSD = _usd
                        self.defaults.set(self.result, forKey: "USDData")
                    }
                    
                }
            case Base.GBP:
                do{
                    let _gbp = try? JSONDecoder().decode(Data.self, from: data)
                    if (_gbp!.success != nil && _gbp!.success!)
                    {
                        self.decodedGBP = _gbp
                        self.defaults.set(self.result, forKey: "GBPData")
                    }
                }
            }
            self.semaphore.signal()
            
            
        }
        
        task.resume()
        semaphore.wait()
        task.cancel()
    }
    
    public func SetData()
    {
        self.result = json
        let data = json.data(using: .utf8)!
        let _decoded = try! JSONDecoder().decode(Data.self, from: data)
        self.decodedEUR = _decoded
        
        
    }
}

struct Row: View{
    var data: Data
    var color = Color.green
    var key: String
    
    init(data: Data, key: String)
    {
        self.data = data
        self.key = key
        
        if(data.rates![key]!.change! < 0)
        {
            color = Color.red
        }
    }

    var body: some View
    {
        HStack
        {
            Text(data.base! + " / " + key).padding(1)
            Text("Current \n " + (String(round(data.rates![key]!.end_rate! * 1000) / 1000)))
                .padding(1)
            Text("Change \n" + (String(data.rates![key]!.change!)))
                .padding(1)
                .foregroundColor(color)
            Text("Change % \n" + String(round(data.rates![key]!.change_pct! * 100) / 100))
                .padding(1)
            .foregroundColor(color)
            
        }
        
    }
}

struct ContentView: View {
    let service = WebService()
    var body: some View {
        
        
        List
        {
            let keysEUR = ["USD","JPY","GBP","AUD","CAD","NZD","CHF","HKD"]
            let keysUSD = ["JPY","CAD","CHF"]
            let keysGBP = ["USD","JPY","AUD","CAD","CHF","HKD"]
            ForEach(keysEUR, id: \.self) { key in
                if(service.decodedEUR != nil && service.decodedEUR!.rates![key] != nil)
                {
                    Row(data: service.decodedEUR!, key: key)
                }
        
            }
            ForEach(keysUSD, id: \.self) { key in
                if(service.decodedUSD != nil && service.decodedUSD!.rates![key] != nil )
                {
                    Row(data: service.decodedUSD!, key: key)
                }
        
            }
            ForEach(keysGBP, id: \.self) { key in
                if(service.decodedGBP != nil && service.decodedGBP!.rates![key] != nil)
                {
                    Row(data: service.decodedGBP!, key: key)
                }
        
            }
            
        }
        
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        ContentView()
    }
}
