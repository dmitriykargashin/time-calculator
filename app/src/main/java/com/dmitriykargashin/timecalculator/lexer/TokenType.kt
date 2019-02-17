package com.dmitriykargashin.timecalculator.lexer

sealed class TokenType {
    abstract val value: String

    object PLUS : TokenType() {
        override val value = "+"
    }

    object MINUS : TokenType() {
        override val value = "−"
    }

    object MULTIPLY : TokenType() {
        override val value = "×"
    }

    object DIVIDE : TokenType() {
        override val value = "÷"
    }

    object NUMBER : TokenType() {
        override val value = "0.0"
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

}