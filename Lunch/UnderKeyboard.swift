// ----------------------------
//
// UnderKeyboardLayoutConstraint.swift
//
// ----------------------------

import UIKit


/**
 Adjusts the length (constant value) of the bottom layout constraint when keyboard shows and hides.
 */
@objc public class UnderKeyboardLayoutConstraint: NSObject {
    private weak var bottomLayoutConstraint: NSLayoutConstraint?
    private weak var bottomLayoutGuide: UILayoutSupport?
    private var keyboardObserver = UnderKeyboardObserver()
    private var initialConstraintConstant: CGFloat = 0
    private var minMargin: CGFloat = 10
    
    private var viewToAnimate: UIView?
    
    public override init() {
        super.init()
        
        keyboardObserver.willAnimateKeyboard = keyboardWillAnimate
        keyboardObserver.animateKeyboard = animateKeyboard
        keyboardObserver.start()
    }
    
    deinit {
        stop()
    }
    
    /// Stop listening for keyboard notifications.
    public func stop() {
        keyboardObserver.stop()
    }
    
    /**
     
     Supply a bottom Auto Layout constraint. Its constant value will be adjusted by the height of the keyboard when it appears and hides.
     
     - parameter bottomLayoutConstraint: Supply a bottom layout constraint. Its constant value will be adjusted when keyboard is shown and hidden.
     
     - parameter view: Supply a view that will be used to animate the constraint. It is usually the superview containing the view with the constraint.
     
     - parameter minMargin: Specify the minimum margin between the keyboard and the bottom of the view the constraint is attached to. Default: 10.
     
     - parameter bottomLayoutGuide: Supply an optional bottom layout guide (like a tab bar) that will be taken into account during height calculations.
     
     */
    public func setup(bottomLayoutConstraint: NSLayoutConstraint,
                      view: UIView, minMargin: CGFloat = 10,
                      bottomLayoutGuide: UILayoutSupport? = nil) {
        
        initialConstraintConstant = bottomLayoutConstraint.constant
        self.bottomLayoutConstraint = bottomLayoutConstraint
        self.minMargin = minMargin
        self.bottomLayoutGuide = bottomLayoutGuide
        self.viewToAnimate = view
        
        // Keyboard is already open when setup is called
        if let currentKeyboardHeight = keyboardObserver.currentKeyboardHeight
            , currentKeyboardHeight > 0 {
            
            keyboardWillAnimate(height: currentKeyboardHeight)
        }
    }
    
    func keyboardWillAnimate(height: CGFloat) {
        guard let bottomLayoutConstraint = bottomLayoutConstraint else { return }
        
        let layoutGuideHeight = bottomLayoutGuide?.length ?? 0
        let correctedHeight = height - layoutGuideHeight
        
        if height > 0 {
            let newConstantValue = correctedHeight + minMargin
            
            if newConstantValue > initialConstraintConstant {
                // Keyboard height is bigger than the initial constraint length.
                // Increase constraint length.
                bottomLayoutConstraint.constant = newConstantValue
            } else {
                // Keyboard height is NOT bigger than the initial constraint length.
                // Show the initial constraint length.
                bottomLayoutConstraint.constant = initialConstraintConstant
            }
            
        } else {
            bottomLayoutConstraint.constant = initialConstraintConstant
        }
    }
    
    func animateKeyboard(height: CGFloat) {
        viewToAnimate?.layoutIfNeeded()
    }
}


// ----------------------------
//
// UnderKeyboardObserver.swift
//
// ----------------------------

import UIKit

/**
 Detects appearance of software keyboard and calls the supplied closures that can be used for changing the layout and moving view from under the keyboard.
 */
public final class UnderKeyboardObserver: NSObject {
    public typealias AnimationCallback = (_ height: CGFloat) -> ()
    
    let notificationCenter: NotificationCenter
    
    /// Function that will be called before the keyboard is shown and before animation is started.
    public var willAnimateKeyboard: AnimationCallback?
    
    /// Function that will be called inside the animation block. This can be used to call `layoutIfNeeded` on the view.
    public var animateKeyboard: AnimationCallback?
    
    /// Current height of the keyboard. Has value `nil` if unknown.
    public var currentKeyboardHeight: CGFloat?
    
    public override init() {
        notificationCenter = NotificationCenter.default
        super.init()
    }
    
    deinit {
        stop()
    }
    
    /// Start listening for keyboard notifications.
    public func start() {
        stop()
        
        notificationCenter.addObserver(self, selector: #selector(UnderKeyboardObserver.keyboardNotification(notification:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
        notificationCenter.addObserver(self, selector: #selector(UnderKeyboardObserver.keyboardNotification(notification:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
    }
    
    /// Stop listening for keyboard notifications.
    public func stop() {
        notificationCenter.removeObserver(self)
    }
    
    // MARK: - Notification
    
    func keyboardNotification(notification: NSNotification) {
        let isShowing = notification.name == NSNotification.Name.UIKeyboardWillShow
        
        if let userInfo = notification.userInfo,
            let height = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
            let duration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber {
            
            let correctedHeight = isShowing ? height : 0
            willAnimateKeyboard?(correctedHeight)
            
            UIView.animate(withDuration: duration,
                                       delay: TimeInterval(0),
                                       options: UIViewAnimationOptions(rawValue: animationCurveRawNSN.uintValue),
                                       animations: { [weak self] in
                                        self?.animateKeyboard?(correctedHeight)
                },
                                       completion: nil
            )
            
            currentKeyboardHeight = correctedHeight
        }
    }
}