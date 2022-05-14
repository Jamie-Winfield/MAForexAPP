//
//  FavouriteView.swift
//  MAForexAPP
//
//  Created by Jamie Winfield on 5/14/22.
//

import Foundation
import SwiftUI

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
