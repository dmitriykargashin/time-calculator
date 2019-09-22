/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator


import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import com.dmitriykargashin.timecalculator.data.expression.isErrorAfterCheckForPoint
import com.dmitriykargashin.timecalculator.data.expression.isErrorsInExpression
import com.dmitriykargashin.timecalculator.data.repository.ExpressionRepository
import com.dmitriykargashin.timecalculator.internal.extension.toToken
import com.dmitriykargashin.timecalculator.internal.extension.toTokens
import com.dmitriykargashin.timecalculator.ui.calculator.CalculatorViewModel
import com.dmitriykargashin.timecalculator.utilites.InjectorUtils
import org.hamcrest.MatcherAssert
import org.junit.Rule

import org.junit.Test

class WhenCheckExpressionForErrors {


    @get:Rule
    val rule = InstantTaskExecutorRule()


    @Test
    fun `Check expression for double PLUS`() {

        val expression = "0+".toTokens()
        val expressionToAdd = "+".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))

    }

    @Test
    fun `Check expression for double MINUS`() {

        val expression = "0-".toTokens()
        val expressionToAdd = "-".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))

    }

    @Test
    fun `Check expression for double DIV`() {

        val expression = "0/".toTokens()
        val expressionToAdd = "/".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))

    }

    @Test
    fun `Check expression for double MULTIPLY`() {

        val expression = "0*".toTokens()
        val expressionToAdd = "*".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))

    }

    @Test
    fun `Check expression for OPERATORS * and div `() {

        val expression = "0*".toTokens()
        val expressionToAdd = "/".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))

    }

    @Test
    fun `Check expression for double OPERATORS * and +`() {

        val expression = "0*".toTokens()
        val expressionToAdd = "+".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))


    }

    @Test
    fun `Check expression for double OPERATORS * and -`() {

        val expression = "0*".toTokens()
        val expressionToAdd = "-".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS - and +`() {

        val expression = "0-".toTokens()
        val expressionToAdd = "+".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS - and div`() {

        val expression = "0-".toTokens()
        val expressionToAdd = "/".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS - and *`() {

        val expression = "0-".toTokens()
        val expressionToAdd = "*".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS + and -`() {

        val expression = "0+".toTokens()
        val expressionToAdd = "-".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS + and *`() {

        val expression = "0+".toTokens()
        val expressionToAdd = "*".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS + and div`() {

        val expression = "0+".toTokens()
        val expressionToAdd = "/".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS div and -`() {

        val expression = "0/".toTokens()
        val expressionToAdd = "-".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS div and +`() {

        val expression = "0/".toTokens()
        val expressionToAdd = "+".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS div and *`() {

        val expression = "0/".toTokens()
        val expressionToAdd = "*".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    ////////////// checks for TimeOperators
    @Test
    fun `Check expression for double TIME KEYWORDS YEAR and YEAR`() {

        val expression = "0 Year".toTokens()
        val expressionToAdd = "Year".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double TIME KEYWORDS MONTH and MONTH`() {

        val expression = "0 Month".toTokens()
        val expressionToAdd = "Month".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double TIME KEYWORDS WEEK and WEEK`() {

        val expression = "0 Week".toTokens()
        val expressionToAdd = "Week".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double TIME KEYWORDS DAY and DAY`() {

        val expression = "0 Day".toTokens()
        val expressionToAdd = "Day".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double TIME KEYWORDS HOUR and HOUR`() {

        val expression = "0 Hour".toTokens()
        val expressionToAdd = "Hour".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double TIME KEYWORDS MINUTE and MINUTE`() {

        val expression = "0 Minute".toTokens()
        val expressionToAdd = "Minute".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double TIME KEYWORDS SECOND0 and SECOND`() {

        val expression = "0 Second".toTokens()
        val expressionToAdd = "Second".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double TIME KEYWORDS MSecond and MSecond`() {

        val expression = "0 Hour".toTokens()
        val expressionToAdd = "Hour".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    ////another logic tests
    @Test
    fun `Check expression for dividing on NUMBER with TIME OPERATOR`() {

        val expression = "10 Hour / 2".toTokens()
        val expressionToAdd = "Hour".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for multiplying NUMBER with TIME OPERATOR on NUMBER with TIME OPERATOR`() {

        val expression = "10 Hour * 2".toTokens()
        val expressionToAdd = "Hour".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check NOT ERROR expression for dividing NUMBER with TIME OPERATOR on NUMBER with TIME OPERATOR`() {

        val expression = "10  / 2".toTokens()
        val expressionToAdd = "Hour".toToken()

        assert(!isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check NOT ERROR expression for multiplying on NUMBER with TIME OPERATOR`() {

        val expression = "10  * 2".toTokens()
        val expressionToAdd = "Hour".toToken()

        assert(!isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check NOT ERROR expression for Adding NUMBER with TIME OPERATOR and NUMBER with TIME OPERATOR`() {

        val expression = "10 Hour + 2".toTokens()
        val expressionToAdd = "Hour".toToken()

        assert(!isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check NOT ERROR expression for substracting NUMBER with TIME OPERATOR and NUMBER with TIME OPERATOR`() {

        val expression = "10 Hour - 2".toTokens()
        val expressionToAdd = "Hour".toToken()

        assert(!isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for starting with OPERATOR +`() {

        val expression = "".toTokens()
        val expressionToAdd = "+".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for starting with OPERATOR -`() {

        val expression = "".toTokens()
        val expressionToAdd = "-".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for starting with OPERATOR *`() {

        val expression = "".toTokens()
        val expressionToAdd = "*".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for starting with OPERATOR div`() {

        val expression = "".toTokens()
        val expressionToAdd = "/".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for double OPERATORS div and YEAR`() {

        val expression = "0/".toTokens()
        val expressionToAdd = "Year".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for starting with YEAR Keyword`() {

        val expression = "".toTokens()
        val expressionToAdd = "Year".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check NOT ERROR expression for Number multiply`() {

        val expression = "5".toTokens()
        val expressionToAdd = "*".toToken()

        assert(!isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check NOT ERROR expression for + after Year Keyword`() {

        val expression = "5 Year".toTokens()
        val expressionToAdd = "+".toToken()

        assert(!isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check expression for Multiply NUMBER Years on Year Keyword`() {

        val expression = "5 Year *".toTokens()
        val expressionToAdd = "Year".toToken()

        assert(isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check NOT ERROR expression for NUMBER and Month Keyword`() {

        val expression = "5 ".toTokens()
        val expressionToAdd = "Month".toToken()

        assert(!isErrorsInExpression(expressionToAdd, expression))
    }

    /* @Test
     fun `Check expression for NUMBER +  DOT `() {

         val expression = "5 + ".toTokens()
         val expressionToAdd = ".".toToken()

         assert(isErrorsInExpression (expressionToAdd, expression))
     }
 */
    @Test
    fun `Check NOT ERROR expression for NUMBER and Year Keyword`() {

        val expression = "5 ".toTokens()
        val expressionToAdd = "Year".toToken()

        assert(!isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check NOT ERROR float point()`() {

        val expression = "5".toTokens()
        val expressionToAdd = ".".toToken()

        assert(!isErrorsInExpression(expressionToAdd, expression))
    }

    @Test
    fun `Check for Delete symbol 55-2 result 55-`() {
     //   val factory = InjectorUtils.provideCalculatorViewModelFactory()

        //     viewModel = CalculatorViewModel(factory.expressionRepository, factory.tokensRepository)
        // factory.expressionRepository.addToExpression("55".toToken())
        val expressionRepository = ExpressionRepository()
        expressionRepository.setTokens("55-2".toTokens())

        //  val expression =
        //     val expressionToAdd = ".".toToken()
        expressionRepository.deleteLastTokenOrSymbol()
        val listOfActualTokens = expressionRepository.getExpression().value
        val listOfExpectedTokens = "55-".toTokens()
        MatcherAssert.assertThat(listOfActualTokens, isEqualTo(listOfExpectedTokens))
    }


    @Test
    fun `Check for TWICE Delete symbol 55-2 result 55`() {
        //   val factory = InjectorUtils.provideCalculatorViewModelFactory()

        //     viewModel = CalculatorViewModel(factory.expressionRepository, factory.tokensRepository)
        // factory.expressionRepository.addToExpression("55".toToken())
        val expressionRepository = ExpressionRepository()
        expressionRepository.setTokens("55-2".toTokens())

        //  val expression =
        //     val expressionToAdd = ".".toToken()
        expressionRepository.deleteLastTokenOrSymbol()
        expressionRepository.deleteLastTokenOrSymbol()

        val listOfActualTokens = expressionRepository.getExpression().value
        val listOfExpectedTokens = "55".toTokens()
        MatcherAssert.assertThat(listOfActualTokens, isEqualTo(listOfExpectedTokens))
    }
    /*  @Test
      fun `Check double of float point()`() {

          val expression = "5.".toTokens()
          val expressionToAdd = ".".toToken()

          assert(isErrorAfterCheckForPoint (expressionToAdd, expression))
      }

      @Test
      fun `Check float point after Month()`() {

          val expression = "5 Month".toTokens()
          val expressionToAdd = ".".toToken()

          assert(isErrorAfterCheckForPoint (expressionToAdd, expression))
      }

  */
}

