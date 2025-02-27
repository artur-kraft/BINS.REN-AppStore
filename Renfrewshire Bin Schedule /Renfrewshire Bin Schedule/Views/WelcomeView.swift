//
//  WelcomeView.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 17/02/2025.
//


import SwiftUI
import FirebaseAnalytics

struct WelcomeView: View {
    @AppStorage("location") private var location: String?
    

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                List {
                    // List each standard location as a button
                    ForEach(locations, id: \.self) { loc in
                        Button(action: {
                            // Save the chosen location
                            location = loc
                            
                            // Log the chosen location in Firebase Analytics
                            Analytics.logEvent("location_chosen", parameters: [
                                "location_name": loc
                            ])
                        }) {
                            Text(loc)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // "Other" option as a NavigationLink to a new form
                    NavigationLink(destination: OtherLocationView()) {
                        Text("Other")
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.blue)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("🏴󠁧󠁢󠁳󠁣󠁴󠁿 Select location:")
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
