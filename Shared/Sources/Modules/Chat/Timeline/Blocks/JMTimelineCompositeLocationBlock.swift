//
//  JMTimelineCompositeLocationBlock.swift
//  JivoMobile
//
//  Created by Stan Potemkin on 25/09/2018.
//  Copyright © 2018 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import JMTimelineKit

struct JMTimelineCompositeLocationBlockStyle: JMTimelineStyle {
    let ratio: CGFloat

    init(ratio: CGFloat) {
        self.ratio = ratio
    }
}

final class JMTimelineCompositeLocationBlock: JMTimelineBlock {
    private let internalControl = InternalControl()
    
    private var coordinate: CLLocationCoordinate2D?

    override init() {
        super.init()
        
        addSubview(internalControl)
        layer.cornerRadius = Self.defaultCornerRadius
        clipsToBounds = true
        isUserInteractionEnabled = true
        
        addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleTap))
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return internalControl.sizeThatFits(size)
    }
    
    func configure(coordinate value: CLLocationCoordinate2D, style: JMTimelineCompositeLocationBlockStyle, provider: JVChatTimelineProvider, interactor: JVChatTimelineInteractor) {
        linkTo(provider: provider, interactor: interactor)
        
        coordinate = value
        internalControl.configure(coordinate: value, ratio: style.ratio)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        internalControl.frame = bounds
    }
    
    override func updateDesign() {
    }

    override func handleLongPressGesture(recognizer: UILongPressGestureRecognizer) -> Bool {
        return false
    }
    
    @objc private func handleTap() {
        guard let coordinate = coordinate else {
            return
        }
        
        interactor?.requestLocation(coordinate: coordinate)
    }
}

fileprivate final class InternalControl: MKMapView {
    private var coordinate: CLLocationCoordinate2D?
    private var ratio = CGFloat(0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        isScrollEnabled = false
        isZoomEnabled = false
        clipsToBounds = true
        isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(coordinate: CLLocationCoordinate2D, ratio: CGFloat) {
        self.ratio = ratio
        
        mapType = .standard
        
        region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        addAnnotation(annotation)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let height = size.width * ratio
        return CGSize(width: size.width, height: height)
    }
}
