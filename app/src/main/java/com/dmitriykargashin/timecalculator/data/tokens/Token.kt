/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.data.tokens

import kotlin.math.roundToLong


class Token(val type: TokenType, var strRepresentation: String = "") {

    init {
        if (type == TokenType.NUMBER) { // here we'll remove .0 from string representation of integer
            val tmpDouble = strRepresentation.toDouble()
            val tmpInt = tmpDouble.roundToLong()

            if (tmpDouble == tmpInt.toDouble()) strRepresentation = tmpInt.toString()

        }
    }

    constructor (type: TokenType) : this(type, type.value)


    fun length(): Int {
        return strRepresentation.length
    }

}