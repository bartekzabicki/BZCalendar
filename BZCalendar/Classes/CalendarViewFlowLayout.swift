//
//  CalendarViewFlowLayout.swift
//  Calendar
//
//  Created by Bartłomiej Zabicki on 28/03/2019.
//  Copyright © 2019 Bartlomiej Zabicki. All rights reserved.
//

import UIKit

final class CalendarViewFlowLayout: UICollectionViewFlowLayout {
  
  // MARK: - Properties
  
  private var cache: [UICollectionViewLayoutAttributes] = []
  private var superViewFrame: CGRect = .zero
  private(set) var layoutType: CalendarType = .month
  
  private var contentSize: CGSize = .zero
  override var collectionViewContentSize: CGSize {
    return contentSize
  }
  
  // MARK: - Initialization
  
  init(frame: CGRect, layoutType: CalendarType) {
    super.init()
    superViewFrame = frame
    self.layoutType = layoutType
    setup(frame: frame)
  }
  
  override init() {
    super.init()
    minimumLineSpacing = 0
    minimumInteritemSpacing = 0
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    minimumLineSpacing = 0
    minimumInteritemSpacing = 0
  }
  
  // MARK: - Overrides
  
  override func prepare() {
    super.prepare()
    setupLayout()
  }
  
  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    var layoutAttributes = [UICollectionViewLayoutAttributes]()
    for attributes in cache {
      if attributes.frame.intersects(rect) {
        layoutAttributes.append(attributes)
      }
    }
    return layoutAttributes
  }
  
  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    return cache.first { attributes -> Bool in
      return attributes.indexPath == indexPath
    }
  }
  
  // MARK: - Functions
  
  private func setup(frame: CGRect) {
    scrollDirection = .horizontal
    minimumLineSpacing = 0
    minimumInteritemSpacing = 0
  }
  
  public func changeType(to type: CalendarType) {
    layoutType = type
  }
  
  private func setupLayout() {
    guard let collectionView = collectionView else { return }
    switch layoutType {
    case .month:
      setupMonthLayout(in: collectionView)
    case .week:
      setupWeekLayout(in: collectionView)
    }
  }
  
  private func setupMonthLayout(in collectionView: UICollectionView) {
    contentSize = .zero
    cache = [UICollectionViewLayoutAttributes]()
    let itemDimension = (superViewFrame.width - (6 * minimumInteritemSpacing))/7
    itemSize = CGSize(width: itemDimension, height: itemDimension)
    
    for section in 0..<collectionView.numberOfSections {
      for row in 0 ..< collectionView.numberOfItems(inSection: section) {
        let indexPath = IndexPath(item: row, section: section)
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        let x = CGFloat(row % 7) * itemSize.width + (CGFloat(section) * itemSize.width * 7)
        let y = CGFloat(row / 7) * itemSize.height
        let frame = CGRect(origin: CGPoint(x: x, y: y), size: itemSize)
        attributes.frame = frame
        contentSize.width = max(contentSize.width, frame.maxX)
        contentSize.height = max(contentSize.height, frame.maxY)
        cache.append(attributes)
      }
    }
  }
  
  private func setupWeekLayout(in collectionView: UICollectionView) {
    contentSize = .zero
    cache = [UICollectionViewLayoutAttributes]()
    let itemDimension = (superViewFrame.width - (6 * minimumInteritemSpacing))/7
    itemSize = CGSize(width: itemDimension, height: itemDimension)
    var index: CGFloat = 0
    for section in 0..<collectionView.numberOfSections {
      for row in 0..<collectionView.numberOfItems(inSection: section) {
        let indexPath = IndexPath(item: row, section: section)
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        let x = index * itemSize.width
        let y: CGFloat = 0
        let frame = CGRect(origin: CGPoint(x: x, y: y), size: itemSize)
        attributes.frame = frame
        contentSize.width = max(contentSize.width, frame.maxX)
        contentSize.height = max(contentSize.height, frame.maxY)
        cache.append(attributes)
        index += 1
      }
    }
  }
  
}
