//
//  CalendarViewDataSource+Delegate.swift
//  Calendar
//
//  Created by Bartłomiej Zabicki on 28/03/2019.
//  Copyright © 2019 Bartlomiej Zabicki. All rights reserved.
//

import Unicorns

internal struct CalendarCollectionViewDataRequest {
  let months: [CalendarView.Month]
  let selectedDates: [Date]
  let calendar: Calendar
  let calendarType: CalendarType
}

final class CalendarCollectionViewDataSource: NSObject, UICollectionViewDataSource {
  
  // MARK: - Properties
  
  var request: CalendarCollectionViewDataRequest
  private lazy var dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    formatter.timeZone = TimeZone(identifier: "UTC")
    return formatter
  }()
  private lazy var monthDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(identifier: "UTC")!
    formatter.dateFormat = "MMMM yyyy"
    return formatter
  }()
  
  // MARK: - Initialization
  
  init(request: CalendarCollectionViewDataRequest) {
    self.request = request
  }
  
  // MARK: - UICollectionViewDataSource
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return request.months.count
  }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return request.months[section].allDays.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusable(cell: DayCollectionViewCell.self, for: indexPath)
    let date = request.months[indexPath.section].allDays[indexPath.row]
    let dayNumber = dayFormatter.string(from: date)
    let isSelected = request
      .selectedDates
      .contains(where: { request.calendar.compare($0, to: date, toGranularity: .day) == .orderedSame})
    let isCurrentDay = request.calendar.compare(date, to: Date(), toGranularity: .day) == .orderedSame
    
    var selectionState: DayCollectionViewCell.NeighborSelectionState = .none
    request.selectedDates.forEach { selectedDate in
      if let nextDay = request.calendar.date(byAdding: .day, value: 1, to: date),
        request.calendar.compare(nextDay, to: selectedDate, toGranularity: .day) == .orderedSame {
        if selectionState == .none {
          selectionState = .next
        } else {
          selectionState = .both
        }
      }
      if let previousDay = request.calendar.date(byAdding: .day, value: -1, to: date),
        request.calendar.compare(previousDay, to: selectedDate, toGranularity: .day) == .orderedSame {
        if selectionState == .none {
          selectionState = .previous
        } else {
          selectionState = .both
        }
      }
    }
    let viewModel = DayCollectionViewCell.ViewModel(dayNumber: dayNumber,
                                                    dayState: dayState(for: indexPath),
                                                    isSelected: isSelected,
                                                    isCurrentDay: isCurrentDay,
                                                    neighborSelection: selectionState)
    cell.setupView(with: viewModel)
    return cell
  }
  
  // MAKR: - Private Functions
  
  private func dayState(for indexPath: IndexPath) -> DayCollectionViewCell.MonthDayType {
    let month = request.months[indexPath.section]
    if indexPath.row < month.previousMonthDays.count {
      return .previousMonth
    } else if month.previousMonthDays.count + month.currentMonthDays.count <= indexPath.row {
      return .nextMonth
    } else {
      return .currentMonth
    }
  }
  
}

protocol CalendarCollectionViewActionDelegate: class {
  func didTapOn(date: Date, indexPath: IndexPath)
  func didChangeMonth(to: Date)
  func willChangeMonth(to: Date)
  func didChangeWeek(to: Date)
  func willChangeWeek(to: Date)
}

final class CalendarCollectionViewDelegate: NSObject, UICollectionViewDelegate {
  
  // MARK: - Properties
  
  let request: CalendarCollectionViewDataRequest
  weak var delegate: CalendarCollectionViewActionDelegate?
  var currentMonthIndex: Int!
  var oldMonthIndex: Int!
  
  // MARK: - Initialization
  
  init(request: CalendarCollectionViewDataRequest, delegate: CalendarCollectionViewActionDelegate) {
    self.request = request
    self.delegate = delegate
    currentMonthIndex = request.months.count/2
    oldMonthIndex = request.months.count/2
  }
  
