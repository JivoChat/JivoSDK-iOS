//
//  ChipsControl.swift
//  JivoMobile
//

import Foundation
import UIKit

extension ChipsControl {
    struct Options: OptionSet {
        let rawValue: Int
        static let editable = Self.init(rawValue: 1 << 0)
    }

    enum Output {
        case delete(index: Int)
    }
}

final class ChipsControl: UIView {
    var outputHandler: (Output) -> Void = { _ in }
    
    private let options: Options
    
    private var elementsControls = [ChipsElementControl]()
    
    init(options: Options) {
        self.options = options
        
        super.init(frame: .zero)
        
        isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func populate(captions: [String]) {
        if captions.count < elementsControls.count {
            let uselessControls = elementsControls.suffix(elementsControls.count - captions.count)
            uselessControls.forEach { control in
                control.removeFromSuperview()
                elementsControls.jv_removeObject(control)
            }
        }
        else if captions.count > elementsControls.count {
            (0 ..< captions.count - elementsControls.count).forEach { index in
                let control: ChipsElementControl
                if options.contains(.editable) {
                    control = ChipsElementControl(options: .deletable)
                }
                else {
                    control = ChipsElementControl(options: .jv_empty)
                }
                
                control.addTarget(self, action: #selector(handleChipTap), for: .touchUpInside)
                addSubview(control)
                elementsControls.append(control)
            }
        }
        
        zip(elementsControls, captions).forEach { control, caption in
            control.caption = caption
        }
        
        setNeedsDisplay()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        let layout = getLayout(size: bounds.size)
        zip(elementsControls, layout.elementsControlsFrames).layout()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext()
        else {
            return
        }
        
        let layout = getLayout(size: bounds.size)
        context.clear(rect)

        if let arrow = UIImage(named: "ph_arrow") {
            for rect in layout.arrowsFrames {
                arrow.draw(in: rect)
            }
        }
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            elementsControls: elementsControls
        )
    }
    
    @objc private func handleChipTap(button: ChipsElementControl) {
        guard let index = elementsControls.firstIndex(of: button)
        else {
            return
        }
        
        outputHandler(.delete(index: index))
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let elementsControls: [ChipsElementControl]
    
    private let padding = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    private let arrowSize = CGSize(width: 8, height: 16)
    private let arrowGap = CGFloat(5)
    
    var elementsControlsFrames: [CGRect] {
        let arrowSpace = arrowSize.width + arrowGap * 2
        var rect = CGRect(x: padding.left - arrowSpace, y: padding.top, width: 0, height: 0)
        return elementsControls.map { control in
            let size = control.sizeThatFits(.zero)
            
            if rect.maxX + arrowSpace + size.width + arrowSpace <= bounds.maxX - padding.right {
                rect.origin.x = rect.maxX + arrowSpace
            }
            else {
                rect.origin.x = padding.left
                rect.origin.y = rect.maxY + padding.vertical * 0.5
            }
            
            rect.size = size
            return rect
        }
    }
    
    var arrowsFrames: [CGRect] {
        return elementsControlsFrames.dropLast().map { frame in
            let topY = frame.midY - arrowSize.height * 0.5
            let leftX = frame.maxX + arrowGap
            return CGRect(x: leftX, y: topY, width: arrowSize.width, height: arrowSize.height)
        }
    }
    
    var totalSize: CGSize {
        let height = (elementsControlsFrames.last?.maxY).jv_orZero + padding.bottom
        return CGSize(width: bounds.width, height: height)
    }
}
