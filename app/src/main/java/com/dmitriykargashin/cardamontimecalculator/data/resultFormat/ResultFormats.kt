/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.data.resultFormat

class ResultFormats : ArrayList<ResultFormat>() {

   // var selectedResFormat = getSelectedResulFormat()

    fun setSelection(position: Int): ResultFormat {
//this selection clears others selections
        for (resformat in this) {
            if (resformat.isSelected) {
                resformat.isSelected = false
            }

        }

        this[position].isSelected = true
        return this[position]

    }

    fun getSelectedResulFormat(): ResultFormat {
        lateinit var selectedResFormat:ResultFormat

        for (resformat in this) {
            if (resformat.isSelected) {
                 selectedResFormat = resformat
            }
        }

        return selectedResFormat
    }
}