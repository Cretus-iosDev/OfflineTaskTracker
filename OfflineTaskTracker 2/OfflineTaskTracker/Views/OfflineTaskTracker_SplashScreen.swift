import SwiftUI

struct SplashScreenView: View {
    let onFinished: () -> Void

    @State private var animateIcon = false
    @State private var animateTitle = false
    @State private var animateGlow = false
    @State private var animateProgress = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.035, green: 0.055, blue: 0.15),
                    Color(red: 0.075, green: 0.075, blue: 0.28),
                    Color(red: 0.12, green: 0.055, blue: 0.27)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Ambient glow
            Circle()
                .fill(Color.indigo.opacity(0.30))
                .frame(width: 300, height: 300)
                .blur(radius: 90)
                .offset(x: -120, y: -210)
                .scaleEffect(animateGlow ? 1.2 : 0.8)

            Circle()
                .fill(Color.purple.opacity(0.24))
                .frame(width: 280, height: 280)
                .blur(radius: 85)
                .offset(x: 140, y: 210)
                .scaleEffect(animateGlow ? 0.85 : 1.15)

            // Decorative rings
            Circle()
                .stroke(.white.opacity(0.055), lineWidth: 1)
                .frame(width: 330, height: 330)

            Circle()
                .stroke(.white.opacity(0.04), lineWidth: 1)
                .frame(width: 410, height: 410)

            VStack(spacing: 0) {
                Spacer()

                // App icon
                ZStack {
                    Circle()
                        .fill(Color.indigo.opacity(0.22))
                        .frame(width: 154, height: 154)
                        .blur(radius: 22)
                        .scaleEffect(animateGlow ? 1.25 : 0.9)

                    RoundedRectangle(cornerRadius: 38, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.42, green: 0.40, blue: 1.0),
                                    Color(red: 0.32, green: 0.25, blue: 0.86),
                                    Color(red: 0.55, green: 0.28, blue: 0.88)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 112, height: 112)
                        .overlay {
                            RoundedRectangle(cornerRadius: 38, style: .continuous)
                                .stroke(.white.opacity(0.25), lineWidth: 1)
                        }
                        .shadow(color: .indigo.opacity(0.45), radius: 25, y: 12)

                    Image(systemName: "checkmark")
                        .font(.system(size: 49, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .scaleEffect(animateIcon ? 1 : 0.35)
                        .rotationEffect(.degrees(animateIcon ? 0 : -18))
                }
                .scaleEffect(animateIcon ? 1 : 0.72)
                .opacity(animateIcon ? 1 : 0)

                // App title
                VStack(spacing: 9) {
                    Text("OfflineTask")
                        .font(.system(size: 35, weight: .bold, design: .rounded))
                        .tracking(-1.2)
                        .foregroundStyle(.white)

                    Text("TRACKER")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .tracking(5)
                        .foregroundStyle(Color.white.opacity(0.65))

                    Text("Plan less. Accomplish more.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.62))
                        .padding(.top, 8)
                }
                .padding(.top, 30)
                .opacity(animateTitle ? 1 : 0)
                .offset(y: animateTitle ? 0 : 18)

                Spacer()

                // Loading indicator
                VStack(spacing: 12) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.12))

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.cyan,
                                            Color(red: 0.55, green: 0.48, blue: 1),
                                            Color(red: 0.76, green: 0.48, blue: 1)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * (animateProgress ? 1 : 0.08))
                        }
                    }
                    .frame(width: 112, height: 3)

                    Text("YOUR TASKS. YOUR FLOW.")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .tracking(2.2)
                        .foregroundStyle(.white.opacity(0.42))
                }
                .padding(.bottom, 54)
                .opacity(animateTitle ? 1 : 0)
            }
            .padding(.horizontal, 28)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.72).delay(0.15)) {
                animateIcon = true
            }

            withAnimation(.easeOut(duration: 0.7).delay(0.45)) {
                animateTitle = true
            }

            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGlow = true
            }

            withAnimation(.easeInOut(duration: 1.15).delay(0.65)) {
                animateProgress = true
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(2.6))

            guard !Task.isCancelled else { return }
            onFinished()
        }
    }
}

// MARK: - App launch container

/// Shows the splash screen once, then presents the main application.
struct AppLaunchView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
            } else {
                RootView()
                    .transition(.opacity)
            }
        }
    }
}

#Preview {
    SplashScreenView(onFinished: {})
}
