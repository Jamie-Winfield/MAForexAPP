//
//  WebService.swift
//  MAForexAPP
//
//  Created by Jamie Winfield on 5/14/22.
//

import Foundation


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

public struct TimeSeries: Decodable
{
    let base: String?
    let success: Bool?
    let start_date: String?
    let end_date: String?
    let rates: [String: [String: Double]]?
    var keys: Array<String>?
    var dates: Array<String>?
    var data: [String: Array<Double>]?
}

public struct ForexPair: Codable
{
    var base: String
    var quote: String
    
    init(_base: String, _quote: String) {
        base = _base
        quote = _quote
    }
}

public struct PairData
{
    var base: String
    var quote: String
    var start_rate: Double
    var end_rate: Double
    var change: Double
    var change_pct: Double
    var rates: [String: Rates]
    
    init(_base: String, _quote: String, _start_rate: Double, _end_rate: Double, _change: Double, _change_pct: Double)
    {
        base = _base
        quote = _quote
        start_rate = _start_rate
        end_rate = _end_rate
        change = _change
        change_pct = _change_pct
        let _rate: Rates = Rates(start_rate: start_rate, end_rate: end_rate, change: change, change_pct: change_pct)
        rates = [:]
        
        rates[_quote] = _rate
    }
}

public struct FavForexPairs: Codable
{
    var pairs: Array<ForexPair>?
}

public final class WebService : NSObject, ObservableObject
{
    
    var refreshingDict: [String: Bool] = ["EUR" : true, "USD" : true, "GBP": true, "CAD" : true, "AUD" : true, "NZD" : true, "CHF" : true]
    var refreshingDictTime: [String: Bool] = ["EUR" : true, "USD" : true, "GBP": true, "CAD" : true, "AUD" : true, "NZD" : true, "CHF" : true]
    @Published var refreshing: Bool = true
    @Published var refreshingTime: Bool = true
    let defaults = UserDefaults.standard
    var result = "no result"
    
    let nodata: Bool = false    // used to set whether the application should make an API call at startup false = make call
    
    let apikey: String = "jaB6SfQA5PjWvDjvdBAnZx5zTu9stKD8"
    @Published var error: Bool = false
    
    @Published var allApiData: Array<Data> = []
    @Published var favApiData: Array<PairData> = []
    var favPairs: Array<ForexPair> = []
    
    var newApiData: Array<Data> = []
    
    @Published var timeseriesData: Array<TimeSeries> = []
    @Published var timeseriesDataDict: [String: TimeSeries] = [:]
    var newTimeseriesData: Array<TimeSeries> = []
    
    let EURSymbols = "USD,JPY,GBP,AUD,CAD,NZD,CHF,HKD"
    let USDSymbols =  "JPY,CAD,CHF"
    let GBPSymbols = "USD,JPY,AUD,CAD,CHF,HKD"
    let CADSymbols = "JPY,CHF,HKD"
    let AUDSymbols = "USD,,JPY,CAD,CHF,NZD,HKD"
    let NZDSymbols = "USD,JPY,CAD,CHF,HKD"
    let CHFSymbols = "JPY,HKD"
    
    let BaseSymbols: [String] = ["EUR","USD","GBP","CAD","AUD", "NZD", "CHF"]
    var QuoteSymbols: [String: String] = [:]
    // base pairs which should be supported =
    // EUR / USD / GBP / CAD / AUD / NZD / CHF / ZAR? / SGD?
    
    enum RequestType
    {
        case FLUCTUATION, TIMESERIES
    }
    
    public func AddFavPair(_pair: ForexPair)
    {
        DispatchQueue.main.async
        {
            for pair in self.favPairs
            {
                if (pair.base == _pair.base && pair.quote == _pair.quote)
                {
                    // already holds fav pair
                    return
                }
            }
            self.favPairs.append(_pair)
        
            var _favforexpairs: FavForexPairs = FavForexPairs()
            _favforexpairs.pairs = []
            
            for pair in self.favPairs
            {
                
                _favforexpairs.pairs!.append(pair)
                
            }
            let _encoded = try? JSONEncoder().encode(_favforexpairs)
            
            if (_encoded != nil)
            {
                let _encodedString = String(data: _encoded!, encoding: .utf8)!
                self.defaults.set(_encodedString, forKey: "FavPairs")
            }
            if let temp = self.defaults.string(forKey: "FavPairs")
            {
                print(temp)
            }
        
            for _data in self.allApiData
            {
                if (_data.base == _pair.base)
                {
                    for _quote in _data.keys!
                    {
                        if (_quote == _pair.quote)
                        {
                            let _forexdata = PairData(_base: _data.base!, _quote: _quote, _start_rate: _data.rates![_quote]!.start_rate!, _end_rate: _data.rates![_quote]!.end_rate!, _change: _data.rates![_quote]!.change!, _change_pct: _data.rates![_quote]!.change_pct!)
                            self.favApiData.append(_forexdata)
                        
                            return
                        }
                    }
                }
            }
        }
    }
    
