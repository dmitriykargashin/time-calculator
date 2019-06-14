/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.utilites

import com.dmitriykargashin.timecalculator.data.expression.ExpressionRepository
import com.dmitriykargashin.timecalculator.data.tokens.TokensRepository
import com.dmitriykargashin.timecalculator.ui.calculator.CalculatorViewModelFactory

object InjectorUtils {

    fun provideCalculatorViewModelFactory(): CalculatorViewModelFactory {
        // ViewModelFactory needs a repository, which in turn needs a DAO from a database
        // The whole dependency tree is constructed right here, in one place
        val tokensRepository = TokensRepository.getInstance()
        val expressionRepository = ExpressionRepository.getInstance()
        return CalculatorViewModelFactory(expressionRepository, tokensRepository)
    }
}