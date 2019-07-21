/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.data.tokens

import android.text.SpannableString
import com.dmitriykargashin.timecalculator.internal.extension.addStartAndEndSpace
import com.dmitriykargashin.timecalculator.internal.extension.plus
import com.dmitriykargashin.timecalculator.internal.extension.toHTMLWithColor

class Tokens : ArrayList<Token>() {
    override fun toString(): String {
        var tokensString = ""
        for (token: Token in this) {

            tokensString += when (token.type) {
                TokenType.PLUS -> "+"
                TokenType.MINUS -> "-"
                TokenType.DIVIDE -> "/"
                TokenType.MULTIPLY -> "*"
                else -> token.strRepresentation
            }

        }
        return tokensString
    }

    fun toSpannableString(): SpannableString {
        var spanString = SpannableString("")

        for (token in this) {
            when (token.type) {
                TokenType.NUMBER ->
                    spanString = spanString + (token.strRepresentation)

                TokenType.SECOND, TokenType.MSECOND, TokenType.YEAR, TokenType.MONTH, TokenType.WEEK, TokenType.DAY, TokenType.HOUR, TokenType.MINUTE ->
                    spanString = spanString + token.strRepresentation.addStartAndEndSpace().toHTMLWithColor()
            }
        }

        return spanString
    }
}