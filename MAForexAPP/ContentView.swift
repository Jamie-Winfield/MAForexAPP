//
//  ContentView.swift
//  ForexAPP
//
//  Created by user217190 on 5/2/22.
//

import SwiftUI
import Foundation

// github token = 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
public struct Data: Decodable
{
    
    let base: String?
    let date: String?
    let success: Bool?
    let rates: [String: Rates]?
    var keys: Array<String>?
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

public final class WebService : NSObject, ObservableObject
{
    
    var refreshingDict: [String: Bool] = ["EUR" : true, "USD" : true, "GBP": true, "CAD" : true, "AUD" : true, "NZD" : true, "CHF" : true]
    @Published var refreshing: Bool = true
    let defaults = UserDefaults.standard
    var result = "no result"
    
    @Published var allApiData: Array<Data> = []
    var newApiData: Array<Data> = []
    let EURSymbols = "USD,JPY,GBP,AUD,CAD,NZD,CHF,HKD"
    let USDSymbols =  "JPY,CAD,CHF"
    let GBPSymbols = "USD,JPY,AUD,CAD,CHF,HKD"
    let CADSymbols = "JPY,CHF,HKD"
    
    let BaseSymbols: [String] = ["EUR","USD","GBP","CAD","AUD", "NZD", "CHF"]
    // base pairs which should be supported =
    // EUR / USD / GBP / CAD / AUD / NZD / CHF / ZAR? / SGD?
    
    
    public override init()
    {
        super.init()
        self.allApiData = []
        
        for base in BaseSymbols
        {
            let _url = "https://api.apilayer.com/fixer/fluctuation?&base=" + base
            let _saved = defaults.string(forKey: base + "Data")
            if(_saved != nil)
            {
                let data = _saved!.data(using: .utf8)!
                let _decoded = try? JSONDecoder().decode(Data.self, from: data)
                if(_decoded != nil)
                {
                    self.allApiData.append(_decoded!)
                }
            }
            MakeDataRequest(url: _url, base: base)
            
        }
        SetKeys()
        
    }
    
    private func SetKeys()
    {
        DispatchQueue.main.async
        {
            
        
            for index in self.allApiData.indices
            {
                self.allApiData[index].keys = []
                for _key in self.allApiData[index].rates!.keys
                {
                    self.allApiData[index].keys!.append(_key)
                }
            }
        }
    }
    
    public func RefreshData()
    {
        self.newApiData = []
        
        for key in self.refreshingDict.keys
        {
            
            self.refreshingDict[key] = true
        }
        refreshing = true
        for base in BaseSymbols
        {
            let _url = "https://api.apilayer.com/fixer/fluctuation?&base=" + base
            MakeDataRequest(url: _url, base: base)
            
        }
        
        
        
    }
    
    public func MakeDataRequest(url: String, base: String)
    {
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
            print(self.result)
            let _data = try? JSONDecoder().decode(Data.self, from: data)
            if(_data != nil)
            {
                
                if (_data!.success != nil && _data!.success!)
                {
                    self.defaults.set(self.result, forKey:  base+"Data")
                    self.newApiData.append(_data!)
                    
                }
                
            }
            
            
                
            self.refreshingDict[base] = false
            
            var _refresh = false
            for refresh in self.refreshingDict
            {
                if(refresh.value)
                {
                   _refresh = true
                }
            }
            
            if (!_refresh)
            {
                DispatchQueue.main.async
                {
                    if (!self.newApiData.isEmpty)
                    {
                        self.allApiData = self.newApiData
                        
                    }
                    
                    self.refreshing = _refresh
                }
                self.newApiData = []
                self.SetKeys()
            }
            
            
            
        }
        
        task.resume()
    }
    
    public func SetData()
    {
        self.result = json
        let data = json.data(using: .utf8)!
        let _decoded = try! JSONDecoder().decode(Data.self, from: data)
        self.allApiData.append(_decoded)
        
        
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
    @ObservedObject var service = WebService()
    
    var body: some View {
        
        VStack
        {
            
            
            if(!service.refreshing)
               {
            Text("Refresh").onTapGesture {
                self.service.RefreshData()
            }.padding()
            }
            else
            {
                HStack
                {
                    Text("Refreshing").padding()
                    ProgressView()
                }
            }
        List
        {
            
            ForEach(service.allApiData.indices, id: \.self) { index in
                if(service.allApiData[index].keys != nil)
                {
                    ForEach(service.allApiData[index].keys!, id: \.self) {key in
                        Row(data: service.allApiData[index], key: key)
                    }
                }
            }
             /*
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
              */
            
        }
        }
        
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        ContentView()
    }
}
