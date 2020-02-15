//
//  AddGoodsViewController.swift
//  Project_2Q_2019
//
//  Created by JUNHYEOK KWON on 2020/01/25.
//  Copyright © 2020 JUNHYEOK KWON. All rights reserved.
//

import UIKit
import RxSwift

final class AddGoodsViewController: UIViewController, StoryboardInstantiable {

    enum TextFieldTag: Int {
        case nameTextField
        case priceTextField
        case countTextField
    }

    @IBOutlet private weak var scrollViewBottomContraints: NSLayoutConstraint!
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var priceTextField: UITextField!
    @IBOutlet private weak var amountTextField: UITextField!
    @IBOutlet private weak var addButton: RoundButton!

    private let disposeBag = DisposeBag()

    var viewModel: AddGoodsViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        nameTextField.delegate = self
        priceTextField.delegate = self
        amountTextField.delegate = self

        nameTextField.becomeFirstResponder()

        bindViewModel()
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
    }
    @IBAction private func addGoods(_ sender: Any) {
        viewModel.addGoodsToFirebase(dateList: viewModel.makeGoodsData())
    }

    private func bindViewModel() {

        // Input
        nameTextField.rx.text.orEmpty
            .bind(to: viewModel.nameText)
            .disposed(by: disposeBag)

        priceTextField.rx.text.orEmpty
            .bind(to: viewModel.priceText)
            .disposed(by: disposeBag)

        amountTextField.rx.text.orEmpty
            .bind(to: viewModel.amountText)
            .disposed(by: disposeBag)

        // Output
        viewModel.isAddButtonValid
            .bind(to: addButton.rx.isEnabled)
            .disposed(by: disposeBag)

        viewModel.apiState.emit(onNext: { [weak self] (state) in
            guard let this = self, let view = this.view else { return }

            switch state {
            // 로딩 시 인디케이터 표시
            case .loading:
                ActivityIndicator.shared.start(view: view)
            // 성공시 인디케이터 중지 및 디스미스
            case .success:
                ActivityIndicator.shared.stop(view: view)
                this.dismiss(animated: true)
            // 실패시 드롭다운 표시 및 에러 핸들링 인디케이터 중지
            case .failed(let error):
                DropDownManager.shared.showDropDownNotification(view: view,
                                                                width: nil,
                                                                height: nil,
                                                                type: .error,
                                                                message: error.description)
                apiErrorLog(logMessage: error.description)
                ActivityIndicator.shared.stop(view: view)
            }
        }).disposed(by: disposeBag)
    }
}

extension AddGoodsViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch TextFieldTag.init(rawValue: textField.tag) {
        case .nameTextField:
            priceTextField.becomeFirstResponder()
        default:
            break
        }
        return true
    }
}

// MARK: Keyboard Notifications
extension AddGoodsViewController {

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
        scrollViewBottomContraints.constant = 0
    }

    private func moveContent(forKeyboardFrame keyboardFrame: CGRect) {
        scrollViewBottomContraints.constant = keyboardFrame.height
    }
}
