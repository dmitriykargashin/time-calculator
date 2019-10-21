/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.utilites

import com.dmitriykargashin.cardamontimecalculator.data.repository.ExpressionRepository
import com.dmitriykargashin.cardamontimecalculator.data.repository.ResultFormatsRepository
import com.dmitriykargashin.cardamontimecalculator.data.repository.TokensRepository
import com.dmitriykargashin.cardamontimecalculator.ui.calculator.CalculatorViewModelFactory

object InjectorUtils {

    fun provideCalculatorViewModelFactory(): CalculatorViewModelFactory {
        // ViewModelFactory needs a repository, which in turn needs a DAO from a database
        // The whole dependency tree is constructed right here, in one place
        val tokensRepository = TokensRepository.getInstance()
        val expressionRepository = ExpressionRepository.getInstance()
        val resultFormatsRepository = ResultFormatsRepository.getInstance()
        return CalculatorViewModelFactory(expressionRepository, tokensRepository,resultFormatsRepository)
    }
}