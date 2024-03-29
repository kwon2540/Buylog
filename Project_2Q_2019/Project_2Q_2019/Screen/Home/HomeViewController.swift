//
//  HomeViewController.swift
//  Project_2Q_2019
//
//  Created by JUNHYEOK KWON on 2019/08/25.
//  Copyright © 2019 JUNHYEOK KWON. All rights reserved.
//

import UIKit
import RxSwift

final class HomeViewController: UIViewController, StoryboardInstantiable {

    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var coverView: UIView!
    @IBOutlet private weak var sideMenuView: UIView!
    @IBOutlet private weak var sideMenuViewTrailingConstraints: NSLayoutConstraint!
    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var logoutMenuView: UIView!

    private let disposeBag = DisposeBag()

    var viewModel: HomeViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        bindViewModel()
        setupGestures()

        viewModel.observeGoodsData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        setupCollectionView()
    }

    @IBAction private func menu(_ sender: Any) {
        usernameLabel.text = UserDefaults.standard.object(forKey: "USER_NAME") as? String
        let sideMenuWidth = sideMenuView.frame.width
        coverView.isHidden = false
        coverView.alpha = 0
        sideMenuViewTrailingConstraints.constant = sideMenuWidth

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
            self?.view.layoutIfNeeded()
            self?.coverView.alpha = 1
        })
    }

    @IBAction private func graph(_ sender: Any) {
        let vc = GraphViewController.getStoryBoard()
        vc.viewModel = GraphViewModel()
        present(vc, animated: true)
    }

    @IBAction private func history(_ sender: Any) {
        let historyViewModel = HistoryViewModel()
        let historyViewController = HistoryViewController.getStoryBoard()
        historyViewController.viewModel = historyViewModel
        present(historyViewController, animated: true)
    }

    @IBAction private func add(_ sender: Any) {
        let vc = AddGoodsViewController.getStoryBoard()
        vc.dismissed = { [weak self] in
            guard let this = self else { return }

            this.coverView.isHidden = true
        }
        vc.viewModel = AddGoodsViewModel()

        coverView.isHidden = false
        present(vc, animated: true)
    }

    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.registerXib(of: HomeCollectionViewCell.self)

        let cellWidth = collectionView.frame.width - 80
        let cellHeight = collectionView.frame.height

        // 상하, 좌우 inset value 설정
        let insetX = (collectionView.bounds.width - cellWidth) / 2.0
        let insetY = (collectionView.bounds.height - cellHeight) / 2.0

        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        layout.minimumLineSpacing = 20
        collectionView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)

        // 스크롤이 빠르게 감속되도록 설정
        collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
    }

    private func setupGestures() {
        let coverViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(coverViewTapped))
        coverView.addGestureRecognizer(coverViewTapGesture)

        let logoutMenuTapGesture = UITapGestureRecognizer(target: self, action: #selector(logoutMenuTapped))
        logoutMenuView.addGestureRecognizer(logoutMenuTapGesture)
    }

    private func edit(goods: Goods) {
        let vc = EditGoodsViewController.getStoryBoard()
        vc.dismissed = { [weak self] in
            guard let this = self else { return }

            this.coverView.isHidden = true

        }
        vc.viewModel = EditGoodsViewModel(goods: goods, dateCount: viewModel.getDateCount())

        coverView.isHidden = false

        DispatchQueue.main.async { [weak self] in
            guard let this = self else { return }

            this.present(vc, animated: true)
        }
    }

    private func bindViewModel() {

        // API
        viewModel.apiState.emit(onNext: { [weak self] (state) in
            guard let this = self, let view = this.view else { return }

            switch state {
            // Show indicator when loading
            case .loading:
                ActivityIndicator.shared.start(view: view)
            // Stop indicator and reload collectionview when success
            case .success:
                this.collectionView.reloadData()
                ActivityIndicator.shared.stop(view: view)
            // Error handling when failed
            case .failed(let error):
                DropDownManager.shared.showDropDownNotification(view: view,
                                                                width: nil,
                                                                height: nil,
                                                                type: .error,
                                                                message: error.description)
                apiErrorLog(logMessage: error.description)
                ActivityIndicator.shared.start(view: view)
            }
        }).disposed(by: disposeBag)
    }

    @objc private func coverViewTapped() {
        if sideMenuViewTrailingConstraints.constant != 0 {

            sideMenuViewTrailingConstraints.constant = 0

            let animations = { [weak self] in
                guard let this = self else { return }

                this.view.layoutIfNeeded()
                this.coverView.alpha = 0
            }

            let completion: (Bool) -> Void = { [weak self] _ in
                guard let this = self else { return }

                this.coverView.isHidden = true
                this.coverView.alpha = 1
            }

            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: animations, completion: completion)
        }
    }

    @objc private func logoutMenuTapped() {
        let confirmationAlert = UIAlertController(title: "ログアウトしますか？", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            FirebaseManager.shared.signOut()
            AppDelegate.shared.rootViewController.showLoginScreen()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        confirmationAlert.addAction(okAction)
        confirmationAlert.addAction(cancelAction)

        present(confirmationAlert, animated: true)
    }
}

extension HomeViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueCell(of: HomeCollectionViewCell.self, for: indexPath)
        cell.bind(viewmodel: HomeCollectionViewModel(goods: viewModel.goods))
        cell.didSelectGoods = { [weak self] goods in
            guard let this = self else { return }

            this.edit(goods: goods)
        }

        switch viewModel.reloadState {
        case .success:
            cell.reload()
        default:
            break
        }

        return cell
    }
}

extension HomeViewController: UICollectionViewDelegateFlowLayout {

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {

        // item의 사이즈와 item 간의 간격 사이즈를 구해서 하나의 item 크기로 설정.
        guard let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let cellWidthIncludingSpacing = layout.itemSize.width + layout.minimumLineSpacing

        // targetContentOff을 이용하여 x좌표가 얼마나 이동했는지 확인
        // 이동한 x좌표 값과 item의 크기를 비교하여 몇 페이징이 될 것인지 값 설정
        var offset = targetContentOffset.pointee
        let index = (offset.x + scrollView.contentInset.left) / cellWidthIncludingSpacing
        var roundedIndex = round(index)

        // scrollView, targetContentOffset의 좌표 값으로 스크롤 방향을 알 수 있다.
        // index를 반올림하여 사용하면 item의 절반 사이즈만큼 스크롤을 해야 페이징이 된다.
        // 스크로로 방향을 체크하여 올림,내림을 사용하면 좀 더 자연스러운 페이징 효과를 낼 수 있다.
        if scrollView.contentOffset.x > targetContentOffset.pointee.x {
            roundedIndex = floor(index)
        } else {
            roundedIndex = ceil(index)
        }

        // 위 코드를 통해 페이징 될 좌표값을 targetContentOffset에 대입하면 된다.
        offset = CGPoint(x: roundedIndex * cellWidthIncludingSpacing - scrollView.contentInset.left, y: -scrollView.contentInset.top)
        targetContentOffset.pointee = offset
    }
}
