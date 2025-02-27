//
//  UIKitCalendarView.swift
//  Renfrewshire Bin Schedule
//
//  Created by Artur Kraft on 17/02/2025.
//

import SwiftUI
import UIKit

struct UIKitCalendarView: UIViewRepresentable {
    typealias UIViewType = UIView
    var controller: BinScheduleController

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()

        // Create and configure the UICalendarView.
        let calendarView = UICalendarView()
        calendarView.backgroundColor = UIColor.systemGray6

        // Configure a custom calendar with Monday as the first day.
        var customCalendar = Calendar.current
        customCalendar.firstWeekday = 2  // Monday (1 = Sunday, so 2 = Monday)
        calendarView.calendar = customCalendar
        calendarView.locale = Locale.current

        // Use single-date selection behavior.
        calendarView.selectionBehavior = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.delegate = context.coordinator

        // Set the initial visible month to the current month.
        let currentComponents = customCalendar.dateComponents([.year, .month], from: Date())
        calendarView.visibleDateComponents = currentComponents

        // Limit available dates to your events.
        if let first = controller.collections.first, let last = controller.collections.last {
            calendarView.availableDateRange = DateInterval(start: first.date, end: last.date)
        }

        // Create a label that will show the bins for the selected date.
        let selectedBinsLabel = UILabel()
        selectedBinsLabel.textAlignment = .center
        selectedBinsLabel.numberOfLines = 0
        selectedBinsLabel.font = UIFont.systemFont(ofSize: 14)
        selectedBinsLabel.text = "Select a date to see bin collections"

        // Create a vertical stack view to hold the calendar and label.
        let stackView = UIStackView(arrangedSubviews: [calendarView, selectedBinsLabel])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .fill
        stackView.distribution = .fill

        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        // Set the calendarView height constraint based on device.
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        if UIDevice.current.userInterfaceIdiom == .pad {
            NSLayoutConstraint.activate([
                calendarView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.85)
            ])
        } else {
            NSLayoutConstraint.activate([
                calendarView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.75)
            ])
        }
        
        // Save a reference to the label in the coordinator.
        context.coordinator.selectedBinsLabel = selectedBinsLabel

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Retrieve the stack view and the calendar view.
        guard let stackView = uiView.subviews.first as? UIStackView,
              let calendarView = stackView.arrangedSubviews.first as? UICalendarView
        else { return }
        
        // Update available date range when events change.
        if let first = controller.collections.first, let last = controller.collections.last {
            calendarView.availableDateRange = DateInterval(start: first.date, end: last.date)
        }
        
        // Reload decorations for the visible date components.
        calendarView.reloadDecorations(forDateComponents: [calendarView.visibleDateComponents], animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: UIKitCalendarView
        var selectedBinsLabel: UILabel!

        init(_ parent: UIKitCalendarView) {
            self.parent = parent
        }

        // Provide a decoration for dates that have bin collections.
        func calendarView(_ calendarView: UICalendarView,
                          decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard let date = calendarView.calendar.date(from: dateComponents) else { return nil }
            let collections = parent.controller.collections.filter { collection in
                calendarView.calendar.isDate(collection.date, inSameDayAs: date)
            }
            guard let collection = collections.first else { return nil }

            // If there's only one bin in this collection, use the default dot decoration.
            if collection.bins.count == 1 {
                let uiColor = collection.bins.first!.uiColor
                return UICalendarView.Decoration.default(color: uiColor)
            }

            // Otherwise, create a custom view that shows a dot for each bin.
            return UICalendarView.Decoration.customView {
                let containerView = UIView()
                let stackView = UIStackView()
                stackView.axis = .horizontal
                stackView.alignment = .center
                stackView.spacing = 3

                if collection.bins.isEmpty {
                    return UIView()
                }

                for bin in collection.bins {
                    let dot = UIView()
                    dot.backgroundColor = bin.uiColor  // Use the same uiColor as the single dot.
                    dot.layer.cornerRadius = 4
                    dot.translatesAutoresizingMaskIntoConstraints = false

                    NSLayoutConstraint.activate([
                        dot.widthAnchor.constraint(equalToConstant: 8),
                        dot.heightAnchor.constraint(equalToConstant: 8)
                    ])

                    stackView.addArrangedSubview(dot)
                }

                containerView.addSubview(stackView)
                stackView.translatesAutoresizingMaskIntoConstraints = false

                NSLayoutConstraint.activate([
                    stackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                    stackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
                ])

                return containerView
            }
        }

        // Skip months with no events.
        func calendarView(_ calendarView: UICalendarView,
                          didChangeVisibleDateComponentsFrom visibleDateComponents: DateComponents) {
            guard let year = visibleDateComponents.year,
                  let month = visibleDateComponents.month else { return }

            let calendar = calendarView.calendar
            let comps = DateComponents(year: year, month: month, day: 1)
            guard let visibleMonthDate = calendar.date(from: comps) else { return }

            let monthHasEvents = parent.controller.collections.contains { collection in
                calendar.isDate(collection.date, equalTo: visibleMonthDate, toGranularity: .month)
            }

            if !monthHasEvents {
                if let nextEvent = parent.controller.collections.first(where: { $0.date > visibleMonthDate }) {
                    let nextComps = calendar.dateComponents([.year, .month], from: nextEvent.date)
                    calendarView.visibleDateComponents = nextComps
                } else if let previousEvent = parent.controller.collections.last(where: { $0.date < visibleMonthDate }) {
                    let prevComps = calendar.dateComponents([.year, .month], from: previousEvent.date)
                    calendarView.visibleDateComponents = prevComps
                }
            }
        }
        
        // MARK: Selection Delegate
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents = dateComponents,
                  let selectedDate = Calendar.current.date(from: dateComponents)
            else {
                DispatchQueue.main.async {
                    self.selectedBinsLabel.text = "No bin collections for this date."
                }
                return
            }
            
            // Find collections for the selected date.
            let collections = parent.controller.collections.filter { collection in
                Calendar.current.isDate(collection.date, inSameDayAs: selectedDate)
            }
            if let collection = collections.first {
                let binsText = collection.bins.map { $0.displayName }.joined(separator: ", ")
                DispatchQueue.main.async {
                    self.selectedBinsLabel.text = "Collection Day for Bins: \(binsText)"
                }
            } else {
                DispatchQueue.main.async {
                    self.selectedBinsLabel.text = "No bin collections for this date."
                }
            }
        }
    }
}
