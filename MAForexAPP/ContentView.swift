//
//  ContentView.swift
//  ForexAPP
//
//  Created by Jamie Winfield on 5/2/22.
//

import SwiftUI
import Foundation
import Combine
import SwiftUICharts


// github token = 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






struct ContentView: View {
    @ObservedObject var service = WebService()
    
    var body: some View {
        
        NavigationView
        {
            VStack
            {
                
                HStack
                {
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    VStack
                    {
                        if(!service.refreshing)
                        {
                            Button("Refresh")
                            {
                                self.service.RefreshData()
                            }
                            
                        }
                        else
                        {
                            HStack
                            {
                                Text("Refreshing")
                                ProgressView()
                            }
                        }
                        
                        NavigationLink(destination: FavouriteView(_service: service))
                        {
                            Text("Favourites").padding()
                        }
                    }.padding()
                    
                    
                    Spacer()
                    Image("logo")
                        .resizable()
                        .frame(width: 75, height: 75)
                        .padding()
                    
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
                
            }.navigationBarTitleDisplayMode(.inline)
                .alert(isPresented: $service.error)
            {
                Alert(title: Text("Error"), message: Text("Failed to Refresh"), dismissButton: .default(Text("OK")))
            }
            
        }.navigationViewStyle(StackNavigationViewStyle())
        
        
        
        
    }
    
    
    
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        ContentView()
    }
}













































