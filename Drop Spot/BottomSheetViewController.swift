//
//  BottomSheetViewController.swift
//  yuri
//
//  Created by John Konderla on 5/31/17.
//  Copyright © 2017 John Konderla. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps

protocol InteractWithRoot {
    func setHash(hash: String)
    func showTitle(id: Int)
}

class BottomSheetViewController: UIViewController, UITextFieldDelegate{
    // holdView can be UIImageView instead
    @IBOutlet weak var holdView: UIView!
    @IBOutlet weak var left: UIButton!
    @IBOutlet weak var right: UIButton!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var locationList: UITableView!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var cancelSearch: UIButton!
    
    let fullView: CGFloat = 100
    var partialView: CGFloat {
        return UIScreen.main.bounds.height - (left.frame.maxY + UIApplication.shared.statusBarFrame.height - 50)
    }
    var showLeft = true
    let blue = UIColor(colorLiteralRed: 0, green: 148/255, blue: 247.0/255.0, alpha: 1)
    
    var locationArray = [[String: Any]]()
    
    var crossClassDelegate:InteractWithRoot?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(BottomSheetViewController.panGesture))
        view.addGestureRecognizer(gesture)
        
        locationList.delegate = self
        locationList.dataSource = self
        locationList.register(UINib(nibName: "DefaultTableViewCell", bundle: nil), forCellReuseIdentifier: "default")
        
        roundViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareBackgroundView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.6, animations: { [weak self] in
            let frame = self?.view.frame
            let yComponent = self?.partialView
            self?.view.frame = CGRect(x: 0, y: yComponent!, width: frame!.width, height: frame!.height)
        })
        searchField.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        self.searchField.text = ""
        self.searchField.resignFirstResponder()
    }
    @IBAction func rightButton(_ sender: AnyObject) {
        print("right clicked")
        if(showLeft) {
            right.setTitleColor(blue, for: .normal)
            right.backgroundColor = UIColor.white
            left.setTitleColor(UIColor.white, for: .normal)
            left.backgroundColor = blue
            showLeft = false
        } else {
            print("already selected...")
        }
    }
    @IBAction func leftButton(_ sender: AnyObject) {
        print("left clicked")
        if(!showLeft) {
            left.setTitleColor(blue, for: .normal)
            left.backgroundColor = UIColor.white
            right.setTitleColor(UIColor.white, for: .normal)
            right.backgroundColor = blue
            showLeft = true
        } else {
            print("already selected...")
        }
    }
    
    @IBAction func close(_ sender: AnyObject) {
        UIView.animate(withDuration: 0.3, animations: {
            let frame = self.view.frame
            self.view.frame = CGRect(x: 0, y: self.partialView, width: frame.width, height: frame.height)
        })
    }
    
    func panGesture(_ recognizer: UIPanGestureRecognizer) {
        
        let translation = recognizer.translation(in: self.view)
        let velocity = recognizer.velocity(in: self.view)
        let y = self.view.frame.minY
        if ( y + translation.y >= fullView) && (y + translation.y <= partialView ) {
            self.view.frame = CGRect(x: 0, y: y + translation.y, width: view.frame.width, height: view.frame.height)
            recognizer.setTranslation(CGPoint.zero, in: self.view)
        }
        
        if recognizer.state == .ended {
            showBottomView(velocity: velocity, y: y)
        }
    }
    func showBottomView(velocity: CGPoint, y: CGFloat) {
        print("using my new showBottomView method")
        var duration =  velocity.y < 0 ? Double((y - fullView) / -velocity.y) : Double((partialView - y) / velocity.y )
        
        duration = duration > 1.3 ? 1 : duration
        
        UIView.animate(withDuration: duration, delay: 0.0, options: [.allowUserInteraction], animations: {
            if  velocity.y >= 0 {
                self.view.frame = CGRect(x: 0, y: self.partialView, width: self.view.frame.width, height: self.view.frame.height)
                
                self.searchField.resignFirstResponder()
            } else {
                self.view.frame = CGRect(x: 0, y: self.fullView, width: self.view.frame.width, height: self.view.frame.height)
            }
            
        }, completion: nil)
    }
    
    func roundViews() {
        view.layer.cornerRadius = 5
        holdView.layer.cornerRadius = 3
        left.layer.cornerRadius = 10
        right.layer.cornerRadius = 10
        left.layer.borderColor = blue.cgColor
        right.layer.borderColor = blue.cgColor
        left.layer.borderWidth = 1
        right.layer.borderWidth = 1
        view.clipsToBounds = true
    }
    
    func prepareBackgroundView(){
        let blurEffect = UIBlurEffect.init(style: .light)
        let visualEffect = UIVisualEffectView.init(effect: blurEffect)
        let bluredView = UIVisualEffectView.init(effect: blurEffect)
        bluredView.contentView.addSubview(visualEffect)
        
        visualEffect.frame = UIScreen.main.bounds
        bluredView.frame = UIScreen.main.bounds
        
        view.insertSubview(bluredView, at: 0)
        
    }
    func addLocations(locations: Array<Any>) {
        locationArray = locations as! [[String : Any]]
        print("locations...", locations)
        print("locationArray", locationArray)
        locationList.reloadData()
    }
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        print("I'm clicking my search field.....")
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.allowUserInteraction], animations: {
            self.view.frame = CGRect(x: 0, y: self.fullView, width: self.view.frame.width, height: self.view.frame.height)
        }, completion: nil)
        return true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("TextField should return method called")
        if let submitHash = textField.text {
         crossClassDelegate?.setHash(hash: submitHash)
        }
        textField.resignFirstResponder();
        return true;
    }

}
extension BottomSheetViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        print("count \(locationArray.count)")
        return locationArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let itemView = tableView.dequeueReusableCell(withIdentifier: "default")!
        let locationSelected = locationArray[indexPath.item]
        if let hashTag = locationSelected["hash"] as? String{
            let distanceTo = locationSelected["distanceTo"] as? String ?? "no distance.."
            itemView.textLabel?.text = "\(hashTag) \(distanceTo)"
        }
        
        return itemView
    }
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let locationSelected = locationArray[indexPath.item]
        if let lat = locationSelected["lat"] as? Float{
            let lng = locationSelected["lng"] as? Float ?? 12.00
            let id = locationSelected["locationID"] as? Int ?? 101101
            let colorCode = locationSelected["colorCode"] as? Int ?? 101101
            let hashTag = locationSelected["hash"] as? String ?? "noHash"
            let distanceTo = locationSelected["distanceTo"] as? String ?? "no distance"
            print("locationID:", id, "lat:", lat, "lng:", lng, "colorCode:", colorCode, "hash:", hashTag, "distanceTo \(distanceTo)")
            UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction], animations: {
                self.view.frame = CGRect(x: 0, y: self.partialView, width: self.view.frame.width, height: self.view.frame.height)
            }, completion: nil)
            crossClassDelegate?.showTitle(id: id)
            self.topLabel.text = hashTag
            self.distanceLabel.text = distanceTo
        }
        
    }
    
    
}
