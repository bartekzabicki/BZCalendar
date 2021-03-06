//
//  DayCollectionViewCell.swift
//  Calendar
//
//  Created by Bartłomiej Zabicki on 30/03/2019.
//  Copyright © 2019 Bartlomiej Zabicki. All rights reserved.
//

import UIKit
import Unicorns

@IBDesignable
class DayCollectionViewCell: UICollectionViewCell {
  
  // MARK: - Enums
  
  enum MonthDayType {
    case previousMonth
    case currentMonth
    case nextMonth
  }
  
  enum NeighborSelectionState {
    case next
    case previous
    case both
    case `none`
  }
  
  // MARK: - Outlets
  
  private lazy var innerView: UIView = {
    var view = UIView()
    view.backgroundColor = .clear
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  private lazy var dayLabel: UILabel = {
    let label = UILabel()
    label.backgroundColor = .clear
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = "1"
    label.textAlignment = .center
    return label
  }()
  
  // MARK: - Structures
  
  struct ViewModel {
    let dayNumber: String
    let dayState: MonthDayType
    let isSelected: Bool
    let isCurrentDay: Bool
    let neighborSelection: NeighborSelectionState
  }
  
  // MARK: - Properties
  
  private static var selectedArcRadius: CGFloat = 25
  
  private(set) var viewModel: ViewModel?
  private lazy var selectionLayer: CAShapeLayer = {
    let layer = CAShapeLayer()
    layer.strokeStart = 0
    return layer
  }()
  
  // MARK: - Lifecycle
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupLayout()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupLayout()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    reloadSelectionLayer(with: (selectionLayer.path = selectionLayerPath(state: viewModel?.neighborSelection ?? .none)))
  }
  
  // MARK: - Functions
  
  func setupView(with viewModel: ViewModel) {
    self.viewModel = viewModel
    dayLabel.text = viewModel.dayNumber
    adjustDay(to: viewModel.dayState)
    adjustSelection(to: viewModel.isSelected, neighborSelection: viewModel.neighborSelection)
    adjustCurrentDay(to: viewModel.isCurrentDay)
  }
  
  // MARK: - Private Functions
  
  private func setupLayout() {
    addSubview(innerView)
    innerView.addSubview(dayLabel)
    anchor(view: innerView, to: self)
    anchor(view: dayLabel, to: innerView)
    
    reloadSelectionLayer(with: (selectionLayer.path = selectionLayerPath(state: .none)))
    selectionLayer.zPosition = -1
    layer.insertSublayer(selectionLayer, below: innerView.layer)
  }
  
  private func adjustDay(to dayState: MonthDayType) {
    switch dayState {
    case .currentMonth:
      dayLabel.textColor = UIColor(hexString: "333333")
    default:
      dayLabel.textColor = UIColor(hexString: "BDCDD1")
    }
  }
  
  private func adjustSelection(to isSelected: Bool, neighborSelection: NeighborSelectionState) {
    if isSelected {
      dayLabel.textColor = .white
    }
    let color = isSelected ? UIColor(hexString: "81A9EB") : .clear
    reloadSelectionLayer(with: (selectionLayer.fillColor = color.cgColor))
    switch neighborSelection {
    case .previous, .next, .both:
      selectionLayer.path = selectionLayerPath(state: neighborSelection)
    case .none: break
    }
  }
  
  private func selectionLayerPath(state: NeighborSelectionState) -> CGPath {
    let rect = CGRect(x: (bounds.width - DayCollectionViewCell.selectedArcRadius) / 2,
                      y: (bounds.height - DayCollectionViewCell.selectedArcRadius) / 2,
                      width: DayCollectionViewCell.selectedArcRadius,
                      height: DayCollectionViewCell.selectedArcRadius)
    var modifiedRect = rect
    modifiedRect.size.width = bounds.width - rect.origin.x
    switch state {
    case .previous:
      modifiedRect.origin.x = -5
      modifiedRect.size.width += 5
      return UIBezierPath(roundedRect: modifiedRect, byRoundingCorners: [.bottomRight, .topRight], cornerRadii: CGSize(width: 4, height: 4)).cgPath
    case .next:
      modifiedRect.size.width = bounds.width + 20
      return UIBezierPath(roundedRect: modifiedRect, byRoundingCorners: [.bottomLeft, .topLeft], cornerRadii: CGSize(width: 4, height: 4)).cgPath
    case .both:
      modifiedRect.origin.x = -5
      modifiedRect.size.width = bounds.width + 20
      return UIBezierPath(rect: modifiedRect).cgPath
    case .none:
      return UIBezierPath(ovalIn: rect).cgPath
    }
  }
  
  private func adjustCurrentDay(to isCurrentDay: Bool) {
    if isCurrentDay {
      dayLabel.textColor = .red
    }
  }
  
  private func reloadSelectionLayer(with clousure: @autoclosure () -> Void) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    clousure()
    CATransaction.commit()
  }
  
  private func anchor(view: UIView, to superview: UIView) {
    view.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
    view.leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
    view.trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
    view.bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
  }
  
}
