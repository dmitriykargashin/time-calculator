/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.data.tokens

import java.math.BigDecimal

//import android.util.Log


class Token(val type: TokenType, val value: BigDecimal, var strRepresentation: String = "") {

    init {
        if (type.isTimeKeyword()) {
            if (value.compareTo(1.toBigDecimal()) != 0) {
                strRepresentation += 's'
            }
        }

        /* if (type == TokenType.NUMBER) { // here we'll remove .0 from string representation of integer
         *//*    Log.i("TAG", "NUMBER: $strRepresentation")
            val tmpDouble = strRepresentation.toDouble()
            val tmpInt = tmpDouble.roundToLong()

            if (tmpDouble == tmpInt.toDouble()) strRepresentation = tmpInt.toString()*//*
//            Log.i("TAG", "NUMBER2: $strRepresentation")
        }*/
    }

    constructor (type: TokenType, value: BigDecimal) : this(type, value, type.value)

    fun addDotToNumber() {
        //  Log.i("TAG", "NUMBER DOT: $strRepresentation")
        if (!strRepresentation.contains(".")) strRepresentation += "."
        //   Log.i("TAG", "NUMBER DOT: $strRepresentation")
    }


    fun length(): Int {
        return strRepresentation.length
    }

    fun mergeNumberToNumber(token: Token) {
        strRepresentation += token.strRepresentation
    }

    fun deleteOneLastSymbolInNumber() {
        if (type == TokenType.NUMBER) {
            if (length() > 0) {
                strRepresentation = strRepresentation.dropLast(1)
            }

        }
    }


    fun toTokens(): Tokens {
        val a = Tokens()
        a.add(this)
        return a

    }

}