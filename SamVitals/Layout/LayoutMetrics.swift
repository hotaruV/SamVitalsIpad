import SwiftUI

struct LayoutMetrics {
    let size: CGSize

    var usesColumns: Bool { size.width > size.height && size.width >= 1_050 }
    var isCompact: Bool { size.width < 800 || size.height < 800 }
    var isVeryCompact: Bool { size.height < 760 }

    var horizontalPadding: CGFloat { isCompact ? 28 : 48 }
    var verticalPadding: CGFloat { isVeryCompact ? 20 : (isCompact ? 30 : 54) }
    var sectionSpacing: CGFloat { isVeryCompact ? 22 : (isCompact ? 30 : 48) }
    var columnSpacing: CGFloat { isCompact ? 32 : 54 }
    var availableWidth: CGFloat {
        max(size.width - (horizontalPadding * 2), 0)
    }

    var contentWidth: CGFloat {
        if usesColumns {
            return min(availableWidth, 1_520)
        }

        return min(availableWidth, 920)
    }

    var formWidth: CGFloat {
        if usesColumns {
            let proportionalWidth = contentWidth * 0.42
            let minimumWidth: CGFloat = isCompact ? 420 : 500
            let maximumWidth: CGFloat = isCompact ? 520 : 640

            return min(max(proportionalWidth, minimumWidth), maximumWidth)
        }

        return min(
            availableWidth,
            isCompact ? 620 : 700
        )
    }
    var logoSize: CGFloat { isCompact ? 64 : 80 }
    var titleSize: CGFloat {
        if isVeryCompact { return 36 }
        return isCompact ? 42 : 52
    }
    var bodySize: CGFloat { isCompact ? 17 : 19 }
    var featureHeight: CGFloat { isCompact ? 142 : 166 }
    var cardPadding: CGFloat { isVeryCompact ? 24 : (isCompact ? 28 : 36) }
    var fieldHeight: CGFloat { isCompact ? 58 : 68 }
}
