//
//  HomeViewController.swift
//  Instagram
//
//  Created by YutaIwashina on 2017/04/14.
//  Copyright © 2017年 Yuta.Iwashina. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var postArray: [PostData] = []
    
    // FIRDatabaseのobserveEventの登録状態を表す
    var observing = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // テーブルセルのタップを無効にする
        tableView.allowsSelection = false
        
        // TableViewの初期化
        let nib = UINib(nibName: "PostTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "Cell")
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DEBUG_PRINT: viewWillAppear")
        
        if FIRAuth.auth()?.currentUser != nil {
            if self.observing == false {
                // 要素が追加されたらpostArrayに追加してTableViewを再表示する
                let postsRef = FIRDatabase.database().reference().child(Const.PostPath)
                postsRef.observe(.childAdded, with: { snapshot in
                    print("DEBUG_PRINT: .childAddedイベントが発生しました。")
                    
                    // PostDataクラスを生成して受け取ったデータを設定する
                    if let uid = FIRAuth.auth()?.currentUser?.uid {
                        let postData = PostData(snapshot: snapshot, myId: uid)
                        self.postArray.insert(postData, at: 0)
                        
                        // TableViewを再表示する
                        self.tableView.reloadData()
                    }
                })
                
                // 要素が変更されたら該当のデータをpostArrayから一度削除した後に新しいデータを追加してTableViewを再表示する
                postsRef.observe(.childChanged, with: { snapshot in
                    print("DEBUG_PRINT: .childChangedイベントが発生しました。")
                    
                    if let uid = FIRAuth.auth()?.currentUser?.uid {
                        // PostDataクラスを生成して受け取ったデータを設定する
                        let postData = PostData(snapshot: snapshot, myId: uid)
                        
                        // 保持している配列からidが同じものを探す
                        var index: Int = 0
                        for post in self.postArray {
                            if post.id == postData.id {
                                index = self.postArray.index(of: post)!
                                break
                            }
                        }
                        
                        // 差し替えるため一度削除する
                        self.postArray.remove(at: index)
                        
                        // 削除したところに更新済みのデータを追加する
                        self.postArray.insert(postData, at: index)
                        
                        // TableViewの現在表示されているセルを更新する
                        self.tableView.reloadData()
                    }
                })
                
                // FIRDatabaseのobserveEventが上記コードにより登録されたため
                // trueとする
                observing = true
            }
        } else {
            if observing == true {
                // ログアウトを検出したら、一旦テーブルをクリアしてオブザーバーを削除する
                // テーブルをクリアする
                postArray = []
                tableView.reloadData()
                // オブザーバーを削除する
                FIRDatabase.database().reference().removeAllObservers()
                
                // FIRDatabaseのobserveEventが上記コードにより削除されたため
                // false
                observing = false
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得してデータを設定する
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath as IndexPath) as! PostTableViewCell
        cell.setPostData(postData: postArray[indexPath.row])
        
        // セル内のボタンのアクションをソースコードで設定する
        cell.likeButton.addTarget(self, action: #selector(handleButton(sender:event:)), for:  UIControlEvents.touchUpInside)
        cell.commentButton.addTarget(self, action: #selector(commentButton(sender:event:)), for: UIControlEvents.touchUpInside)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        // Auto Layoutを使ってセルの高さを動的に変更する
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // セルをタップされたら何もせずに選択状態を解除する
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
    }
    
    // セル内のボタンがタップされた時に呼ばれるメソッド
    func handleButton(sender: UIButton, event:UIEvent) {
        print("DEBUG_PRINT: likeボタンがタップされました。")
        
        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        // 配列からタップされたインデックスのデータを取り出す
        let postData = postArray[indexPath!.row]
        
        // Firebaseに保存するデータの準備
        if let uid = FIRAuth.auth()?.currentUser?.uid {
            if postData.isLiked {
                // すでにいいねをしていた場合はいいねを解除するためIDを取り除く
                var index = -1
                for likeId in postData.likes {
                    if likeId == uid {
                        // 削除するためにインデックスを保持しておく
                        index = postData.likes.index(of: likeId)!
                        break
                    }
                }
                postData.likes.remove(at: index)
            } else {
                postData.likes.append(uid)
            }
            
            // 増えたlikesをFirebaseに保存する
            let postRef = FIRDatabase.database().reference().child(Const.PostPath).child(postData.id!)
            let likes = ["likes": postData.likes]
            postRef.updateChildValues(likes)
        }
    }
    
    /* コメントボタン処理 --------------------------------------------------------------------------------------*/
    func commentButton(sender: UIButton, event: UIEvent) {
        print("DEBUG_PRINT: commentボタンがタップされました。")
        
        // インスタンス生成
        let commentView = storyboard!.instantiateViewController(withIdentifier: "comment") as! CommentViewController
        
        // タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        // 配列からタップされたインデックスのデータを取り出す
        let postData = postArray[indexPath!.row]
        
        // CommentViewControllerにタップされたPostDataを送る
        commentView.postData = postData
        
        // コメント入力をさせるCommentViewControllerへ画面遷移
        self.present(commentView, animated: true, completion: nil)
    }
    /* コメントボタン処理 end-----------------------------------------------------------------------------------*/

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
