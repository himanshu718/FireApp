//
//  MenuViewController.swift
//  ThingsUI
//
//  Created by Ryan Nystrom on 3/8/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit

protocol ContextMenuSelectStateDelegate {
    func didSelect(itemType: String, isWhichDropDown : String )
}

class MenuViewController: UITableViewController {
    
    var isWhichDropDown = ""
    var delegate: ContextMenuSelectStateDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.reloadData()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.layoutIfNeeded()
        if isWhichDropDown == "Location"{
            preferredContentSize = CGSize(width: 200, height: 500)
        }else if isWhichDropDown == "Vehicle Type"{
            preferredContentSize = CGSize(width: 200, height: 355.6)
        }
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        tableView.backgroundColor = .white
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isWhichDropDown == "Location"{
            return arrOfStates.count
        }else if isWhichDropDown == "Vehicle Type"{
            return arrOfVehicleTypes.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if isWhichDropDown == "Location"{
            cell.textLabel?.text = arrOfStates[indexPath.row]
        }else if isWhichDropDown == "Vehicle Type"{
            cell.textLabel?.text = arrOfVehicleTypes[indexPath.row]
        }
        cell.textLabel?.font = .boldSystemFont(ofSize: 17)
        cell.textLabel?.textColor = .black
        cell.backgroundColor = .white
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)


        var items = ""
        if isWhichDropDown == "Location"{
            items = arrOfStates[indexPath.row]
        }else if isWhichDropDown == "Vehicle Type"{
            items = arrOfVehicleTypes[indexPath.row]
        }
        
        delegate!.didSelect(itemType: items, isWhichDropDown: isWhichDropDown)
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}