  // MARK: - UICollectionViewDelegate
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let day = request.months[indexPath.section].allDays[indexPath.row]
    delegate?.didTapOn(date: day, indexPath: indexPath)
  }
  
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    guard let collectionView = scrollView as? UICollectionView else { return }
    currentMonthIndex = monthIndexFor(contentOffset: scrollView.contentOffset, in: collectionView)
  }
  
  func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                 withVelocity velocity: CGPoint,
                                 targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    guard let collectionView = scrollView as? UICollectionView else { return }
    targetContentOffset.pointee = scrollView.contentOffset
    let monthPosition = calculatedMonthPosition(in: collectionView, on: scrollView.contentOffset, velocity: velocity)
    targetContentOffset.pointee.x = monthPosition
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    checkIfMonthDidChange(in: scrollView)
  }
  
  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      checkIfMonthDidChange(in: scrollView)
    }
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard let collectionView = scrollView as? UICollectionView else { return }
    
    let blankOffset: CGFloat = 100
    let maxCollectionViewContent = CGFloat(request.months.count) * collectionView.bounds.width
    
    if scrollView.contentOffset.x < -blankOffset {
      switch request.calendarType {
      case .month:
        callDelegate(delegateMethod: delegate?.didChangeMonth(to: dateFor(index: 0)), index: 0)
      case .week:
        callDelegate(delegateMethod: delegate?.didChangeWeek(to: dateFor(index: 0)), index: 0)
      }
    } else if scrollView.contentOffset.x > maxCollectionViewContent {
      let index = request.months.count - 1
      switch request.calendarType {
      case .month:
        callDelegate(delegateMethod: delegate?.didChangeMonth(to: dateFor(index: index)), index: index)
      case .week:
        callDelegate(delegateMethod: delegate?.didChangeWeek(to: dateFor(index: index)), index: index)
      }
    } else {
      let index = monthIndexFor(contentOffset: scrollView.contentOffset, in: collectionView)
      switch request.calendarType {
      case .month:
        callDelegate(delegateMethod: delegate?.willChangeMonth(to: dateFor(index: index)), index: index)
      case .week:
        callDelegate(delegateMethod: delegate?.willChangeWeek(to: dateFor(index: index)), index: index)
      }
    }
  }
  
  // MARK: - Private functions
  
  private func calculatedMonthPosition(in collectionView: UICollectionView, on contentOffset: CGPoint, velocity: CGPoint) -> CGFloat {
    guard let flowLayout = collectionView.collectionViewLayout as? CalendarViewFlowLayout else { return 0 }
    let monthWidth = (flowLayout.itemSize.width) * 7
    let months = collectionView.contentSize.width/monthWidth
    
    var currentMonthIndex = monthIndexFor(contentOffset: contentOffset, in: collectionView)
    let velocityCriticalPoint: CGFloat = 0
    
    let isTheSameMonth = currentMonthIndex == self.currentMonthIndex
    if isTheSameMonth {
      if velocity.x > velocityCriticalPoint, currentMonthIndex + 1 < Int(months) {
        currentMonthIndex += 1
      } else if velocity.x < -velocityCriticalPoint, currentMonthIndex - 1 >= 0 {
        currentMonthIndex -= 1
      }
    }
    self.currentMonthIndex = currentMonthIndex
    
    return (CGFloat(currentMonthIndex) * monthWidth)
  }
  
  private func monthIndexFor(contentOffset: CGPoint, in collectionView: UICollectionView) -> Int {
    guard let flowLayout = collectionView.collectionViewLayout as? CalendarViewFlowLayout else { return 0 }
    let monthWidth = (flowLayout.itemSize.width + flowLayout.minimumLineSpacing) * 7
    return Int(round(contentOffset.x / monthWidth))
  }
  
  private func checkIfMonthDidChange(in scrollView: UIScrollView) {
    if currentMonthIndex != oldMonthIndex {
      switch request.calendarType {
      case .month:
        callDelegate(delegateMethod: delegate?.didChangeMonth(to: dateFor(index: currentMonthIndex)), index: currentMonthIndex)
        restoreDefaultIndexes()
      case .week:
        callDelegate(delegateMethod: delegate?.didChangeWeek(to: dateFor(index: currentMonthIndex)), index: currentMonthIndex)
      }
    }
  }
  
  private func dateFor(index: Int) -> Date {
    if request.months.indices.contains(index) {
      return request.months[index].currentMonthDays.first!
    } else {
      if currentMonthIndex < 0 {
        return request.months.first!.currentMonthDays.first!
      } else {
        return request.months.last!.currentMonthDays.first!
      }
    }
  }
  
  private func callDelegate(delegateMethod: @autoclosure () -> Void?, index: Int) {
    if request.months.indices.contains(index) {
      delegateMethod()
    } else {
      if index < 0 {
        delegateMethod()
      } else {
        delegateMethod()
      }
    }
  }
  
  private func restoreDefaultIndexes() {
    currentMonthIndex = request.months.count/2
    oldMonthIndex = request.months.count/2
  }
  
}
