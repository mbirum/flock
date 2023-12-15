
import Foundation
import SwiftUI
import MapKit

struct LocationSearchView: View {
    @State var onResultTap: (_ item: MKLocalSearchCompletion) -> Void
    @Binding var isPresent: Bool
    @FocusState var isLoaded: Bool
    
    @ObservedObject var locationSearchService: LocationSearchService = LocationSearchService()
    
    var body: some View {
//        Form {
            VStack {
                HStack {
                    TextField("123 Main St", text: $locationSearchService.searchQuery)
                        .focused($isLoaded)
                        .frame(height: 40)
                        .padding(18)
                        .padding(.top, 5)
                        .onAppear(perform: {
                            self.isLoaded = true
                        })
                        .onChange(of: locationSearchService.searchQuery) {
                            if (locationSearchService.searchQuery == "") {
                                locationSearchService.completions = []
                            }
                        }
                    Button("Cancel", action: {
                        isPresent.toggle()
                    })
                    .padding(.top, 23)
                    .padding(.trailing, 18)
                    .padding(.bottom, 18)
                }
                Divider()
                List(locationSearchService.completions) { completion in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(completion.title)
                            Text(completion.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 5)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        locationSearchService.completions = []
                        locationSearchService.searchQuery = ""
                        onResultTap(completion)
                    }
                    
                }.listStyle(.plain)
                
            }
//        }
        
    }
}

