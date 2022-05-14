//
//  ExpandedView.swift
//  MAForexAPP
//
//  Created by Jamie Winfield on 5/14/22.
//

import Foundation
import SwiftUICharts
import SwiftUI

struct ExpandedView : View
{
    @State var orientation = UIDevice.current.orientation
    
    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
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
            fav.toggle()
            for _index in service.allApiData.indices
            {
                if(service.allApiData[_index].base == base)
                {
                    index = _index
                    break
                }
            }
        }
        
        
    }
    
    
    var body: some View
    {
        Group
        {
        VStack
        {
            if(orientation.isPortrait)
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
            Text("Tap and hold to see more detail")
            Row(data: _data, key: key, service: service)
            }
            else if(orientation.isLandscape)
            {
                LineView(data: service.timeseriesDataDict[base]!.data![key]!, title: base + "/" + key, legend: "Last 30 Days", valueSpecifier: "%.4f")
                
            }
            else
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
                Text("Tap and hold to see more detail")
                Row(data: _data, key: key, service: service)            }
            
        }
        }.onReceive(orientationChanged) { _ in
            self.orientation = UIDevice.current.orientation
        }
    }
}
