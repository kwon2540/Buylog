//
//  EditBoughtGoodsViewController.swift
//  Project_2Q_2019
//
//  Created by Maharjan Binish on 2020/11/29.
//  Copyright © 2020 JUNHYEOK KWON. All rights reserved.
//

import UIKit
import RxSwift

final class EditBoughtGoodsViewController: UIViewController, StoryboardInstantiable {

    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var removeButton: UIButton!
    @IBOutlet private weak var completeButton: UIButton!
    @IBOutlet private weak var revertButton: UIButton!
    @IBOutlet private weak var lifeButton: UIButton!
    @IBOutlet private weak var fashionButton: UIButton!
    @IBOutlet private weak var hobbiesButton: UIButton!
    @IBOutlet private weak var miscellaneousButton: UIButton!
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var nameSaperator: UIView!
    @IBOutlet private weak var amountTextField: UITextField!
    @IBOutlet private weak var amountSaperator: UIView!
    @IBOutlet private weak var priceTextField: UITextField!
    @IBOutlet private weak var priceSaperator: UIView!
    @IBOutlet private weak var keyboardSpaceConstraint: NSLayoutConstraint!

    private let disposeBag = DisposeBag()

    private lazy var categoryButtons: [UIButton] = [lifeButton, fashionButton, hobbiesButton, miscellaneousButton]

    var viewModel: EditBoughtGoodsViewModel!
    var dismissed: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()

        bindViewModel()
    }

    deinit {
        if viewModel.dataDidChanged {
            viewModel.dataDidChangedSubject.onNext(())
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardObservers()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObservers()
    }

    @IBAction private func dismiss(_ sender: Any) {
        dismiss(animated: true)
        dismissed?()
    }

    @IBAction private func remove(_ sender: Any) {
        viewModel.deleteBoughtGoods()
        viewModel.dataDidChanged = true
    }

    @IBAction private func revert(_ sender: Any) {
        viewModel.revertBoughtGoods()
        viewModel.dataDidChanged = true
    }

    @IBAction private func categoryButtons(_ sender: UIButton) {
        guard !sender.isSelected else { return }

        categoryButtons[sender.tag].isSelected = true
        categoryButtons.enumerated().forEach { index, button in
            if index != sender.tag {
                button.isSelected = false
            }
        }
    }

    @IBAction private func complete(_ sender: Any) {
        guard let tag = categoryButtons.filter({ $0.isSelected }).first?.tag else { return }
        viewModel.udpateBoughtGoods(selectedButtonTag: tag)
        viewModel.dataDidChanged = true
    }

    private func setup() {
        setupLayouts()
        setupCategoryButton()
    }

    private func setupLayouts() {
        mainView.layer.cornerRadius = 20
        mainView.clipsToBounds = true

        completeButton.isEnabled = false

        priceTextField.becomeFirstResponder()

        nameTextField.text = viewModel.boughtGoods.name
        amountTextField.text = String(viewModel.boughtGoods.amount)
        priceTextField.text = String(viewModel.boughtGoods.price)
    }

    private func setupCategoryButton() {
        if let tag = viewModel.getSeletedCategoryButtonTag() {
            categoryButtons[tag].isSelected = true
        }
    }

    private func bindViewModel() {

        // Input
        nameTextField.rx.text.orEmpty
            .bind(to: viewModel.nameText)
            .disposed(by: disposeBag)

        amountTextField.rx.text.orEmpty
            .bind(to: viewModel.amountText)
            .disposed(by: disposeBag)

        priceTextField.rx.text.orEmpty
            .bind(to: viewModel.priceText)
            .disposed(by: disposeBag)

        // Output
        viewModel.isCompleteButtonEnabled
            .bind(to: completeButton.rx.isEnabled)
            .disposed(by: disposeBag)

        viewModel.nameSeparatorColor
            .bind(to: nameSaperator.rx.backgroundColor)
            .disposed(by: disposeBag)

        viewModel.amountSeparatorColor
            .bind(to: amountSaperator.rx.backgroundColor)
            .disposed(by: disposeBag)

        viewModel.priceSeparatorColor
            .bind(to: priceSaperator.rx.backgroundColor)
            .disposed(by: disposeBag)

        // API
        viewModel.apiState.emit(onNext: { [weak self] (state) in
            guard let this = self, let view = this.view else { return }

            switch state {
            // Show indicator when loading
            case .loading:
                ActivityIndicator.shared.start(view: view)
            // Stop indicator and dismiss when success
            case .success:
                ActivityIndicator.shared.stop(view: view)
                this.dismiss(animated: true)
                this.dismissed?()
            // Error handling when failed
            case .failed(let error):
                DropDownManager.shared.showDropDownNotification(view: view,
                                                                width: nil,
                                                                height: nil,
                                                                type: .error,
                                                                message: error.description)
                apiErrorLog(logMessage: error.description)
                ActivityIndicator.shared.stop(view: view)
                this.dismiss(animated: true)
                this.dismissed?()
            }
        }).disposed(by: disposeBag)
    }
}

// MARK: Keyboard Notifications
extension EditBoughtGoodsViewController {

    private func addKeyboardObservers() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                                       selector: #selector(handleContentUnderKeyboard(notification:)),
                                       name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(handleContentUnderKeyboard(notification:)),
                                       name: UIResponder.keyboardWillChangeFrameNotification,
                                       object: nil)
    }

    private func removeKeyboardObservers() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
    }

    @objc private func handleContentUnderKeyboard(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let keyboardEndFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        switch notification.name {
        case UIResponder.keyboardWillHideNotification:
            moveContentForDismissKeyboard()
        default:
            let convertedKeyboardEndFrame = view.convert(keyboardEndFrame.cgRectValue, to: view.window)
            moveContent(forKeyboardFrame: convertedKeyboardEndFrame)
        }
    }

    private func moveContentForDismissKeyboard() {
        keyboardSpaceConstraint.constant = 0
    }

    private func moveContent(forKeyboardFrame keyboardFrame: CGRect) {
        keyboardSpaceConstraint.constant = keyboardFrame.height
    }
}
