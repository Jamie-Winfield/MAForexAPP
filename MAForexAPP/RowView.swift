//
//  RowView.swift
//  MAForexAPP
//
//  Created by Jamie Winfield on 5/14/22.
//

import Foundation
import SwiftUI


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
            
            Text("Current \n " + (String(format: "%.3f", data.rates[key]!.end_rate!)))
                .padding(1.0)
            
            Text("Change \n" + (String(data.rates[key]!.change!)))
                .padding(1)
                .foregroundColor(color)
            
            Text("Change% \n" + String(format: "%.2f", data.rates[key]!.change_pct!))
                .padding(1.0)
                .foregroundColor(color)
            
            
            
        }
        
    }
}
