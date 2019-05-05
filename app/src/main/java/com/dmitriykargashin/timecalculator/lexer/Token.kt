/*
 * Copyright (c) 2019. Dmitriy Kargashin
 *
 * Token class
 */

package com.dmitriykargashin.timecalculator.lexer

import kotlin.math.roundToLong


class Token(val type: TokenType, var strRepresentation: String = "") {

    init {
        if (type == TokenType.NUMBER) { // here we'll remove .0 from integer
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