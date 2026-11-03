import SwiftUI

struct PastureCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        configuration.isOn
                            ? .pastureChecked
                            : .clear
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(
                                configuration.isOn
                                    ? .pastureChecked
                                    : .pastureCheckboxBorder,
                                lineWidth: 1.5
                            )
                    }
                    .overlay {
                        if configuration.isOn {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.pastureGreen)
                        }
                    }
                    .frame(width: 19, height: 19)
                    .accessibilityHidden(true)
                
                configuration.label
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(
            configuration.isOn ? "Completed" : "Not completed"
        )
    }
}
