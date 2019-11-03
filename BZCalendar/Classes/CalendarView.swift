//
//  CalendarView.swift
//  Calendar
//
//  Created by Bartłomiej Zabicki on 28/03/2019.
//  Copyright © 2019 Bartlomiej Zabicki. All rights reserved.
//

import UIKit

public protocol CalendarViewDelegate: class {
  func didChangeDate(to: Date)
  func willChangeDate(to: Date)
  func didSelect(day: Date)
  func didDeselect(day: Date)
}

public enum CalendarType {
  case month
  case week
  
  var calendarComponent: Calendar.Component {
    switch self {
    case .month:
      return .month
    case .week:
      return .weekOfYear
    }
  }
}

@IBDesignable
open class CalendarView: UIView {
  
  // MARK: - Structures
  
  struct Element {
    let previousMonthDays: [Date]
    let currentMonthDays: [Date]
    let nextMonthDays: [Date]
    
    var allDays: [Date] {
      return [previousMonthDays, currentMonthDays, nextMonthDays].flatMap {$0}
    }
  }
  
  // MARK: - Properties
  
  @IBInspectable public var calendarInsets: UIEdgeInsets = .zero
  @IBInspectable public var areSwipeGestureRecognizersActive = true
  @IBInspectable public var isSelectingDaysActive = true
  
  private lazy var collectionView: UICollectionView = {
    let collectionView = UICollectionView(frame: bounds,
                                          collectionViewLayout: CalendarViewFlowLayout(frame: bounds, layoutType: calendarType))
    let nibName = UINib(nibName: DayCollectionViewCell.reuseIdentifier, bundle: Bundle(for: CalendarView.self))
    collectionView.register(nibName, forCellWithReuseIdentifier: DayCollectionViewCell.reuseIdentifier)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.backgroundColor = backgroundColor
    collectionView.alwaysBounceVertical = false
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
  private var elementsOnSides: Int = 3 {
    didSet {
      setupCalendar(for: currentDisplayedDate)
    }
  }
  private(set) var selectedDates: [Date] = []
  private(set) var calendarType: CalendarType = .month
  
  public weak var delegate: CalendarViewDelegate?
  private var heightConstraint: NSLayoutConstraint?
  
  // MARK: - Initialization
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setupView()
  }
  
  open override func layoutSubviews() {
    super.layoutSubviews()
    
    let collectionViewLayout = CalendarViewFlowLayout(frame: bounds, layoutType: calendarType)
    collectionView.setCollectionViewLayout(collectionViewLayout, animated: false)
    adjustCollectionViewPosition()
    adjustHeightConstraint()
  }
  
  // MARK: - Functions
  
  public func changeToPrevious() {
    displayPreviousElement(calendarType: calendarType)
  }
  
  public func changeToNext() {
    displayNextElement(calendarType: calendarType)
  }
  
  public func changeTo(date: Date) {
    currentDisplayedDate = date
    setupCalendar(for: currentDisplayedDate)
    delegate?.didChangeDate(to: currentDisplayedDate)
  }
  
  public func select(date: Date) {
    guard !selectedDates.contains(date) else { return }
    selectedDates.append(date)
    reloadData()
  }
  
  public func select(dates: [Date]) {
    selectedDates.forEach ({ [weak self] date in
      selectedDates.removeAll(where: { $0 == date })
      self?.delegate?.didDeselect(day: date)
    })
    selectedDates = dates
    reloadData()
  }
  
  public func deselect(date: Date) {
    selectedDates.removeAll(where: { $0 == date })
  }
  
  public func reloadData() {
    changeTo(date: currentDisplayedDate)
  }
  
  public func changeCalendarType(to calendarType: CalendarType) {
    self.calendarType = calendarType
    setupCalendar(for: currentDisplayedDate)
    collectionViewLayout.changeType(to: calendarType)
    collectionView.collectionViewLayout.invalidateLayout()
    collectionView.collectionViewLayout.prepare()
    adjustHeightConstraint()
  }
  
  // MARK: - Private Functions
  
  internal func setupView() {
    translatesAutoresizingMaskIntoConstraints = false
    addWeekdays()
    addCollectionView()
    setupCalendar(for: Date())
    adjustHeightConstraint()
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
    let request = preparedCollectionViewDataRequest(for: date, type: calendarType)
    collectionViewDataSource = CalendarCollectionViewDataSource(request: request)
    collectionViewDelegate = CalendarCollectionViewDelegate(request: request, delegate: self)
    collectionView.dataSource = collectionViewDataSource
    collectionView.delegate = collectionViewDelegate
    adjustCollectionViewPosition()
  }
  
