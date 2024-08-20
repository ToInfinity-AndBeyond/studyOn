import SwiftUI
import Firebase


struct LocationDetailView: View {
  @EnvironmentObject var viewModel: StudyLocationViewModel
  @State var studyLocation: StudyLocation?
  @Binding var show: Bool
  @Binding var userFavorites: Set<String>

  @State private var userCrowdness: Double = 0
  @State private var userNoise: Double = 0

  @State private var isOpen: Bool = true    
  @EnvironmentObject var userViewModel: UserViewModel
  @State private var isFavorite: Bool = false  
  @EnvironmentObject var fontSizeManager: FontSizeManager
  @State private var showConfirmation: Bool = false
  @State private var userRating: Double = 2.5
  @State private var commentContent: String = ""
  @State private var userName: String = ""




  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
       Button {
         show.toggle()
       } label: {
         Image(systemName: "arrowtriangle.left.fill")
           .resizable()
           .frame(width: 24, height: 24)
           .foregroundStyle(.gray, Color(.systemGray6))
       }
       .padding(.leading, 15)
       .padding(.bottom, 25)

      HStack {
        Text(studyLocation?.name ?? "")
          .font(.title)
          .fontWeight(.black)
          .padding(.leading, 15)

        Spacer()

        Button(action: {
          toggleFavorite()
        }) {
          Image(systemName: isFavorite ? "heart.fill" : "heart")
            .resizable()
            .frame(width: 24, height: 24)
            .foregroundColor(isFavorite ? .red : .gray)
        }
        .padding(.trailing, 15)
        .onAppear(){
            viewModel.fetchData()
            userViewModel.fetchUserFavorites() {
                self.isFavorite = userViewModel.userFavorites.contains(studyLocation?.name ?? "")
            }
            Task {
                    await viewModel.fetchComments(for: studyLocation)
                }
        }
      }

      HStack {
        Text(isOpen ? "Open" : "Closed")
          .font(.title2)
          .fontWeight(.bold)
          .foregroundStyle(isOpen ? .green : .red)
        Spacer()
      }
      .padding(.leading, 15)
      .padding([.top, .bottom], 5)
      .onAppear {
        isOpen = (studyLocation?.hours.isOpenNow()) != nil
      }

      HStack(alignment: .center) {
        let score = String(format: "%.1f", studyLocation?.rating ?? 0)
        StarRatingView(rating: studyLocation?.rating ?? 0, color: .orange, starRounding: .ceilToHalfStar, starSize: 20)
        Text("\(score)")
          .font(.title2)
          .fontWeight(.bold)
          .foregroundStyle(.orange)

        Text("(\(studyLocation?.comments.count ?? 0))").font(.title3).fontWeight(.medium)
        Spacer()
      }
      .padding([.leading, .trailing], 15)

