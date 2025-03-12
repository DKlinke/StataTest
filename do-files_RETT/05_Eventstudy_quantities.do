capture close all
capture log close
clear all
set maxvar 100000
set matsize 10000
log using "${logs}\log_05_Eventstudy_quant_${today}.log", replace

	  
global prereftax17 prereftax_1724_17 prereftax_1724_16 prereftax_1724_15 prereftax_1724_14 prereftax_1724_13 ///
 					prereftax_1724_12 prereftax_1724_11 prereftax_1724_10 prereftax_1724_9 prereftax_1724_8 prereftax_1724_7 prereftax_1724_6 prereftax_1724_5 prereftax_1724_3 prereftax_1724_2 prereftax_1724_1 					
global postreftax postreftax_1224_0 postreftax_1224_1 postreftax_1224_2 postreftax_1224_3 postreftax_1224_4 postreftax_1224_5 postreftax_1224_6 postreftax_1224_7 postreftax_1224_8 postreftax_1224_9 postreftax_1224_10 postreftax_1224_11 postreftax_1224_12 ///
				  postreftax_1224_13 postreftax_1224_14 postreftax_1224_15 postreftax_1224_16 postreftax_1224_17 postreftax_1224_18 postreftax_1224_19 postreftax_1224_20 postreftax_1224_21 postreftax_1224_22 postreftax_1224_23 		  

				  
global prereflntax17   prereflntax_1724_17 prereflntax_1724_16 prereflntax_1724_15 prereflntax_1724_14 prereflntax_1724_13 ///
					prereflntax_1724_12 prereflntax_1724_11 prereflntax_1724_10 prereflntax_1724_9 prereflntax_1724_8 prereflntax_1724_7 prereflntax_1724_6 prereflntax_1724_5 prereflntax_1724_3 prereflntax_1724_2 prereflntax_1724_1 
global postreflntax postreflntax_1224_0 postreflntax_1224_1 postreflntax_1224_2 postreflntax_1224_3 postreflntax_1224_4 postreflntax_1224_5 postreflntax_1224_6 postreflntax_1224_7 postreflntax_1224_8 postreflntax_1224_9 postreflntax_1224_10 postreflntax_1224_11 postreflntax_1224_12 ///
					postreflntax_1224_13 postreflntax_1224_14 postreflntax_1224_15 postreflntax_1224_16 postreflntax_1224_17 postreflntax_1224_18 postreflntax_1224_19 postreflntax_1224_20 postreflntax_1224_21 postreflntax_1224_22 postreflntax_1224_23 
											



global graphinput  all_noctrl_ife 
use Nnachbar $prereftaxnb $postreftaxnb flaeche ersterpreis ort daysposted pricediff pricediff_pc $prereform $postreform $prereftax17 prereftax_1224_4 $postreftax $prereflntax $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright ln_preisqm wmt* pricechpc jahr plz kreis ags bula betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc using "${data}/F_u_B/ifo_etwp_4q19_prep_3624.dta", clear      
gen housetype = "etwp"
append using "${data}/F_u_B/ifo_ehp_4q19_prep_3624.dta", keep(Nnachbar $prereftaxnb $postreftaxnb flaeche ersterpreis ort daysposted pricediff pricediff_pc $prereform $postreform $prereftax17 prereftax_1224_4 $postreftax $prereflntax $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright ln_preisqm wmt* pricechpc jahr plz kreis ags bula betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc)
replace housetype = "ehp" if housetype==""
append using "${data}/F_u_B/ifo_mfhp_4q19_prep_3624.dta", keep(Nnachbar $prereftaxnb $postreftaxnb flaeche ersterpreis ort daysposted pricediff pricediff_pc $prereform $postreform $prereftax17 prereftax_1224_4 $postreftax $prereflntax $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright ln_preisqm wmt* pricechpc jahr plz kreis ags bula betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc)
replace housetype = "mfhp" if housetype==""
gen ehp = 0
replace ehp = 1 if housetype == "ehp"
gen etwp = 0
replace etwp = 1 if housetype == "etwp"
gen mfhp = 0
replace mfhp = 1 if housetype == "mfhp"


local Aggr  bula	

preserve

	collapse (sum) quant_ehp = ehp quant_etwp = etwp quant_mfhp = mfhp (first) $prereftax17 ${postreftax}, by("`Aggr'" monlast jahr)

	gen quant_all     = quant_ehp + quant_etwp + quant_mfhp
	gen quant_ehpetwp = quant_ehp + quant_etwp

	gen ln_quant_all     = ln(quant_all)
	gen ln_quant_ehpetwp = ln(quant_ehpetwp)
	gen ln_quant_ehp     = ln(quant_ehp)
	gen ln_quant_etwp    = ln(quant_etwp)


	local Aggr  bula
	xtset `Aggr'

	foreach depvar of varlist  ln_quant_ehp ln_quant_etwp {
		qui {
			xtreg `depvar' $prereftax17 $postreftax i.monlast, fe vce(cluster `Aggr')
			estimates store all_noctrl_ife, title(Int. trends)
		}
		display "Event study, continuous treatment, no controls, all distances, `depvar'"
		estout all*ctrl*, varwidth(30) cells(b(star fmt(3)) se(fmt(3)) p(par fmt(3))) starlevels(* 0.05 ** 0.01 *** 0.001) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax17 $postreftax) style(fixed) label collabels(none) replace
		qui {
			foreach type in $graphinput {
				estimates restore `type'
				matrix b=e(b)
				matrix coeff1 = b[1,14..39]
				matrix coeff2 = b[1,2..13]
				
				matrix lowerb = [_b[prereftax_1724_16] - invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] - invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] - invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] - invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] - invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
				_b[prereftax_1724_11] - invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] - invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] - invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] - invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] - invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] - invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] - invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] - invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] - invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] - invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
				_b[postreftax_1224_0] - invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] - invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] - invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] - invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] - invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] - invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] - invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] - invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] - invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] - invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] - invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] - invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] - invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
				_b[postreftax_1224_13] - invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] - invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] - invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] - invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] - invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] - invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] - invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] - invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] - invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] - invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
				
				matrix upperb = [_b[prereftax_1724_16] + invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] + invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] + invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] + invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] + invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
				_b[prereftax_1724_11] + invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] + invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] + invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] + invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] + invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] + invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] + invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] + invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] + invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] + invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
				_b[postreftax_1224_0] + invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] + invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] + invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] + invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] + invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] + invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] + invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] + invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] + invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] + invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] + invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] + invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] + invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
				_b[postreftax_1224_13] + invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] + invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] + invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] + invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] + invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] + invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] + invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] + invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] + invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] + invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
				
				matrix res_`type' = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
				svmat res_`type'
				scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_`type'3 res_`type'4 res_`type'2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Quantity effect") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-.3 "-30%" -.2 "-20%" -.1 "-10%" 0 "0%" .1 "10%" .2 "20%" .3 "30%")  ytitle("Tax semi-elasticity") // yscale(range(-.25 .25))
				graph export "${graphs}\ESi_all_popgallwp_deltatax_`depvar'_`type'_`Aggr'.pdf", replace
				matrix drop _all
				drop res_`type'*
			}
		}
	qui estimates drop *
	}
restore
cap log close



