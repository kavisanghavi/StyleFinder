/**
 * Virtual Try-On View
 *
 * AI-powered virtual try-on using Nano Banana (Google Gemini)
 * Shows how clothing items would look on the user
 */

import SwiftUI

struct VirtualTryOnView: View {
    @State private var userPhoto: UIImage?
    @State private var clothingPhoto: UIImage?
    @State private var resultImage: UIImage?
    @State private var showingUserPicker = false
    @State private var showingClothingPicker = false
    @State private var isGenerating = false
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "EC4899"), Color(hex: "8B5CF6")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: Color(hex: "EC4899").opacity(0.3), radius: 20, x: 0, y: 10)

                            Image(systemName: "figure.stand.line.dotted.figure.stand")
                                .font(.system(size: 36, weight: .light))
                                .foregroundColor(.white)
                        }

                        Text("Virtual Try-On")
                            .font(.system(size: 28, weight: .bold))

                        Text("See how clothes look on you with AI")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Photo Selection Cards
                    HStack(spacing: 12) {
                        // User Photo
                        PhotoSelectionCard(
                            image: userPhoto,
                            title: "Your Photo",
                            icon: "person.fill",
                            color: "6366F1"
                        ) {
                            showingUserPicker = true
                        }

                        // Clothing Photo
                        PhotoSelectionCard(
                            image: clothingPhoto,
                            title: "Clothing",
                            icon: "tshirt.fill",
                            color: "EC4899"
                        ) {
                            showingClothingPicker = true
                        }
                    }
                    .padding(.horizontal, 20)

                    // Generate Button
                    if userPhoto != nil && clothingPhoto != nil && resultImage == nil {
                        Button(action: generateTryOn) {
                            HStack(spacing: 12) {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.95)
                                } else {
                                    Image(systemName: "wand.and.stars.inverse")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                Text(isGenerating ? "Creating Magic..." : "Try It On")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "EC4899"), Color(hex: "8B5CF6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: Color(hex: "EC4899").opacity(0.4), radius: 20, x: 0, y: 10)
                        }
                        .disabled(isGenerating)
                        .padding(.horizontal, 20)
                    }

                    // Result
                    if let result = resultImage {
                        VStack(spacing: 20) {
                            // Success Header
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(hex: "10B981"))

                                Text("Here's How It Looks!")
                                    .font(.system(size: 24, weight: .bold))
                            }

                            // Result Image
                            Image(uiImage: result)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(maxHeight: 400)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                                .padding(.horizontal, 20)

                            // Action Buttons
                            HStack(spacing: 12) {
                                Button(action: resetTryOn) {
                                    Text("Try Another")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(hex: "6366F1"))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(Color(hex: "6366F1").opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }

                                Button(action: {}) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.down")
                                            .font(.system(size: 15))
                                        Text("Save")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(Color(hex: "EC4899"))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // Instructions (when no photos selected)
                    if userPhoto == nil || clothingPhoto == nil {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("How It Works")
                                .font(.system(size: 20, weight: .semibold))

                            VStack(spacing: 12) {
                                InstructionRow(number: "1", text: "Upload a photo of yourself")
                                InstructionRow(number: "2", text: "Select the clothing item to try on")
                                InstructionRow(number: "3", text: "Let AI show you how it looks!")
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color(hex: "F8F9FA"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingUserPicker) {
                ImagePicker(image: $userPhoto, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showingClothingPicker) {
                ImagePicker(image: $clothingPhoto, sourceType: .photoLibrary)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    func generateTryOn() {
        guard let userImg = userPhoto,
              let clothingImg = clothingPhoto else {
            errorMessage = "Please select both photos"
            showError = true
            return
        }

        isGenerating = true

        Task {
            do {
                let result = try await APIClient.shared.virtualTryOn(
                    userImage: userImg,
                    clothingItems: [clothingImg],
                    styleGuidance: nil
                )

                await MainActor.run {
                    withAnimation(.spring(response: 0.4)) {
                        resultImage = result
                        isGenerating = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Try-on failed: \(error.localizedDescription)"
                    showError = true
                    isGenerating = false
                }
            }
        }
    }

    func resetTryOn() {
        withAnimation(.spring(response: 0.3)) {
            resultImage = nil
            userPhoto = nil
            clothingPhoto = nil
        }
    }
}

// MARK: - Photo Selection Card

struct PhotoSelectionCard: View {
    let image: UIImage?
    let title: String
    let icon: String
    let color: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(hex: color).opacity(0.1))
                            .frame(width: 140, height: 140)

                        VStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(Color(hex: color))

                            Text("Tap to Add")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "EC4899"), Color(hex: "8B5CF6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Text(number)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

#Preview {
    VirtualTryOnView()
}
