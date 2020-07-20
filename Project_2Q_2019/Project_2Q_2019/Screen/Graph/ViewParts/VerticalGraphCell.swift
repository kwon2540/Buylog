//
//  VerticalGraphCell.swift
//  Project_2Q_2019
//
//  Created by Kwon junhyeok on 2020/07/16.
//  Copyright © 2020 JUNHYEOK KWON. All rights reserved.
//

import UIKit

class VerticalGraphCell: UICollectionViewCell {
    
    enum GraphType {
        case month
        case date
    }
    
    @IBOutlet private weak var expenditureLabel: UILabel!
    @IBOutlet private weak var verticalGraphView: UIView!
    @IBOutlet private weak var dateNumberLabel: UILabel!
    @IBOutlet private weak var dateCharacterLabel: UILabel!
    @IBOutlet private weak var verticalGraphHeight: NSLayoutConstraint!
    @IBOutlet private weak var verticalGraphTop: NSLayoutConstraint!
    @IBOutlet private weak var verticalGraphBottom: NSLayoutConstraint!
    
    private func setEmptyGraphView() {
        let dashedLineBorder = CAShapeLayer()
        let maxGraphViewHeight = self.frame.height - (expenditureLabel.frame.height + dateNumberLabel.frame.height + dateCharacterLabel.frame.height + verticalGraphTop.constant + verticalGraphBottom.constant)
        let graphView = verticalGraphView.bounds
        let graphViewFrame = CGRect(x: graphView.minX, y: graphView.minY, width: graphView.width, height: maxGraphViewHeight)
        dashedLineBorder.strokeColor = UIColor.lightGray.cgColor
        dashedLineBorder.lineWidth = 0.3
        dashedLineBorder.lineDashPattern = [1.5, 1.5]
        dashedLineBorder.frame = graphViewFrame
        dashedLineBorder.fillColor = nil
        dashedLineBorder.path = UIBezierPath(roundedRect: graphViewFrame, cornerRadius: graphView.width / 2).cgPath
        verticalGraphHeight.constant = maxGraphViewHeight
        verticalGraphView.layer.addSublayer(dashedLineBorder)
    }
    
    private func setGraphView(graphType: GraphType, graphHeight: CGFloat) {
        verticalGraphHeight.constant = graphHeight
        verticalGraphView.backgroundColor = graphType == .month ? .c6889FF : .c44CB97
        let cornerRadius = graphHeight < verticalGraphView.frame.width ? graphHeight / 2 : verticalGraphView.frame.width / 2
        verticalGraphView.layer.cornerRadius = cornerRadius
    }
    
    func set(graphType: GraphType, expenditure: String, dateNumber: String, DateCharacter: String, graphHeight: CGFloat) {
        expenditureLabel.text = expenditure
        dateNumberLabel.text = dateNumber
        dateCharacterLabel.text = DateCharacter
        graphHeight == .zero ? setEmptyGraphView() : setGraphView(graphType: graphType, graphHeight: graphHeight)
    }
}
