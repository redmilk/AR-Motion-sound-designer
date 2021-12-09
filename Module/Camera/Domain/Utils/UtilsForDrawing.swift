//
//  UtilsForDrawing.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 09.12.2021.
//

import Foundation
import UIKit

class UtilsForDrawing {
    
    // MARK: - Public
    
    static func addCircleImage(
        atPoint point: CGPoint,
        to view: UIView,
        radius: CGFloat
    ) {
        let divisor: CGFloat = 2.0
        let xCoord = point.x - radius / divisor
        let yCoord = point.y - radius / divisor
        let circleRect = CGRect(x: xCoord, y: yCoord, width: radius, height: radius)
        let circleView = UIImageView(frame: circleRect)
        circleView.image = UIImage(named: "point")
        circleView.layer.cornerRadius = radius / divisor
        circleView.alpha = Constant.circleImageAlpha
        view.addSubview(circleView)
        circleView.bringSubviewToFront(view)
    }
    
    static func addCircle(
        atPoint point: CGPoint,
        to view: UIView,
        color: UIColor,
        radius: CGFloat
    ) {
        let divisor: CGFloat = 2.0
        let xCoord = point.x - radius / divisor
        let yCoord = point.y - radius / divisor
        let circleRect = CGRect(x: xCoord, y: yCoord, width: radius, height: radius)
        let circleView = UIView(frame: circleRect)
        circleView.layer.cornerRadius = radius / divisor
        circleView.alpha = Constant.circleViewAlpha
        circleView.backgroundColor = color
        view.addSubview(circleView)
        circleView.bringSubviewToFront(view)
    }
    
    static func addLineSegment(
        fromPoint: CGPoint, toPoint: CGPoint, inView: UIView, color: UIColor, width: CGFloat
    ) {
        let path = UIBezierPath()
        path.move(to: fromPoint)
        path.addLine(to: toPoint)
        let lineLayer = CAShapeLayer()
        lineLayer.path = path.cgPath
        lineLayer.strokeColor = color.cgColor
        lineLayer.fillColor = nil
        lineLayer.opacity = 1.0
        lineLayer.lineWidth = width
        let lineView = UIView()
        lineView.layer.addSublayer(lineLayer)
        inView.addSubview(lineView)
    }
    
    static func addRectangle(_ rectangle: CGRect, to view: UIView, color: UIColor) {
        guard !rectangle.isNaN() else { return }
        let rectangleView = UIView(frame: rectangle)
        rectangleView.layer.cornerRadius = Constant.rectangleViewCornerRadius
        rectangleView.alpha = Constant.rectangleViewAlpha
        rectangleView.backgroundColor = color
        view.addSubview(rectangleView)
    }
    
    static func addShape(withPoints points: [NSValue]?, to view: UIView, color: UIColor) {
        guard let points = points else { return }
        let path = UIBezierPath()
        for (index, value) in points.enumerated() {
            let point = value.cgPointValue
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
            if index == points.count - 1 {
                path.close()
            }
        }
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = color.cgColor
        let rect = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
        let shapeView = UIView(frame: rect)
        shapeView.alpha = Constant.shapeViewAlpha
        shapeView.layer.addSublayer(shapeLayer)
        view.addSubview(shapeView)
    }
}
