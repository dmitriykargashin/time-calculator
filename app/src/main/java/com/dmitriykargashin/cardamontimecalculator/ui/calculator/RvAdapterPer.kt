/*
 * Copyright (c) 2019. Dmitriy Kargashin
 */

package com.dmitriykargashin.cardamontimecalculator.ui.calculator

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.dmitriykargashin.cardamontimecalculator.R
import com.dmitriykargashin.cardamontimecalculator.internal.extension.toHTMLWithGreenColor
import com.google.android.material.card.MaterialCardView
import kotlinx.android.synthetic.main.card_view_formats.view.*
import java.math.RoundingMode


class RvAdapterPer(private val viewModel: CalculatorViewModel) :
    RecyclerView.Adapter<RvAdapterPer.ViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int)
            : ViewHolder {
        val v: View = LayoutInflater.from(parent.context)
            .inflate(R.layout.card_view_per, parent, false)
        return ViewHolder(v)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {

        val perUnit = viewModel.getPerUnits().value!![position]
        val perUnits = viewModel.getPerUnits().value!!

        holder.id.text =
            perUnits.amount.toString() + " " + perUnits.unitName + " per " + perUnit.timeUnit.strRepresentation.toHTMLWithGreenColor() +" in the interval"
        holder.name.text =
            perUnit.unitsPer_Result.setScale(2, RoundingMode.HALF_UP).toPlainString() + " "+ perUnits.unitName


//        holder.cardView.setOnClickListener {
//            viewModel.setSelectedFormat(position)
//
//        }
    }

    override fun getItemCount(): Int {
        return viewModel.getPerUnits().value!!.size
    }


    class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val id = itemView.tvFormat as TextView
        val name = itemView.tvResultFormat as TextView
        val cardView = itemView.materialCardView as MaterialCardView


    }


}