//
//  ChipsElementControl.swift
//  JivoMobile
//

import Foundation
import UIKit

struct ChipsElementControlOptions: OptionSet {
    let rawValue: Int
    static let deletable = Self.init(rawValue: 1 << 0)
}

final class ChipsElementControl: UIButton {
    private let paddings = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    
    init(options: ChipsElementControlOptions) {
        super.init(frame: .zero)
        
        backgroundColor = JVDesign.colors.resolve(usage: .actionButtonCloud)
        layer.masksToBounds = true

        titleLabel?.font = JVDesign.fonts.resolve(.medium(14), scaling: .caption1)
        setTitleColor(JVDesign.colors.resolve(usage: .actionActiveButtonForeground), for: .normal)
        
        if options.contains(.deletable), #available(iOS 13.0, *) {
            semanticContentAttribute = .forceRightToLeft
            jv_imageEdgeInsets = UIEdgeInsets(top: 3, left: 4, bottom: 3, right: -3)
            jv_contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            setImage(UIImage(systemName: "xmark"), for: .normal)
            imageView?.contentMode = .scaleAspectFit
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var caption: String? {
        get {
            return title(for: .normal)
        }
        set {
            setTitle(newValue, for: .normal)
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return super.sizeThatFits(.zero).jv_extendedBy(insets: paddings)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.midY
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if !super.point(inside: point, with: event) {
            return false
        }
        else if let control = imageView {
            let touchPoint = control.convert(point, to: control)
            return control.frame.insetBy(dx: -5, dy: -5).contains(touchPoint)
        }
        else {
            return false
        }
    }
}
