import SwiftUI

struct MemeSwipeView: View {
    @StateObject private var viewModel = MemeSwipeViewModel()
    @State private var offset = CGSize.zero
    @State private var color: Color = .black
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let currentMeme = viewModel.currentMeme {
                ZStack {
                    // Meme Card
                    MemeCard(meme: currentMeme, uploader: viewModel.currentMemeUploader) // Pass uploader
                        .offset(x: offset.width, y: 0)
                        .rotationEffect(.degrees(Double(offset.width / 40)))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    offset = gesture.translation
                                    withAnimation {
                                        changeColor(width: offset.width)
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation {
                                        swipeCard(width: offset.width)
                                        changeColor(width: offset.width)
                                    }
                                }
                        )
                    
                    // Like/Dislike Overlay
                    HStack {
                        Image(systemName: "xmark")
                            .font(.system(size: 100))
                            .foregroundColor(.red)
                            .opacity(Double(offset.width < 0 ? min(-offset.width / 50, 1) : 0))
                        
                        Spacer()
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.green)
                            .opacity(Double(offset.width > 0 ? min(offset.width / 50, 1) : 0))
                    }
                    .padding(.horizontal, 40)
                }
                
                // Action Buttons
                HStack(spacing: 40) {
                    Button {
                        withAnimation {
                            swipeCard(width: -500)
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                    
                    Button {
                        withAnimation {
                            swipeCard(width: 500)
                        }
                    } label: {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 20)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "theatermasks.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No more memes to show!")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("Check back later for new memes")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            viewModel.loadMemes()
        }
    }
    
    private func swipeCard(width: CGFloat) {
        switch width {
        case -500...(-150):
            offset = CGSize(width: -500, height: 0)
            viewModel.dislikeMeme()
        case 150...500:
            offset = CGSize(width: 500, height: 0)
            viewModel.likeMeme()
        default:
            offset = .zero
        }
    }
    
    private func changeColor(width: CGFloat) {
        switch width {
        case -500...(-130):
            color = .red
        case 130...500:
            color = .green
        default:
            color = .black
        }
    }
}

struct MemeCard: View {
    let meme: Meme
    let uploader: AppUser? // Added uploader
    
    var body: some View {
        VStack(spacing: 8) { // Main container for card elements
            ZStack(alignment: .bottomLeading) { // Use ZStack for image + overlay
                // Image
                AsyncImage(url: URL(string: meme.imageName)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure ProgressView fills space
            }
            .frame(width: 340, height: 400) // Main card dimensions
            .background(Color.gray.opacity(0.2)) // Background for placeholder
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1) // Border
            )

            // Uploader Info Overlay
            if let uploader = uploader {
                VStack(alignment: .leading) {
                    Text(uploader.name) // Display uploader's name
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    // You could add more info here like uploader.age if available and desired
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                        LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                                       startPoint: .bottom, endPoint: .center)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20)) // Match card's corner radius for the gradient part
                }
            }
            .frame(width: 340, height: 400) // Ensure ZStack itself has the defined frame
            
            // Tags section
            if !meme.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(meme.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal) // Horizontal padding for the content within ScrollView
                }
                .frame(height: 30) // Define a height for the tags scroll view area
                .padding(.horizontal, 10) // Padding for the ScrollView itself to not touch edges
            } else {
                // Keep the card height consistent even if there are no tags
                Spacer().frame(height: 30)
            }
        }
        .frame(width: 340) // Overall width of the card including potential tags area
        .padding(.bottom, meme.tags.isEmpty ? 0 : 10) // Add padding if tags are present
        .background(Color.white) // Add a background to the VStack if needed, e.g., for shadow
        .cornerRadius(20) // Apply corner radius to the VStack
        .shadow(radius: 3) // Optional shadow for the card
    }
}

#Preview {
    MemeSwipeView()
} 