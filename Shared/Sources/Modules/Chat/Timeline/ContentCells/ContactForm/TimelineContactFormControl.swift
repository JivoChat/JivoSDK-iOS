//
//  TimelineContactFormControl.swift
//  App
//
//  Created by Stan Potemkin on 21.11.2022.
//  Copyright © 2022 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import JivoFoundation

fileprivate let TimelineContactFormControlFieldBase = 0xEDA_211122

extension TimelineContactFormControl {
    enum Output {
        case toggleSizing(tag: Int)
        case submit(values: Values)
    }
    
    typealias Sizing = (
        JVMessageBodyContactFormStatus
    )
    
    struct Values {
        let name: String?
        let phone: String?
        let email: String?
    }
}

final class TimelineContactFormControl: UIView, UITextFieldDelegate {
    var outputHandler: ((Output) -> Void)?
    
    private let buttonControl = BigButton(type: .primary, sizing: .medium)

    private var fieldControls = [UITextField]()
    private var idToFieldControlMap = [String: UITextField]()
    
    init() {
        super.init(frame: .zero)
        
        isOpaque = false
        
        buttonControl.caption = loc["common.send"]
        buttonControl.shortTapHandler = { [weak self] in self?.handleButtonTap() }
        addSubview(buttonControl)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var fields = [TimelineContactFormField]() {
        didSet {
            let fieldsMap = Dictionary(uniqueKeysWithValues: zip(fields.map(\.id), fields))
            let oldIds = Set(idToFieldControlMap.keys)
            let newIds = fields.map(\.id)
            
            for id in oldIds.subtracting(newIds) {
                guard let control = idToFieldControlMap[id]
                else {
                    continue
                }
                
                control.removeFromSuperview()
                
                fieldControls.jv_removeObject(control)
                idToFieldControlMap.removeValue(forKey: id)
            }
            
            for (index, id) in newIds.enumerated() {
                guard let field = fieldsMap[id]
                else {
                    continue
                }
                
                if let control = idToFieldControlMap[id] {
                    configureField(index: index, control: control, field: field)
                }
                else {
                    let control = TimelineContactFormFieldControl()
                    configureField(index: index, control: control, field: field)
                    addSubview(control)
                    
                    fieldControls.append(control)
                    idToFieldControlMap[id] = control
                }
            }
            
            fillControlsUsingCache()
            adjustForm(controls: .all)
        }
    }
    
    var keyboardAnchorControl: KeyboardAnchorControl? {
        didSet {
            for control in fieldControls {
                control.inputAccessoryView = keyboardAnchorControl
            }
        }
    }
    
    var cache: ChatTimelineContactFormCache? {
        didSet {
            fillControlsUsingCache()
            adjustForm(controls: .all)
        }
    }
    
    var accentColor: UIColor? = JVDesign.colors.resolve(usage: .accentGreen) {
        didSet {
            accentColor = accentColor ?? JVDesign.colors.resolve(usage: .accentGreen)
            buttonControl.accentColor = accentColor
            setNeedsDisplay()
        }
    }
    
    var sizing = Sizing.inactive {
        didSet {
            adjustForm(controls: .all)
        }
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layout = getLayout(size: size)
        return layout.totalSize
    }
    
    override func layoutSubviews() {
        let layout = getLayout(size: bounds.size)
        zip(fieldControls, layout.fieldControlsFrames).layout()
        zip(fieldControls, layout.fieldControlsAlphas).display()
        buttonControl.frame = layout.buttonControlFrame
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext()
        else {
            return
        }
        
        let layout = getLayout(size: rect.size)
        
        let formRect = layout.decorationFrame.inset(by: layout.shadowOffsets)
        let formPath = UIBezierPath(roundedRect: formRect, cornerRadius: 10).cgPath
        
        context.addPath(formPath)
        context.setLineWidth(0.5)
        context.setStrokeColor(JVDesign.colors.resolve(usage: .lightDimmingShadow).cgColor)
        context.strokePath()
        
        context.addPath(formPath)
        context.setFillColor(JVDesign.colors.resolve(usage: .primaryBackground).cgColor)
        context.setShadow(offset: CGSize(width: 0, height: -2), blur: 0, color: accentColor?.cgColor)
        context.fillPath()
        
        context.addPath(formPath)
        context.setFillColor(JVDesign.colors.resolve(usage: .primaryBackground).cgColor)
        context.setShadow(offset: CGSize(width: 0, height: 3), blur: 3.0, color: JVDesign.colors.resolve(usage: .lightDimmingShadow).cgColor)
        context.fillPath()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsDisplay()
    }
    
    private func getLayout(size: CGSize) -> Layout {
        return Layout(
            bounds: CGRect(origin: .zero, size: size),
            sizing: sizing,
            fieldControls: fieldControls,
            buttonControl: buttonControl
        )
    }
    
    private func configureField(index: Int, control: UITextField, field: TimelineContactFormField) {
        control.placeholder = field.placeholder
        control.text = field.value
        control.keyboardType = field.keyboardType
        control.tag = TimelineContactFormControlFieldBase + index
        control.delegate = self
        
        switch field.interactivity {
        case .enabled:
            control.isEnabled = true
        case .disabled:
            control.isEnabled = false
        }
        
        performAdjustment(control: control, input: field.value)
    }
    
    private func performAdjustment(control: UITextField, input: String?) {
        if performValidation(control: control, input: input) {
            control.rightViewMode = .always
        }
        else {
            control.rightViewMode = .never
        }
    }
    
    private func performValidation(control: UITextField, input: String?) -> Bool {
        guard let validator = s_validators[control.keyboardType]
        else {
            return false
        }
        
        if validator.isValid(input: input ?? String()) {
            return true
        }
        else {
            return false
        }
    }
    
    private func fillControlsUsingCache() {
        for field in fields {
            guard let control = idToFieldControlMap[field.id]
            else {
                continue
            }
            
            if let value = cache?.read(id: field.id) {
                control.text = value
            }
            else {
                control.text = field.value
            }
        }
    }
    
    private enum _FormControls {
        case all
        case single(control: UITextField, input: String)
    }
    
    private func adjustForm(controls: _FormControls) {
        var validation = [String: Bool]()
        for (id, control) in idToFieldControlMap {
            validation[id] = performValidation(control: control, input: control.text)
        }
        
        switch controls {
        case .all:
            break
        case .single(let control, let input):
            guard let id = idToFieldControlMap.first(where: {$0.value === control})?.key
            else {
                return
            }
            
            let status = performValidation(control: control, input: input)
            performAdjustment(control: control, input: input)
            validation[id] = status
        }
        
        switch sizing {
        case .inactive:
            buttonControl.caption = loc["common.send"]
            buttonControl.isEnabled = false
        case .editable:
            buttonControl.caption = loc["common.send"]
            buttonControl.isEnabled = validation.values.reduce(true, { buff, item in buff && item })
        case .syncing:
            buttonControl.caption = loc["common.send"]
            buttonControl.isEnabled = false
        case .snapshot:
            buttonControl.caption = loc["contact_form.status.sent"]
            buttonControl.isEnabled = false
        }
    }
    
    @objc private func handleButtonTap() {
        let nameControl = idToFieldControlMap["name"]
        let phoneControl = idToFieldControlMap["phone"]
        let emailControl = idToFieldControlMap["email"]

        let values = Values(
            name: nameControl?.text?.jv_valuable,
            phone: phoneControl?.text?.jv_valuable,
            email: emailControl?.text?.jv_valuable
        )
        
        outputHandler?(.submit(values: values))
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        switch sizing {
        case .inactive:
            outputHandler?(.toggleSizing(tag: textField.tag))
            return false
        case .editable:
            return true
        case .syncing:
            return false
        case .snapshot:
            return false
        }
    }
    
    internal func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let item = idToFieldControlMap.first(where: { $1 === textField }) {
            let oldValue = textField.text ?? String()
            let newValue = (oldValue as NSString).replacingCharacters(in: range, with: string)
            cache?.save(id: item.key, value: newValue)
            adjustForm(controls: .single(control: textField, input: newValue))
        }
        
        return true
    }
}

