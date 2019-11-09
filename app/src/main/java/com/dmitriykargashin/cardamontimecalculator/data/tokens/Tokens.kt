/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.data.tokens

import android.text.SpannableString
import com.dmitriykargashin.cardamontimecalculator.internal.extension.*
import android.icu.lang.UCharacter.GraphemeClusterBreak.T
import android.util.Log


class Tokens : ArrayList<Token>(), Cloneable {

    override fun clone(): Tokens {
        val newTokens = Tokens()

        for (token in this) {
            newTokens.add(Token(type = token.type, strRepresentation = token.strRepresentation))
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
                else -> " " + token.strRepresentation
            }

        }
        return tokensString.trim()
    }

    fun toSpannableString(): SpannableString {
        var spanString = SpannableString("")

        for (token in this) {
            when (token.type) {
                TokenType.NUMBER ->
                    spanString += token.strRepresentation

                TokenType.SECOND, TokenType.MSECOND, TokenType.YEAR, TokenType.MONTH, TokenType.WEEK, TokenType.DAY, TokenType.HOUR, TokenType.MINUTE ->
                    spanString += token.strRepresentation.addStartAndEndSpace()
                        .toHTMLWithGreenColor()

                TokenType.MULTIPLY, TokenType.PLUS, TokenType.DIVIDE, TokenType.MINUS ->
                    spanString += token.strRepresentation.addStartAndEndSpace()

                TokenType.ERROR -> spanString += token.strRepresentation.addStartAndEndSpace()
                    .toHTMLWithRedColor()
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
                    spanString += token.strRepresentation.addStartAndEndSpace()
                        .toHTMLWithLightGreenColor()
                TokenType.MULTIPLY, TokenType.PLUS, TokenType.DIVIDE, TokenType.MINUS ->
                    spanString += token.strRepresentation.addStartAndEndSpace()
                        .toHTMLWithGrayColor()

                TokenType.ERROR -> spanString += token.strRepresentation.addStartAndEndSpace()
                    .toHTMLWithRedColor()
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

    fun findLastNearestOperatorToken(): Token? {
        var i = this.size - 1

        while (i >= 0) {
            if (this[i].type.isOperator()) return this[i]
            i--
        }

        return null
    }

    fun findTokenBeforeLastNearestOperatorToken(): Token? {
        var i = this.size - 1

        while (i >= 0) {
            if (this[i].type.isOperator()) {
                return if (i > 0)
                    this[i - 1]
                else null
            }
            i--
        }

        return null
    }

    fun findTokenBeforeTokenBeforeLastNearestOperatorToken(): Token? {
        var i = this.size - 1

        while (i >= 0) {
            if (this[i].type.isOperator()) {
                return if (i > 1)
                    this[i - 2]
                else null
            }
            i--
        }

        return null
    }


    fun isLastExpressionBlockHasTimeKeyword(): Boolean {

        var i = this.size - 1
//here i'll find starting index of last block for searching time keyword
        while (i >= 0) {
            if (this[i].type == TokenType.PLUS || this[i].type == TokenType.MINUS) break
            i--
        }

        Log.d("Tag I", i.toString())
        if (i < 0) i = 0
        while (i <= this.size - 1) {
            if (this[i].type.isTimeKeyword()) return true
            i++
        }

        return false
    }
}