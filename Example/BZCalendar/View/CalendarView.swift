//
//  CalendarView.swift
//  Calendar
//
//  Created by Bartłomiej Zabicki on 28/03/2019.
//  Copyright © 2019 Bartlomiej Zabicki. All rights reserved.
//

import UIKit

protocol CalendarViewDelegate: class {
  func didChangeMonth(to: Date)
  func willChangeMonth(to: Date)
  func didSelect(day: Date)
  func didDeselect(day: Date)
}

internal enum CalendarType {
  case month
  case week
}

@IBDesignable
final class CalendarView: UIView {
  
  // MARK: - Structures
  
  struct Month {
    let previousMonthDays: [Date]
    let currentMonthDays: [Date]
    let nextMonthDays: [Date]
    var weeks: [Week] {
      return allDays.chunked(into: 7).compactMap({ Week(days: $0)} )
    }
    
    var allDays: [Date] {
      return [previousMonthDays, currentMonthDays, nextMonthDays].flatMap {$0}
    }
  }
  
  struct Week {
    let days: [Date]
  }
  
  // MARK: - Properties
  
  static let defaultFullHeight: CGFloat = 271
  static let defaultCompactHeight: CGFloat = 125
  
  @IBInspectable public var calendarInsets: UIEdgeInsets = .zero
  @IBInspectable public var areSwipeGestureRecognizersActive = true
  
  override var intrinsicContentSize: CGSize {
    return CGSize(width: 343, height: 271)
  }
  
  private lazy var collectionView: UICollectionView = {
    let collectionView = UICollectionView(frame: bounds, collectionViewLayout: CalendarViewFlowLayout(frame: bounds, daysCount: 70))
    collectionView.register(reuseIdentifying: DayCollectionViewCell.self)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.backgroundColor = backgroundColor
    return collectionView
  }()
  private var collectionViewLayout: CalendarViewFlowLayout {
    return collectionView.collectionViewLayout as! CalendarViewFlowLayout
  }
  private lazy var weekdaysStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.backgroundColor = backgroundColor
    stackView.distribution = .fillEqually
    return stackView
  }()
  private lazy var calendar: Calendar = {
    var calendar = Calendar.current
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
  }()
  private lazy var monthDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(identifier: "UTC")!
    formatter.dateFormat = "MMMM"
    return formatter
  }()
  
  private var collectionViewDataSource: CalendarCollectionViewDataSource!
  private var collectionViewDelegate: CalendarCollectionViewDelegate!
  private var currentDisplayedDate = Date()
  private var monthsOnSides: Int = 3 {
    didSet {
      setupCalendar(for: currentDisplayedDate)
    }
  }
  private(set) var selectedDates: [Date] = []
  private(set) var calendarType: CalendarType = .month
  
  public weak var delegate: CalendarViewDelegate?

  // MARK: - Initialization
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setupView()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let collectionViewLayout = CalendarViewFlowLayout(frame: bounds, daysCount: 70)
    collectionView.setCollectionViewLayout(collectionViewLayout, animated: false)