      HStack(alignment: .center) {
        Menu(
          "\(crowdnessLevelToText(userCrowdness: userCrowdness, dataCrowdness: studyLocation?.envFactor.dynamicData["crowdedness"] ?? -1))"
        ) {
          Button("Sparse") { userCrowdness = 1 }
                .disabled(!NotificationHandlerModel.shared.allowDynamicDataSubmit)
          Button("Crowded") { userCrowdness = 2 }
                .disabled(!NotificationHandlerModel.shared.allowDynamicDataSubmit)
          Button("Full") { userCrowdness = 3 }
                .disabled(!NotificationHandlerModel.shared.allowDynamicDataSubmit)
        }
        .buttonStyle(.bordered)

        Menu(
          "\(noiseLevelToText(userNoise: userNoise, dataNoise: studyLocation?.envFactor.dynamicData["noise"] ?? -1))"
        ) {
          Button("Quiet") { userNoise = 1 }
                .disabled(!NotificationHandlerModel.shared.allowDynamicDataSubmit)
          Button("Audible") { userNoise = 2 }
                .disabled(!NotificationHandlerModel.shared.allowDynamicDataSubmit)
          Button("Loud") { userNoise = 3 }
                .disabled(!NotificationHandlerModel.shared.allowDynamicDataSubmit)
        }
        .buttonStyle(.bordered)
 
        Spacer()

        Button("Submit") {
          let crowdness =
            userCrowdness == 0
            ? studyLocation?.envFactor.dynamicData["crowdedness"] ?? 0 : userCrowdness

          let noise =
            userNoise == 0 ? studyLocation?.envFactor.dynamicData["noise"] ?? 0 : userNoise
            
          NotificationHandlerModel.shared.allowDynamicDataSubmit = false

          Task {
            await viewModel.submitDynamicData(
              studyLocation: studyLocation, crowdness: crowdness, noise: noise)
              
            viewModel.fetchData()
            let findID = studyLocation?.documentID ?? ""
            studyLocation = viewModel.findLocationByDocumentID(documentIDKey: findID)
          }

          withAnimation {
            showConfirmation = true
          }

          DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation {
                showConfirmation = false
            }
          }
        }
        .disabled(!NotificationHandlerModel.shared.allowDynamicDataSubmit)
        .buttonStyle(.borderedProminent)
      }
      .padding([.leading, .trailing], 20)
      .padding(.top, 10)

      ImageSliderView(images: studyLocation?.images ?? []).frame(height: 300)
        .padding([.leading, .trailing], 8)
        .padding([.top, .bottom], 12)

      if let envFactor = studyLocation?.envFactor {
        AtmosphereView(envFactor: envFactor)
      }

      openHoursButton
      if viewModel.showOpenHoursList {
        OpeningHoursView(hours: studyLocation?.hours ?? [:])
          .padding([.leading, .trailing], 18)
      }
        if studyLocation?.category == "cafe" {
            Text("Preferred Study Time: Mon-Fri 10:00 - 15:00")
                .font(.system(size: fontSizeManager.bodySize))
                .padding()
        }

      detailsButton
      if viewModel.showEnvFactors {
        if let envFactor = studyLocation?.envFactor {
          EnvView(envFactor: envFactor)
        }
      }

      VStack {
        Text("Comments")
          .font(.largeTitle)
          .padding()
          
          HStack {
              StarSwipeView(rating: $userRating, color: .orange, starRounding: .ceilToHalfStar, starSize: 40)
              Spacer()
                
              Button("Submit") {
                let num = studyLocation?.num ?? 0
                let currentRating = studyLocation?.rating ?? 0
      //          print(num)
      //          print(currentRating)
                let newRating = (Double(num) * currentRating + userRating) / Double(num + 1)

                Task {
                  await viewModel.submitRating(studyLocation: studyLocation, rating: newRating, ratingNum: num + 1)
                  viewModel.fetchData()
                  let findID = studyLocation?.documentID ?? ""
                  studyLocation = viewModel.findLocationByDocumentID(documentIDKey: findID)
                }
              }
              .padding(8)
              .background(.blue)
              .foregroundColor(.white)
              .cornerRadius(8)
              
          }
          .padding(.horizontal, 40)
          
        CommentsView(comments: studyLocation?.comments ?? [])
          VStack(alignment: .leading) {
                              TextField("Your name", text: $userName)
                                  .textFieldStyle(RoundeorderTextFieldStyle())
                                  .padding(.horizontal)
                                  .disabled(true)

                              TextField("Add a comment", text: $commentContent)
                                  .textFieldStyle(RoundedBorderTextFieldStyle())
                                  .padding(.horizontal)

                              Button("Submit Comment") {
                                  if !commentContent.isEmpty {
                                      let newComment = Comment(name: userName, content: commentContent)

                                      Task {
                                          await viewModel.submitComment(studyLocation: studyLocation, comment: newComment)
                                          await viewModel.fetchComments(for: studyLocation)
                                          let findID = studyLocation?.documentID ?? ""
                                          studyLocation = viewModel.findLocationByDocumentID(documentIDKey: findID)
                                          commentContent = ""
                                      }
                                  }
                              }
                              .padding()
                              .background(Color.blue)
                              .foregroundColor(.white)
                              .cornerRadius(8)
                              .padding(.horizontal)
                          }
      }
      .padding(.bottom, 20)
    }
    .onAppear {
                if let currentUser = userViewModel.currentUser {
                    userName = currentUser.name
                }
                Task {
                    await viewModel.fetchComments(for: studyLocation)
                }
            }
    .overlay(
      VStack {
        if showConfirmation {
          HStack {
            Spacer()
            HStack {
              Image(systemName: "checkmark")
                .foregroundColor(.white)
              Text("Submitted")
                .foregroundColor(.white)
            }
            .padding()
            .background(Color.gray)
            .cornerRadius(8)
            Spacer()
          }
          .transition(.opacity)
          .padding(.top, 200)
        }
        Spacer()
      }
    )
    .scrollable()
  }

  private func toggleFavorite() {
    if isFavorite {
      userViewModel.removeFavoriteLocation(locationId: studyLocation?.name ?? "")
        userFavorites.remove(studyLocation?.name ?? "")
    } else {
      userViewModel.addFavoriteLocation(locationId: studyLocation?.name ?? "")
        userFavorites.insert(studyLocation?.name ?? "")
    }
    isFavorite.toggle()  
  }

  private func checkIfFavorite() -> Bool {  
    guard let user = userViewModel.currentUser, let location = studyLocation else { return false }
    return user.favoriteLocations.contains(location.id.uuidString)
  }
}

