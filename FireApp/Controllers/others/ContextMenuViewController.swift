//
//  ContextMenuViewController.swift
//  FireApp
//
//  Created by Devlomi on 4/09/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//

import UIKit
enum ContextItemType {
    case copy, forward, reply, delete
}
struct ContextItem {
    let title: String
    let image: UIImage
    let type: ContextItemType
}

protocol ContextMenuSelectDelegate {
    func didSelect(itemType: ContextItemType, indexPath: IndexPath)
}

class ContextMenuViewController: UITableViewController {

    var delegate: ContextMenuSelectDelegate?
    var currentIndexPath: IndexPath!
    

    var contextItems: [ContextItem] = [
        ContextItem(title: Strings.copy, image: UIImage(named: "copy")!, type: .copy),
        ContextItem(title: Strings.forward, image: UIImage(named: "forward")!, type: .forward),
        ContextItem(title: Strings.reply, image: UIImage(named: "reply")!, type: .reply),
        ContextItem(title: Strings.delete, image: UIImage(named: "delete")!, type: .delete)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = ""
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.reloadData()
        tableView.layoutIfNeeded()
        preferredContentSize = CGSize(width: 135, height: tableView.contentSize.height)
        tableView.backgroundColor = .clear
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contextItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = contextItems[indexPath.row]
        cell.separatorInset.left = 0
        cell.textLabel?.text = item.title
        cell.textLabel?.font = .boldSystemFont(ofSize: 14)
        cell.textLabel?.textColor = .white
        cell.imageView?.image = item.image
        cell.backgroundColor = .clear
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = contextItems[indexPath.row]

        delegate!.didSelect(itemType: item.type, indexPath: currentIndexPath)
        dismiss(animated: true, completion: nil)

    }
    func removeItems(items:[ContextItemType]){
        for item in items{
            contextItems.removeAll(where: {$0.type == item})
        }
    }
}
