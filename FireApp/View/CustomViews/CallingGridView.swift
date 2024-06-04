//
//  CallingGridView.swift
//  CallingGridProject
//
//  Created by Devlomi on 9/18/20.
//  Copyright © 2020 Devlomi. All rights reserved.
//

import UIKit
class CallingGridView: UIView {
    private var items = [GridItem]()


    func removeItem(id: Int) {
        items.removeAll(where: { $0.id == id })
        updateItems()
        updateViews()
    }

    func addItem(id: Int, view: UIView) {
        //prevent duplicates
        if items.contains(where: { $0.id == id }) {
            return
        }



        let index = items.endIndex //this will return 0 if empty
        let gridItem = getGridItem(index: index, count: items.count, id: id, view: view)
        items.append(gridItem)

        updateItems()
        updateViews()
    }


    private func updateItems() {
        for (index, gridItem) in items.enumerated() {
            items[index] = getGridItem(index: index, count: items.count, id: gridItem.id, view: gridItem.view)
        }
    }

    private func updateViews() {
        removeAllViews()



        let columnsCount = items.max { $0.column < $1.column }?.column ?? 1


        let gridHeight = Int(self.frame.height) / columnsCount
        let gridWidth = self.frame.width / 2 //2 rows max
        for item in items {
            if let view = item.view {


                self.addSubview(view)

                let height = CGFloat(gridHeight)
                let width: CGFloat = item.fullWidth ? self.frame.width : gridWidth

                let viewX: CGFloat = item.row == 1 ? 0 : gridWidth



                let viewY: CGFloat = item.column == 1 ? CGFloat(0) : CGFloat((gridHeight * (item.column - 1)))
                
                view.frame = CGRect(x: viewX, y: viewY, width: width, height: height)
                item.view = view

         

            }
        }
    }


    private func getGridItem(index: Int, count: Int, id: Int, view: UIView? = nil) -> GridItem {
        var fullWidth = false
        var row: Int
        var column: Int

        let previousItemOrDefault = getPreviousItemOrDefault(index: index)


        if (count == 1) {
            fullWidth = true
            row = 1
            column = 1
        } else if (count == 2) {
            fullWidth = true
            row = 1
            column = index + 1

        } else {

            if (index == 0) {
                if (!count.isOdd) {
                    fullWidth = true
                }
                row = 1
                column = 1
            } else {

                if (previousItemOrDefault.fullWidth || previousItemOrDefault.row == 2) {

                    //get the next column
                    row = 1
                    column = previousItemOrDefault.column + 1
                } else {
                    row = 2
                    column = previousItemOrDefault.column
                }
            }

        }

        return GridItem(id: id, view: view, column: column, row: row, fullWidth: fullWidth)
    }



    private func getPreviousItemOrDefault(index: Int) -> GridItem {
        if let item = items[safe: index - 1] {
            return item
        }

        return GridItem(id: 1, view: nil, column: 1, row: 1, fullWidth: true)
    }
    func removeAllItems() {
        items.removeAll()
        removeAllViews()
    }

    func removeAllViews() {
        self.subviews.forEach({ $0.removeFromSuperview() }) // this gets things done
    }
}

 fileprivate class GridItem: NSObject {
    let id: Int
    var view: UIView?
    let column: Int
    let row: Int
    let fullWidth: Bool

    init(id: Int, view: UIView?, column: Int, row: Int, fullWidth: Bool = false) {
        self.id = id
        self.view = view
        self.column = column
        self.row = row
        self.fullWidth = fullWidth

    }

}





extension Int {
    var isOdd: Bool {
        return self % 2 == 0
    }
}
