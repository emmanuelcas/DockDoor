import SwiftUI

struct DonationView: View {
    var body: some View {
        UniformCardView(
            title: "Support PeekDeck",
            description: "If you find PeekDeck useful, consider donating. Your support helps keep the project going!",
            buttonTitle: "Support PeekDeck",
            buttonLink: "https://buymeacoffee.com/keplercafe"
        )
    }
}
