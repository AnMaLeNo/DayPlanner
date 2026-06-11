//
//  Theme.swift
//  DayPlanner
//
//  Système de design minimal partagé : espacements, rayons, badges et cartes.
//  Le verre (Liquid Glass) est réservé à la couche de contrôle (boutons, toolbars) ;
//  le contenu utilise des cartes et des puces sobres, conformément aux HIG.
//

import SwiftUI

enum Theme {
    static let cardRadius: CGFloat = 16
    static let fieldRadius: CGFloat = 12
    static let cardSpacing: CGFloat = 18
    static let contentPadding: CGFloat = 24
    static let contentMaxWidth: CGFloat = 760
}

// MARK: - Priorité

extension Priority {
    var displayLabel: String {
        switch self {
        case .high: "Haute"
        case .medium: "Moyenne"
        case .low: "Basse"
        }
    }

    var tint: Color {
        switch self {
        case .high: .orange
        case .medium: .blue
        case .low: .secondary
        }
    }

    var symbolName: String {
        switch self {
        case .high: "flame.fill"
        case .medium: "equal.circle.fill"
        case .low: "tortoise.fill"
        }
    }
}

struct PriorityBadge: View {
    let priority: Priority

    var body: some View {
        Label(priority.displayLabel, systemImage: priority.symbolName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(priority.tint)
            .background(priority.tint.opacity(0.14), in: Capsule())
            .accessibilityLabel("Priorité \(priority.displayLabel)")
    }
}

// MARK: - Puce d'information

struct InfoChip: View {
    let systemImage: String
    let text: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.fill.tertiary, in: Capsule())
    }
}

// MARK: - Carte de contenu

private struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.cardSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                .background.secondary,
                in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .strokeBorder(.separator.opacity(0.6))
            }
    }
}

extension View {
    /// Carte de contenu standard : padding, fond secondaire, coin continu, fin liseré.
    func card() -> some View {
        modifier(CardBackground())
    }
}
