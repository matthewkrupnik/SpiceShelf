import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    private let checkmarkView = UIImageView()
    private let messageLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handleSharedContent()
    }

    private func setupUI() {
        let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .medium)
        checkmarkView.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
        checkmarkView.tintColor = .systemGreen
        checkmarkView.translatesAutoresizingMaskIntoConstraints = false
        checkmarkView.alpha = 0

        messageLabel.text = "Saved to Spice Nook"
        messageLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        messageLabel.textColor = .label
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.alpha = 0

        view.addSubview(checkmarkView)
        view.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            checkmarkView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            checkmarkView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -16),
            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: checkmarkView.bottomAnchor, constant: 12),
        ])
    }

    private func handleSharedContent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            dismiss()
            return
        }

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, _ in
                        DispatchQueue.main.async {
                            if let url = item as? URL {
                                self?.saveAndConfirm(url: url.absoluteString)
                            } else if let data = item as? Data,
                                      let url = URL(dataRepresentation: data, relativeTo: nil) {
                                self?.saveAndConfirm(url: url.absoluteString)
                            } else {
                                self?.dismiss()
                            }
                        }
                    }
                    return
                }

                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] item, _ in
                        DispatchQueue.main.async {
                            if let text = item as? String,
                               let url = URL(string: text),
                               url.scheme?.hasPrefix("http") == true {
                                self?.saveAndConfirm(url: text)
                            } else {
                                self?.dismiss()
                            }
                        }
                    }
                    return
                }
            }
        }

        dismiss()
    }

    private func saveAndConfirm(url: String) {
        guard let defaults = UserDefaults(suiteName: "group.mk.lan.SpiceShelf") else {
            dismiss()
            return
        }
        var queue = defaults.stringArray(forKey: "pendingImportURLs") ?? []
        queue.append(url)
        defaults.set(queue, forKey: "pendingImportURLs")
        defaults.synchronize()

        UIView.animate(withDuration: 0.3) {
            self.checkmarkView.alpha = 1
            self.messageLabel.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.dismiss()
        }
    }

    private func dismiss() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
