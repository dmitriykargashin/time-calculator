/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator

import android.arch.core.executor.testing.InstantTaskExecutorRule
import android.arch.lifecycle.ViewModelProviders
import android.text.SpannableString
import com.dmitriykargashin.timecalculator.internal.extension.spannable
import com.dmitriykargashin.timecalculator.internal.extension.toHTMLWithColor
import com.dmitriykargashin.timecalculator.ui.calculator.CalculatorActivity
import com.dmitriykargashin.timecalculator.ui.calculator.CalculatorViewModel
import com.dmitriykargashin.timecalculator.ui.calculator.CalculatorViewModelFactory
import com.dmitriykargashin.timecalculator.utilites.InjectorUtils
import org.hamcrest.MatcherAssert.assertThat
import org.junit.Before
import org.junit.Test
import org.junit.rules.TestRule
import org.junit.Rule


class WhenViewModelCalculateExpression {
    // common function for calculate expression

    private lateinit var factory: CalculatorViewModelFactory
    private  lateinit var viewModel:CalculatorViewModel

    @get:Rule
    var rule: TestRule = InstantTaskExecutorRule()

    @Before
    fun initialize() {


        factory = InjectorUtils.provideCalculatorViewModelFactory()

        viewModel = CalculatorViewModel(factory.expressionRepository, factory.tokensRepository)


    }
    //  val viewModel= CalculatorViewModel()

    @Test
    fun Calculate_Expr_0_plus_10_Equals_10() {

    !!!    val expressionForCalculate = "0+10".toHTMLWithColor()
        val listOfExpectedTokens = "10".toTokens()
        viewModel.setExpression(expressionForCalculate)
        val listOfActualTokens = viewModel.getTokens()
        assertThat(listOfActualTokens.value, isEqualTo(listOfExpectedTokens))

        //  val listOfActualTokens = CalculateExpression(expressionForCalculate)

        //   assertThat(listOfActualTokens, isEqualTo(listOfExpectedTokens))
    }
}