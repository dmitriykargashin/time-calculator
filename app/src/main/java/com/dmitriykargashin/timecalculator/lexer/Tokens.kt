/*
 * Copyright (c) 2019. Dmitriy Kargashin
 * List of Tokens
 */

package com.dmitriykargashin.timecalculator.lexer

class Tokens : ArrayList<Token>() {
    override fun toString(): String {
        var tokensString = ""
        for (token: Token in this) {

            when (token.type) {
                TokenType.PLUS -> tokensString += "+"
                TokenType.MINUS -> tokensString += "-"
                TokenType.DIVIDE -> tokensString += "/"
                TokenType.MULTIPLY -> tokensString += "*"
                else -> tokensString += token.strRepresentation
            }


        }
        return tokensString
    }
}