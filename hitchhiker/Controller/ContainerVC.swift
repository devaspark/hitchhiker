//
//  ContainerVC.swift
//  hitchhiker
//
//  Created by Rex Kung on 3/17/18.
//  Copyright © 2018 Rex Kung. All rights reserved.
//

import UIKit
import QuartzCore

enum SlideOutState {
    case collapsed
    case leftMenuExtended
}

enum ShowWhichVC {
    case homeVC
}

var showVC: ShowWhichVC = .homeVC

class ContainerVC: UIViewController {

    var homeVC: HomeVC!
    var leftVC: LeftMenuBarVC!
    var tap: UITapGestureRecognizer!
    
    private var _centerController: UIViewController!
    private var _currentState: SlideOutState = .collapsed {
        didSet {
            let shouldShowShadow = (_currentState != .collapsed)
            
            shouldShowShadowForCenterViewController(status: shouldShowShadow)
        }
    }
    private var _isHidden = false
    
    let centerPanelExpandedOffset: CGFloat = 160
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initCenter(screen: showVC)
    }

    func initCenter(screen: ShowWhichVC) {
        var presentingController: UIViewController
        
        showVC = screen
        
        if homeVC == nil {
            homeVC = UIStoryboard.homeVC()
            homeVC.delegate = self
        }
        
        presentingController = homeVC
        
        if let con = _centerController {
            con.view.removeFromSuperview()
            con.removeFromParentViewController()
        }
        
        _centerController = presentingController
        
        view.addSubview(_centerController.view)
        addChildViewController(_centerController)
        _centerController.didMove(toParentViewController: self)
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    override var prefersStatusBarHidden: Bool {
        return _isHidden
    }

}

extension ContainerVC: CenterVCDelegate {
    func toggleLeftMenu() {
        let notAlreadyExpanded = (_currentState != .leftMenuExtended)
        
        if notAlreadyExpanded {
            addLeftMenuViewController()
        }
        
        animateLeftMenu(shouldExpand: notAlreadyExpanded)
    }
    
    func addLeftMenuViewController() {
        if leftVC == nil {
            leftVC = UIStoryboard.leftMenuController()
            addChildSideMenuViewController(leftVC!)
        }
    }
    
    @objc func animateLeftMenu(shouldExpand: Bool) {
        if shouldExpand {
            _isHidden = !_isHidden
            animateStatusBar()
            setupWhiteCoverView()
            _currentState = .leftMenuExtended
            animateCenterMenuXPosition(targetPosition: _centerController.view.frame.width - centerPanelExpandedOffset)
        } else {
            _isHidden = !_isHidden
            animateStatusBar()
            hideWhiteCoverView()
            animateCenterMenuXPosition(targetPosition: 0, completion: { (finished) in
                self._currentState = .collapsed
                self.leftVC = nil
            })
        }
    }
    
    func addChildSideMenuViewController(_ sideMenuController: LeftMenuBarVC) {
        view.insertSubview(sideMenuController.view, at: 0)
        addChildViewController(sideMenuController)
        sideMenuController.didMove(toParentViewController: self)
        
    }
    
    func animateStatusBar() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    func animateCenterMenuXPosition(targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self._centerController.view.frame.origin.x = targetPosition
        }, completion: completion)
    }
    
    func setupWhiteCoverView() {
        let whiteCoverView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        whiteCoverView.alpha = 0.0
        whiteCoverView.backgroundColor = UIColor.white
        whiteCoverView.tag = 25
        
        self._centerController.view.addSubview(whiteCoverView)
        whiteCoverView.fadeTo(alphaValue: 0.75, withDuration: 0.2)
        
        tap = UITapGestureRecognizer(target: self, action: #selector(animateLeftMenu(shouldExpand:)))
        tap.numberOfTapsRequired = 1
        
        self._centerController.view.addGestureRecognizer(tap)
    }
    
    func hideWhiteCoverView() {
        self._centerController.view.removeGestureRecognizer(tap)
        for subview in self._centerController.view.subviews {
            if subview.tag == 25 {
                UIView.animate(withDuration: 0.2, animations: {
                    subview.alpha = 0.0
                }, completion: { (finished) in
                    subview.removeFromSuperview()
                })
            }
        }
    }
    
    func shouldShowShadowForCenterViewController(status: Bool) {
        if status == true {
            _centerController.view.layer.shadowOpacity = 0.6
        } else {
            _centerController.view.layer.shadowOpacity = 0.0
        }
    }
    
}

private extension UIStoryboard {
    class func mainStoryBoard() -> UIStoryboard {
        return UIStoryboard(name: "Main", bundle: Bundle.main)
    }
    
    class func leftMenuController() -> LeftMenuBarVC? {
        return mainStoryBoard().instantiateViewController(withIdentifier: "LeftMenuBarVC") as? LeftMenuBarVC
    }
    
    class func homeVC() -> HomeVC? {
        return mainStoryBoard().instantiateViewController(withIdentifier: "HomeVC") as? HomeVC
    }
}
