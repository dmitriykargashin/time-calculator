package com.dmitriykargashin.timecalculator

import android.support.v7.app.AppCompatActivity
import android.os.Bundle
import kotlinx.android.synthetic.main.activity_main.*


import com.dmitriykargashin.timecalculator.extension.toHTMLWithColor

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
            tvResult.append(" Year ".toHTMLWithColor())
        }
        buttonMonth.setOnClickListener {
            tvResult.append(" Month ".toHTMLWithColor())
        }
        buttonWeek.setOnClickListener {
            tvResult.append(" Week ".toHTMLWithColor())
        }
        buttonDay.setOnClickListener {
            tvResult.append(" Day ".toHTMLWithColor())
        }
        buttonHour.setOnClickListener {
            tvResult.append(" Hour ".toHTMLWithColor())
        }
        buttonMinute.setOnClickListener {
            tvResult.append(" Minute ".toHTMLWithColor())
        }
        buttonSecond.setOnClickListener {
            tvResult.append(" Second ".toHTMLWithColor())
        }
        buttonMsec.setOnClickListener {
            tvResult.append(" MSec ".toHTMLWithColor())
        }

        ///operators
        buttonMultiply.setOnClickListener {

            tvResult.append(" \u00D7 ")
        }
        buttonDivide.setOnClickListener {
            tvResult.append(" \u00F7 ")
        }
        buttonSubstraction.setOnClickListener {
            tvResult.append(" \u2212 ")
        }
        buttonAddition.setOnClickListener {
            tvResult.append(" + ")
        }

        buttonClear.setOnClickListener {
            tvResult.text = ""
        }
    }
}
