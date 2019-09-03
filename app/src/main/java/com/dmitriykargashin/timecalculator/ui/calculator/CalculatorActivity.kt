/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.timecalculator.ui.calculator

import androidx.lifecycle.Observer
import androidx.lifecycle.ViewModelProviders
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle

import com.dmitriykargashin.timecalculator.data.tokens.Token
import kotlinx.android.synthetic.main.activity_main.*


import com.dmitriykargashin.timecalculator.data.tokens.TokenType


import com.dmitriykargashin.timecalculator.utilites.InjectorUtils

import android.text.method.ScrollingMovementMethod
import com.dmitriykargashin.timecalculator.R
import android.opengl.ETC1.getHeight
import android.text.Layout
import android.text.Selection
import android.text.Editable








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

                tvOnlineResult.text = it?.toLightSpannableString()

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
                tvExpressionField.text = it.toSpannableString()
               tvExpressionField.movementMethod = ScrollingMovementMethod()
               // tvExpressionField.setTextIsSelectable(true)

                /*val layout = tvExpressionField.getLayout()
                if (layout != null) {
                    val scrollDelta = (layout!!.getLineBottom(tvExpressionField.getLineCount() - 1)
                            - tvExpressionField.getScrollY() - tvExpressionField.getHeight())
                    if (scrollDelta > 0)
                        tvExpressionField.scrollBy(0, scrollDelta)
                }*/

               // tvExpressionField.scroll
            }
        )

        //nums
        buttonNum1.setOnClickListener {

            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "1"))
        }
        buttonNum2.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation ="2"))

        }
        buttonNum3.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation ="3"))

        }
        buttonNum4.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation ="4"))

        }
        buttonNum5.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation ="5"))

        }
        buttonNum6.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation ="6"))
        }
        buttonNum7.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation ="7"))
        }
        buttonNum8.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation ="8"))
        }
        buttonNum9.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation ="9"))
        }
        buttonNum0.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation ="0"))

        }
        buttonComma.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.DOT))

        }

        /// times
        buttonYear.setOnClickListener {

            viewModel.addToExpression(Token(type = TokenType.YEAR))
        }
        buttonMonth.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.MONTH))

        }
        buttonWeek.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.WEEK))

        }
        buttonDay.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.DAY))
        }
        buttonHour.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.HOUR))
        }
        buttonMinute.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.MINUTE))
        }
        buttonSecond.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.SECOND))
        }
        buttonMsec.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.MSECOND))
        }

        ///operations
        buttonMultiply.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.MULTIPLY))

        }
        buttonDivide.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.DIVIDE))

        }
        buttonSubstraction.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.MINUS))

        }
        buttonAddition.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.PLUS))

        }

        buttonDelete.setOnClickListener {
            viewModel.clearOneLastSymbol()
        }

        buttonDelete.setOnLongClickListener {
            viewModel.clearAll()
            true
        }
        buttonEqual.setOnClickListener {
            viewModel.sendResultToExpression()
            // calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())

        }
    }


}


