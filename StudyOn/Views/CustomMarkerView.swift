import SwiftUI

struct CustomMarkerView: View {
    var rating: Double
    var category: String
    
    var body: some View {
        libraryIcon
            .shadow(radius: 3)
    }
    
    func colorForRating(_ rating: Double) -> Color {
        let clampedRating = min(max(rating, 0), 5)
        let green = clampedRating / 5.0
        let red = (5.0 - clampedRating) / 5.0
        return Color(red: red, green: green, blue: 0.0)
    }
    
    private func imageForCategory(_ category: String) -> String {
        switch category {
        case "library":
            return "book.fill"
        case "cafe":
            return "cup.and.saucer.fill"
        default:
            return "book.fill"
        }
    }
}

#Preview {
    CustomMarkerView(rating: previewStudyLocation.rating, category: previewStudyLocation.category)
}

extension CustomMarkerView {
    private var libraryIcon: some View {
        VStack(spacing: 0) {
            Image(systemName: imageForCategory(previewStudyLocation.category))
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .font(.headline)
                .foregroundColor(.white)
                .padding(6)
                .background(colorForRating(rating))
                .cornerRadius(36)
            
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 10, height: 10)
                .foregroundColor(colorForRating(rating))
                .rotationEffect(Angle(degrees: 180))
                .offset(y: -3)
                .padding(.bottom, 35)
            
        }
    }
}