  private func adjustCollectionViewPosition() {
    collectionView.contentOffset.x = collectionView.bounds.width * CGFloat(elementsOnSides)
  }
  
  private func preparedCollectionViewDataRequest(for date: Date, type: CalendarType) -> CalendarCollectionViewDataRequest {
    let calendarComponent = type.calendarComponent
    var elements: [Element] = []
    for elementIndex in 1...elementsOnSides {
      let previousElementDate = calendar.date(byAdding: calendarComponent, value: -elementIndex, to: date)!
      let nextElementDate = calendar.date(byAdding: calendarComponent, value: elementIndex, to: date)!
      
      switch type {
      case .month:
        elements.insert(preparedMonth(for: previousElementDate), at: 0)
        elements.append(preparedMonth(for: nextElementDate))
      case .week:
        elements.insert(preparedWeek(for: previousElementDate), at: 0)
        elements.append(preparedWeek(for: nextElementDate))
      }
    }
    switch type {
    case .month:
      elements.insert(preparedMonth(for: date), at: elements.count/2)
    case .week:
      elements.insert(preparedWeek(for: date), at: elements.count/2)
    }
    return .init(elements: elements, selectedDates: selectedDates, calendar: calendar, calendarType: calendarType)
  }
  
  private func preparedMonth(for date: Date) -> Element {
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
    
    return Element(previousMonthDays: previousMonthDays,
                   currentMonthDays: currentMonthDays,
                   nextMonthDays: nextMonthDays)
  }
  
  private func preparedWeek(for date: Date) -> Element {
    let weekOfTheYear = calendar.component(.weekOfYear, from: date)
    let yearForWeekOfYear = calendar.component(.yearForWeekOfYear, from: date)
    let firstDateOfWeek = calendar.date(from: DateComponents(calendar: calendar,
                                                             weekOfYear: weekOfTheYear,
                                                             yearForWeekOfYear: yearForWeekOfYear))!
    let weekDaysCount = calendar.weekdaySymbols.count
    var days = Array.init(repeating: firstDateOfWeek, count: weekDaysCount)
      .enumerated()
      .compactMap({ calendar.date(byAdding: .day, value: $0.offset, to: firstDateOfWeek)})
    let previousMonthDays = days.filter({ calendar.compare($0, to: date, toGranularity: .month) == .orderedAscending})
    let nextMonthDays = days.filter({ calendar.compare($0, to: date, toGranularity: .month) == .orderedDescending})
    days = days.filter({ !previousMonthDays.contains($0) && !nextMonthDays.contains($0)})
    return Element(previousMonthDays: previousMonthDays,
                   currentMonthDays: days,
                   nextMonthDays: nextMonthDays)
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
  
  private func displayNextElement(calendarType: CalendarType) {
    currentDisplayedDate = calendar.date(byAdding: calendarType.calendarComponent, value: 1, to: currentDisplayedDate)!
    setupCalendar(for: currentDisplayedDate)
    delegate?.didChangeDate(to: currentDisplayedDate)
  }
  
  private func displayPreviousElement(calendarType: CalendarType) {
    currentDisplayedDate = calendar.date(byAdding: calendarType.calendarComponent, value: -1, to: currentDisplayedDate)!
    setupCalendar(for: currentDisplayedDate)
    delegate?.didChangeDate(to: currentDisplayedDate)
  }
  
  private func transformToDates(days: [Int], for monthDate: Date) -> [Date] {
    return days.compactMap { calendar.date(from: DateComponents(calendar: calendar,
                                                                year: calendar.component(.year, from: monthDate),
                                                                month: calendar.component(.month, from: monthDate),
                                                                day: $0)) }
  }
  
  private func adjustHeightConstraint() {
    let constant = collectionViewLayout.collectionViewContentSize.height + weekdaysStackView.bounds.height
    if let heightConstraint = heightConstraint {
      heightConstraint.constant = constant
    } else {
      heightConstraint = heightAnchor.constraint(equalToConstant: constant)
      heightConstraint?.isActive = true
    }
    layoutIfNeeded()
  }
  
}

extension CalendarView: CalendarCollectionViewActionDelegate {
  func didChangeDate(to date: Date) {
    let date = calendar.startOfDay(for: date)
    currentDisplayedDate = date
    setupCalendar(for: currentDisplayedDate)
    delegate?.didChangeDate(to: currentDisplayedDate)
  }
  
  func willChangeDate(to date: Date) {
    let date = calendar.startOfDay(for: date)
    delegate?.willChangeDate(to: date)
  }
  
  func didTapOn(date: Date, indexPath: IndexPath) {
    let date = calendar.startOfDay(for: date)
    guard isSelectingDaysActive else {
      select(dates: [date])
      delegate?.didSelect(day: date)
      return
    }
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
  
}
