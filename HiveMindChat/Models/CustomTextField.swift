// CustomTextField.swift

import SwiftUI
import UIKit

struct CustomTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onCommit: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, onCommit: onCommit)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.text = text
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = UIColor.systemGray6
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 4, bottom: 12, right: 4) // Update this line
        textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) // Update this line
        
        // Update the placeholder label frame
        let placeholderLabel = UILabel()
        placeholderLabel.text = placeholder
        placeholderLabel.font = UIFont.systemFont(ofSize: 16)
        placeholderLabel.textColor = UIColor.lightGray
        placeholderLabel.tag = 100
        placeholderLabel.frame = CGRect(x: 8, y: 8, width: textView.bounds.width - 16, height: 25) // Update this line to set the frame
        textView.addSubview(placeholderLabel)
        textView.setValue(placeholderLabel, forKey: "placeholderLabel")
        textView.returnKeyType = .send
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CustomTextField
        var onCommit: () -> Void
        
        init(_ parent: CustomTextField, onCommit: @escaping () -> Void) {
            self.parent = parent
            self.onCommit = onCommit
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            
            let placeholderLabel = textView.viewWithTag(100) as? UILabel
            placeholderLabel?.isHidden = !textView.text.isEmpty
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                textView.resignFirstResponder()
                onCommit()
                return false
            }
            return true
        }
    }
}