//#Preview {
//  LocationDetailView(studyLocation: .constant(previewStudyLocation), show: .constant(false))
//}

struct AtmosphereView: View {
    @EnvironmentObject var fontSizeManager: FontSizeManager
    
  let envFactor: EnvFactor

  var body: some View {
    HStack {
      ForEach(envFactor.atmosphere, id: \.self) { item in
        Text("#" + item)
                    .font(.system(size: fontSizeManager.bodySize))
          .padding(.vertical, 5)
          .padding(.horizontal, 10)
          .background(Color.black)
          .foregroundColor(.white)
          .cornerRadius(10)
      }
    }
    .padding(.leading, 15)
  }
}

struct EnvView: View {
    @EnvironmentObject var fontSizeManager: FontSizeManager
    
  let envFactor: EnvFactor

  var body: some View {
    VStack(alignment: .leading) {
      ForEach(envFactor.staticData.sorted(by: >), id: \.key) { key, value in
        HStack {
          Text("\(key):")
            .font(.system(size: fontSizeManager.subheadlineSize))
          Spacer()
          Text(String(format: "%.1f", value))
            .font(.system(size: fontSizeManager.subheadlineSize))
        }
        .padding([.leading, .trailing], 18)
        .padding(.vertical, 5)
      }
    }
    .padding()
  }
}

struct OpeningHoursView: View {
    @EnvironmentObject var fontSizeManager: FontSizeManager
    
  let hours: [String: OpeningHours]
    
  var body: some View {
    VStack(alignment: .leading) {

      ForEach(
        ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], id: \.self
      ) { (day: String) in
        HStack {
          Text(day)
            .font(.system(size: fontSizeManager.headlineSize))
          Spacer()
          if let openingHours = hours[day] {
            VStack(alignment: .trailing) {
              Text(openingHours.opening + " - " + openingHours.closing)
                .font(.system(size: fontSizeManager.subheadlineSize))
            }
          } else {
            Text("Closed")
              .font(.system(size: fontSizeManager.subheadlineSize))
              .foregroundColor(.gray)
          }
        }
        .padding(.vertical, 5)
      }
    }
    .padding(.horizontal)
  }
}
//
//struct StarRatingView: View {
//  var rating: Double
//
//  var body: some View {
//    HStack(spacing: 2) {
//      ForEach(0..<5) { index in
//        Image(systemName: "star.fill")
//          .foregroundColor(index < Int(rating.rounded()) ? .orange : .gray)
//      }
//    }
//  }
//}

struct StarRatingView: View {
    var rating: Double
    var color: Color
    var starRounding: StarRounding
    var starSize: CGFloat
    
