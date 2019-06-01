/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.data.tokens

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
}