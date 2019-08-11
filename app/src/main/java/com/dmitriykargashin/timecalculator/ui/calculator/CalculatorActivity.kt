/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.ui.calculator

import androidx.lifecycle.Observer
import androidx.lifecycle.ViewModelProviders
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.system.Os.read
import android.text.SpannableString
import android.widget.TextView
import com.dmitriykargashin.timecalculator.R
import com.dmitriykargashin.timecalculator.internal.extension.addStartAndEndSpace
import kotlinx.android.synthetic.main.activity_main.*


import com.dmitriykargashin.timecalculator.internal.extension.toHTMLWithColor
import com.dmitriykargashin.timecalculator.data.tokens.TokenType

import com.dmitriykargashin.timecalculator.data.calculator.CalculatorOfTime
import com.dmitriykargashin.timecalculator.internal.extension.removeAllSpaces
import com.dmitriykargashin.timecalculator.internal.extension.removeHTML
import com.dmitriykargashin.timecalculator.data.lexer.LexicalAnalyzer
import com.dmitriykargashin.timecalculator.data.tokens.Tokens
import com.dmitriykargashin.timecalculator.utilites.InjectorUtils
import kotlinx.coroutines.*


class CalculatorActivity : AppCompatActivity() {


    override fun onDestroy() {
        super.onDestroy()
        //      scope.coroutineContext.cancelChildren() // cancel the job when activity is destroyed
    }


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        initUI()

    }

    private fun initUI() {



        val factory = InjectorUtils.provideCalculatorViewModelFactory()
        val viewModel = ViewModelProviders.of(this, factory)
            .get(CalculatorViewModel::class.java)

        viewModel.getTokens().observe(
            this,
            Observer {

                tvOnlineResult.text = it?.toSpannableString()
                /*tokens ->
                               val stringBuilder = StringBuilder()
                               tokens. forEach{ quote ->
                                   stringBuilder.append("$quote\n\n")
                               }
                               textView_quotes.text = stringBuilder.toString()
               */
                // calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
            }
        )

        viewModel.getExpression().observe(
            this,
            Observer {
                tvExpressionField.text = it

            }
        )

        //nums
        buttonNum1.setOnClickListener {

            viewModel.addToExpression("1")
        }
        buttonNum2.setOnClickListener {
            viewModel.addToExpression("2")

        }
        buttonNum3.setOnClickListener {
            viewModel.addToExpression("3")

        }
        buttonNum4.setOnClickListener {
            viewModel.addToExpression("4")

        }
        buttonNum5.setOnClickListener {
            viewModel.addToExpression("5")

        }
        buttonNum6.setOnClickListener {
            viewModel.addToExpression("6")
        }
        buttonNum7.setOnClickListener {
            viewModel.addToExpression("7")
        }
        buttonNum8.setOnClickListener {
            viewModel.addToExpression("8")
        }
        buttonNum9.setOnClickListener {
            viewModel.addToExpression("9")
        }
        buttonNum0.setOnClickListener {
            viewModel.addToExpression("0")

        }
        buttonComma.setOnClickListener {
            viewModel.addToExpression(".")

        }

        /// times
        buttonYear.setOnClickListener {

            viewModel.addToExpression(TokenType.YEAR)
        }
        buttonMonth.setOnClickListener {
            viewModel.addToExpression(TokenType.MONTH)

        }
        buttonWeek.setOnClickListener {
            viewModel.addToExpression(TokenType.WEEK)

        }
        buttonDay.setOnClickListener {
            viewModel.addToExpression(TokenType.DAY)
        }
        buttonHour.setOnClickListener {
            viewModel.addToExpression(TokenType.HOUR)
        }
        buttonMinute.setOnClickListener {
            viewModel.addToExpression(TokenType.MINUTE)
        }
        buttonSecond.setOnClickListener {
            viewModel.addToExpression(TokenType.SECOND)
        }
        buttonMsec.setOnClickListener {
            viewModel.addToExpression(TokenType.MSECOND)
        }

        ///operations
        buttonMultiply.setOnClickListener {
            viewModel.addToExpression(TokenType.MULTIPLY)

        }
        buttonDivide.setOnClickListener {
            viewModel.addToExpression(TokenType.DIVIDE)

        }
        buttonSubstraction.setOnClickListener {
            viewModel.addToExpression(TokenType.MINUS)

        }
        buttonAddition.setOnClickListener {
            viewModel.addToExpression(TokenType.PLUS)

        }

        buttonClear.setOnClickListener {
            viewModel.setExpression("")
        }

        buttonEqual.setOnClickListener {

            // calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())

        }
    }


}


