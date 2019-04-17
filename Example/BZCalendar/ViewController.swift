//
//  ViewController.swift
//  BZCalendar
//
//  Created by Bartek Zabicki on 04/17/2019.
//  Copyright (c) 2019 Bartek Zabicki. All rights reserved.
//

import UIKit
import Unicorns

class ViewController: UIViewController {
  
  // MARK: - Outlets
  
  @IBOutlet weak var calendarView: CalendarView!
  @IBOutlet weak var monthLabel: UILabel!
  
  // MARK: - Properties
  
  let monthFormatter = DateFormatter()
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    monthFormatter.dateFormat = "MMMM yyyy"
    calendarView.delegate = self
  }
  
  // MARK: - Actions
  
  @IBAction func rightButton(_ sender: UIButton) {
    calendarView.changeToNextMonth()
  }
  
  @IBAction func leftButton(_ sender: UIButton) {
    calendarView.changeToPreviousMonth()
  }
  
  @IBAction func weekButton(_ sender: UIButton) {
    calendarView.changeCalendarType(to: .week)
  }
  
  @IBAction func monthButton(_ sender: UIButton) {
    calendarView.changeCalendarType(to: .month)
  }
}

// MARK: - CalendarViewDelegate

extension ViewController: CalendarViewDelegate {
  func didChangeMonth(to date: Date) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMMM yyyy"
    title = dateFormatter.string(from: date)
    self.monthLabel.text = self.monthFormatter.string(from: date)
  }
  
  func willChangeMonth(to date: Date) {
    DispatchQueue.main.async {
      self.monthLabel.text = self.monthFormatter.string(from: date)
    }
  }
  
  func didSelect(day: Date) {
    Log.s("Select day: \(day)")
  }
  
  func didDeselect(day: Date) {
    Log.s("Deselect day: \(day)")
  }
  
}