    private let fullStar = Image(systemName: "star.fill")
    private let halfStar = Image(systemName: "star.lefthalf.fill")
    private let emptyStar = Image(systemName: "star")
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<5) { index in
                self.star(for: index)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: self.starSize, height: self.starSize)
                    .foregroundColor(self.color)
            }
        }
    }
    
    private func star(for index: Int) -> Image {
        let threshold = Double(index) + 1
        switch starRounding {
        case .roundToHalfStar:
            if rating >= threshold - 0.25 {
                return fullStar
            } else if rating >= threshold - 0.75 {
                return halfStar
            } else {
                return emptyStar
            }
        case .ceilToHalfStar:
            if rating > threshold - 0.5 {
                return fullStar
            } else if rating > threshold - 1 {
                return halfStar
            } else {
                return emptyStar
            }
        case .floorToHalfStar:
            if rating >= threshold {
                return fullStar
            } else if rating >= threshold - 0.5 {
                return halfStar
            } else {
                return emptyStar
            }
        case .roundToFullStar:
            return rating >= threshold - 0.5 ? fullStar : emptyStar
        case .ceilToFullStar:
            return rating > threshold - 1 ? fullStar : emptyStar
        case .floorToFullStar:
            return rating >= threshold ? fullStar : emptyStar
        }
    }
}


struct ImageSliderView: View {
  let images: [String]  // List of image names

  var body: some View {
    TabView {
      ForEach(images, id: \.self) { imageName in
        Image(imageName)
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .clipped()
      }
    }
    .tabViewStyle(PageTabViewStyle())
  }
}

struct CommentsView: View {
    let comments: [Comment]
    @EnvironmentObject var fontSizeManager: FontSizeManager
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(comments) { comment in
                    CommentRow(comment: comment)
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .font(.system(size: fontSizeManager.bodySize))
                }
            }
            .padding()
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    @EnvironmentObject var fontSizeManager: FontSizeManager
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(comment.name)
                .font(.system(size: fontSizeManager.headlineSize))
                .foregroundColor(.blue)
            if let date = comment.date {
                Text(date, style: .date)
                    .font(.system(size: fontSizeManager.subheadlineSize))
                    .foregroundColor(.gray)
            }
            Text(comment.content)
                .font(.system(size: fontSizeManager.bodySize))
                .foregroundColor(.primary)
        }
    }
}

// Crowdness (Double) to Text (String) to be shown in the drop down button
func crowdnessLevelToText(userCrowdness: Double, dataCrowdness: Double) -> String {
  let crowdness = userCrowdness == 0 ? dataCrowdness : userCrowdness  // if the user has selected the crowdness, use their data

  if crowdness == -1 {
    return "Unknown"
  }

    if crowdness <= 1.67 {
        return "Sparse"
    } else if crowdness <= 2.33 {
        return "Crowded"
      } else {
        return "Full"
      }
    }

// Noiseness Level (Double) to Text (String) to be shown in the drop down button
func noiseLevelToText(userNoise: Double, dataNoise: Double) -> String {
  let noise = userNoise == 0 ? dataNoise : userNoise  // if user has selected the noise, use their data

  if noise == -1 {
    return "Unknown"
  }

    if noise <= 1.67 {
    return "Quiet"
    } else if noise <= 2.33 {
    return "Audible"
  } else {
    return "Loud"
  }
}

//#Preview {
//  LocationDetailView(studyLocation: .constant(previewStudyLocation), show: .constant(false))
//}

extension View {
  func scrollable() -> some View {
    ScrollView {
      self
    }
  }
}

extension LocationDetailView {
    private var openHoursButton: some View {
        Button(action: viewModel.toggleOpenHoursList) {
            HStack {
                Image(systemName: "arrow.right")
                    .font(.system(size: fontSizeManager.headlineSize))
                    .foregroundColor(.primary)
                    .rotationEffect(Angle(degrees: viewModel.showOpenHoursList ? 90 : 0))
                Text("Open Hours")
                    .font(.system(size: fontSizeManager.title2Size))
                    .fontWeight(.black)
                    .foregroundColor(.primary)
                    .frame(height: 55, alignment: .leading)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding([.leading, .top], 5)
        }
    }
    
    private var detailsButton: some View {
        Button(action: viewModel.toggleEnvFactors) {
            HStack {
                Image(systemName: "arrow.right")
                    .font(.system(size: fontSizeManager.headlineSize))
                    .foregroundColor(.primary)
                    .rotationEffect(Angle(degrees: viewModel.showEnvFactors ? 90 : 0))
                
                Text("Details")
                    .font(.system(size: fontSizeManager.title2Size))
                    .fontWeight(.black)
                    .foregroundColor(.primary)
                    .frame(height: 55, alignment: .leading)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.leading, 5)
        }
    }
}



