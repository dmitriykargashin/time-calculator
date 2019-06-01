/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.data.tokens


sealed class TokenType {
    abstract val value: String

    object PLUS : TokenType() {
        override val value = "+"
    }

    object MINUS : TokenType() {
        override val value = "−"
    }

    object PARENTHESES_LEFT : TokenType() {
        override val value = "("
    }

    object PARENTHESES_RIGHT : TokenType() {
        override val value = ")"
    }

    object MULTIPLY : TokenType() {
        override val value = "×"
    }

    object DIVIDE : TokenType() {
        override val value = "÷"
    }

    object NUMBER : TokenType() {
        override val value = "0.0" // current value may differ!! should use stringRepresenatation for view actual value
    }

    object YEAR : TokenType() {
        override val value = "Year"
    }

    object MONTH : TokenType() {
        override val value = "Month"
    }

    object WEEK : TokenType() {
        override val value = "Week"
    }

    object DAY : TokenType() {
        override val value = "Day"
    }

    object HOUR : TokenType() {
        override val value = "Hour"
    }

    object MINUTE : TokenType() {
        override val value = "Minute"
    }

    object SECOND : TokenType() {
        override val value = "Second"
    }

    object MSECOND : TokenType() {
        override val value = "MSecond"
    }

    object ERROR : TokenType() {
        override val value = "ERROR"
    }

}