    public func RemoveFavPair(_pair: ForexPair)
    {
        DispatchQueue.main.async
        {
            
        
            for index in self.favPairs.indices
            {
                if(self.favPairs[index].base == _pair.base && self.favPairs[index].quote == _pair.quote)
                {
                    self.favPairs.remove(at: index)
                    let tempPairs = self.favPairs
                    self.favPairs = []
                    self.favApiData = []
                    for pair in tempPairs
                    {
                        self.AddFavPair(_pair: pair)
                    }
                
                    return
                }
            }
        }
    }
    
    public func HasFavPair(_pair: ForexPair) -> Bool
    {
        for pair in favPairs
        {
            if (pair.base == _pair.base && pair.quote == _pair.quote)
            {
                return true
            }
        }
        return false
        
    }
    
    public override init()
    {
        super.init()
        self.QuoteSymbols = ["EUR": EURSymbols, "USD": USDSymbols, "GBP": GBPSymbols, "CAD": CADSymbols, "AUD": AUDSymbols, "NZD": NZDSymbols, "CHF": CHFSymbols]
        
        self.allApiData = []
        
        for base in BaseSymbols
        {
           
            var _saved = defaults.string(forKey: base + "Data")
            if(_saved != nil)
            {
                let data = _saved!.data(using: .utf8)!
                let _decoded = try? JSONDecoder().decode(Data.self, from: data)
                if(_decoded != nil)
                {
                    self.allApiData.append(_decoded!)
                }
            }
            
            _saved = defaults.string(forKey: base + "TimeData")
            if(_saved != nil)
            {
                let data = _saved!.data(using: .utf8)!
                let _decoded = try? JSONDecoder().decode(TimeSeries.self, from: data)
                if(_decoded != nil)
                {
                    self.timeseriesData.append(_decoded!)
                    self.timeseriesDataDict["base"] = _decoded
                }
            }
            if(!nodata)
            {
                var _url = "https://api.apilayer.com/fixer/fluctuation?start_date=" + GetDate(day: -1) + "&end_date=" + GetDate(day: 0) + "&symbols=" + QuoteSymbols[base]! + "&base=" + base
                MakeDataRequest(url: _url, base: base, type: .FLUCTUATION)
                _url = "https://api.apilayer.com/fixer/timeseries?start_date=" + GetDate(day: -30) + "&end_date=" + GetDate(day: 0) + "&symbols=" + QuoteSymbols[base]! + "&base=" + base
                MakeDataRequest(url: _url, base: base, type: .TIMESERIES)
                
            }
            else
            {
                DispatchQueue.main.async {
                    self.refreshingTime = false
                    self.refreshing = false
                }
            }
            
        }
        
        let _saved = self.defaults.string(forKey: "FavPairs")
        if(_saved != nil)
        {
            let data = _saved!.data(using: .utf8)!
            let _decoded = try? JSONDecoder().decode(FavForexPairs.self, from: data)
            if (_decoded != nil)
            {
                for _pair in _decoded!.pairs!
                {
                    self.favPairs.append(_pair)
                }
            }
        }
        SetKeys()
        SetDates()
    }
    
