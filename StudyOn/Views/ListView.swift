import Foundation
import SwiftUI

struct ListView: View {
    @EnvironmentObject var viewModel: StudyLocationViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @Binding var searchText: String
    @Binding var selectedFilter: String?
    @Binding var userFavorites: Set<String>
    
    @Binding var showDetails: Bool
    @State private var selectedLocation: StudyLocation?
    @EnvironmentObject var fontSizeManager: FontSizeManager

    var body: some View {
        NavigationView {
            List(viewModel.studyLocations.filter(shouldShowLocation), id: \.documentID) { location in
                Button(action: {
                    self.selectedLocation = location
                    showDetails.toggle()
                }) {
                    listItemContent(location)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
            }
            .fullScreenCover(isPresented: $showDetails) {
                LocationDetailView(studyLocation: selectedLocation, show: $showDetails, userFavorites: $userFavorites)
                    .environmentObject(viewModel)
                    .environmentObject(userViewModel)
                    .environmentObject(fontSizeManager)
            }
            .listStyle(PlainListStyle())
        }
        .onAppear {
            viewModel.fetchData()
        }
    }

    @ViewBuilder
    private func listItemContent(_ location: StudyLocation) -> some View {
        HStack {
            if let imageName = location.images.first {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .cornerRadius(10)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(10)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(location.name)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Rating: \(String(format: "%.1f", location.rating))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    if let crowdedness = location.envFactor.dynamicData["crowdedness"],
                        let noise = location.envFactor.dynamicData["noise"] {
                            Text("Crowdedness: \(String(format: "%.1f", crowdedness))")
                                .font(.caption)
                                .padding(5)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                            
                            Text("Noise: \(String(format: "%.1f", noise))")
                                .font(.caption)
                                .padding(5)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                    }
                }
            }
            .padding(.leading, 10)
        }
        .padding()
        .frame(height: 120)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }

    private func shouldShowLocation(_ location: StudyLocation) -> Bool {
        (selectedFilter == nil || location.category == selectedFilter || (selectedFilter == "fav" && userFavorites.contains(location.name))) &&
        (searchText.isEmpty || location.name.localizedCaseInsensitiveContains(searchText))
    }
}


