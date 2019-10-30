/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.ui.calculator

import androidx.lifecycle.Observer
import androidx.lifecycle.ViewModelProviders
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle

import com.dmitriykargashin.cardamontimecalculator.data.tokens.Token
import kotlinx.android.synthetic.main.activity_main.*


import com.dmitriykargashin.cardamontimecalculator.data.tokens.TokenType


import com.dmitriykargashin.cardamontimecalculator.utilites.InjectorUtils

import android.text.method.ScrollingMovementMethod


import android.os.Build

import com.dmitriykargashin.cardamontimecalculator.R
import android.view.View
import android.view.ViewAnimationUtils
import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.util.Log
import android.view.animation.AccelerateDecelerateInterpolator
import kotlinx.android.synthetic.main.view_formats.*
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.dmitriykargashin.cardamontimecalculator.BuildConfig
import com.dmitriykargashin.cardamontimecalculator.internal.extension.toHTMLWithLightGreenColor
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.MobileAds

import kotlin.math.hypot


class CalculatorActivity : AppCompatActivity() {


    private lateinit var factory: CalculatorViewModelFactory
    lateinit var viewModel: CalculatorViewModel
    //  private val TAG = "MainActivity"

    // Called when leaving the activity
    public override fun onPause() {
        adView.pause()
        super.onPause()
    }

    // Called when returning to the activity
    public override fun onResume() {
        super.onResume()
        adView.resume()
    }

    // Called before the activity is destroyed
    public override fun onDestroy() {
        adView.destroy()
        super.onDestroy()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        if (!isPaidVersion()) {

            MobileAds.initialize(this)
            val adRequest =
                AdRequest.Builder().addTestDevice("C38113ED0332D64C52D625B7ED43DDED").build()
            adView.loadAd(adRequest)

        } else adView.visibility = View.GONE

        initUI()

    }


    fun isPaidVersion() = BuildConfig.PRO_VERSION


    override fun onBackPressed() {
        if (viewModel.getIsFormatsLayoutVisible().value!!) closeFormatsLayout(10, 10)
        else moveTaskToBack(true)
    }