//    adjustCollectionViewPosition()
  }
  
  // MARK: - Functions
  
  public func changeToPreviousMonth() {
    displayPreviousMonth()
  }
  
  public func changeToNextMonth() {
    displayNextMonth()
  }
  
  public func changeTo(date: Date) {
    currentDisplayedDate = date
    setupCalendar(for: currentDisplayedDate)
    delegate?.didChangeMonth(to: currentDisplayedDate)
  }
  
  public func select(date: Date) {
    guard !selectedDates.contains(date) else { return }
    selectedDates.append(date)
  }
  
  public func deselect(date: Date) {
    selectedDates.removeAll(where: { $0 == date })
  }
  
  public func reloadData() {
    changeTo(date: currentDisplayedDate)
  }
  
  public func changeCalendarType(to calendarType: CalendarType) {
    self.calendarType = calendarType
    collectionViewLayout.changeType(to: calendarType)
    collectionView.collectionViewLayout.invalidateLayout()
    collectionView.setCollectionViewLayout(collectionViewLayout, animated: true)
  }
  
  // MARK: - Private Functions
  
  private func setupView() {
    addWeekdays()
    addCollectionView()
    setupCalendar(for: Date())
  }
  
  private func addWeekdays() {
    addSubview(weekdaysStackView)
    weekdaysStackView.topAnchor.constraint(equalTo: topAnchor, constant: calendarInsets.top).isActive = true
    weekdaysStackView.leftAnchor.constraint(equalTo: leftAnchor, constant: calendarInsets.left).isActive = true
    rightAnchor.constraint(equalTo: weekdaysStackView.rightAnchor, constant: calendarInsets.right).isActive = true
    weekdayVeryShortSymbols(weekStartSunday: false).compactMap { weekday -> UIView? in
      let label = UILabel()
      label.text = weekday
      label.textAlignment = .center
      label.font = .systemFont(ofSize: 13)
      label.textColor = UIColor(hexString: "BDCDD1")
      return label
    }.forEach({ weekdaysStackView.addArrangedSubview($0) })
  }
  
  private func addCollectionView() {
    addSubview(collectionView)
    collectionView.topAnchor.constraint(equalTo: weekdaysStackView.bottomAnchor, constant: 0).isActive = true
    collectionView.leftAnchor.constraint(equalTo: leftAnchor, constant: calendarInsets.left).isActive = true
    rightAnchor.constraint(equalTo: collectionView.rightAnchor, constant: calendarInsets.right).isActive = true
    bottomAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: calendarInsets.bottom).isActive = true
  }
  
  private func setupCalendar(for date: Date) {
    let request = preparedCollectionViewDataRequest(for: date)
    collectionViewDataSource = CalendarCollectionViewDataSource(request: request)
    collectionViewDelegate = CalendarCollectionViewDelegate(request: request, delegate: self)
    collectionView.dataSource = collectionViewDataSource
    collectionView.delegate = collectionViewDelegate
    adjustCollectionViewPosition()
  }
  
  private func adjustCollectionViewPosition() {
    switch calendarType {
    case .month:
      collectionView.contentOffset.x = collectionView.bounds.width * CGFloat(monthsOnSides)
    case .week:
      collectionView.scrollToItem(at: IndexPath(row: 8, section: monthsOnSides), at: .left, animated: true)
    }
  }
  
  private func preparedCollectionViewDataRequest(for date: Date) -> CalendarCollectionViewDataRequest {
    var months: [Month] = []
    for monthIndex in 1...monthsOnSides {
      let previousMonthDate = calendar.date(byAdding: .month, value: -monthIndex, to: date)!
      let nextMonthDate = calendar.date(byAdding: .month, value: monthIndex, to: date)!
      months.insert(preparedMonth(for: previousMonthDate), at: 0)
      months.append(preparedMonth(for: nextMonthDate))
    }
    months.insert(preparedMonth(for: date), at: months.count/2)
    return .init(months: months, selectedDates: selectedDates, calendar: calendar, calendarType: calendarType)
  }
  
  private func preparedMonth(for date: Date) -> Month {
    
    let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: date)!
    let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: date)!
    
    let previousMonthDaysCount =  calendar.range(of: .day, in: .month, for: previousMonthDate)!.count
    let currentMonthDaysCount =  calendar.range(of: .day, in: .month, for: date)!.count
    let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year,.month], from: date))!
    
    let previousMonthDaysToDisplay = weekday(of: firstDayOfMonth, weekStartSunday: false)
    var previousMonthDaysRange: [Int] = []
    if previousMonthDaysToDisplay > 0 {
      previousMonthDaysRange = Array(previousMonthDaysCount - (previousMonthDaysToDisplay - 1)...previousMonthDaysCount)
    }
    
    let previousMonthDays = transformToDates(days: previousMonthDaysRange, for: previousMonthDate)
    
    let currentMonthDays = transformToDates(days: Array(1...currentMonthDaysCount), for: date)
    
    let nextMonthDaysCount = calendar.weekdaySymbols.count
      - ((previousMonthDays.count + currentMonthDays.count) % calendar.weekdaySymbols.count)
    
    let nextMonthDays = transformToDates(days: Array(1...nextMonthDaysCount), for: nextMonthDate)
    
    return Month(previousMonthDays: previousMonthDays,
                 currentMonthDays: currentMonthDays,
                 nextMonthDays: nextMonthDays)
  }
  
  private func preparedWeek(for date: Date) -> Week {
    let currentWeekDaysFirst =  calendar.range(of: .day, in: .weekOfMonth, for: date)!.first!
    let currentWeekDaysCount =  calendar.range(of: .day, in: .weekOfMonth, for: date)!.count
    let currentWeekDays = transformToDates(days: Array(currentWeekDaysFirst...currentWeekDaysCount), for: date)
    return Week(days: currentWeekDays)
  }
  
  func weekday(of date: Date, weekStartSunday: Bool) -> Int {
    guard !weekStartSunday else { return calendar.component(.weekday, from: date) }
    let weekDay = calendar.component(.weekday, from: date)
    switch weekDay {
    case 1:
      return 6
    default:
      return weekDay - 2
    }
  }
  
  func weekdayVeryShortSymbols(weekStartSunday: Bool) -> [String] {
    guard !weekStartSunday else { return calendar.veryShortWeekdaySymbols }
    var symbols = calendar.veryShortWeekdaySymbols
    symbols.append(symbols[0])
    symbols.remove(at: 0)
    return symbols
  }
  
  private func displayNextMonth() {
    currentDisplayedDate = calendar.date(byAdding: .month, value: 1, to: currentDisplayedDate)!
    setupCalendar(for: currentDisplayedDate)
    delegate?.didChangeMonth(to: currentDisplayedDate)
  }
  
  private func displayPreviousMonth() {
    currentDisplayedDate = calendar.date(byAdding: .month, value: -1, to: currentDisplayedDate)!
    setupCalendar(for: currentDisplayedDate)
    delegate?.didChangeMonth(to: currentDisplayedDate)
  }
  
  private func transformToDates(days: [Int], for monthDate: Date) -> [Date] {
    return days.compactMap { calendar.date(from: DateComponents(calendar: calendar,
                                                                year: calendar.component(.year, from: monthDate),
                                                                month: calendar.component(.month, from: monthDate),
                                                                day: $0)) }
  }

}

extension CalendarView: CalendarCollectionViewActionDelegate {
  func didChangeMonth(to date: Date) {
//    currentDisplayedDate = date
//    setupCalendar(for: currentDisplayedDate)
//    delegate?.didChangeMonth(to: currentDisplayedDate)
  }
  
  func willChangeMonth(to date: Date) {
    delegate?.willChangeMonth(to: date)
  }
  
  func didTapOn(date: Date, indexPath: IndexPath) {
    let isSelected = collectionViewDataSource
      .request
      .selectedDates
      .contains(where: { Calendar.current.compare($0, to: date, toGranularity: .day) == .orderedSame})
    if isSelected {
      deselect(date: date)
      reloadData()
      delegate?.didDeselect(day: date)
    } else {
      select(date: date)
      reloadData()
      delegate?.didSelect(day: date)
    }
  }
  
  func didChangeWeek(to: Date) {
    
  }
  
  func willChangeWeek(to: Date) {
    
  }
  
}
