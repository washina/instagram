//
//  CommentViewController.swift
//  Instagram
//
//  Created by YutaIwashina on 2017/04/18.
//  Copyright © 2017年 Yuta.Iwashina. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import SVProgressHUD

class CommentViewController: UIViewController {
    
    @IBOutlet weak var scvBackGround: UIScrollView!
    @IBOutlet weak var getImageView: UIImageView!
    @IBOutlet weak var getDateLabel: UILabel!
    @IBOutlet weak var getCaptionLabel: UILabel!
    @IBOutlet weak var inputCommentTextField: UITextField!
    
    var postData: PostData!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // 各データの表示処理
        // image
        self.getImageView.image = postData.image
        // date
        let formatter = DateFormatter()
        formatter.locale = NSLocale(localeIdentifier: "ja_JP") as Locale!
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString:String = formatter.string(from: postData.date! as Date)
        self.getDateLabel.text = dateString
        // name & caption
        self.getCaptionLabel.text = "\(postData.name!) : \(postData.caption!)"
        
//        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する
//        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
//        self.view.addGestureRecognizer(tapGesture)
    }
    
    /* コメント保存処理 -------------------------------------------------------------------------------------------------*/
    @IBAction func commentPostButton(_ sender: Any) {
        // コメント入力欄にコメントが入っているかの条件分岐
        if inputCommentTextField.text != "" {
            // コメントしているユーザーの表示名を取得
            let name = FIRAuth.auth()?.currentUser?.displayName
            
            // インスタンス作成->commentを格納
            let postRef = FIRDatabase.database().reference().child(Const.PostPath).child(self.postData.id!)
            var comments = self.postData.comments
            comments.append(["commenterName": name!, "commentText": inputCommentTextField.text!])
            postRef.updateChildValues(["comments": comments])
            
            // HUDで投稿完了を表示する
            SVProgressHUD.showSuccess(withStatus: "投稿しました")
            // 全てのモーダルを閉じる
            UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
        } else {
            SVProgressHUD.showError(withStatus: "コメントを入力して下さい")
        }
    }
    /* コメント保存処理 end----------------------------------------------------------------------------------------------*/
    
//    // キーボードを閉じる
//    func dismissKeyboard() {
//        view.endEditing(true)
//    }
    
    //改行ボタンが押された際に呼ばれる.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
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
