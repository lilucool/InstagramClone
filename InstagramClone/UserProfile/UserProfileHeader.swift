//
//  UserProfileHeader.swift
//  InstagramClone
//
//  Created by Mac Gallagher on 3/19/18.
//  Copyright © 2018 Mac Gallagher. All rights reserved.
//

import UIKit
import Firebase

protocol UserProfileHeaderDelegate {
    func didChangeToListView()
    func didChangeToGridView()
}

class UserProfileHeader: UICollectionViewCell {
   
    var delegate: UserProfileHeaderDelegate?
    
    var user: User? {
        didSet {
            configureUser()
        }
    }
    
    private let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.layer.cornerRadius = 80 / 2
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.image = #imageLiteral(resourceName: "user")
        return iv
    }()
    
    private lazy var gridButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "grid"), for: .normal)
        button.addTarget(self, action: #selector(handleChangeToGridView), for: .touchUpInside)
        return button
    }()
    
    private lazy var listButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "list"), for: .normal)
        button.tintColor = UIColor(white: 0, alpha: 0.2)
        button.addTarget(self, action: #selector(handleChangeToListView), for: .touchUpInside)
        return button
    }()
    
    private let bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "ribbon"), for: .normal)
        button.tintColor = UIColor(white: 0, alpha: 0.2)
        return button
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "username"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    private let postsLabel = UserProfileStatsLabel(value: 0, title: "posts")
    
    private let followersLabel = UserProfileStatsLabel(value: 0, title: "followers")
    
    private let followingLabel = UserProfileStatsLabel(value: 0, title: "following")
    
    private lazy var editProfileFollowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Edit Profile", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 3
        button.addTarget(self, action: #selector(handleEditProfileOrFollow), for: .touchUpInside)
        return button
    }()
    
    static var headerId = "userProfileHeaderId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    private func sharedInit() {
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, bottom: nil, right: nil, paddingTop: 12, paddingLeft: 12, paddingBottom: 0, paddingRight: 0, width: 80, height: 80)
        
        setupBottomToolbar()
        
        addSubview(usernameLabel)
        usernameLabel.anchor(top: profileImageView.bottomAnchor, left: leftAnchor, bottom: gridButton.topAnchor, right: rightAnchor, paddingTop: 4, paddingLeft: 12, paddingBottom: 0, paddingRight: 12, width: 0, height: 0)
        
        setupUserStatsView()
        
        addSubview(editProfileFollowButton)
        editProfileFollowButton.anchor(top: postsLabel.bottomAnchor, left: postsLabel.leftAnchor, bottom: nil, right: followingLabel.rightAnchor, paddingTop: 2, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 34)
    }
    
    private func setupUserStatsView() {
        let stackView = UIStackView(arrangedSubviews: [postsLabel, followersLabel, followingLabel])
        stackView.distribution = .fillEqually
        addSubview(stackView)
        stackView.anchor(top: topAnchor, left: profileImageView.rightAnchor, bottom: nil, right: rightAnchor, paddingTop: 12, paddingLeft: 12, paddingBottom: 0, paddingRight: 12, width: 0, height: 50)
    }
    
    private func setupFollowStyle() {
        editProfileFollowButton.setTitle(("Follow"), for: .normal)
        editProfileFollowButton.backgroundColor = UIColor.rgb(red: 17, green: 154, blue: 237)
        editProfileFollowButton.setTitleColor(.white, for: .normal)
        editProfileFollowButton.layer.borderColor = UIColor(white: 0, alpha: 0.2).cgColor
    }
    
    private func setupBottomToolbar() {
        let topDividerView = UIView()
        topDividerView.backgroundColor = UIColor(white: 0, alpha: 0.2)
        
        let bottomDividerView = UIView()
        bottomDividerView.backgroundColor = UIColor(white: 0, alpha: 0.2)
        
        let stackView = UIStackView(arrangedSubviews: [gridButton, listButton, bookmarkButton])
        stackView.distribution = .fillEqually
        
        addSubview(stackView)
        addSubview(topDividerView)
        addSubview(bottomDividerView)
        
        topDividerView.anchor(top: stackView.topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        bottomDividerView.anchor(top: stackView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0.5)
        stackView.anchor(top: nil, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 44)
    }
    
    private func configureUser() {
        usernameLabel.text = user?.username
        setupEditFollowButton()
        if let profileImageUrl = user?.profileImageUrl {
            profileImageView.loadImage(urlString: profileImageUrl)
        }
        configureUserStats()
    }
    
    private func configureUserStats() {
        guard let uid = user?.uid else { return }
        
        Database.database().reference().child("posts").child(uid).observe(.value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Any] else { return }
            self.postsLabel.setValue(value: dictionaries.count)
        })
        
        Database.database().reference().child("following").child(uid).observe(.value, with: { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Int] else { return }
            self.followingLabel.setValue(value: dictionaries.count)
        })
        
        Database.database().reference().child("followers").child(uid).observe(.value) { (snapshot) in
            guard let dictionaries = snapshot.value as? [String: Int] else { return }
            self.followersLabel.setValue(value: dictionaries.count)
        }
    }
    
    private func setupEditFollowButton() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        guard let userId = user?.uid else { return }
        
        if currentLoggedInUserId == userId {
            //edit
        } else {
            
            // check if following
            Database.database().reference().child("following").child(currentLoggedInUserId).child(userId).observeSingleEvent(of: .value, with: { (snapshot) in
                
                if let isFollowing = snapshot.value as? Int, isFollowing == 1 {
                    self.editProfileFollowButton.setTitle("Unfollow", for: .normal)
                    
                } else {
                    self.setupFollowStyle()
                }
                
            }) { (err) in
                print("Failed to check if following:", err)
            }
        }
    }
    
    @objc private func handleChangeToGridView() {
        gridButton.tintColor = UIColor.mainBlue
        listButton.tintColor = UIColor(white: 0, alpha: 0.2)
        delegate?.didChangeToGridView()
    }

    @objc private func handleChangeToListView() {
        listButton.tintColor = UIColor.mainBlue
        gridButton.tintColor = UIColor(white: 0, alpha: 0.2)
        delegate?.didChangeToListView()
    }
    
    //Move this code to UserProfileController
    @objc private func handleEditProfileOrFollow() {
        guard let currentLoggedInUserId = Auth.auth().currentUser?.uid else { return }
        
        guard let userId = user?.uid else { return }
        
        if editProfileFollowButton.titleLabel?.text == "Unfollow" {
            //unfollow
            
            Database.database().reference().child("following").child(currentLoggedInUserId).child(userId).removeValue { (err, _) in
                if let err = err {
                    print("Failed to unfollow user:", err)
                    return
                }
                
                Database.database().reference().child("followers").child(userId).removeValue(completionBlock: { (err, _) in
                    if let err = err {
                        print("Failed to unfollow user:", err)
                        return
                    }
                    
                    print("Sucessfully unfollowed user:", self.user?.username ?? "")
                    
                    self.setupFollowStyle()
                })
            }
            
        } else {
            //follow
            let followingRef = Database.database().reference().child("following").child(currentLoggedInUserId)
            
            let values = [userId: 1]
            followingRef.updateChildValues(values) { (err, ref) in
                if let err = err {
                    print("Failed to follow user:", err)
                    return
                }
                
                let followersRef = Database.database().reference().child("followers").child(userId)
                
                let values = [currentLoggedInUserId: 1]
                followersRef.updateChildValues(values) { (err, ref) in
                    
                    if let err = err {
                        print("Failed to follow user:", err)
                        return
                    }
                    
                    print("Sucessfully followed user: ", self.user?.username ?? "")
                    
                    self.editProfileFollowButton.setTitle("Unfollow", for: .normal)
                    self.editProfileFollowButton.backgroundColor = .white
                    self.editProfileFollowButton.setTitleColor(.black, for: .normal)
                }
                
            }
        }
    }
    
}






