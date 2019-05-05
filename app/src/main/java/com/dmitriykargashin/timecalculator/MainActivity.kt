package com.dmitriykargashin.timecalculator

import android.support.v7.app.AppCompatActivity
import android.os.Bundle
import android.widget.TextView
import com.dmitriykargashin.timecalculator.extension.addStartAndEndSpace
import kotlinx.android.synthetic.main.activity_main.*


import com.dmitriykargashin.timecalculator.extension.toHTMLWithColor
import com.dmitriykargashin.timecalculator.lexer.TokenType

import com.dmitriykargashin.timecalculator.calculator.CalculatorOfTime
import com.dmitriykargashin.timecalculator.extension.removeAllSpaces
import com.dmitriykargashin.timecalculator.extension.removeHTML
import com.dmitriykargashin.timecalculator.lexer.LexicalAnalyzer
import com.dmitriykargashin.timecalculator.lexer.Tokens
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.Channel
import kotlin.coroutines.coroutineContext


class MainActivity : AppCompatActivity() {

    protected val job = SupervisorJob() // the instance of a Job for this activity

    val scope = CoroutineScope(Dispatchers.IO + job)
    //  val coroutineContext = Dispatchers.Main.immediate + job

    override fun onDestroy() {
        super.onDestroy()
        scope.coroutineContext.cancelChildren() // cancel the job when activity is destroyed
    }


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        initButtonListeners()

    }

    private fun initButtonListeners() {
        //nums
        buttonNum1.setOnClickListener {
            tvExpressionField.append("1")
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }
        buttonNum2.setOnClickListener {
            tvExpressionField.append("2")
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }
        buttonNum3.setOnClickListener {
            tvExpressionField.append("3")
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }
        buttonNum4.setOnClickListener {
            tvExpressionField.append("4")
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }
        buttonNum5.setOnClickListener {
            tvExpressionField.append("5")
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }
        buttonNum6.setOnClickListener {
            tvExpressionField.append("6")
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }
        buttonNum7.setOnClickListener {
            tvExpressionField.append("7")
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }
        buttonNum8.setOnClickListener {
            tvExpressionField.append("8")
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }
        buttonNum9.setOnClickListener {
            tvExpressionField.append("9")
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }
        buttonNum0.setOnClickListener {
            tvExpressionField.append("0")
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }
        buttonComma.setOnClickListener {
            tvExpressionField.append(".")
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }

        /// times
        buttonYear.setOnClickListener {
            //todo https://stackoverflow.com/questions/37904739/html-fromhtml-deprecated-in-android-n
            //   tvResult.append(" Year ".toHTMLWithColor())
            tvExpressionField.append(TokenType.YEAR.value.addStartAndEndSpace().toHTMLWithColor())
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }
        buttonMonth.setOnClickListener {
            tvExpressionField.append(TokenType.MONTH.value.addStartAndEndSpace().toHTMLWithColor())
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }
        buttonWeek.setOnClickListener {
            tvExpressionField.append(TokenType.WEEK.value.addStartAndEndSpace().toHTMLWithColor())
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }
        buttonDay.setOnClickListener {
            tvExpressionField.append(TokenType.DAY.value.addStartAndEndSpace().toHTMLWithColor())
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }
        buttonHour.setOnClickListener {
            tvExpressionField.append(TokenType.HOUR.value.addStartAndEndSpace().toHTMLWithColor())
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }
        buttonMinute.setOnClickListener {
            tvExpressionField.append(TokenType.MINUTE.value.addStartAndEndSpace().toHTMLWithColor())
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }
        buttonSecond.setOnClickListener {
            tvExpressionField.append(TokenType.SECOND.value.addStartAndEndSpace().toHTMLWithColor())
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }
        buttonMsec.setOnClickListener {
            tvExpressionField.append(TokenType.MSECOND.value.addStartAndEndSpace().toHTMLWithColor())
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())
        }

        ///operations
        buttonMultiply.setOnClickListener {
            tvExpressionField.append(TokenType.MULTIPLY.value.addStartAndEndSpace())
            //  tvResult.append(" \u00D7 ")
        }
        buttonDivide.setOnClickListener {
            tvExpressionField.append(TokenType.DIVIDE.value.addStartAndEndSpace())
            //  tvResult.append(" \u00F7 ")
        }
        buttonSubstraction.setOnClickListener {
            tvExpressionField.append(TokenType.MINUS.value.addStartAndEndSpace())
            //   tvResult.append(" \u2212 ")
        }
        buttonAddition.setOnClickListener {
            tvExpressionField.append(TokenType.PLUS.value.addStartAndEndSpace())
            //tvResult.append(" + ")
        }

        buttonClear.setOnClickListener {
            tvExpressionField.text = ""
        }

        buttonEqual.setOnClickListener {
            calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())

        }
    }


    private fun calculateAndPrintResult(expressionString: String) {
        scope.coroutineContext.cancelChildren() // here we cancel all previous
        // coroutines because we need only last result
        scope.launch {

            val listOfTokens = LexicalAnalyzer.analyze(expressionString)

            val listOfResultTokens = CalculatorOfTime.evaluate(listOfTokens)

            withContext(Dispatchers.Main) {
                tvOnlineResult.text = ""
                convertEvaluatedTokensToFormattedString(tvOnlineResult, listOfResultTokens)
            }


        }


    }


    private fun convertEvaluatedTokensToFormattedString(textView: TextView, listOfResultTokens: Tokens) {


        for (token in listOfResultTokens) {
            when (token.type) {
                TokenType.NUMBER ->
                    textView.append(token.strRepresentation)

                TokenType.SECOND, TokenType.MSECOND, TokenType.YEAR, TokenType.MONTH, TokenType.WEEK, TokenType.DAY, TokenType.HOUR, TokenType.MINUTE ->
                    textView.append(token.strRepresentation.addStartAndEndSpace().toHTMLWithColor())
            }
        }
        //      Log.i("TAG", textView.text.toString())

    }
}