    private func SetDates()
    {
        DispatchQueue.main.async
        {
            for index in self.timeseriesData.indices
            {
                self.timeseriesData[index].dates = []
                self.timeseriesData[index].keys = []
                self.timeseriesData[index].data = [:]
                
                for i in -30...0
                {
                    if (self.timeseriesData[index].rates![GetDate(day: i)] != nil)
                    {
                        self.timeseriesData[index].dates!.append(GetDate(day: i))
                    }
                    
                }
                
                for _key in self.timeseriesData[index].rates![self.timeseriesData[index].dates![0]]!.keys
                {
                    self.timeseriesData[index].keys!.append(_key)
                    var _data: [Double] = []
                    for i in -30...0
                    {
                        if(self.timeseriesData[index].rates![GetDate(day: i)]?[_key] != nil )
                        {
                            _data.append(self.timeseriesData[index].rates![GetDate(day: i)]![_key]!)
                            
                        }
                        
                    }
                    self.timeseriesData[index].data![_key] = _data
                }
                self.timeseriesDataDict[self.timeseriesData[index].base!] = self.timeseriesData[index]
            }
            
        }
        
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
            
            let _favpairs = self.favPairs
            self.favPairs = []
            self.favApiData = []
            for _pair in _favpairs
            {
                self.AddFavPair(_pair: _pair)
            }
            
        }
    }
    
    public func RefreshData()
    {
        self.newApiData = []
        self.newTimeseriesData = []
        
        for key in self.refreshingDict.keys
        {
            
            self.refreshingDict[key] = true
        }
        for key in self.refreshingDictTime.keys
        {
            self.refreshingDictTime[key] = true
        }
        refreshing = true
        refreshingTime = true
        for base in BaseSymbols
        {
            var _url = "https://api.apilayer.com/fixer/fluctuation?start_date=" + GetDate(day: -1) + "&end_date=" + GetDate(day: 0) + "&symbols=" + QuoteSymbols[base]! + "&base=" + base
            MakeDataRequest(url: _url, base: base, type: .FLUCTUATION)
            _url = "https://api.apilayer.com/fixer/timeseries?start_date=" + GetDate(day: -30) + "&end_date=" + GetDate(day: 0) + "&symbols=" + QuoteSymbols[base]! + "&base=" + base
            MakeDataRequest(url: _url, base: base, type: .TIMESERIES)
        }
    }
    
    func MakeDataRequest(url: String, base: String, type: RequestType)
    {
        var request = URLRequest(url: URL(string: url)!,timeoutInterval: 10)
        
        request.httpMethod = "GET"
        request.addValue(apikey, forHTTPHeaderField: "apikey")
        let task = URLSession.shared.dataTask(with: request)
        {
            data, response, error in
          guard let data = data else {
            print(String(describing: error))
            
              DispatchQueue.main.async {
                  self.error = true
              }
            self.SetRefreshing(_key: base, _type: type)
            return
          }
            
            self.result = String(data: data, encoding: .utf8)!
            print(self.result)
            
            var _error: Bool = false
            switch (type)
            {
            case .FLUCTUATION:
                do {
                    let _data = try? JSONDecoder().decode(Data.self, from: data)
                    if(_data != nil)
                    {
                        
                        if (_data!.success != nil && _data!.success!)
                        {
                            self.defaults.set(self.result, forKey:  base+"Data")
                            self.newApiData.append(_data!)
                            
                        }
                        else
                        {
                            _error = true
                        }
                        
                    }
                    else
                    {
                        _error = true
                    }
                }
            case .TIMESERIES:
                do {
                    let _data = try? JSONDecoder().decode(TimeSeries.self, from: data)
                    
                    if (_data != nil)
                    {
                        if (_data!.success != nil && _data!.success!)
                        {
                            self.defaults.set(self.result, forKey:  base+"TimeData")
                            self.newTimeseriesData.append(_data!)
                            
                        }
                        else
                        {
                            _error = true
                        }
                    }
                    else
                    {
                        _error = true
                    }
                }
            }
            self.SetRefreshing(_key: base, _type: type)
            DispatchQueue.main.async
            {
                if (_error)
                {
                    self.error = _error
                }
            }
        }
        
        task.resume()
    }
    
    func SetRefreshing(_key: String, _type: RequestType)
    {
        switch (_type)
        {
        case .FLUCTUATION:
            do {
                
                self.refreshingDict[_key] = false
                
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
                        if (self.newApiData.isEmpty == false)
                        {
                            self.allApiData = self.newApiData
                            
                        }
                        self.newApiData = []
                        self.SetKeys()
                        self.refreshing = _refresh
                        
                    }
                    
                }
                
            }
        case .TIMESERIES:
            do{
                self.refreshingDictTime[_key] = false
                var _refresh = false
                
                for refresh in self.refreshingDictTime
                {
                    if (refresh.value)
                    {
                        _refresh = true
                    }
                }
                if(!_refresh)
                {
                    
                   
                    DispatchQueue.main.async
                    {
                        if(self.newTimeseriesData.isEmpty == false)
                        {
                            self.timeseriesData = self.newTimeseriesData
                            self.SetDates()
                        }
                        self.newTimeseriesData = []
                        self.refreshingTime = false
                    }
                }
                
            }
        }
    }
}