    private fun initUI() {


        factory = InjectorUtils.provideCalculatorViewModelFactory()
        viewModel = ViewModelProviders.of(this, factory)
            .get(CalculatorViewModel::class.java)


        val linearLayoutManager = LinearLayoutManager(
            this, RecyclerView.VERTICAL, false
        )
        rvFormatsToChoose.layoutManager = linearLayoutManager


        // Observe the model
        viewModel.getResultFormats().observe(this, Observer {
            rvFormatsToChoose.adapter = RvAdapterResultFormats(viewModel)
            Log.d("TAG", "changeFormat")
        })

        viewModel.getIsFormatsLayoutVisible().observe(this, Observer {
            if (it)
                formatsLayout.visibility = View.VISIBLE
            else
                formatsLayout.visibility = View.GONE
        })


        viewModel.getSelectedFormat().observe(this, Observer {

            Log.d("TAG", "changeFormat click")

            buttonFormats.text = it.textPresentationOfTokens.toHTMLWithLightGreenColor()

            val touchPointX = commonConstraintLayout.width / 2
            val touchPointY = commonConstraintLayout.height / 2

            if (formatsLayout.isAttachedToWindow && viewModel.getIsFormatsLayoutVisible().value!!) {
                Log.d("TAG", "changeFormat click ${formatsLayout.visibility == View.VISIBLE}")
                closeFormatsLayout(
                    touchPointX,
                    touchPointY
                )
            }

        })

        viewModel.getResultTokens().observe(
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


        toolbarInitalize()


        //nums
        buttonNum1.setOnClickListener {

            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "1"))
        }
        buttonNum2.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "2"))

        }
        buttonNum3.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "3"))

        }
        buttonNum4.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "4"))

        }
        buttonNum5.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "5"))

        }
        buttonNum6.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "6"))
        }
        buttonNum7.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "7"))
        }
        buttonNum8.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "8"))
        }
        buttonNum9.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "9"))
        }
        buttonNum0.setOnClickListener {
            viewModel.addToExpression(Token(type = TokenType.NUMBER, strRepresentation = "0"))

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
            //      Log.i("TAG","pressed delete")
        }

        buttonFormats.setOnClickListener {
            viewModel.updateResultFormats()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {


                //  forceRippleAnimation(tvOnlineResult)

                val location = IntArray(2)
                buttonFormats.getLocationOnScreen(location)

                val x = location[0] + buttonFormats.width / 2
                val y = location[1] + buttonFormats.height / 2

                val startRadius = 0
                val endRadius =
                    hypot(
                        commonConstraintLayout.width.toDouble(),
                        commonConstraintLayout.height.toDouble()
                    )
                        .toInt()

                val anim =
                    ViewAnimationUtils.createCircularReveal(
                        formatsLayout,
                        x,
                        y,
                        startRadius.toFloat(),
                        endRadius.toFloat()
                    ).apply {
                        interpolator = AccelerateDecelerateInterpolator()
                        duration = 600
                    }
                // make the view invisible when the animation is done
                /*    anim.addListener(object : AnimatorListenerAdapter() {

                        override fun onAnimationEnd(animation: Animator) {
                            super.onAnimationEnd(animation)
                            //           mainConstraintLayout.visibility = View.GONE

                            // viewModel.clearAll()
                        }
                    })*/
                viewModel.setIsFormatsLayoutVisible(true)
                formatsLayout.visibility = View.VISIBLE

                anim.start()


            } else {
                viewModel.setIsFormatsLayoutVisible(true)
                formatsLayout.visibility = View.VISIBLE

            }
        }

        buttonDelete.setOnLongClickListener {

            if (!viewModel.isExpressionEmpty()) {


                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {


                    //  forceRippleAnimation(tvOnlineResult)

                    val location = IntArray(2)
                    buttonDelete.getLocationOnScreen(location)

                    val x = location[0] + buttonDelete.width / 2
                    val y = tvOnlineResult.bottom

                    val startRadius = 0
                    val endRadius =
                        hypot(
                            tvExpressionField.width.toDouble(),
                            tvExpressionField.height.toDouble() + tvOnlineResult.height.toDouble() + buttonFormats.height.toDouble()
                        )
                            .toInt()

                    val anim =
                        ViewAnimationUtils.createCircularReveal(
                            tvFakeForClear,
                            x,
                            y,
                            startRadius.toFloat(),
                            endRadius.toFloat()
                        ).apply {
                            interpolator = AccelerateDecelerateInterpolator()
                            duration = 400
                        }
                    // make the view invisible when the animation is done
                    anim.addListener(object : AnimatorListenerAdapter() {

                        override fun onAnimationEnd(animation: Animator) {
                            super.onAnimationEnd(animation)
                            tvFakeForClear.visibility = View.GONE
                            viewModel.clearAll()
                        }
                    })
                    tvFakeForClear.visibility = View.VISIBLE
                    anim.start()

                } else
                    viewModel.clearAll()
            }
            true
        }


        buttonEqual.setOnClickListener {
            viewModel.sendResultToExpression()
            // calculateAndPrintResult(tvExpressionField.text.toString().removeHTML().removeAllSpaces())

        }


    }

    private fun toolbarInitalize() {
        toolbar.setNavigationOnClickListener {

            closeFormatsLayout(10, 10)


            // back button pressed

        }


    }

    private fun closeFormatsLayout(x: Int, y: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {


            /*  val x = 10
              val y = 10*/

            val endRadius = 0
            val startRadius =
                hypot(
                    commonConstraintLayout.width.toDouble(),
                    commonConstraintLayout.height.toDouble()
                )
                    .toInt()

            val anim =
                ViewAnimationUtils.createCircularReveal(
                    formatsLayout,
                    x,
                    y,
                    startRadius.toFloat(),
                    endRadius.toFloat()
                ).apply {
                    interpolator = AccelerateDecelerateInterpolator()
                    duration = 450
                }
            // make the view invisible when the animation is done
            anim.addListener(object : AnimatorListenerAdapter() {

                override fun onAnimationEnd(animation: Animator) {
                    super.onAnimationEnd(animation)
                    viewModel.setIsFormatsLayoutVisible(false)
                    formatsLayout.visibility = View.GONE

                    //  viewModel.clearAll()
                }
            })
            //       formatsLayout = View.GONE


            anim.start()

        } else {
            viewModel.setIsFormatsLayoutVisible(false)
            formatsLayout.visibility = View.GONE

        }
    }

/*  override fun onTouchEvent(event: MotionEvent?): Boolean {
      if (event?.actionMasked == MotionEvent.ACTION_UP) {
          lastTouchDownXY[0] = event.x.toInt()
          lastTouchDownXY[1] = event.y.toInt()
          Log.i("TAG", "onLongClick: x = {$event.x}, y = {$event.y}")

      }
      return super.onTouchEvent(event)
  }*/


/*  var clickListener: View.OnClickListener = View.OnClickListener {
      // retrieve the stored coordinates
      val x = lastTouchDownXY[0]
      val y = lastTouchDownXY[1]

      // use the coordinates for whatever

      Log.i("TAG", "onLongClick: x = $x, y = $y")
  }*/

/*
    protected fun forceRippleAnimation(view: View) {
        val background = view.getBackground()

        if (Build.VERSION.SDK_INT >= 21 && background is RippleDrawable) {
            val rippleDrawable = background as RippleDrawable

            rippleDrawable.state = intArrayOf(android.R.attr.state_pressed, android.R.attr.state_enabled)

            val handler = Handler()

            handler.postDelayed(Runnable { rippleDrawable.state = intArrayOf() }, 0)
        }
    }*/
}


