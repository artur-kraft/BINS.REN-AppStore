//
//  InfoView.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 17/02/2025.
//

import SwiftUI
import FirebaseAnalytics

// MARK: - InfoView
struct InfoView: View {
    let bins: [Bin] = [
        Bin(name: "Blue", imageName: "blueBin", itemsAllowed: ["cardboard (flatten it so it's easier to collect)", "cereal boxes", "toilet and kitchen roll tubes", "paper (as long as it's clean and dry)", "envelopes (it's okay to leave the clear, plastic window on them)", "magazines", "newspapers", "office paper", "telephone directories", "paperback books", "catalogues", "junk mail and takeaway menus"], itemsNotAllowed: ["hardback books", "envelopes with interior padding, such as bubble wrap", "plastic wrapping and bubble wrap", "polystyrene", "packaging with food residue", "used tissues and kitchen roll", "foil gift wrapping paper", "tinfoil", "shredded paper", "takeaway pizza boxes (they are too dirty)", "plastic bags (put any paper and cardboard directly into the bin, not in a bag)", "photos", "Tetra Pak packaging"]),
        Bin(name: "Brown", imageName: "brownBin", itemsAllowed: ["grass cuttings (permission required)", "flowers and plants (permission required)", "weeds (permission required)", "leaves (permission required)", "branches and twigs - small enough to fit in the bin with the lid closed  (permission required)", "cooked and uncooked food", "fruit and vegetable peelings", "tea bags and coffee grounds", "eggshells", "out-of-date food (all packaging removed)", "meat, fish, and small bones"], itemsNotAllowed: ["plastic bags", "packaging", "liquids", "fats and cooking oils (set these aside and wait for them to solidify, and then they can go in your general waste bin)", "rubble and soil", "pet waste and bedding", "plant pots", "wood and fencing", "timber or logs", "garden furniture", "stones, gravel, or concrete (including DIY waste, such as plasterboard)"]),
        Bin(name: "Green", imageName: "greenBin", itemsAllowed: ["plastic bottles", "plastic pots, tubs, and trays", "plastic fruit and vegetable trays", "plastic takeaway containers (emptied and rinsed)", "cleaning product bottles", "shampoo and shower gel bottles", "drinks cans (emptied and rinsed)", "food tins, including pet food tins (emptied and rinsed)", "biscuit and sweet tins", "aerosols", "glass bottles and jars", "plastic milk cartons"], itemsNotAllowed: ["food residue", "carrier bags", "sweet and crisp wrappers", "plastic wrapping and bubble wrap", "polystyrene food and drink pouches", "hard plastics (such as toys, coat hangers, or CD cases)", "food and drink pouches", "light bulbs", "Pyrex or crockery", "mirrors", "tinfoil", "batteries", "vapes", "plastic bags (put any plastic, cans, and glass directly into the bin, not in a bag)"]),
        Bin(name: "Grey", imageName: "greyBin", itemsAllowed: ["non-recyclable waste", "plastic bags", "polystyrene or foam packing", "crisp and sweet wrappers", "used tissues and paper towels", "cling film", "tinfoil", "lightbulbs", "pet litter", "nappies", "personal hygiene products (such as tampons, incontinence products, and baby wipes)", "food and drinks pouches", "hard plastics (such as toys, coat hangers, or CD cases)", "envelopes with interior padding, such as bubble wrap", "shredded paper", "Tetra Pak packaging"], itemsNotAllowed: ["plastics, cans, and glass", "paper, card, and cardboard", "food waste", "garden waste", "electrical items", "textiles and shoes", "batteries", "vapes (vape refills can go in your grey bin, but not the battery)"])
    ]
    
    @State private var selectedBin: Bin? = nil
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        ScrollView {
            VStack {
                Text("Press on each bin to find out what items should go there.")
                    .font(sizeClass == .regular ? .title : .headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, sizeClass == .regular ? 60 : 30)
                    .padding(.top, 40)

                topRow
                    .padding()
                
                if let bin = selectedBin {
                    binDetails(for: bin)
                        .transition(.slide)
                }
                
                bottomRow
                    .padding()
            }
        }
        .navigationTitle("Bin Information")
    }
    
    private var topRow: some View {
        LazyHGrid(rows: [GridItem(.flexible())], spacing: 20) {
            ForEach(bins.indices.prefix(2), id: \.self) { index in
                let bin = bins[index]
                binButton(for: bin)
            }
        }
        .padding(.horizontal, sizeClass == .regular ? 60 : 20)
    }
    
    private var bottomRow: some View {
        LazyHGrid(rows: [GridItem(.flexible())], spacing: 20) {
            ForEach(bins.indices.suffix(from: 2), id: \.self) { index in
                let bin = bins[index]
                binButton(for: bin)
            }
        }
        .padding(.horizontal, sizeClass == .regular ? 60 : 20)
    }
    
    private func binButton(for bin: Bin) -> some View {
        Button(action: {
            // Log event when a bin is pressed
            logBinSelection(binName: bin.name)
            
            if let selectedBin = selectedBin, selectedBin == bin {
                self.selectedBin = nil
            } else {
                self.selectedBin = bin
            }
        }) {
            VStack {
                Image(bin.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: sizeClass == .regular ? 240 : 160, height: sizeClass == .regular ? 384 : 256)
                    .opacity(selectedBin.map { $0 == bin ? 0.5 : 1 } ?? 1)
                    .grayscale(selectedBin.map { $0 == bin ? 0.5 : 0 } ?? 0)

                Text(bin.name)
                    .font(sizeClass == .regular ? .title2 : .headline)
                    .foregroundColor(selectedBin.map { $0 == bin ? .gray : .primary } ?? .primary)
            }
        }
    }
    


    
    private func binDetails(for bin: Bin) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Items allowed in ").font(.title2).bold() +
            Text("\(bin.name.lowercased())").font(.title2).bold().foregroundColor(colorForBinName(bin.name)) +
            Text(" bin:").font(.title2).bold()
            
            // Display allowed items with bullet points
            ForEach(bin.itemsAllowed, id: \.self) { item in
                HStack(alignment: .top) {
                    Text("✅")
                        .font(.title3)
                        .frame(width: 30, alignment: .leading)
                    
                    Text(item)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 600, alignment: .leading)
                        .padding(.horizontal)
                }
            }
            Spacer()
            
            Text("Items not allowed in ").font(.title2).bold() +
            Text("\(bin.name.lowercased())").font(.title2).bold().foregroundColor(colorForBinName(bin.name)) +
            Text(" bin:").font(.title2).bold()
            
            // Display not allowed items with bullet points
            ForEach(bin.itemsNotAllowed, id: \.self) { item in
                HStack(alignment: .top) {
                    Text("❌")
                        .font(.title3)
                        .frame(width: 30, alignment: .leading)
                    
                    Text(item)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 600, alignment: .leading)
                        .padding(.horizontal)
                }
            }
        }
        .frame(maxWidth: 700) // Limit the overall width of the list container
        .padding(sizeClass == .regular ? 40 : 30)
        .multilineTextAlignment(.leading)
        .transition(.slide)
    }

}

func logBinSelection(binName: String) {
    Analytics.logEvent("bin_selected", parameters: [
        "bin_name": binName
    ])
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView()
    }
}
