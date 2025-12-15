//
//  EventEditViewControllerRepresentable.swift
//  TAC342_FinalProject
//
//  UIKit bridge to wrap EKEventEditViewController for SwiftUI
//  This satisfies the UIKit integration requirement
//

import SwiftUI
import EventKit
import EventKitUI

struct EventEditViewControllerRepresentable: UIViewControllerRepresentable {
    let eventStore: EKEventStore
    let event: EKEvent?
    var onComplete: (EKEventEditViewAction, String?) -> Void
    
    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        controller.eventStore = eventStore
        if let existingEvent = event {
            controller.event = existingEvent
        } else {
            let newEvent = EKEvent(eventStore: eventStore)
            newEvent.calendar = eventStore.defaultCalendarForNewEvents
            controller.event = newEvent
        }
        controller.editViewDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }
    
    class Coordinator: NSObject, EKEventEditViewDelegate {
        let onComplete: (EKEventEditViewAction, String?) -> Void
        
        init(onComplete: @escaping (EKEventEditViewAction, String?) -> Void) {
            self.onComplete = onComplete
        }
        
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            let eventIdentifier: String? = action == .saved ? controller.event?.eventIdentifier : nil
            controller.dismiss(animated: true) { [weak self] in
                self?.onComplete(action, eventIdentifier)
            }
        }
    }
}

