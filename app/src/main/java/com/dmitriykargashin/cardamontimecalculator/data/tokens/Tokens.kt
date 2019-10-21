/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.data.tokens

import android.text.SpannableString
import com.dmitriykargashin.cardamontimecalculator.internal.extension.*

class Tokens : ArrayList<Token>(), Cloneable {

    override fun clone(): Tokens {
        val newTokens = Tokens()

        for (token in this) {
            newTokens.add(Token(type =token.type, strRepresentation = token.strRepresentation ))
        }
        return newTokens
    }

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

    fun toStringWithSpaces(): String {
        var tokensString = ""
        for (token: Token in this) {

            tokensString += when (token.type) {
                TokenType.PLUS -> " +"
                TokenType.MINUS -> " -"
                TokenType.DIVIDE -> " /"
                TokenType.MULTIPLY -> " *"
                else -> " "+token.strRepresentation
            }

        }
        return  tokensString.trim()
    }

    fun toSpannableString(): SpannableString {
        var spanString = SpannableString("")

        for (token in this) {
            when (token.type) {
                TokenType.NUMBER ->
                    spanString += token.strRepresentation

                TokenType.SECOND, TokenType.MSECOND, TokenType.YEAR, TokenType.MONTH, TokenType.WEEK, TokenType.DAY, TokenType.HOUR, TokenType.MINUTE ->
                    spanString += token.strRepresentation.addStartAndEndSpace().toHTMLWithGreenColor()

                TokenType.MULTIPLY, TokenType.PLUS, TokenType.DIVIDE, TokenType.MINUS ->
                    spanString += token.strRepresentation.addStartAndEndSpace()

                TokenType.ERROR -> spanString += token.strRepresentation.addStartAndEndSpace().toHTMLWithRedColor()
            }
        }

        return spanString
    }

    fun toLightSpannableString(): SpannableString {
        var spanString = SpannableString("")

        for (token in this) {
            when (token.type) {
                TokenType.NUMBER ->
                    spanString += token.strRepresentation.toHTMLWithGrayColor()

                TokenType.SECOND, TokenType.MSECOND, TokenType.YEAR, TokenType.MONTH, TokenType.WEEK, TokenType.DAY, TokenType.HOUR, TokenType.MINUTE ->
                    spanString += token.strRepresentation.addStartAndEndSpace().toHTMLWithLightGreenColor()
                TokenType.MULTIPLY, TokenType.PLUS, TokenType.DIVIDE, TokenType.MINUS ->
                    spanString += token.strRepresentation.addStartAndEndSpace().toHTMLWithGrayColor()

                TokenType.ERROR -> spanString += token.strRepresentation.addStartAndEndSpace().toHTMLWithRedColor()
            }
        }

        return spanString
    }

    // here we check whether the set of tokens is a simple arithmetic expression
    fun isSimpleArithmeticExpression(): Boolean {
        for (token in this) {
            when (token.type) {
                TokenType.MSECOND, TokenType.SECOND, TokenType.HOUR, TokenType.MINUTE, TokenType.DAY, TokenType.WEEK, TokenType.MONTH, TokenType.YEAR -> return false

            }
        }
        return true
    }

    fun removeLastToken(): Tokens {
        this.removeAt(this.lastIndex)
        return this
    }
}