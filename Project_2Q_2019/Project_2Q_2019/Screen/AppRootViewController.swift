//
//  AppRootViewController.swift
//  Project_2Q_2019
//
//  Created by JUNHYEOK KWON on 2019/08/25.
//  Copyright © 2019 JUNHYEOK KWON. All rights reserved.
//

import UIKit

final class AppRootViewController: UIViewController {

    private var current: UIViewController

    init() {
        current = SplashViewController.getStoryBoard()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(current)
        current.view.frame = view.bounds
        view.addSubview(current.view)
        current.didMove(toParent: self)
    }

    private func changeChild(currentViewController: UIViewController, newViewController: UIViewController, trasitionOption: UIView.AnimationOptions = .transitionCrossDissolve) {
        currentViewController.willMove(toParent: nil)

        addChild(newViewController)
        view.addSubview(newViewController.view)

        transition(from: current, to: newViewController, duration: 0.5, options: trasitionOption, animations: {
            newViewController.view.alpha = 1
            currentViewController.view.alpha = 0
        }, completion: { _ in
            currentViewController.view.removeFromSuperview()
            currentViewController.removeFromParent()
            newViewController.didMove(toParent: self)
            self.current = newViewController
        })
    }
}

// MARK: Transitions
extension AppRootViewController {

    func showLoginScreen() {
        let vc = LoginViewController.getStoryBoard()
        changeChild(currentViewController: current, newViewController: vc)
    }

    func showHomeScreen() {
        let vc = HomeViewController.getStoryBoard()
        vc.viewModel = HomeViewModel()
        changeChild(currentViewController: current, newViewController: vc)
    }
}
