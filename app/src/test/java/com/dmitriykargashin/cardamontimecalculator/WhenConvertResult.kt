/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator

import com.dmitriykargashin.cardamontimecalculator.data.tokens.TokenType
import com.dmitriykargashin.cardamontimecalculator.internal.extension.toTokenInMSec
import com.dmitriykargashin.cardamontimecalculator.internal.extension.toTokens
import com.dmitriykargashin.cardamontimecalculator.utilites.TimeConverter
import org.hamcrest.MatcherAssert
import org.junit.Test

class WhenConvertResult {
    @Test
    fun `Convert Result 10 Year to 10 Year`() {
        val listOfExpectedTokens = "10 Year".toTokens()
        val forConvertInMsec = "10 Year".toTokenInMSec()

        val listOfResultTokens =
            TimeConverter.convertExpressionInMsecsToType(forConvertInMsec, TokenType.YEAR)

        MatcherAssert.assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }

    @Test
    fun `Convert Result 1 Year to 12 Month`() {
        val listOfExpectedTokens = "12.166666666666666 Month".toTokens()
        val forConvertInMsec = "1 Year".toTokenInMSec()

        val listOfResultTokens =
            TimeConverter.convertExpressionInMsecsToType(forConvertInMsec, TokenType.MONTH)

        MatcherAssert.assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }

    @Test
    fun `Convert Result 12 Month to 360 Day`() {
        val listOfExpectedTokens = "360 Day".toTokens()
        val forConvertInMsec = "12 Month".toTokenInMSec()

        val listOfResultTokens =
            TimeConverter.convertExpressionInMsecsToType(forConvertInMsec, TokenType.DAY)

        MatcherAssert.assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }


    @Test
    fun `Convert Result 12,5 Month to 375 Day`() {
        val listOfExpectedTokens = "375.0 Day".toTokens()
        val forConvertInMsec = "12.5 Month".toTokenInMSec()

        val listOfResultTokens =
            TimeConverter.convertExpressionInMsecsToType(forConvertInMsec, TokenType.DAY)

        MatcherAssert.assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }


    @Test
    fun `Convert Result 12,5 Month to 1,0273972602739727 Year`() {
        val listOfExpectedTokens = "1.0273972602739727 Year".toTokens()
        val forConvertInMsec = "12.5 Month".toTokenInMSec()

        val listOfResultTokens =
            TimeConverter.convertExpressionInMsecsToType(forConvertInMsec, TokenType.YEAR)

        MatcherAssert.assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }


    @Test
    fun `Convert Result 2 Day to 48 Hour`() {
        val forConvertInTokens = "2 Day".toTokens()
        val formatResult = "Hour".toTokens()
        val listOfExpectedTokens = "48 Hour".toTokens()

        val listOfResultTokens =
            TimeConverter.convertTokensToTokensWithFormat(forConvertInTokens, formatResult)

        MatcherAssert.assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }

    @Test
    fun `Convert Result 2,1 Day to 50,4 Hour`() {
        val forConvertInTokens = "2.1 Day".toTokens()
        val formatResult = "Hour".toTokens()
        val listOfExpectedTokens = "50.4 Hour".toTokens()

        val listOfResultTokens =
            TimeConverter.convertTokensToTokensWithFormat(forConvertInTokens, formatResult)

        MatcherAssert.assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }

    @Test
    fun `Convert Result 48 Hour to 48 Hour`() {
        val forConvertInTokens = "48 Hour".toTokens()
        val formatResult = "Hour".toTokens()
        val listOfExpectedTokens = "48 Hour".toTokens()

        val listOfResultTokens =
            TimeConverter.convertTokensToTokensWithFormat(forConvertInTokens, formatResult)

        MatcherAssert.assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }


    @Test
    fun `Convert Result 2,1 Day to 50 Hour 24 Minute`() {
        val forConvertInTokens = "2.1 Day".toTokens()
        val formatResult = "Hour Minute".toTokens()
        val listOfExpectedTokens = "50 Hour 24 Minute".toTokens()

        val listOfResultTokens =
            TimeConverter.convertTokensToTokensWithFormat(forConvertInTokens, formatResult)

        MatcherAssert.assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }

    @Test
    fun `Convert Result 2,1 Day to 24 Minute`() {
        val forConvertInTokens = "2.1 Day".toTokens()
        val formatResult = "Minute".toTokens()
        val listOfExpectedTokens = "3024 Minute".toTokens()

        val listOfResultTokens =
            TimeConverter.convertTokensToTokensWithFormat(forConvertInTokens, formatResult)

        MatcherAssert.assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }

    @Test
    fun `Convert Result 2,12 Day to 24 Minute`() {
        val forConvertInTokens = "2.12 Day".toTokens()
        val formatResult = "Minute".toTokens()
        val listOfExpectedTokens = "3052.8 Minute".toTokens()

        val listOfResultTokens =
            TimeConverter.convertTokensToTokensWithFormat(forConvertInTokens, formatResult)

        MatcherAssert.assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }

    @Test
    fun `Convert Result 2,12 Day to Month`() {
        val forConvertInTokens = "2.12222222 Day".toTokens()
        val formatResult = "Month".toTokens()
        val listOfExpectedTokens = "0.0707 Month".toTokens()

        val listOfResultTokens =
            TimeConverter.convertTokensToTokensWithFormat(forConvertInTokens, formatResult)

        MatcherAssert.assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }


    @Test
    fun `Convert Result 12 Day to 12 Day`() {
        val forConvertInTokens = "12 Day".toTokens()
        val formatResult = "Day".toTokens()
        val listOfExpectedTokens = "12 Day".toTokens()

        val listOfResultTokens =
            TimeConverter.convertTokensToTokensWithFormat(forConvertInTokens, formatResult)

        MatcherAssert.assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }

    @Test
    fun `Convert Result 12 Day to Year Month Day Minute Second`() {
        val forConvertInTokens = "0.1 Day".toTokens()
        val formatResult = "Year Month Day Hour Minute Second".toTokens()
        val listOfExpectedTokens = "0.0707 Month".toTokens()

        val listOfResultTokens =
            TimeConverter.convertTokensToTokensWithFormat(forConvertInTokens, formatResult)

        MatcherAssert.assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }

    @Test
    fun `Convert Result 12 Day to Month`() {
        val forConvertInTokens = "13.1 Day".toTokens()
        val formatResult = "Month ".toTokens()
        val listOfExpectedTokens = "0.4367Month".toTokens()

        val listOfResultTokens =
            TimeConverter.convertTokensToTokensWithFormat(forConvertInTokens, formatResult)

        MatcherAssert.assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }


    @Test
    fun `Convert Result 240000Msec to Minute`() {
        val forConvertInTokens = "235000 Second".toTokens()
        val formatResult = "Hour Minute ".toTokens()
        val listOfExpectedTokens = "65 Hour 16.6667 Minute".toTokens()

        val listOfResultTokens =
            TimeConverter.convertTokensToTokensWithFormat(forConvertInTokens, formatResult)

        MatcherAssert.assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }

    @Test
    fun `Convert Result 240000Msec to Day Hour Minute Second`() {
        val forConvertInTokens = "62 Minute".toTokens()
        val formatResult = "Day Hour Minute Second ".toTokens()
        val listOfExpectedTokens = "1 Hour 2 Minute".toTokens()

        val listOfResultTokens =
            TimeConverter.convertTokensToTokensWithFormat(forConvertInTokens, formatResult)

        MatcherAssert.assertThat(listOfResultTokens, isEqualTo(listOfExpectedTokens))

    }
}
