//
//  FirebaseManager.swift
//  Project_2Q_2019
//
//  Created by JUNHYEOK KWON on 2019/11/04.
//  Copyright © 2019 JUNHYEOK KWON. All rights reserved.
//

import FirebaseAuth
import FirebaseFirestore
import CodableFirebase
import RxCocoa

// MARK: APIManager
protocol APIManager {
    func checkLogin() -> Bool
    func createUserAccount(email: String, password: String, name: String, completion: @escaping (APIState) -> Void)
    func signIn(email: String, password: String, completion: @escaping (APIState) -> Void)
    func signOut()
    func addGoods(goods: Goods, completion: @escaping (APIState) -> Void)
    func loadGoods(completion: @escaping ([Goods]?, APIState) -> Void)
    func addBoughtGoods(boughtGoods: BoughtGoods, completion: @escaping (APIState) -> Void)
    func deleteGoods(id: String, completion: @escaping (APIState) -> Void)
    func loadDateCounts(completion: @escaping ([DateCount]?) -> Void)
    func updateDateCount(dateCount: DateCount, completion: @escaping (APIState) -> Void)
}

// MARK: APIStateProtocol
protocol APIStateProtocol {
    var apiStateRelay: PublishRelay<APIState> { get }
}

extension APIStateProtocol {
    var apiState: Signal<APIState> { apiStateRelay.asSignal() }
}

enum APIState {
    case loading
    case success
    case failed(error: FirebaseManager.Error)
}

struct FirebaseManager: APIManager {

    enum Collections: String {
        case users
        case goodslist
        case goods
        case boughtgoods
        case datecount

        var key: String {
            return self.rawValue
        }
    }

    enum Error {
        case firebaseError(debugDescription: String)
        case authError
        case encodeError
        
        var description: String {
            switch self {
            case .firebaseError(let debugDescription):
                return debugDescription
            case .authError:
                return "Auth Error"
            case .encodeError:
                return "Encode Error"
            }
        }
    }

    static var shared = FirebaseManager()
    
    private let firestore = Firestore.firestore()

    private init() {}

    func checkLogin() -> Bool {
        return Auth.auth().currentUser?.uid != nil
    }

    func createUserAccount(email: String, password: String, name: String, completion: @escaping (APIState) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { (_, error) in
            if error != nil {
                // Failed create
                return completion(.failed(error: .firebaseError(debugDescription: error.debugDescription)))
            }
            
            guard let uid = Auth.auth().currentUser?.uid else {
                // Failed get UID
                return completion(.failed(error: .authError))
            }

            let user = User(email: email, name: name, uid: uid, startDate: Date())

            guard let data = try? FirestoreEncoder().encode(user) else {
                // Failed encode
                return completion(.failed(error: .encodeError))
            }
            
            self.firestore.collection(Collections.users.key)
                .document(uid)
                .setData(data) { (error) in
                    if error != nil {
                        // Failed add collection data
                        return completion(.failed(error: .firebaseError(debugDescription: error.debugDescription)))
                    }
                    completion(.success)
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (APIState) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { (_, error) in
            if error != nil {
                // Failed signIn
                return completion(.failed(error: .firebaseError(debugDescription: error.debugDescription)))
            }
            completion(.success)
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
    }

    func addGoods(goods: Goods, completion: @escaping (APIState) -> Void) {

        guard let uid = Auth.auth().currentUser?.uid else {
            // Failed get UID
            return completion(.failed(error: .authError))
        }

        guard let data = try? FirestoreEncoder().encode(goods) else {
            // Failed encode
            return completion(.failed(error: .encodeError))
        }
        
        firestore.collection(Collections.goodslist.key)
            .document(uid).collection(Collections.goods.key)
            .document(goods.id).setData(data) { (error) in
                if error != nil {
                    // Failed add collection data
                    return completion(.failed(error: .firebaseError(debugDescription: error.debugDescription)))
                }
                completion(.success)
        }
    }

    func loadGoods(completion: @escaping ([Goods]?, APIState) -> Void) {

        guard let uid = Auth.auth().currentUser?.uid else {
            // Failed get UID
            return completion(nil, .failed(error: .authError))
        }
        
        firestore.collection(Collections.goodslist.key)
            .document(uid)
            .collection(Collections.goods.key)
            .getDocuments { (snapshot, error) in
                if error != nil {
                    // Failed get collection data
                    return completion(nil, .failed(error: .firebaseError(debugDescription: error.debugDescription)))
                }
                
                guard let documentsData = snapshot?.documents else {
                    // Failed get documents data
                    return completion(nil, .failed(error: .firebaseError(debugDescription: error.debugDescription)))
                }
                
                let goods = documentsData.compactMap {
                    try? FirestoreDecoder().decode(Goods.self, from: $0.data())
                }
                
                completion(goods, .success)
        }
    }
    
    func addBoughtGoods(boughtGoods: BoughtGoods, completion: @escaping (APIState) -> Void) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            // Failed get UID
            return completion(.failed(error: .authError))
        }
        
        guard let data = try? FirestoreEncoder().encode(boughtGoods) else {
            // Failed encode
            return completion(.failed(error: .encodeError))
        }
        
        firestore.collection(Collections.goodslist.key)
            .document(uid)
            .collection(Collections.boughtgoods.key)
            .document(boughtGoods.id).setData(data) { (error) in
                if error != nil {
                    // Failed add collection data
                    return completion(.failed(error: .firebaseError(debugDescription: error.debugDescription)))
                }
                
                completion(.success)
        }
    }
    
    func deleteGoods(id: String, completion: @escaping (APIState) -> Void) {

        guard let uid = Auth.auth().currentUser?.uid else {
            // Failed get UID
            return completion(.failed(error: .authError))
        }

        firestore.collection(Collections.goodslist.key)
            .document(uid).collection(Collections.goods.key)
            .document(id).delete { (error) in
                if error != nil {
                    // Failed remove collection data
                    return completion(.failed(error: .firebaseError(debugDescription: error.debugDescription)))
                }
                
                completion(.success)
        }
    }
    
    func loadDateCounts(completion: @escaping ([DateCount]?) -> Void) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            // Failed get UID
            return completion(nil)
        }
        
        firestore.collection(Collections.goodslist.key)
            .document(uid)
            .collection(Collections.datecount.key)
            .getDocuments { (snapshot, error) in
                if error != nil {
                    // Failed get collection data
                    return completion(nil)
                }
                
                guard let documentsData = snapshot?.documents else {
                    // Failed get documents data
                    return completion(nil)
                }
                
                let dateCount = documentsData.compactMap {
                    try? FirestoreDecoder().decode(DateCount.self, from: $0.data())
                }
                
                completion(dateCount)
        }
    }

    func updateDateCount(dateCount: DateCount, completion: @escaping (APIState) -> Void) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            // Failed get UID
            return completion(.failed(error: .authError))
        }
        
        guard let data = try? FirestoreEncoder().encode(dateCount) else {
            // Failed encode
            return completion(.failed(error: .encodeError))
        }
        
        firestore.collection(Collections.goodslist.key)
            .document(uid)
            .collection(Collections.datecount.key)
            .document(dateCount.date)
            .setData(data) { (error) in
                if error != nil {
                    // Failed update collection data
                    return completion(.failed(error: .firebaseError(debugDescription: error.debugDescription)))
                }
                completion(.success)
        }
    }
}
