//
//  LocationSelectionView.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 20/02/2025.
//


import SwiftUI

struct LocationSelectionView: View {
    @State private var selectedLocation: String = ""
    
    var body: some View {
        VStack {
            Text("Select Location:")
                .font(.headline)
            
            List(locations, id: \.self) { location in
                Button(action: {
                    selectedLocation = location
                    UserDefaults.standard.set(location, forKey: "location")
                }) {
                    Text(location)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            .navigationTitle("Select Location")
        }
    }
}

struct LocationSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LocationSelectionView()
    }
}
