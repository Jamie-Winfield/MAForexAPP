//
//  ContentView.swift
//  ForexAPP
//
//  Created by user217190 on 5/2/22.
//

import SwiftUI
import Foundation
import Combine
import SwiftUICharts

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
public func GetDate(day: Int) -> String
{
    var dayComponent = DateComponents()
    dayComponent.day = day
    let calendar = Calendar.current
    let date = calendar.date(byAdding: dayComponent, to: Date())!
    let formatter = DateFormatter()
    formatter.locale = .current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
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
    var pairs: [ForexPair]?
}

public final class WebService : NSObject, ObservableObject
{
    
    var refreshingDict: [String: Bool] = ["EUR" : true, "USD" : true, "GBP": true, "CAD" : true, "AUD" : true, "NZD" : true, "CHF" : true]
    var refreshingDictTime: [String: Bool] = ["EUR" : true, "USD" : true, "GBP": true, "CAD" : true, "AUD" : true, "NZD" : true, "CHF" : true]
    @Published var refreshing: Bool = true
    @Published var refreshingTime: Bool = true
    let defaults = UserDefaults.standard
    var result = "no result"
    
    let nodata: Bool = true
    
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
        
            let _encoded = try? JSONEncoder().encode(self.favPairs)
            if (_encoded != nil)
            {
                self.defaults.set(_encoded, forKey: "FavPairs")
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
                    //dump(self.timeseriesData[index].data![_key]!)
                }
                self.timeseriesDataDict[self.timeseriesData[index].base!] = self.timeseriesData[index]
            }
            //dump(self.timeseriesData[0].data!["USD"]!)
            
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
                do {
                    let _data = try? JSONDecoder().decode(TimeSeries.self, from: data)
                    
                    if (_data != nil)
                    {
                        if (_data!.success != nil && _data!.success!)
                        {
                            self.defaults.set(self.result, forKey:  base+"TimeData")
                            self.newTimeseriesData.append(_data!)
                            
                        }
                    }
                    
                    self.refreshingDictTime[base] = false
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
    var data: PairData
    var color = Color.green
    var key: String
    var service: WebService

    
    init(data: PairData, key: String, service: WebService)
    {
        self.data = data
        self.key = key
        self.service = service
        
        if(data.rates[key]!.change! < 0)
        {
            color = Color.red
        }
        
        
    }
    
   

    var body: some View
    {
        HStack
        {
            Text(data.base + " / " + key).padding(1)
            
            Text("Current \n " + (String(round(data.rates[key]!.end_rate! * 1000) / 1000)))
                .padding(1)
            
            Text("Change \n" + (String(data.rates[key]!.change!)))
                .padding(1)
                .foregroundColor(color)
            
            Text("Change % \n" + String(round(data.rates[key]!.change_pct! * 100) / 100))
                .padding(1)
            .foregroundColor(color)
            
            
            
        }
        
    }
}

struct LineShape: Shape
{
    var yValues: [Double]
    
    func path(in rect: CGRect) -> Path
    {
        let xIncrement = (rect.width / (CGFloat(yValues.count) - 1))
        let factor = rect.height / CGFloat(yValues.max() ?? 1.0)
        var path = Path()
        path.move(to: CGPoint(x: 0.0, y: rect.height - (yValues[0] * factor)))
        for i in 1..<yValues.count
        {
            let pt = CGPoint(x: (Double(i) * Double(xIncrement)), y: (rect.height - (yValues[i] * factor)))
            path.addLine(to: pt)
        }
        return path
    }
    
}

struct LineChartView1: View
{
    var title: String
    var data: [Double]
    
    var body: some View
    {
        GeometryReader
        {
            gr in
            let headHeight = gr.size.height * 0.10
            VStack
            {
                ChartHeaderView(title: title, height: headHeight)
                ChartAreaView(data: data)
            }
        }
    }
}

struct ChartHeaderView: View
{
    var title: String
    var height: CGFloat
    
    var body: some View
    {
        Text(title)
            .frame(height: height)
    }
}

struct ChartAreaView: View
{
    var data: [Double]
    
    var body: some View
    {
        ZStack
        {
            RoundedRectangle(cornerRadius: 3.0)
                .fill(Color(#colorLiteral(red: 0.8906, green: 0.9005, blue: 0.82088, alpha: 1)))
            
            LineShape(yValues: data)
                .stroke(Color.red, lineWidth: 2.0)
        }
    }
}

struct FavouriteView: View{
    
    var service: WebService
    
    init(_service: WebService) {
        service = _service
    }
    
    var body: some View
    {
            List
            {
                ForEach(service.favApiData.indices, id: \.self)
                { index in
                        
                            
                    let base = service.favApiData[index].base
                    let key = service.favApiData[index].quote
                        
                    NavigationLink(destination: ExpandedView(_index: index, _key: key , _base: base, _service: service))
                    {
                        Row(data: service.favApiData[index], key: key, service: service)
                    }
                        
                    
                }
                
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
            Button("Refresh") {
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
            
            
            NavigationView
            {
                VStack
                {
                    NavigationLink(destination: FavouriteView(_service: service))
                    {
                        Text("Favourites").padding()
                    }
                List
                {
            
                    
                    
                    ForEach(service.allApiData.indices, id: \.self) { index in
                        if(service.allApiData[index].keys != nil)
                        {
                            ForEach(service.allApiData[index].keys!, id: \.self) {key in
                                
                                let base = service.allApiData[index].base!
                                
                                
                                NavigationLink(destination: ExpandedView(_index: index, _key: key, _base: base, _service: service))
                                {
                                    let _data: PairData = PairData(_base: base, _quote: key, _start_rate: service.allApiData[index].rates![key]!.start_rate!, _end_rate: service.allApiData[index].rates![key]!.end_rate!, _change: service.allApiData[index].rates![key]!.change!, _change_pct: service.allApiData[index].rates![key]!.change_pct!)
                                    Row(data: _data, key: key, service: service)
                                }
                            }
                        }
                    }
            
                }
                }
            }.navigationTitle("Back").navigationViewStyle(StackNavigationViewStyle())
        }
        
        
    }
}

struct ExpandedView : View
{
    var index: Int
    var key: String
    var service: WebService
    var base: String
    var pair: ForexPair
    @State var fav: Bool = false
    init(_index: Int, _key: String, _base: String, _service: WebService)
    {
        index = _index
        key = _key
        service = _service
        base = _base
        
        pair = ForexPair(_base: base, _quote: key)
        if(service.HasFavPair(_pair: pair))
        {
            //fav.toggle()
        }
        
        
    }
    
    
    var body: some View
    {
        VStack
        {
            if(!service.HasFavPair(_pair: pair) && !fav)
            {
                Button("Favourite")
                {
                    service.AddFavPair(_pair: ForexPair(_base: base, _quote: key))
                    fav.toggle()
                
                }
            }
            else
            {
                Button("Un-Favourite")
                {
                    service.RemoveFavPair(_pair: ForexPair(_base: base, _quote: key))
                    fav.toggle()
                
                }
                
            }
            LineView(data: service.timeseriesDataDict[base]!.data![key]!, title: base + "/" + key, legend: "Last 30 Days", valueSpecifier: "%.4f")
            let _data: PairData = PairData(_base: base, _quote: key, _start_rate: service.allApiData[index].rates![key]!.start_rate!, _end_rate: service.allApiData[index].rates![key]!.end_rate!, _change: service.allApiData[index].rates![key]!.change!, _change_pct: service.allApiData[index].rates![key]!.change_pct!)
            Row(data: _data, key: key, service: service)
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        ContentView()
    }
}













































