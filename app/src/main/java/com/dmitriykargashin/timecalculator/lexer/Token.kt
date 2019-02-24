/*
 * Copyright (c) 2019. Dmitriy Kargashin
 *
 * Token class
 */

package com.dmitriykargashin.timecalculator.lexer


class Token(val type: TokenType, val strRepresentation: String = "", val position: Int) {


    constructor (type: TokenType, position: Int) : this(type, type.value, position)

    fun length(): Int {
        return strRepresentation.length
    }

}