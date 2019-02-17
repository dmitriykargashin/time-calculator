package com.dmitriykargashin.timecalculator

import android.support.v7.app.AppCompatActivity
import android.os.Bundle
import com.dmitriykargashin.timecalculator.extension.addStartAndEndSpace
import kotlinx.android.synthetic.main.activity_main.*


import com.dmitriykargashin.timecalculator.extension.toHTMLWithColor
import com.dmitriykargashin.timecalculator.lexer.TokenType

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        initButtonListeners()

    }

    private fun initButtonListeners() {
        //nums
        buttonNum1.setOnClickListener {
            tvResult.append("1")
        }
        buttonNum2.setOnClickListener {
            tvResult.append("2")
        }
        buttonNum3.setOnClickListener {
            tvResult.append("3")
        }
        buttonNum4.setOnClickListener {
            tvResult.append("4")
        }
        buttonNum5.setOnClickListener {
            tvResult.append("5")
        }
        buttonNum6.setOnClickListener {
            tvResult.append("6")
        }
        buttonNum7.setOnClickListener {
            tvResult.append("7")
        }
        buttonNum8.setOnClickListener {
            tvResult.append("8")
        }
        buttonNum9.setOnClickListener {
            tvResult.append("9")
        }
        buttonNum0.setOnClickListener {
            tvResult.append("0")
        }
        buttonComma.setOnClickListener {
            tvResult.append(".")
        }

        /// times
        buttonYear.setOnClickListener {
            //todo https://stackoverflow.com/questions/37904739/html-fromhtml-deprecated-in-android-n
         //   tvResult.append(" Year ".toHTMLWithColor())
            tvResult.append(TokenType.YEAR.value.addStartAndEndSpace().toHTMLWithColor())
        }
        buttonMonth.setOnClickListener {
            tvResult.append(TokenType.MONTH.value.addStartAndEndSpace().toHTMLWithColor())
        }
        buttonWeek.setOnClickListener {
            tvResult.append(TokenType.WEEK.value.addStartAndEndSpace().toHTMLWithColor())
        }
        buttonDay.setOnClickListener {
            tvResult.append(TokenType.DAY.value.addStartAndEndSpace().toHTMLWithColor())
        }
        buttonHour.setOnClickListener {
            tvResult.append(TokenType.HOUR.value.addStartAndEndSpace().toHTMLWithColor())
        }
        buttonMinute.setOnClickListener {
            tvResult.append(TokenType.MINUTE.value.addStartAndEndSpace().toHTMLWithColor())
        }
        buttonSecond.setOnClickListener {
            tvResult.append(TokenType.SECOND.value.addStartAndEndSpace().toHTMLWithColor())
        }
        buttonMsec.setOnClickListener {
            tvResult.append(TokenType.MSECOND.value.addStartAndEndSpace().toHTMLWithColor())
        }

        ///operators
        buttonMultiply.setOnClickListener {
            tvResult.append(TokenType.MULTIPLY.value.addStartAndEndSpace())
          //  tvResult.append(" \u00D7 ")
        }
        buttonDivide.setOnClickListener {
            tvResult.append(TokenType.DIVIDE.value.addStartAndEndSpace())
          //  tvResult.append(" \u00F7 ")
        }
        buttonSubstraction.setOnClickListener {
            tvResult.append(TokenType.MINUS.value.addStartAndEndSpace())
         //   tvResult.append(" \u2212 ")
        }
        buttonAddition.setOnClickListener {
            tvResult.append(TokenType.PLUS.value.addStartAndEndSpace())
            //tvResult.append(" + ")
        }

        buttonClear.setOnClickListener {
            tvResult.text = ""
        }
    }
}