fileprivate struct Layout {
    let bounds: CGRect
    let sizing: TimelineContactFormControl.Sizing
    let fieldControls: [UITextField]
    let buttonControl: UIButton
    
    private let minSideMargin = CGFloat(20)
    private let maxTotalWidth = CGFloat(320)
    private let controlsGap = CGFloat(16)
    
    var shadowOffsets: UIEdgeInsets {
        return UIEdgeInsets(top: 2, left: 0, bottom: 6, right: 0)
    }
    
    var innerMargins: UIEdgeInsets {
        return UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
    }
    
    var decorationFrame: CGRect {
        var rect = formAnchorFrame
        rect.size.height = buttonControlFrame.maxY + innerMargins.bottom + shadowOffsets.bottom
        return rect
    }
    
    var fieldControlsFrames: [CGRect] {
        var rect = formAnchorFrame
            .inset(by: UIEdgeInsets(top: 0, left: 25, bottom: 0, right: 15))
            .offsetBy(dx: 0, dy: shadowOffsets.top + innerMargins.top)
        
        return fieldControls.map { control in
            defer {
                rect.origin.y += rect.height + controlsGap
            }
            
            let size = control.jv_size(forWidth: rect.width)
            rect.size.height = 11 + size.height + 11
            return rect
        }
    }
    
    var fieldControlsAlphas: [CGFloat] {
        switch sizing {
        case .inactive:
            return [CGFloat(1.0)] + Array(repeating: 0, count: fieldControls.count - 1)
        case .editable, .syncing, .snapshot:
            return Array(repeating: 1.0, count: fieldControls.count)
        }
    }
    
    var buttonControlFrame: CGRect {
        let fieldBottomY: CGFloat = {
            switch sizing {
            case .inactive:
                return (fieldControlsFrames.first?.maxY).jv_orZero
            case .editable, .syncing, .snapshot:
                return (fieldControlsFrames.last?.maxY).jv_orZero
            }
        }()
        
        let topY = fieldBottomY + controlsGap
        let anchor = formAnchorFrame.insetBy(dx: 15, dy: 0)
        let size = buttonControl.jv_size(forWidth: anchor.width)
        return CGRect(x: anchor.minX, y: topY, width: anchor.width, height: size.height)
    }
    
    var totalSize: CGSize {
        let height = decorationFrame.maxY
        return CGSize(width: bounds.width, height: height)
    }
    
    private var formAnchorFrame: CGRect {
        let relativeBounds = bounds.insetBy(dx: minSideMargin, dy: 0)
        let width = min(maxTotalWidth, relativeBounds.width)
        let leftX = (bounds.width - width) * 0.5
        return CGRect(x: leftX, y: 0, width: width, height: 0)
    }
}

fileprivate let s_validators: [UIKeyboardType: TimelineContactFormValidator] = [
    UIKeyboardType.default:
        TimelineContactFormDefaultValidator(),
    UIKeyboardType.phonePad:
        TimelineContactFormPhoneValidator(),
    UIKeyboardType.emailAddress:
        TimelineContactFormEmailValidator()
]
