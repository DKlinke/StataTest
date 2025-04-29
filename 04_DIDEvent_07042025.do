*-------------------------------------------------------------------------------------------------------------------
*   Project Title: THE DETERMINANTS OF TAX COMPLIANCE
*	Code: Analyze full_gwap.dta
/* 
 04_DATUM_DiDEvent.do Schätzt erste DiD bzw EventStudien mit zuvor festgelegter Ziel Variable

******************************************************************
* Umbenannte Variablen 		 									 *
****************************************************************** 

  Keine
  
 */
*-------------------------------------------------------------------------------------------------------------------

*-------------------------------------------------------------------------------------------------------------------

// Vorab über Kette der Programm 00 und 01 02 laufen lassen, oder direkt durchlaufen lassen
	use "$neudatenpfad/Temp/preperation.dta", clear
	use "$neudatenpfad/Temp/preperation_RANDOM.dta", clear

*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block 0 : Übersicht zu neg Personalausgaben und gaps über xtset
*	----
*	-------------------------------------------------------------------------------------------------------------------
// neg Personalausgaben	und ags
	generate negative = (e_personalausg < 0)

// ags mit führenden nullen
	list ags in 1/10
	describe ags 
	tostring ags, replace force // String Formatierung um führende nullen einzufügen
	replace ags = "0" + ags if strlen(ags) == 7 // führende 0en hinzufügen
	generate bundesland = substr(ags, 1, 2)

	*tabulate negative bundesland,col
	*tabulate negative rechtsform, col // Rechtsform des Unternehmens


// gaps im Panel
	xtdescribe

	
	
// OPTION 1:  Behalte nur volle id Jahr Kombinationen

	preserve 
		by id: gen n_years =_N  // Gibt für jede id die Anzahl der Beobachtungen, also Anzahl der Jahre die sie auftaucht in n_years aus
		tab n_years
		keep if n_years == 7
		save "$neudatenpfad/Temp/preperation_allyears.dta", replace
	restore


// OPTION 2: Erstelle pattern variablen wie  bei xtdescribe (sodass Datensatz nach Bedarf gefiltert werden kann)

	preserve
		summarize jahr, meanonly
		local max = r(max)
		local min = r(min)
		local range = r(max) - r(min) + 1
		local miss : display _dup(`range') "." //  string an Punkten kreieren entsprechend der range
		bysort id (jahr) : gen this = substr("`miss'", 1, jahr[1]-`min') + "1" if _n == 1
		by id : replace this = substr("`miss'", 1, jahr - jahr[_n-1] - 1) + "1" if _n > 1
		by id : replace this = this + substr("`miss'", 1, `max'- jahr[_N]) if _n == _N
		by id : gen pattern = this[1]
		by id : replace pattern = pattern[_n-1] + this if _n > 1
		by id : replace pattern = pattern[_N]
		tab pattern
		xtdescribe

	// Bestimme die pattern die behalten werden sollen

		* keep if substr(pattern, 1, 3) == "11."  // behält patterns like "11.1...", "11....", etc.
		* keep if substr(pattern, strlen(pattern)-2, 3) == "11."  // behält patterns like "...11.", ".1.11."
		keep if inlist(pattern,"1111111", ".111111", "111111.", ".11111.", "..11111", "11111..")
		xtdescribe
		save "$neudatenpfad/Temp/preperation_min5years.dta", replace
	restore

*******************************************************************************************************************************************************************************************************************

*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block 1 : Simples DiD mit n_years == 7 (OPTION 1)
*	----
*	-------------------------------------------------------------------------------------------------------------------

	use "$neudatenpfad/Temp/preperation_allyears.dta", clear

*	-------------------------------------------------------------------------------------------------------------------	
* STEP 1: Code für Pattern erstellen
*	-------------------------------------------------------------------------------------------------------------------
	// Pattern für Steuererhöhung(=1) keine Veränderung (=0) Verringerung (=-1). Für 2013 keine Veränderung berechenbar weil es sich um das erste Jahr handelt (=n) by id (ist ähnlich zu pattern, das man mit xtdescribe erhält). Der Code ist so geschrieben, dass auch für variable ranges von Jahren funktioniert, insofern keine Lücken enthalten sind. Wenn ausgewählte Jahre nicht vorhanden sind, dann wird "." eingefügt.
	
	summarize jahr, meanonly // festlegen der range(also Jahre)
	local max = r(max)
	local min = r(min)
	local range = r(max) - r(min) + 1
	local miss : display _dup(`range') "." //  string an Punkten kreieren entsprechend der 
	bysort id (jahr) : gen that = "" 
	
	// Erstes vorkommende Jahr in der range
	bysort id (jahr) : replace that = substr("`miss'", 1, jahr[1]-`min') + "n" if _n == 1 & missing(taxhike) // n für change not computable (da erstes Jahr)
	bysort id (jahr) : replace that = substr("`miss'", 1, jahr[1]-`min') + "1" if _n == 1 & taxhike == 1 // optional da Fall nie eintreten sollte
	bysort id (jahr) : replace that = substr("`miss'", 1, jahr[1]-`min') + "0" if _n == 1 & taxchange == 0 // optional da Fall nie eintreten sollte
	bysort id (jahr) : replace that = substr("`miss'", 1, jahr[1]-`min') + "-1" if _n == 1 & taxdrop == 1 // optional da Fall nie eintreten sollte
	
	// Folgejahre
	by id : replace that = substr("`miss'", 1, jahr - jahr[_n-1] - 1) + "1" if _n > 1 & taxhike == 1
	by id : replace that = substr("`miss'", 1, jahr - jahr[_n-1] - 1) + "0" if _n > 1 & taxchange == 0
	by id : replace that = substr("`miss'", 1, jahr - jahr[_n-1] - 1) + "-1" if _n > 1 & taxdrop == 1
	
	// Letztes vorkommende Jahr noch nicht am ende der range? Dann Zeichenkette an Punkten anfügen
	by id : replace that = that + substr("`miss'", 1, `max'- jahr[_N]) if _n == _N 
	
	by id : gen pattern_tax = that[1]
	by id : replace pattern_tax = pattern_tax[_n-1] + that if _n > 1
	by id : replace pattern_tax = pattern_tax[_N]
	
	tab pattern_tax, sort
	

preserve
	duplicates drop id, force
	tab pattern_tax, sort // um richtige absolute Zahl unterschiedlicher patterns anzuzeigen
restore


*	-------------------------------------------------------------------------------------------------------------------
* STEP 2: Behandlungs und Kontrollgruppe festlegen
*	-------------------------------------------------------------------------------------------------------------------

	gen treat = 1 if inlist(pattern_tax, "n000100") // von 2013 bis 2019 beobachtbar, taxchange nur im Jahr 2017, und in den anderen Jahren keine Veränderung
	replace treat = 0 if inlist(pattern_tax, "n000000") // von 2013 bis 2019 beobachtbar, kein taxchange in keinem der Jahre von 2013 bis 2019
	gen post = (jahr >= 2017) // 1 ab 2017 da nach § 16(3) GewStg, Erhöhung bis 30.Juni des Vorjahres festgelegt worden sein muss und entsprechend von Unternehmen antizipiert werden kann. Erhöhung gilt dann zum 1. eines Jahres
	gen treat_post = treat * post 
	
	
	by id (ags), sort: gen byte moved = (ags[1] != ags[_N]) // solche ids die unterschiedliche ags haben, sich also dem treatment potentiell (un)absichtlich entziehen werden gedropped
	tab pattern_tax moved, col
	drop if moved == 1

	
	
	
	
	
	
	
	
	
/* Weitere Auswahlmöglichkeiten
	* keep if substr(pattern_tax, 1, 3) == "11."  // behält patterns like "11.1...", "11....", etc.
	* keep if substr(pattern_tax, strlen(pattern_tax)-2, 3) == "11."  // behält patterns like "...11.", ".1.11."
	*keep if inlist(pattern_tax, "n000000", "n000100")
	*save "$neudatenpfad/Temp/preperation_xxxx.dta", replace
*/


*	-------------------------------------------------------------------------------------------------------------------
* STEP 3: Standard DiD schätzen 2x2
*	-------------------------------------------------------------------------------------------------------------------

// Y_it = β₀ + β₁ * treat_post_it + α_i + γ_t + ε_it  wobei α_i fixed effect für die ags sind und γ_t fixed effekt für jahr ist und treat_post_it ein Dummy, wenn in post period und treatment gruppe!

//Option 1
	reghdfe e_personalausg treat_post, a(ags jahr) vce(cluster ags) 
	
	/* identify singleton via tbd
	gen nonmissing= !missing(e_personalausg) & !missing(treat_post)
	bys id: egen count= total(nonmissing)
	browse if count<2
	*/	
	reghdfe stpfgew treat_post, a(ags jahr) vce(cluster ags)

//Option 2 (singletons werden nicht gelöscht)
	*encode ags, gen(ags_numeric)
	*encode jahr, gen (jahr_numeric)
	*xtreg e_personalausg treat_post i.ags_numeric i.jahr, fe robust cluster(ags)  
	



*	-------------------------------------------------------------------------------------------------------------------
* STEP 4: Dynamic DiD long term effects schätzen 2xT mit 2016 als letztes pre treatment jahr, Treatment 2017
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
* Behandlungs und Kontrollgruppe festlegen.Referenz 2016
*	-------------------------------------------------------------------------------------------------------------------



// e_personalausg ohne 2013

preserve 

	* Interact being in the treated group with Qtr, 
	* using ib3 to drop (the last one before treatment)
	reghdfe e_personalausg treat##ib2016.jahr if jahr != 2013, ///  
		a(ags jahr) vce(cluster ags)


	g coef = .
	g se = .
	forvalues i = 2014(1)2019 {  // entsprechend anpassen zu 2013 bis 2019
		replace coef = _b[1.treat#`i'.jahr] if jahr == `i'  
		replace se = _se[1.treat#`i'.jahr] if jahr == `i'
	}
	
	* Make confidence intervals
	g ci_top = coef+1.96*se
	g ci_bottom = coef - 1.96*se

	* Limit ourselves to one observation per jahr
	keep jahr coef se ci_*
	duplicates drop

	* Create connected scatterplot of coefficients
	* with CIs included with rcap 
	* and a line at 0 from function
	sort jahr
	twoway (sc coef jahr, connect(line)) ///  Plottete geschätzte coeffizienten (also dependent variable) gegen zeit
	  (rcap ci_top ci_bottom jahr) ///
		(function y = 0, range(2013 2019)), xline(2016, lpattern(dash) lcolor(black)) xtitle("Jahr") /// horizontale Linie und verticale Linie wird hinzugefügt
		caption("95% Confidence Intervals Shown") ///
		legend(off) // Legende ausblenden
restore




// stpfgew ohne 2013
preserve 

	* Interact being in the treated group with Qtr, 
	* using ib3 to drop (the last one before treatment)
	reghdfe stpfgew treat##ib2016.jahr if jahr != 2013, ///  
		a(ags jahr) vce(cluster ags)


	g coef = .
	g se = .
	forvalues i = 2014(1)2019 {  // entsprechend anpassen zu 2013 bis 2019
		replace coef = _b[1.treat#`i'.jahr] if jahr == `i'  
		replace se = _se[1.treat#`i'.jahr] if jahr == `i'
	}
	
	* Make confidence intervals
	g ci_top = coef+1.96*se
	g ci_bottom = coef - 1.96*se

	* Limit ourselves to one observation per jahr
	keep jahr coef se ci_*
	duplicates drop

	* Create connected scatterplot of coefficients
	* with CIs included with rcap 
	* and a line at 0 from function
	sort jahr
	twoway (sc coef jahr, connect(line)) ///  Plottete geschätzte coeffizienten (also dependent variable) gegen zeit
	  (rcap ci_top ci_bottom jahr) ///
		(function y = 0, range(2013 2019)), xline(2016, lpattern(dash) lcolor(black)) xtitle("Jahr") /// horizontale Linie und verticale Linie wird hinzugefügt
		caption("95% Confidence Intervals Shown") ///
		legend(off) // Legende ausblenden
restore


// stpfgew mit log
	gen ln_stpfgew=ln(stpfgew)
preserve 


	* Interact being in the treated group with Qtr, 
	* using ib3 to drop (the last one before treatment)
	reghdfe ln_stpfgew treat##ib2016.jahr if jahr != 2013, ///  
		a(ags jahr) vce(cluster ags)


	g coef = .
	g se = .
	forvalues i = 2014(1)2019 {  // entsprechend anpassen zu 2013 bis 2019
		replace coef = _b[1.treat#`i'.jahr] if jahr == `i'  
		replace se = _se[1.treat#`i'.jahr] if jahr == `i'
	}
	
	* Make confidence intervals
	g ci_top = coef+1.96*se
	g ci_bottom = coef - 1.96*se

	* Limit ourselves to one observation per jahr
	keep jahr coef se ci_*
	duplicates drop

	* Create connected scatterplot of coefficients
	* with CIs included with rcap 
	* and a line at 0 from function
	sort jahr
	twoway (sc coef jahr, connect(line)) ///  Plottete geschätzte coeffizienten (also dependent variable) gegen zeit
	  (rcap ci_top ci_bottom jahr) ///
		(function y = 0, range(2013 2019)), xline(2016, lpattern(dash) lcolor(black)) xtitle("Jahr") /// horizontale Linie und verticale Linie wird hinzugefügt
		caption("95% Confidence Intervals Shown") ///
		legend(off) // Legende ausblenden
restore

// e_personalausg mit log

gen ln_e_personalausg=ln(e_personalausg)

preserve 
	
	* Interact being in the treated group with Qtr, 
	* using ib3 to drop (the last one before treatment)
	reghdfe ln_e_personalausg treat##ib2016.jahr if jahr != 2013, ///  
		a(ags jahr) vce(cluster ags)


	g coef = .
	g se = .
	forvalues i = 2014(1)2019 {  // entsprechend anpassen zu 2013 bis 2019
		replace coef = _b[1.treat#`i'.jahr] if jahr == `i'  
		replace se = _se[1.treat#`i'.jahr] if jahr == `i'
	}
	
	* Make confidence intervals
	g ci_top = coef+1.96*se
	g ci_bottom = coef - 1.96*se

	* Limit ourselves to one observation per jahr
	keep jahr coef se ci_*
	duplicates drop

	* Create connected scatterplot of coefficients
	* with CIs included with rcap 
	* and a line at 0 from function
	sort jahr
	twoway (sc coef jahr, connect(line)) ///  Plottete geschätzte coeffizienten (also dependent variable) gegen zeit
	  (rcap ci_top ci_bottom jahr) ///
		(function y = 0, range(2013 2019)), xline(2016, lpattern(dash) lcolor(black)) xtitle("Jahr") /// horizontale Linie und verticale Linie wird hinzugefügt
		caption("95% Confidence Intervals Shown") ///
		legend(off) // Legende ausblenden
restore









*	-------------------------------------------------------------------------------------------------------------------
*  Dynamic DiD long term effects schätzen 2xT mit 2017 als letztes pre treatment jahr, Treatment 2018
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
* Behandlungs und Kontrollgruppe festlegen.Referenz 2017
*	-------------------------------------------------------------------------------------------------------------------

	gen treat2018 = 1 if inlist(pattern_tax, "n000010") // von 2013 bis 2019 beobachtbar, taxchange nur im Jahr 2018, und in den anderen Jahren keine Veränderung
	replace treat2018 = 0 if inlist(pattern_tax, "n000000") // von 2013 bis 2019 beobachtbar, kein taxchange in keinem der Jahre von 2013 bis 2019
	gen post2018 = (jahr >= 2018) 
	gen treat_post2018 = treat2018 * post2018 
	
	
	gen ln_e_personalausg = ln(e_personalausg)
*	-------------------------------------------------------------------------------------------------------------------
* Dyn DID schätzen
*	-------------------------------------------------------------------------------------------------------------------

// e_personalausg ohne 2013

preserve 

	* Interact being in the treated group with Qtr, 
	* using ib3 to drop (the last one before treatment)
	reghdfe e_personalausg treat2018##ib2017.jahr if jahr != 2013, ///  
		a(ags jahr) vce(cluster ags)


	g coef = .
	g se = .
	forvalues i = 2014(1)2019 {  // ggf. entsprechend anpassen zu 2013 bis 2019
		replace coef = _b[1.treat2018#`i'.jahr] if jahr == `i'  
		replace se = _se[1.treat2018#`i'.jahr] if jahr == `i'
	}
	
	* Make confidence intervals
	g ci_top = coef+1.96*se
	g ci_bottom = coef - 1.96*se

	* Limit ourselves to one observation per jahr
	keep jahr coef se ci_*
	duplicates drop

	* Create connected scatterplot of coefficients
	* with CIs included with rcap 
	* and a line at 0 from function
	sort jahr
	twoway (sc coef jahr, connect(line)) ///  Plottete geschätzte coeffizienten (also dependent variable) gegen zeit
	  (rcap ci_top ci_bottom jahr) ///
		(function y = 0, range(2013 2019)), xline(2017, lpattern(dash) lcolor(black)) xtitle("Jahr") /// horizontale Linie und verticale Linie wird hinzugefügt
		caption("95% Confidence Intervals Shown") ///
		legend(off) // Legende ausblenden
restore







// stpfgew ohne 2013
preserve 

	* Interact being in the treated group with Qtr, 
	* using ib3 to drop (the last one before treatment)
	reghdfe stpfgew treat2018##ib2017.jahr if jahr != 2013, ///  
		a(ags jahr) vce(cluster ags)


	g coef = .
	g se = .
	forvalues i = 2014(1)2019 {  // ggf. entsprechend anpassen zu 2013 bis 2019
		replace coef = _b[1.treat2018#`i'.jahr] if jahr == `i'  
		replace se = _se[1.treat2018#`i'.jahr] if jahr == `i'
	}
	
	* Make confidence intervals
	g ci_top = coef+1.96*se
	g ci_bottom = coef - 1.96*se

	* Limit ourselves to one observation per jahr
	keep jahr coef se ci_*
	duplicates drop

	* Create connected scatterplot of coefficients
	* with CIs included with rcap 
	* and a line at 0 from function
	sort jahr
	twoway (sc coef jahr, connect(line)) ///  Plottete geschätzte coeffizienten (also dependent variable) gegen zeit
	  (rcap ci_top ci_bottom jahr) ///
		(function y = 0, range(2013 2019)), xline(2017, lpattern(dash) lcolor(black)) xtitle("Jahr") /// horizontale Linie und verticale Linie wird hinzugefügt
		caption("95% Confidence Intervals Shown") ///
		legend(off) // Legende ausblenden
restore




//LOG

preserve 

	* Interact being in the treated group with Qtr, 
	* using ib3 to drop (the last one before treatment)
	reghdfe ln_e_personalausg treat2018##ib2017.jahr if jahr != 2013 & , ///  
		a(ags jahr) vce(cluster ags)


	g coef = .
	g se = .
	forvalues i = 2014(1)2019 {  // ggf. entsprechend anpassen zu 2013 bis 2019
		replace coef = _b[1.treat2018#`i'.jahr] if jahr == `i'  
		replace se = _se[1.treat2018#`i'.jahr] if jahr == `i'
	}
	
	* Make confidence intervals
	g ci_top = coef+1.96*se
	g ci_bottom = coef - 1.96*se

	* Limit ourselves to one observation per jahr
	keep jahr coef se ci_*
	duplicates drop

	* Create connected scatterplot of coefficients
	* with CIs included with rcap 
	* and a line at 0 from function
	sort jahr
	twoway (sc coef jahr, connect(line)) ///  Plottete geschätzte coeffizienten (also dependent variable) gegen zeit
	  (rcap ci_top ci_bottom jahr) ///
		(function y = 0, range(2013 2019)), xline(2017, lpattern(dash) lcolor(black)) xtitle("Jahr") /// horizontale Linie und verticale Linie wird hinzugefügt
		caption("95% Confidence Intervals Shown") ///
		legend(off) // Legende ausblenden
restore




preserve 

	* Interact being in the treated group with Qtr, 
	* using ib3 to drop (the last one before treatment)
	reghdfe ln_stpfgew treat2018##ib2017.jahr if jahr != 2013, ///  
		a(ags jahr) vce(cluster ags)


	g coef = .
	g se = .
	forvalues i = 2014(1)2019 {  // ggf. entsprechend anpassen zu 2013 bis 2019
		replace coef = _b[1.treat2018#`i'.jahr] if jahr == `i'  
		replace se = _se[1.treat2018#`i'.jahr] if jahr == `i'
	}
	
	* Make confidence intervals
	g ci_top = coef+1.96*se
	g ci_bottom = coef - 1.96*se

	* Limit ourselves to one observation per jahr
	keep jahr coef se ci_*
	duplicates drop

	* Create connected scatterplot of coefficients
	* with CIs included with rcap 
	* and a line at 0 from function
	sort jahr
	twoway (sc coef jahr, connect(line)) ///  Plottete geschätzte coeffizienten (also dependent variable) gegen zeit
	  (rcap ci_top ci_bottom jahr) ///
		(function y = 0, range(2013 2019)), xline(2017, lpattern(dash) lcolor(black)) xtitle("Jahr") /// horizontale Linie und verticale Linie wird hinzugefügt
		caption("95% Confidence Intervals Shown") ///
		legend(off) // Legende ausblenden
restore



*	-------------------------------------------------------------------------------------------------------------------
*  Dynamic DiD long term effects schätzen 2xT mit 2015 als letztes pre treatment jahr, Treatment 2016
*	-------------------------------------------------------------------------------------------------------------------
*	
*	-------------------------------------------------------------------------------------------------------------------
* Behandlungs und Kontrollgruppe festlegen.Referenz 2015
*	-------------------------------------------------------------------------------------------------------------------

	gen treat2016 = 1 if inlist(pattern_tax, "n001000") // von 2013 bis 2019 beobachtbar, taxchange nur im Jahr 2016, und in den anderen Jahren keine Veränderung
	replace treat2016 = 0 if inlist(pattern_tax, "n000000") // von 2013 bis 2019 beobachtbar, kein taxchange in keinem der Jahre von 2013 bis 2019
	gen post2016 = (jahr >= 2016) 
	gen treat_post2016 = treat2016 * post2016 

*	-------------------------------------------------------------------------------------------------------------------
* Dyn DID schätzen
*	-------------------------------------------------------------------------------------------------------------------

// e_personalausg ohne 2013

preserve 

	* Interact being in the treated group with Qtr, 
	* using ib3 to drop (the last one before treatment)
	reghdfe e_personalausg treat2016##ib2015.jahr if jahr != 2013, ///  
		a(ags jahr) vce(cluster ags)


	g coef = .
	g se = .
	forvalues i = 2014(1)2019 {  // ggf. entsprechend anpassen zu 2013 bis 2019
		replace coef = _b[1.treat2016#`i'.jahr] if jahr == `i'  
		replace se = _se[1.treat2016#`i'.jahr] if jahr == `i'
	}
	
	* Make confidence intervals
	g ci_top = coef+1.96*se
	g ci_bottom = coef - 1.96*se

	* Limit ourselves to one observation per jahr
	keep jahr coef se ci_*
	duplicates drop

	* Create connected scatterplot of coefficients
	* with CIs included with rcap 
	* and a line at 0 from function
	sort jahr
	twoway (sc coef jahr, connect(line)) ///  Plottete geschätzte coeffizienten (also dependent variable) gegen zeit
	  (rcap ci_top ci_bottom jahr) ///
		(function y = 0, range(2013 2019)), xline(2015, lpattern(dash) lcolor(black)) xtitle("Jahr") /// horizontale Linie und verticale Linie wird hinzugefügt
		caption("95% Confidence Intervals Shown") ///
		legend(off) // Legende ausblenden
restore







// stpfgew ohne 2013

preserve 

	* Interact being in the treated group with Qtr, 
	* using ib3 to drop (the last one before treatment)
	reghdfe stpfgew treat2016##ib2015.jahr if jahr != 2013, ///  
		a(ags jahr) vce(cluster ags)


	g coef = .
	g se = .
	forvalues i = 2014(1)2019 {  // ggf. entsprechend anpassen zu 2013 bis 2019
		replace coef = _b[1.treat2016#`i'.jahr] if jahr == `i'  
		replace se = _se[1.treat2016#`i'.jahr] if jahr == `i'
	}
	
	* Make confidence intervals
	g ci_top = coef+1.96*se
	g ci_bottom = coef - 1.96*se

	* Limit ourselves to one observation per jahr
	keep jahr coef se ci_*
	duplicates drop

	* Create connected scatterplot of coefficients
	* with CIs included with rcap 
	* and a line at 0 from function
	sort jahr
	twoway (sc coef jahr, connect(line)) ///  Plottete geschätzte coeffizienten (also dependent variable) gegen zeit
	  (rcap ci_top ci_bottom jahr) ///
		(function y = 0, range(2013 2019)), xline(2015, lpattern(dash) lcolor(black)) xtitle("Jahr") /// horizontale Linie und verticale Linie wird hinzugefügt
		caption("95% Confidence Intervals Shown") ///
		legend(off) // Legende ausblenden
restore





//LOG

preserve 

	* Interact being in the treated group with Qtr, 
	* using ib3 to drop (the last one before treatment)
	reghdfe ln_e_personalausg treat2016##ib2015.jahr if jahr != 2013, ///  
		a(ags jahr) vce(cluster ags)


	g coef = .
	g se = .
	forvalues i = 2014(1)2019 {  // ggf. entsprechend anpassen zu 2013 bis 2019
		replace coef = _b[1.treat2016#`i'.jahr] if jahr == `i'  
		replace se = _se[1.treat2016#`i'.jahr] if jahr == `i'
	}
	
	* Make confidence intervals
	g ci_top = coef+1.96*se
	g ci_bottom = coef - 1.96*se

	* Limit ourselves to one observation per jahr
	keep jahr coef se ci_*
	duplicates drop

	* Create connected scatterplot of coefficients
	* with CIs included with rcap 
	* and a line at 0 from function
	sort jahr
	twoway (sc coef jahr, connect(line)) ///  Plottete geschätzte coeffizienten (also dependent variable) gegen zeit
	  (rcap ci_top ci_bottom jahr) ///
		(function y = 0, range(2013 2019)), xline(2015, lpattern(dash) lcolor(black)) xtitle("Jahr") /// horizontale Linie und verticale Linie wird hinzugefügt
		caption("95% Confidence Intervals Shown") ///
		legend(off) // Legende ausblenden
restore



preserve 

	* Interact being in the treated group with Qtr, 
	* using ib3 to drop (the last one before treatment)
	reghdfe ln_stpfgew treat2016##ib2015.jahr if jahr != 2013, ///  
		a(ags jahr) vce(cluster ags)


	g coef = .
	g se = .
	forvalues i = 2014(1)2019 {  // ggf. entsprechend anpassen zu 2013 bis 2019
		replace coef = _b[1.treat2016#`i'.jahr] if jahr == `i'  
		replace se = _se[1.treat2016#`i'.jahr] if jahr == `i'
	}
	
	* Make confidence intervals
	g ci_top = coef+1.96*se
	g ci_bottom = coef - 1.96*se

	* Limit ourselves to one observation per jahr
	keep jahr coef se ci_*
	duplicates drop

	* Create connected scatterplot of coefficients
	* with CIs included with rcap 
	* and a line at 0 from function
	sort jahr
	twoway (sc coef jahr, connect(line)) ///  Plottete geschätzte coeffizienten (also dependent variable) gegen zeit
	  (rcap ci_top ci_bottom jahr) ///
		(function y = 0, range(2013 2019)), xline(2015, lpattern(dash) lcolor(black)) xtitle("Jahr") /// horizontale Linie und verticale Linie wird hinzugefügt
		caption("95% Confidence Intervals Shown") ///
		legend(off) // Legende ausblenden
restore


















*	-------------------------------------------------------------------------------------------------------------------
* STEP 6: Dynamic DiD long term andere variablen, variablen begrenzen, e_c25281 Fortbildung , reingewinnsatz haobreingewinnsatz rohgewinnsatz2

*	-------------------------------------------------------------------------------------------------------------------

// Variablen begrenzen


preserve 

	* Interact being in the treated group with Qtr, 
	* using ib3 to drop (the last one before treatment)
	reghdfe ln_e_personalausg treat##ib2016.jahr if jahr != 2013 & gk ==1, ///  
		a(ags jahr) vce(cluster ags)


	g coef = .
	g se = .
	forvalues i = 2014(1)2019 {  // entsprechend anpassen zu 2013 bis 2019
		replace coef = _b[1.treat#`i'.jahr] if jahr == `i'  
		replace se = _se[1.treat#`i'.jahr] if jahr == `i'
	}
	
	* Make confidence intervals
	g ci_top = coef+1.96*se
	g ci_bottom = coef - 1.96*se

	* Limit ourselves to one observation per jahr
	keep jahr coef se ci_*
	duplicates drop

	* Create connected scatterplot of coefficients
	* with CIs included with rcap 
	* and a line at 0 from function
	sort jahr
	twoway (sc coef jahr, connect(line)) ///  Plottete geschätzte coeffizienten (also dependent variable) gegen zeit
	  (rcap ci_top ci_bottom jahr) ///
		(function y = 0, range(2013 2019)), xline(2016, lpattern(dash) lcolor(black)) xtitle("Jahr") /// horizontale Linie und verticale Linie wird hinzugefügt
		caption("95% Confidence Intervals Shown") ///
		legend(off) // Legende ausblenden
restore






//e_reings schlecht gefüllt nutze g_reings
inspect g_reings

inspect gk








*	-------------------------------------------------------------------------------------------------------------------
* STEP 7: Dynamic DiD long term heterogenitäten -> Unterschiede in der größe der unternehmen, g_fef17 gk Betreiebsgrößenklasse, Wirtschaftszweig wz08 ? in Unternehmen die gewinn bzw verlust machen (aktuell gut bzw schlechte lage)
*	-------------------------------------------------------------------------------------------------------------------

// krasse ausreiser
histogram ln_stpfgew
histogram ln_e_personalausg
histogram e_personalausg

// ändern sich kategorisierungsvariablen über die Zeit,wenn ja welche? Teste
/*
	by id (ags), sort: gen byte moved = (ags[1] != ags[_N]) // solche ids die unterschiedliche ags haben, sich also dem treatment potentiell (un)absichtlich entziehen werden gedropped
	tab pattern_tax moved, col
	drop if moved == 1
*/


























*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block III:  "Teste" Parallel Trends Assumption und Führe Placebo Tests durch
*	----
*	-------------------------------------------------------------------------------------------------------------------	


// prior test: look at prior trend and see if different, oder statistical test um zu sehen ob unterschiedlich und wie sehr unterschiedlich. Teste Y = alpha_g + beta1 * Time + beta2 * Time * Group + epsilon on pre treatment data, where alpha_g is a set of fixed effects for the group. Wenn β2 signifikant von null verschieden ist, bedeutet dies, dass die Trends zwischen den Gruppen vor der Behandlung unterschiedlich waren, was die Annahme paralleler Trends verletzt. Wenn keine signifikanz gibt das Indiz, dass die Trends wohl vorher nicht unterschiedlich sind (bzw. vermutlich parallel verlaufen).

//nutze dep.var oder log variante dafür

preserve	
	keep if post == 0
	gen time_group = jahr * treat //Gruppe ändern
	reghdfe ln_stpfgew jahr time_group, a(ags) vce(cluster ags)
restore

preserve	
	keep if post2018 == 0
	gen time_group2018 = jahr * treat2018 //Gruppe ändern
	reghdfe e_personalausg jahr time_group2018, a(ags) vce(cluster ags)
restore

preserve	
	keep if post2016 == 0
	gen time_group2016 = jahr * treat2016 //Gruppe ändern
	reghdfe ln_e_personalausg jahr time_group2016, a(ags) vce(cluster ags)
restore

//grafisch
preserve
	// Mittelwerte von rate für jede Gruppe und jedes Quartal berechnen
	egen y_mean = mean(e_personalausg), by(jahr treat)

	// Plot erstellen mit twoway line und scatter für beide Gruppen im selben Plot
	sort jahr
	twoway ///
		(line y_mean jahr if treat == 0, sort) /// Linie für Control 
		(line y_mean jahr if treat == 1, sort) /// Linie für Treatment 
		(scatter y_mean jahr if treat == 0, msymbol(circle) mcolor(black)) /// Marker für Control (schwarz, keine Legende)
		(scatter y_mean jahr if treat== 1, msymbol(triangle) mcolor(black) ) , /// Marker für Treatment (schwarz, keine Legende)
		xline(2016.5) ///
		legend(label(1 "Control Group") label(2 "Treatment Group") order(1 2)) /// Legende hinzufügen
		xtitle("Jahr") ytitle("(mean) y") /// 
		title("Parallel Trends Test") /// 
	
restore




// placebo testen: Daten vor treatment nutzen, wähle eine zufällige pre treatment periode, oder mehrere und schauen wie wahres treatment sich verhält -> randomization inference, schätze selbes DiD Modell aber Treated sollte entsprechend 1 sein wenn in treated group und nach dem fake Treatment. Wenn man effekt findet obwohl keiner da, dann stimmt etwas mit dem Design nicht!
// Alternativ statt zeitperioden: treated groups droppen und dann eine andere gruppe als treated group wählen wird (macht jetzt bei unserem bsp nicht so viel sinn)

preserve

	keep if post == 0
	drop post
	gen post = (jahr >= 2016) // weitere zufällige Jahre denkbar
	
	gen Fake1treat_post = treat * post 
	*gen Fake2treat_post = treat * post
	reghdfe stpfgew Fake1treat_post, a(ags jahr) vce(cluster ags)
	*reghdfe stpfgew Fake2treat_post, a(ags jahr) vce(cluster ags)

restore





*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block IV:  ado Files die genutzt werden können für die Analyse mit DiD und Event am GWAP und ToDo
*	----
*	-------------------------------------------------------------------------------------------------------------------

/* 
csdid
did_multiplegt
drdid
eventstudyinteract
*/

// ToDo:
// Überprüfe Rechtsform Selektion, nur Personengesellschaften logisch sinnvoll?

// 02 Block II : Ausgabe der sample ags 

preserve
	keep ags
	duplicates drop ags, force
	sort ags
	export excel using "$outputpfad\unique_agssample_export.xlsx", firstrow(variables) replace
	di as text "Unique AGS im Sample wurden als .xlsx in den output Ordner exportiert"
restore



// Gib NA seperat aus
*codebook
*misstable summarize 



*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block X: Updates
*	-------------------------------------------------------------------------------------------------------------------

* gk verändern so dass es den Wert für alle ids hat die ...
* Stata Code: Größenklasse (gk) auf den Wert von 2019 fixieren

* --- Annahmen ---
* 1. Ihre Variable für die Unternehmens-ID heißt 'id' (oder ähnlich eindeutig)
* 2. Ihre Variable für das Jahr heißt 'jahr' (oder 'year', etc.)
* 3. Ihre Variable für die Größenklasse heißt 'gk'
* ==> Ersetzen Sie 'id', 'jahr' und 'gk' ggf. durch Ihre tatsächlichen Variablennamen!

* --- Sicherstellen, dass die Daten korrekt sortiert sind (gut für bysort) ---
sort id jahr

* --- Schritt 1: Temporäre Variable erstellen, die nur den gk-Wert von 2019 enthält ---
* Diese Variable enthält den Wert von 'gk' nur in der Zeile, die dem Jahr 2019 entspricht.
* In allen anderen Zeilen enthält sie einen Missing Value (.).
gen temp_gk_2019 = gk if jahr == 2019
label variable temp_gk_2019 "GK nur aus Jahr 2019 (temporär)"

* --- Schritt 2: Den Wert von 2019 auf alle Jahre für jede ID übertragen ---
* 'bysort id:' führt den Befehl für jede Unternehmens-ID separat aus.
* 'egen gk_fest_2019 = max(temp_gk_2019)' erstellt die neue Variable 'gk_fest_2019'.
* Innerhalb jeder 'id'-Gruppe nimmt 'max()' den höchsten Wert von 'temp_gk_2019'.
* Da 'temp_gk_2019' nur für 2019 einen Wert hat (und sonst missing ist),
* findet 'max()' genau diesen einen Wert und weist ihn ALLEN Beobachtungen dieser 'id' zu.
* Falls eine 'id' keine Beobachtung im Jahr 2019 hat, wird 'gk_fest_2019' für diese ID missing sein.
bysort id: egen gk_fest_2019 = max(temp_gk_2019)
label variable gk_fest_2019 "GK (festgeschrieben auf Stand 2019)"

* --- Schritt 3: Temporäre Variable löschen ---
drop temp_gk_2019

* --- Schritt 4: Überprüfung (Optional aber empfohlen) ---
* Zeigen Sie einige Beispiele an, um zu prüfen, ob es funktioniert hat:
* list id jahr gk gk_fest_2019 if id == <eine ID aus Ihren Daten>

* Prüfen, ob der Wert innerhalb einer ID konstant ist (ignoriert Missings)
*bysort id (jahr): assert gk_fest_2019 == gk_fest_2019[_n-1] if _n > 1 & !missing(gk_fest_2019)

* Zusammenfassung der neuen Variable anzeigen
summarize gk_fest_2019
tabulate gk_fest_2019, missing // Zeigt die Verteilung der fixierten Größenklassen

di _newline _asis "Neue Variable 'gk_fest_2019' wurde erstellt."







*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
* Transformation von Variablen

	*signierte Log transformation Eine Möglichkeit ist die Verwendung einer "signierten Logarithmus"-Transformation: • sign(Gewinn) * log(abs(Gewinn) + 1). Diese Transformation bewahrt das Vorzeichen der Gewinne/Verluste. Vergleiche signed log mit dem normalen log der nur positive werte nimmt !

	generate x_signedlog = sign(x) * ln(abs(x) + 1)

	*Transformation (Relativ) stpfgew im Vergleich zum Vorjahr

	sort id_variable time_variable

	xtset id_variable time_variable

	generate stpfgew_growth_pct = ((stpfgew - L.stpfgew) / abs(L.stpfgew)) * 100


* OPTIONAL: Überprüfen Sie einige Ergebnisse

* list id_variable time_variable stpfgew L.stpfgew stpfgew_growth_pct if mod(_n, 50) == 0 // Zeigt jede 50. Beobachtung an
* summarize stpfgew_growth_pct // Gibt deskriptive Statistiken für die neue Variable aus
	* kategoriale Variable
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------	
*-------------------------------------------------------------------------------

* continuous variable treatment (Steueränderung) wie gehabt nur entsprechend ersetzen
* Lade deine vorbereiteten Daten (falls noch nicht geschehen)
use "$neudatenpfad/Temp/preperation_allyears.dta", clear

*-------------------------------------------------------------------------------
* STEP 1: Definiere Treatment-Gruppe (nur 2017) und Kontrollgruppe
*-------------------------------------------------------------------------------
* Erstelle Indikator für die spezifische Treatment-Gruppe (nur 2017 Änderung)
gen treat_group_2017 = (pattern_tax == "n000100")

* Erstelle Indikator für die Kontrollgruppe (nie Änderung)
gen control_group = (pattern_tax == "n000000")

* Behalte nur diese beiden Gruppen
keep if treat_group_2017 == 1 | control_group == 1

* Drop Einheiten, die umgezogen sind (optional, falls noch nicht geschehen)
* bysort id (jahr): gen ags_first = ags[1]
* bysort id (jahr): gen ags_last = ags[_N]
* gen byte moved = (ags_first != ags_last)
* drop if moved == 1
* drop ags_first ags_last moved

*-------------------------------------------------------------------------------
* STEP 2: Erstelle die kontinuierliche Treatment-Intensitäts-Variable
*-------------------------------------------------------------------------------
* ANNAHME: 'tax_change_magnitude' existiert und misst die Änderungshöhe.
* Wir brauchen die Intensität der Änderung von 2017 für die behandelte Gruppe.

gen unit_treatment_intensity = .
* Weise der 2017-Gruppe die Änderungsrate aus 2017 zu
replace unit_treatment_intensity = tax_change_magnitude if treat_group_2017 == 1 & jahr == 2017

* Fülle diesen Wert für alle Jahre der 2017-Gruppe auf
bysort id (jahr): egen intensity_2017_group = max(unit_treatment_intensity)

* Setze Intensität für Kontrollgruppe auf 0
replace intensity_2017_group = 0 if control_group == 1

* Ersetze die temporäre Variable
drop unit_treatment_intensity
rename intensity_2017_group unit_treatment_intensity

* Überprüfung (optional)
* list id jahr treat_group_2017 unit_treatment_intensity if treat_group_2017 == 1

*-------------------------------------------------------------------------------
* STEP 3: Schätze das dynamische DiD Modell mit kontinuierlichem Treatment
*-------------------------------------------------------------------------------
* Modell: Y_it = alpha_i + gamma_t + SUM[delta_y * (Intensity * I(Jahr=y))] + epsilon_it
* Wir nutzen Faktorvariablen: c.intensity_var##i.year_var

local outcomes "e_personalausg stpfgew"

foreach yvar of local outcomes {
    di "Schätze Modell für: `yvar' mit kontinuierlichem Treatment"

    preserve // Sichert den aktuellen Datensatz

    * Schätzung mit reghdfe: Interaktion der kontinuierlichen Intensität mit Jahr-Dummies
    * ib2016.jahr setzt 2016 als Basisjahr für die Zeit-Dummies
    * c.unit_treatment_intensity behandelt die Intensität als kontinuierliche Variable
    * Die Interaktion c.unit_treatment_intensity#i.jahr gibt die Effekte pro Intensitätseinheit pro Jahr (vs. 2016)
    reghdfe `yvar' c.unit_treatment_intensity##ib2016.jahr if jahr != 2013, ///
            absorb(ags jahr) vce(cluster ags)

    *---------------------------------------------------------------------------
    * STEP 4: Extrahiere Koeffizienten und Standardfehler für den Plot
    *---------------------------------------------------------------------------
    * Erstelle leere Variablen für Koeffizienten und SEs
    gen coef = .
    gen se = .
    label var coef "Geschätzter Effekt pro Einheit Steueränderung (vs. 2016)"
    label var se "Standardfehler"

    * Fülle die Variablen mit den geschätzten Werten aus der Regression
    * Die Koeffizienten der Interaktionsterme sind von Interesse
    * Format: _b[c.varname#year.jahr]
    forvalues year = 2014(1)2019 {
        * Wir extrahieren nicht den Koeffizienten für das Basisjahr 2016 (er ist per Definition 0)
        if `year' != 2016 {
            capture confirm variable c.unit_treatment_intensity#`year'.jahr // Prüft, ob Koeffizient existiert
            if _rc == 0 { // Koeffizient existiert
                 replace coef = _b[c.unit_treatment_intensity#`year'.jahr] if jahr == `year'
                 replace se = _se[c.unit_treatment_intensity#`year'.jahr] if jahr == `year'
            }
        }
        * Setze den Wert für das Basisjahr manuell auf 0
        else if `year' == 2016 {
            replace coef = 0 if jahr == `year'
            replace se = 0 if jahr == `year'
        }
    }

    *---------------------------------------------------------------------------
    * STEP 5: Erstelle den Plot
    *---------------------------------------------------------------------------
    * Berechne Konfidenzintervalle (95%)
    gen ci_low = coef - invnormal(0.975) * se
    gen ci_high = coef + invnormal(0.975) * se
    label var ci_low "Untere Grenze 95% CI"
    label var ci_high "Obere Grenze 95% CI"

    * Behalte nur eine Beobachtung pro Jahr für den Plot
    keep jahr coef se ci_low ci_high
    duplicates drop jahr, force
    drop if missing(coef) // Entferne Jahre ohne Koeffizienten (z.B. 2013)

    * Sortiere nach Jahr für korrekte Linienverbindung
    sort jahr

    * Erstelle den Plot (ähnlich deinem ursprünglichen Code)
    local title_suffix : var label `yvar'
    if "`title_suffix'" == "" {
        local title_suffix "`yvar'"
    }

    twoway (scatter coef jahr, connect(line) color(blue)) /// Plot der Koeffizienten
           (rcap ci_low ci_high jahr, color(blue)) /// Plot der Konfidenzintervalle
           , ///
           yline(0, lpattern(dash) lcolor(black)) /// Nulllinie
           xline(2016.5, lpattern(dash) lcolor(gray)) /// Linie zwischen Pre/Post (nach 2016)
           title("Dynamischer Effekt für `title_suffix'") ///
           xtitle("Jahr") ///
           ytitle("Effekt pro Einheit Steueränderung (vs. 2016)") /// Achsenbeschriftung angepasst
           xlabel(2014(1)2019) /// Achsenmarkierungen anpassen
           legend(off) ///
           caption("Kontinuierliches Treatment (Intensität aus 2017), 95% CI", size(small)) /// Angepasste Caption
           graphregion(color(white))

    * Optional: Graphen speichern
    * graph save "dynamic_cont_treat_2017group_`yvar'.gph", replace
    * graph export "dynamic_cont_treat_2017group_`yvar'.png", replace width(1600) height(1200)

    restore // Stellt den Datensatz vor der Schätzung wieder her

    di "---------------------------------------------------------------------"
}

di "Fertig. Die Plots zeigen den geschätzten Effekt pro Einheit Steueränderung über die Jahre."
di "Verglichen wird jeweils mit dem Referenzjahr 2016."






*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*--------------------------------------------------------------------------------------------------------------

* continuous variable treatment (Steueränderung) mit event windows

bysort id (jahr): gen tax_change_magnitude = steuerhebesatz - L.steuerhebesatz

* Lade deine vorbereiteten Daten
use "$neudatenpfad/Temp/preperation_allyears.dta", clear

*-------------------------------------------------------------------------------
* STEP 1: Stelle sicher, dass die Variable für die Steueränderungs-Höhe existiert
*-------------------------------------------------------------------------------
* ANNAHME: Es gibt eine Variable namens 'tax_change_magnitude', die die Änderung
* des Steuersatzes im jeweiligen Jahr enthält (z.B. 10 für +10 Punkte).
* Wenn keine Änderung -> tax_change_magnitude = 0 oder missing.
* Wenn du sie noch nicht hast, erstelle sie (siehe Beispiel oben).

* Beispielhafte Überprüfung (passe Variablennamen an):
* summarize tax_change_magnitude
* list id jahr tax_change_magnitude if tax_change_magnitude != 0 & !missing(tax_change_magnitude)

*-------------------------------------------------------------------------------
* STEP 2: Identifiziere Treatment-Gruppen, Kontrollgruppe und Treatment-Jahr
*-------------------------------------------------------------------------------
* Wie im vorherigen Code:
gen treatment_year = .
replace treatment_year = 2017 if pattern_tax == "n000100" // Gruppe mit Treatment in 2017
replace treatment_year = 2018 if pattern_tax == "n000010" // Gruppe mit Treatment in 2018

gen control_group = (pattern_tax == "n000000")
gen treated_unit = !missing(treatment_year)

keep if treated_unit == 1 | control_group == 1

* Drop Einheiten, die umgezogen sind
bysort id (jahr): gen ags_first = ags[1]
bysort id (jahr): gen ags_last = ags[_N]
gen byte moved = (ags_first != ags_last)
drop if moved == 1
drop ags_first ags_last moved

*-------------------------------------------------------------------------------
* STEP 3: Definiere die relevante Treatment-Intensität für jede Einheit
*-------------------------------------------------------------------------------
* Wir brauchen die *Höhe der Steueränderung*, die das Treatment (im treatment_year) ausgelöst hat.
* Wir speichern diesen Wert für jede behandelte Einheit.

gen intensity_at_treatment = .
replace intensity_at_treatment = tax_change_magnitude if jahr == treatment_year & treated_unit == 1

* Propagiere diesen Wert auf alle Beobachtungen der jeweiligen Einheit
bysort id (treatment_year): egen unit_treatment_intensity = max(intensity_at_treatment)
drop intensity_at_treatment

* Für die Kontrollgruppe ist die Intensität 0
replace unit_treatment_intensity = 0 if control_group == 1

* Überprüfung (optional)
* list id jahr treatment_year tax_change_magnitude unit_treatment_intensity if treated_unit == 1

*-------------------------------------------------------------------------------
* STEP 4: Erstelle relative Zeit und Event-Time Dummies
*-------------------------------------------------------------------------------
gen relative_time = jahr - treatment_year

local event_window_pre = 3
local event_window_post = 1

forvalues k = -`event_window_pre'(1)`event_window_post' {
    gen event_`=subinstr("`k'","-","m",1)' = (relative_time == `k' & treated_unit == 1)
    label var event_`=subinstr("`k'","-","m",1)' "Relative Time = `k'"
}
* Referenzperiode ist t-1 (event_m1)

*-------------------------------------------------------------------------------
* STEP 5: Erstelle Interaktionsterme: Event-Dummy * Treatment-Intensität
*-------------------------------------------------------------------------------
* Diese Terme erfassen den Effekt *pro Einheit* der Steueränderung in jeder relativen Periode.

foreach k_label in m3 m2 m1 0 p1 {
    gen intensity_`k_label' = event_`k_label' * unit_treatment_intensity
    local rt = subinstr("`k_label'","m","-",1)
    local rt = subinstr("`rt'","p","",1)
    label var intensity_`k_label' "Intensity * Rel Time `rt'"
}

* Definiere die Interaktionsterme für die Regression (OHNE Referenzperiode t-1 -> intensity_m1)
local interaction_terms "intensity_m3 intensity_m2 intensity_0 intensity_p1"

*-------------------------------------------------------------------------------
* STEP 6: Schätze das dynamische Modell mit kontinuierlichem Treatment
*-------------------------------------------------------------------------------
* Modell: Y_it = alpha_i + gamma_t + SUM[delta_k * IntensityInteraction_k] + epsilon_it
* alpha_i: Einheiten-Fixed-Effects (ags)
* gamma_t: Zeit-Fixed-Effects (jahr)
* IntensityInteraction_k: Die oben erstellten Interaktionsterme (intensity_m3, ...)
* delta_k: Koeffizient = Effekt pro Einheit Steueränderung in Periode k vs. Periode -1

local outcomes "e_personalausg stpfgew"

foreach yvar of local outcomes {
    di "Schätze Modell für: `yvar'"
    reghdfe `yvar' `interaction_terms', absorb(ags jahr) vce(cluster ags)

    * Speichere Ergebnisse für Plot (alternativ coefplot)
    matrix b = e(b)
    matrix V = e(V)

    * Erstelle Datensatz für Plot
    preserve
    clear
    set obs 5 // Anzahl der Punkte im Plot (-3, -2, -1, 0, 1)
    gen rel_time = .
    gen coef = 0
    gen se = 0

    local i = 1
    foreach var of local interaction_terms {
        local rt_label = subinstr("`var'","intensity_","",1) // Holt "m3", "m2", "0", "p1" etc.
        local rt = subinstr("`rt_label'","m","-",1)
        local rt = subinstr("`rt'","p","",1)

        qui replace rel_time = `rt' in `i'
        qui replace coef = b[1,colsof(b)-colsof(V)+`i'] in `i' // Koeffizient
        qui replace se = sqrt(V[`i',`i']) in `i'          // Standardfehler
        local ++i
    }

    * Füge den Referenzpunkt hinzu (relative_time = -1, coef = 0)
    local ref_period = -1
    qui replace rel_time = `ref_period' in `i'
    qui replace coef = 0 in `i'
    qui replace se = 0 in `i'

    * Berechne Konfidenzintervalle
    gen ci_low = coef - invnormal(0.975) * se
    gen ci_high = coef + invnormal(0.975) * se

    sort rel_time

    * Erstelle den Event Study Plot
    local title_suffix : var label `yvar'
    if "`title_suffix'" == "" {
        local title_suffix "`yvar'"
    }
    
    twoway (scatter coef rel_time, connect(line) color(blue)) ///
           (rcap ci_low ci_high rel_time, color(blue)) ///
           (scatter coef rel_time if rel_time == `ref_period', mcolor(red) msymbol(Dh)) ///
           , ///
           yline(0, lpattern(dash) lcolor(black)) ///
           xline(`ref_period'+0.5, lpattern(dash) lcolor(gray)) ///
           title("Dynamischer Effekt für `title_suffix'") ///
           xtitle("Jahre relativ zur Steueränderung (0 = Jahr der Änderung)") ///
           ytitle("Geschätzter Effekt pro Einheit Steueränderung") ///
           xlabel(-3 "t-3" -2 "t-2" -1 "t-1 (Ref)" 0 "t0" 1 "t+1") ///
           legend(off) ///
           graphregion(color(white))

    * Optional: Speichere Graphen
    * graph save "dynamic_cont_treat_`yvar'.gph", replace
    * graph export "dynamic_cont_treat_`yvar'.png", replace width(1600) height(1200)

    restore
}

di "Interpretation: Die Koeffizienten zeigen die geschätzte Änderung in Y für eine Erhöhung"
di "                der Steueränderungs-Variable um eine Einheit, relativ zum Jahr vor der Änderung."
di "                Prüfe die Vorzeichen und Signifikanz der Pre-Treatment Koeffizienten (t-3, t-2) für die Parallel-Trends-Annahme."





*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*--------------------------------------------------------------------------------------------------------------













*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
* Investitionsvariablen analysieren vorab
/*
e_c25130	AfA auf bewegliche Wirtschaftsgüter (Maschinen Kfz)	"ggf. interessant für Reaktionseffekte
Der Wertverlust des Wirtschaftsguts wird über die Nutzungsdauer verteilt und jährlich als Betriebsausgabe in der Einnahmenüberschussrechnung (EÜR) geltend gemacht. Dadurch reduziert sich der Gewinn und somit die Steuerlast des Unternehmens."


(e_c25131	AfA auf immaterielle Wirtschaftsgüter z. B. erworbene Firmen-, Geschäfts- oder Praxiswerte, Software patente und Lizenzen )	ggf. interessant für Reaktionseffekte)

e_c25134	Sonderabschreibungen nach § 7g EStG (in Cent)	"ggf. interessant für Reaktionseffekte Investitionen? 

Diese Sonderabschreibungen sollen kleine und mittlere Unternehmen (Umsatz und Gewinn grenzen existieren) fördern, indem sie ihnen zusätzliche Abschreibungsmöglichkeiten für bestimmte bewegliche Wirtschaftsgüter des Anlagevermögens gewähren. Dadurch können Unternehmen ihre Steuerlast senken und Investitionen? fördern."
e_c25136	AfA auf unbewegliche Wirtschaftsgüter (Grundstücke und gebäude)	ggf. interessant für Reaktionseffekte
e_c25138	Herabsetzungsbeträge nach § 7g Abs. 2 EStG (in Cent)	Wenn ein Wirtschaftsgut, für das Sonderabschreibungen e_c25134 in Anspruch genommen wurden, vor Ablauf der regulären Nutzungsdauer veräußert, entnommen oder auf andere Weise aus dem Betriebsvermögen ausscheidet, müssen die Sonderabschreibungen rückgängig gemacht werden. Dies geschieht durch die Erfassung von Herabsetzungsbeträgen.
e_c25180	Hinzurechnung der Investitionsabzugsbeträge nach § 7g Abs. 2 EStG aus EF3 -3 (in Cent)	"relevant bei Großinvestitionen kleiner U - ggf. nötig wg. vermeintlichem Liquiditätsengpass/gegenteiliger Effekt bei HS-Senkung

Hier werden die Investitionsabzugsbeträge (steuerliches Förderinstrument, das Unternehmen in Deutschland nutzen können, um Investitionen in bewegliche Wirtschaftsgüter des Anlagevermögens zu fördern) hinzugerechnet, die drei Jahre vor dem aktuellen Wirtschaftsjahr abgezogen wurden."
e_c25181	Hinzurechnung der Investitionsabzugsbeträge nach § 7g Abs. 2 EStG aus EF3 -2 (in Cent)	zwei Jahre vor akteullem wirtschaftsjahr
e_c25182	Hinzurechnung der Investitionsabzugsbeträge nach § 7g Abs. 2 EStG aus EF3 -1 (in Cent)	ein Jahr vor aktuellem Wirtshcaftsjahr
e_c25187	Investitionsabzugsbeträge nach § 7g Abs. 1 EStG (in Cent)	Unternehmen knnen einen bestimmten Prozentsatz der voraussichtlichen Anschaffungskosten eines neuen beweglichen Wirtschaftsguts im Voraus von ihrem Gewinn abziehen. Wird danach wieder hinzugerechnet. =Wirtschaftliches Förderinstrument!

e_c25194	Rechts- und Steuerberatung, Buchführung (in Cent)	Messung der Qualität der StB

e_c25199	Summe der Betriebsausgaben (in Cent)	entspricht also Allen Betriebsausgaben

e_c25217	Gewerbesteuer nicht abziehbarer Teil (in Cent)	bezieht sich auf den Teil der gezahlten Gewerbesteuer, der nicht als Betriebsausgabe in der Einnahmenüberschussrechnung (EÜR) abgezogen werden kann.

e_c25218	Gewerbesteuer abziehbarer Teil (in Cent)	bezieht sich auf den Teil der gezahlten Gewerbesteuer, der als Betriebsausgabe in der Einnahmenüberschussrechnung (EÜR) abgezogen werden kann

e_c25225	Erhaltungsaufwendungen (in Cent)	"Frühindikator für Abwanderung bzw. Erstreaktion auf HS-Anpassung
Aufwendungen (Reparaturen,Wartungen und Renovierungen), die zur Erhaltung des Werts und der Funktionsfähigkeit von Wirtschaftsgütern des Anlagevermögens dienen und als Betriebsausgaben in der EÜR abzugsfähig sind."
e_c25281	Fortbildungskosten (ohne Reisekosten) (in Cent)	Frühindikator für Abwanderung bzw. Fostreaktion gsk HS-Anpassung
*/

* Stata-Code zur schnellen Analyse potenzieller abhängiger Variablen für DiD

* 1. Liste der zu analysierenden Variablen definieren
* (Kopiert aus Ihrer Anfrage)
local potential_dvs ///
    e_c25130  /// AfA bewegliche WG
    e_c25131  /// AfA immaterielle WG
    e_c25134  /// Sonderabschreibungen § 7g
    e_c25136  /// AfA unbewegliche WG
    e_c25138  /// Herabsetzungsbeträge § 7g
    e_c25180  /// Hinzurechnung IAB (t-3)
    e_c25181  /// Hinzurechnung IAB (t-2)
    e_c25182  /// Hinzurechnung IAB (t-1)
    e_c25187  /// Investitionsabzugsbeträge (IAB)
    e_c25194  /// Rechts-/Steuerberatung
    e_c25199  /// Summe Betriebsausgaben
    e_c25217  /// GewSt nicht abziehbar
    e_c25218  /// GewSt abziehbar
    e_c25225  /// Erhaltungsaufwendungen
    e_c25281    // Fortbildungskosten

* 2. Schleife zur Analyse jeder Variable
foreach var of local potential_dvs {
    
    di _newline _dup(70) "-" _newline _asis "Analyse für Variable: ///
       `var' (`: variable label `var'') " _newline _dup(70) "-"

    * a) Detaillierte Zusammenfassung (Schlüsselstatistiken)
    summarize `var', detail
    /* Worauf achten?
        - N: Anzahl gültiger Beobachtungen (vs. Gesamtzahl -> Missing Values?)
        - mean, p50 (Median): Vergleich -> Schiefe?
        - Std. Dev.: Gibt es überhaupt Variation? (Wichtig für DV!)
        - min, max, p1, p99: Wertebereich, extreme Ausreißer? Plausibilität?
        - Skewness: Maß für Schiefe (>1 oder <-1 oft relevant)
    */
    
    * b) Schneller Check auf Nullen oder negative Werte (kann je nach Variable ok/nicht ok sein)
    count if `var' <= 0 & !missing(`var')
    di _newline " -> Anzahl Beobachtungen <= 0: " r(N)

    * c) Histogramm zur Visualisierung der Verteilung
    histogram `var', ///
        xtitle("`: variable label `var''") /// // Achsentitel mit Variablenlabel
        title("Verteilung von `var'")      /// // Titel der Grafik
        name("hist_`var'", replace)           // Eindeutiger Name für die Grafik
    /* Worauf achten?
        - Generelle Form: Symmetrisch? Schief? Multimodal?
        - Sichtbare Ausreißer? Häufung bei Null?
    */
    
    * Kurze Pause, um die Ausgabe zu betrachten (optional, entfernen für schnellen Durchlauf)
    * pause "Weiter mit Enter..."

}

di _newline _dup(70) "-" _newline _asis " Analyse abgeschlossen. " _newline _dup(70) "-"













*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*--------------------------------------------------------------------------------------------------------------

* Herausfinden ob ein Unternehmen ein mobiles oder immobiles Unternehmen ist -> gewerbekennzahl

/*
e_wz08	e_ef11	"Abteilung 		(Stelle 1 bis 2)
Gruppe 		(Stelle 1 bis 3)
Klasse		(Stelle 1 bis 4)
Unterklasse 	(Stelle 1 bis 5)
Zusatzschlüssel (Stelle 6)

Bei der Gewerbekennzahl GKZ handelt es sich um einen fünfstelligen Code zur wirtschaftssystematischen Einordnung des Unternehmens nach der Klassifikation der Wirtschaftszweige (WZ 2008) plus Zusatzschlüssel (eine Satzstelle) (in FEF304U2). 
Maßgebend für die Zuordnung zu einem Wirtschaftszweig ist der Schwer-punkt der wirtschaftlichen Tätigkeit eines Unternehmens. Für Zwecke der Steuerstatistiken wird die Systematik in einigen Punkten zusammengefasst. 

Der Zusatzschlüssel (Stelle 6) ist ein Hilfskennzeichen der Finanzverwaltung und enthält weitere Informationen zum Wirtschaftszweig. Er dient den Fachabteilungen bei der Datenaufbereitung. Eine Verwendung für Auswertungen durch den Datennutzer ist daher weder vorgesehen noch sinnvoll."	


*/
* Stata-Code zur allgemeinen Analyse von e_wz08

* Annahme: e_wz08 enthält den 6-stelligen Code.

* Prüfen, ob die Variable numerisch oder String ist
describe e_wz08

* --- Variante 1: Wenn e_wz08 numerisch ist ---
* Extrahieren der ersten 2 Ziffern (WZ 2008 Abteilung)
* Beispiel: 464500 -> 46
generate wz_abteilung_num = floor(e_wz08 / 10000)
label variable wz_abteilung_num "WZ 2008 Abteilung (numerisch extrahiert)"

* Häufigkeitstabelle der Abteilungen
tabulate wz_abteilung_num, nolabel // Zeigt die Codes an
* (Optional: Wenn Labels für die Abteilungen verfügbar sind, diese nutzen)
* codebook wz_abteilung_num // Gibt mehr Details

* --- Variante 2: Wenn e_wz08 ein String ist ---
* Extrahieren der ersten 2 Zeichen (WZ 2008 Abteilung)
* Beispiel: "464500" -> "46"
generate wz_abteilung_str = substr(e_wz08, 1, 2)
label variable wz_abteilung_str "WZ 2008 Abteilung (String extrahiert)"

* Konvertieren zu numerischem Wert für einfachere Vergleiche (optional, aber oft nützlich)
destring wz_abteilung_str, generate(wz_abteilung) force // force ignoriert Fehler, falls nicht alle konvertierbar
label variable wz_abteilung "WZ 2008 Abteilung (aus String konvertiert)"

* Häufigkeitstabelle der Abteilungen
tabulate wz_abteilung // oder tabulate wz_abteilung_str
* codebook wz_abteilung // oder codebook wz_abteilung_str

* --- Bereinigung ---
* Entscheiden Sie, welche Abteilungsvariable Sie behalten möchten (z.B. wz_abteilung)
* drop wz_abteilung_num wz_abteilung_str // Beispiel, falls 'wz_abteilung' erstellt wurde

* Sie können auch feinere Ebenen analysieren, z.B. die ersten 4 Ziffern (Klasse)
* generate wz_klasse = floor(e_wz08 / 100) // Wenn numerisch
* generate wz_klasse_str = substr(e_wz08, 1, 4) // Wenn String
* tabulate wz_klasse // oder wz_klasse_str


/*
chritt 2: Entwicklung einer Mobilitätsvariable

Hier treffen wir nun Annahmen basierend auf den WZ 2008 Abteilungen (erste 2 Ziffern). Wir erstellen eine neue Variable, z.B. unternehmens_mobilitaet, die Kategorien wie "Immobil" (1) und "Mobil" (2) enthält.

Annahmen zur Mobilität nach WZ 2008 Abteilungen (Beispiele - dies müssen Sie ggf. anpassen!):

    Eher Immobil (Code 1):
        A (01-03): Land-/Forstwirtschaft, Fischerei (stark ortsgebunden)
        B (05-09): Bergbau (ortsgebunden an Vorkommen)
        C (10-33): Verarbeitendes Gewerbe (oft große Anlagen, aber teilw. mobil) -> Tendenz Immobil
        D (35): Energieversorgung (Infrastruktur)
        E (36-39): Wasser/Abwasser/Abfall (Infrastruktur)
        F (41-43): Baugewerbe (Baustellen-gebunden, aber Firmen-HQ mobil?!) -> Tendenz Immobil
        G (45-47): Handel, Reparatur (oft physische Läden/Werkstätten) -> Tendenz Immobil
        H (49-53): Verkehr und Lagerei (Infrastruktur, Lager) -> Tendenz Immobil
        I (55-56): Gastgewerbe (Hotels, Restaurants)
        L (68): Grundstücks-/Wohnungswesen (Immobilien-gebunden)
        O (84): Öffentliche Verwaltung (Ortsgebunden)
        P (85): Erziehung/Unterricht (Schulen, Unis)
        Q (86-88): Gesundheits-/Sozialwesen (Kliniken, Heime)
        R (90-93): Kunst/Unterhaltung/Erholung (Ortsgebundene Einrichtungen wie Theater, Parks) -> Tendenz Immobil
        S (94-96): Sonstige Dienstleistungen (Reparatur, Wäschereien, Friseure etc.) -> Tendenz Immobil
        T (97-98): Private Haushalte
        U (99): Exterritoriale Organisationen
    Eher Mobil (Code 2):
        J (58-63): Information und Kommunikation (Software, IT, Medien - oft wenig physische Bindung)
        K (64-66): Finanz-/Versicherungsdienstleistungen (oft digital, HQs verlagerbar)
        M (69-75): Freiberufliche, wiss., technische Dienstl. (Beratung, Forschung - oft personen-/wissensbasiert)
        N (77-82): Sonstige wirtschaftl. Dienstl. (Vermietung, Reisebüros, Verwaltung - oft Büro-basiert)


*/


* Stellen Sie sicher, dass Sie die numerische Abteilungsvariable 'wz_abteilung' aus Schritt 1 haben.




* Initialisieren der neuen Variable mit Missing (.)
generate unternehmens_mobilitaet = .
label variable unternehmens_mobilitaet "Geschätzte Standortmobilität (1=Immobil, 2=Mobil)"

* Zuweisung basierend auf WZ 2008 Abteilungen

* Eher IMMOBIL (Code 1)
replace unternehmens_mobilitaet = 1 if inlist(wz_abteilung, 1, 2, 3) // A
replace unternehmens_mobilitaet = 1 if inrange(wz_abteilung, 5, 9) // B
replace unternehmens_mobilitaet = 1 if inrange(wz_abteilung, 10, 33) // C
replace unternehmens_mobilitaet = 1 if wz_abteilung == 35 // D
replace unternehmens_mobilitaet = 1 if inrange(wz_abteilung, 36, 39) // E
replace unternehmens_mobilitaet = 1 if inrange(wz_abteilung, 41, 43) // F
replace unternehmens_mobilitaet = 1 if inrange(wz_abteilung, 45, 47) // G
replace unternehmens_mobilitaet = 1 if inrange(wz_abteilung, 49, 53) // H
replace unternehmens_mobilitaet = 1 if inrange(wz_abteilung, 55, 56) // I
replace unternehmens_mobilitaet = 1 if wz_abteilung == 68 // L
replace unternehmens_mobilitaet = 1 if wz_abteilung == 84 // O
replace unternehmens_mobilitaet = 1 if wz_abteilung == 85 // P
replace unternehmens_mobilitaet = 1 if inrange(wz_abteilung, 86, 88) // Q
replace unternehmens_mobilitaet = 1 if inrange(wz_abteilung, 90, 93) // R
replace unternehmens_mobilitaet = 1 if inrange(wz_abteilung, 94, 96) // S
replace unternehmens_mobilitaet = 1 if inrange(wz_abteilung, 97, 98) // T
replace unternehmens_mobilitaet = 1 if wz_abteilung == 99 // U


* Eher MOBIL (Code 2)
replace unternehmens_mobilitaet = 2 if inrange(wz_abteilung, 58, 63) // J
replace unternehmens_mobilitaet = 2 if inrange(wz_abteilung, 64, 66) // K
replace unternehmens_mobilitaet = 2 if inrange(wz_abteilung, 69, 75) // M
replace unternehmens_mobilitaet = 2 if inrange(wz_abteilung, 77, 82) // N

* Labels für die Werte definieren (optional, aber gut für Tabellen/Grafiken)
label define mobilitaet_label 1 "Eher Immobil" 2 "Eher Mobil"
label values unternehmens_mobilitaet mobilitaet_label

* Überprüfen der erstellten Variable
tabulate unternehmens_mobilitaet // Häufigkeit der Kategorien
tabulate wz_abteilung unternehmens_mobilitaet, missing // Kreuztabelle zur Kontrolle der Zuweisung


*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*--------------------------------------------------------------------------------------------------------------

* Event windows-> staggered treatment

* Lade deine vorbereiteten Daten
use "$neudatenpfad/Temp/preperation_allyears.dta", clear

*-------------------------------------------------------------------------------
* STEP 1: Identifiziere Treatment-Gruppen und Kontrollgruppe
*-------------------------------------------------------------------------------
* Annahme: "n000100" -> Treatment nur 2017; "n000010" -> Treatment nur 2018; "n000000" -> Nie Treatment
* Passe diese Strings ggf. an deine pattern_tax Definition an!

gen treatment_year = .
replace treatment_year = 2017 if pattern_tax == "n000100" // Gruppe mit Treatment in 2017
replace treatment_year = 2018 if pattern_tax == "n000010" // Gruppe mit Treatment in 2018

gen control_group = (pattern_tax == "n000000") // Kontrollgruppe (nie behandelt)

* Erstelle eine "jemals behandelt"-Variable
gen treated_unit = !missing(treatment_year)

* Behalte nur die relevanten Gruppen
keep if treated_unit == 1 | control_group == 1

* Drop Einheiten, die umgezogen sind (wie in deinem Code)
bysort id (jahr): gen ags_first = ags[1]
bysort id (jahr): gen ags_last = ags[_N]
gen byte moved = (ags_first != ags_last)
drop if moved == 1
drop ags_first ags_last moved

*-------------------------------------------------------------------------------
* STEP 2: Erstelle die Variable für die relative Zeit zum Treatment
*-------------------------------------------------------------------------------
* Diese Variable gibt an, wie viele Jahre vor/nach dem Treatment eine Beobachtung liegt.
* Für die Kontrollgruppe wird sie fehlend (missing) sein.
gen relative_time = jahr - treatment_year

*-------------------------------------------------------------------------------
* STEP 3: Erstelle Dummy-Variablen für jede relative Zeitperiode
*-------------------------------------------------------------------------------
* Wir brauchen Dummies für -3, -2, -1, 0, 1 relativ zum Treatment-Jahr.
* Wichtig: Diese Dummies sind 1 *nur* für behandelte Einheiten in der entsprechenden relativen Periode,
* und 0 für alle anderen (inklusive Kontrollgruppe und andere Perioden der behandelten Einheiten).

* Definiere den gewünschten Zeitrahmen relativ zum Treatment
local event_window_pre = 3 // Anzahl der Perioden vor Treatment (t-3, t-2, t-1)
local event_window_post = 1 // Anzahl der Perioden nach Treatment (t+1) -> t0 ist das Treatmentjahr selbst

* Erstelle die Event-Time Dummies
forvalues k = -`event_window_pre'(1)`event_window_post' {
    gen event_`=subinstr("`k'","-","m",1)' = (relative_time == `k' & treated_unit == 1)
    label var event_`=subinstr("`k'","-","m",1)' "Relative Time = `k'"
}
* Beispiel: event_m3 für t-3, event_m2 für t-2, event_m1 für t-1, event_0 für t0, event_p1 für t+1

* Wähle die Referenzperiode: t-1 (das letzte Jahr VOR dem Treatment)
* Das bedeutet, wir lassen event_m1 in der Regression weg.

* Optional: Überprüfe die erstellten Variablen
* tab relative_time treated_unit
* tab event_m3
* list id jahr treatment_year relative_time event_* if treated_unit==1 & inrange(relative_time, -3, 1)

*-------------------------------------------------------------------------------
* STEP 4: Schätze das Event Study Modell mit reghdfe
*-------------------------------------------------------------------------------
* Modell: Y_it = alpha_i + gamma_t + SUM[delta_k * EventDummy_k] + epsilon_it
* alpha_i: Einheiten-Fixed-Effects (ags)
* gamma_t: Zeit-Fixed-Effects (jahr)
* EventDummy_k: Die oben erstellten Dummies für relative Zeit (event_m3, event_m2, event_0, event_p1)
* delta_k: Die Koeffizienten, die den DiD-Effekt k Perioden relativ zum Treatment messen (vs. t-1)

* Definiere die abhängigen Variablen
local outcomes "e_personalausg stpfgew"

* Definiere die Event-Time Dummies für die Regression (ohne Referenzperiode event_m1)
local event_dummies "event_m3 event_m2 event_0 event_p1" // Lässt event_m1 weg

foreach yvar of local outcomes {
    di "Schätze Modell für: `yvar'"
    reghdfe `yvar' `event_dummies', absorb(ags jahr) vce(cluster ags)

    * Speichere die Ergebnisse für den Plot (alternativ coefplot nutzen)
    matrix b = e(b)
    matrix V = e(V)

    * Erstelle Datensatz für Plot
    preserve
    clear
    set obs 5 // Anzahl der Punkte im Plot (-3, -2, -1, 0, 1)
    gen rel_time = .
    gen coef = 0
    gen se = 0

    local i = 1
    foreach var of local event_dummies {
        local rt = subinstr("`var'","event_","",1) // Holt "m3", "m2", "0", "p1" etc.
        local rt = subinstr("`rt'","m","-",1)
        local rt = subinstr("`rt'","p","",1)
        
        qui replace rel_time = `rt' in `i'
        qui replace coef = b[1,colsof(b)-colsof(V)+`i'] in `i' // Koeffizient
        qui replace se = sqrt(V[`i',`i']) in `i'          // Standardfehler
        local ++i
    }

    * Füge den Referenzpunkt hinzu (relative_time = -1, coef = 0)
    local ref_period = -1
    qui replace rel_time = `ref_period' in `i'
    qui replace coef = 0 in `i'
    qui replace se = 0 in `i' // SE ist 0 für den normalisierten Referenzpunkt

    * Berechne Konfidenzintervalle
    gen ci_low = coef - invnormal(0.975) * se
    gen ci_high = coef + invnormal(0.975) * se

    * Sortiere nach relativer Zeit für den Plot
    sort rel_time

    * Erstelle den Event Study Plot
    local title_suffix : var label `yvar'
    if "`title_suffix'" == "" {
        local title_suffix "`yvar'"
    }
    
    twoway (scatter coef rel_time, connect(line) color(blue)) /// plot coefficients
           (rcap ci_low ci_high rel_time, color(blue)) /// plot confidence intervals
           (scatter coef rel_time if rel_time == `ref_period', mcolor(red) msymbol(Dh)) /// highlight reference point
           , ///
           yline(0, lpattern(dash) lcolor(black)) /// Nulllinie
           xline(`ref_period'+0.5, lpattern(dash) lcolor(gray)) /// Linie zwischen Pre/Post (zwischen -1 und 0)
           title("Event Study Plot für `title_suffix'") ///
           xtitle("Jahre relativ zur Steuererhöhung (0 = Jahr der Erhöhung)") ///
           ytitle("Geschätzter Effekt (DiD)") ///
           xlabel(-3 "t-3" -2 "t-2" -1 "t-1 (Ref)" 0 "t0" 1 "t+1") /// Achsenbeschriftung
           legend(off) ///
           graphregion(color(white))

    * Optional: Speichere den Graphen
    * graph save "event_study_`yvar'.gph", replace
    * graph export "event_study_`yvar'.png", replace width(1600) height(1200) // Hohe Auflösung für Export

    restore // Gehe zurück zum Originaldatensatz für die nächste Variable
}

di "Hinweis: Negative Koeffizienten vor dem Treatment (t-3, t-2) könnten auf eine Verletzung der Parallel-Trends-Annahme hindeuten."
di "       Moderne Schätzer wie csdid (Callaway & Sant'Anna) können robustere Ergebnisse liefern."


/*

Dein Ziel ist es, die Gruppen, die 2017 oder 2018 eine Steuererhöhung erfahren haben, mit einer Kontrollgruppe zu vergleichen, die nie eine Erhöhung hatte. Dabei sollen die Zeitpunkte relativ zum jeweiligen Treatmentbeginn (-3, -2, -1, 0, 1 Perioden) analysiert und die Effekte gepoolt werden. Die Periode -1 (das Jahr direkt vor der Steuererhöhung) soll als Referenzperiode dienen.

Hier ist ein Vorschlag, wie du deinen Stata-Code anpassen kannst. Ich baue dabei auf deinem bestehenden Code auf, insbesondere der pattern_tax-Variable, die essenziell ist, um die verschiedenen Gruppen zu identifizieren.

Annahmen:

    Dein Datensatz preperation_allyears.dta enthält die Variablen id, jahr, ags, pattern_tax, e_personalausg, stpfgew.
    Die pattern_tax-Variable identifiziert korrekt die Einheiten, die nur 2017 eine Erhöhung hatten (z.B. "n000100"), nur 2018 eine Erhöhung hatten (z.B. "n000010"), und die, die nie eine Erhöhung hatten ("n000000"). Passe die Pattern-Strings unten ggf. an deine spezifischen Daten an.
    Du möchtest die Effekte für 3 Perioden vor (-3, -2, -1), das Treatmentjahr (0) und 1 Periode nach (+1) dem jeweiligen Treatmentbeginn schätzen, wobei Periode -1 die Referenz ist.

Erläuterungen zum Code:

    Treatment-Gruppen definieren: Es wird eine Variable treatment_year erstellt, die das Jahr der erstmaligen Steuererhöhung für die betreffenden Gruppen speichert. Eine control_group-Variable identifiziert die nie behandelten Einheiten.
    Relative Zeit: Die Variable relative_time berechnet für jede Beobachtung einer behandelten Einheit den Abstand zum treatment_year.
    Event-Time Dummies: Für jeden relevanten Zeitpunkt relativ zum Treatment (-3, -2, -1, 0, +1) wird eine Dummy-Variable (event_m3, event_m2, event_m1, event_0, event_p1) erstellt. Diese ist nur dann 1, wenn eine Einheit behandelt wurde und sich im entsprechenden relativen Jahr befindet. Für die Kontrollgruppe sind diese Dummies immer 0.
    Referenzperiode: event_m1 (das Jahr vor dem Treatment) wird als Referenzperiode gewählt und daher in der Regression weggelassen. Die Koeffizienten der anderen Event-Dummies messen den Effekt relativ zu diesem Zeitpunkt.
    Regression (reghdfe): Das Modell schätzt die abhängige Variable (e_personalausg oder stpfgew) auf die Event-Time Dummies unter Kontrolle von Einheiten-Fixed-Effects (absorb(ags)) und Zeit-Fixed-Effects (absorb(jahr)). Die Standardfehler werden auf der Ebene der Einheit (ags) geclustert.
    Plotting: Nach jeder Regression werden die Koeffizienten und Standardfehler extrahiert. Es wird ein temporärer Datensatz erstellt, der die relative Zeit, den Koeffizienten und das Konfidenzintervall enthält. Wichtig ist, den Referenzpunkt (relative Zeit -1, Koeffizient 0) manuell hinzuzufügen. Schließlich wird twoway verwendet, um den typischen Event Study Plot zu erzeugen.

Wichtige Überlegungen:

    Pattern Definition: Stelle sicher, dass die Strings ("n000100", "n000010", "n000000") exakt die Gruppen repräsentieren, die du untersuchen möchtest (insbesondere keine weiteren Steueränderungen in anderen Jahren für diese Gruppen).
    Parallel Trends Annahme: Der Plot ist entscheidend, um die Parallel-Trends-Annahme vor dem Treatment zu prüfen. Die Koeffizienten für event_m3 und event_m2 sollten idealerweise nahe bei Null und statistisch nicht signifikant sein. Wenn sie signifikant von Null abweichen, deutet das auf Probleme mit der Annahme hin.
    Moderne DiD-Methoden: Wie im Code erwähnt, gibt es bei gestaffeltem Treatment Timing potenzielle Probleme mit der klassischen Two-Way Fixed Effects (TWFE) Schätzung (wie hier mit reghdfe implementiert), insbesondere wenn die Behandlungseffekte über die Zeit variieren. Methoden wie die von Callaway & Sant'Anna (ssc install csdid), Sun & Abraham (ssc install eventstudyinteract) oder Borusyak et al. (ssc install did_imputation) sind oft robuster. Der hier gezeigte Code ist jedoch eine direkte Umsetzung deiner Anfrage mit reghdfe und eine gute Grundlage.
    Fenstergröße: Du hast -3 bis +1 Perioden angefragt. Stelle sicher, dass du genügend Datenpunkte für alle Gruppen in diesen relativen Zeitfenstern hast.

Dieser Code sollte dir die gewünschte Event-Study-Analyse und die dazugehörigen Plots liefern. Lass mich wissen, wenn du Anpassungen brauchst oder Fragen hast!




*/












*******************************
*******************************

id im letzten Jahr drüber?

*******************************
*******************************


* Sicherstellen, dass die Daten als Panel definiert sind
xtset id jahr

* Schritt 1: Eine temporäre Variable erstellen, die NUR im letzten Jahr für jede ID 1 ist, wenn hebesatz > 380 ist, und 0 sonst. In allen anderen Jahren ist diese Variable missing (.).
* Wir sortieren nach id und jahr, um sicherzustellen, dass _n und _N korrekt sind und die letzte Beobachtung identifiziert werden kann.
bysort id (jahr): generate byte temp_hebesatz_check = (hebesatz > 380) if _n == _N

* Erklärung zu Schritt 1:
* `bysort id (jahr)`: Sortiert die Daten nach 'id' und innerhalb jeder ID nach 'jahr'.
* `generate byte temp_hebesatz_check`: Erstellt eine neue Variable vom Typ byte (speichereffizient für 0/1 Werte).
* `(hebesatz > 380)`: Die Bedingung, die wir prüfen wollen. Der Ausdruck liefert 1, wenn wahr, und 0, wenn falsch.
* `if _n == _N`: Diese Bedingung stellt sicher, dass der vorhergehende Ausdruck NUR für die letzte Beobachtung ('_n' ist die aktuelle Beobachtungsnummer innerhalb der Gruppe, '_N' ist die Gesamtzahl der Beobachtungen in der Gruppe) jeder ID ausgewertet wird. Für alle anderen Beobachtungen (die nicht das letzte Jahr sind) wird `temp_hebesatz_check` missing (system missing value, .) sein.

* Schritt 2: Die Information aus dem letzten Jahr auf alle Jahre für dieselbe ID übertragen.
* Wir nutzen 'egen' mit der Funktion 'max()' über die ID hinweg. 'egen max()' ignoriert fehlende Werte standardmäßig. Da 'temp_hebesatz_check' nur im letzten Jahr einen Wert (0 oder 1) hat und sonst missing ist, wird 'max()' einfach diesen Wert aus dem letzten Jahr für die gesamte Gruppe (ID) zurückgeben.
bysort id: egen byte hebesatüber380imletztenJahr = max(temp_hebesatz_check)

* Erklärung zu Schritt 2:
* `bysort id`: Sorgt dafür, dass 'egen' die Operation für jede ID separat durchführt.
* `egen byte hebesatüber380imletztenJahr`: Erstellt die finale Variable. 'egen' wird verwendet, weil es Gruppensummen oder -statistiken berechnen und auf die gesamte Gruppe anwenden kann.
* `max(temp_hebesatz_check)`: Berechnet den Maximalwert der temporären Variable innerhalb jeder ID. Da 'temp_hebesatz_check' nur im letzten Jahr einen Nicht-Missing-Wert hat, ist das Maximum entweder 0 oder 1, je nachdem, ob der Hebesatz im letzten Jahr <= 380 oder > 380 war. Dieser Maximalwert wird dann für alle Zeilen der jeweiligen ID zugewiesen.

* Optional: Temporäre Variable löschen, da wir sie nicht mehr brauchen
drop temp_hebesatz_check

* Jetzt hat die Variable 'hebesatüber380imletztenJahr' für alle Beobachtungen derselben ID denselben Wert (1 oder 0), basierend auf dem Hebesatz im letzten beobachteten Jahr dieser ID.

* Du kannst es überprüfen, z.B. für eine spezifische ID:
* list id jahr hebesatz hebesatüber380imletztenJahr if id == deine_id_nummer

* Oder schaue dir die Verteilung der neuen Variable an:
* tabulate hebesatüber380imletztenJahr

* Oder verifiziere, dass der Wert innerhalb jeder ID konstant ist:
* bysort id: tabulate hebesatüber380imletztenJahr

*-----------------------------------------------------------------------
*SCHWELLE WIRD ÜBERSCHRITTEN CHECK
* Sicherstellen, dass die Daten als Panel definiert sind
xtset id jahr

* Schritt 1: Hebesatz-Wert aus dem ersten Jahr für jede ID abrufen und auf alle Jahre der ID übertragen
* Wir sortieren die Daten zuerst nach id und dann nach jahr aufsteigend.
* Innerhalb jeder ID greifen wir dann mit hebesatz[1] auf den Wert im ersten Jahr zu.
* Stata weist diesen Wert automatisch allen Beobachtungen (Jahren) innerhalb der aktuellen bysort-Gruppe (ID) zu.
bysort id (jahr): generate double first_year_hebesatz = hebesatz[1]

* Schritt 2: Hebesatz-Wert aus dem letzten Jahr für jede ID abrufen und auf alle Jahre der ID übertragen
* Wieder sortieren wir nach id und jahr.
* Innerhalb jeder ID greifen wir mit hebesatz[_N] auf den Wert im letzten Jahr zu (_N ist die Gesamtzahl der Beobachtungen in der aktuellen Gruppe/ID).
* Stata weist diesen Wert ebenfalls allen Beobachtungen innerhalb der ID zu.
bysort id (jahr): generate double last_year_hebesatz = hebesatz[_N]

* Erklärung zu Schritt 1 & 2:
* `bysort id (jahr)`: Sortiert die Daten nach 'id' und innerhalb jeder ID nach 'jahr'. Die Klammern um 'jahr' bedeuten, dass innerhalb jeder ID nach 'jahr' sortiert wird, was für die Identifizierung des ersten (`[1]`) und letzten (`[_N]`) Jahres entscheidend ist.
* `generate double ...`: Erstellt die neuen Variablen. Wir verwenden `double`, um sicherzustellen, dass der Hebesatz-Wert korrekt gespeichert wird (obwohl es hier wahrscheinlich auch float tun würde). Stata füllt diese Variable für jede Zeile der aktuellen `bysort`-Gruppe (ID) mit dem entsprechenden Wert (erster oder letzter Hebesatz).

* Schritt 3: Neue Variable erstellen, die prüft, ob Hebesatz im ersten Jahr < 380 UND im letzten Jahr > 380 war.
* Da die Variablen `first_year_hebesatz` und `last_year_hebesatz` für alle Beobachtungen derselben ID denselben Wert haben, wird die Bedingung (`... < 380) & (... > 380)`) für alle Beobachtungen derselben ID entweder überall wahr (1) oder überall falsch (0) sein.
generate byte schwelle_380_ueberschritten = (first_year_hebesatz < 380) & (last_year_hebesatz > 380)

* Erklärung zu Schritt 3:
* `generate byte ...`: Erstellt die finale Variable vom Typ byte (effizient für 0/1).
* `(first_year_hebesatz < 380)`: Prüft die erste Bedingung.
* `&`: Das logische UND. Beide Bedingungen müssen wahr sein.
* `(last_year_hebesatz > 380)`: Prüft die zweite Bedingung.
* Das Ergebnis dieser logischen Kombination (1 wenn beide wahr, 0 sonst) wird der neuen Variable zugewiesen. Da die Werte der beteiligten Variablen innerhalb der ID konstant sind, ist auch das Ergebnis der Prüfung innerhalb der ID konstant.

* Optional: Temporäre Variablen löschen, da wir sie nicht mehr brauchen
drop first_year_hebesatz last_year_hebesatz

* Jetzt hat die Variable 'schwelle_380_ueberschritten' für alle Beobachtungen derselben ID den Wert 1, wenn die Schwelle von 380 im Zeitverlauf dieser ID überschritten wurde (d.h. im ersten Jahr darunter lag und im letzten Jahr darüber), und sonst den Wert 0 für alle Beobachtungen dieser ID.

* Du kannst das Ergebnis überprüfen, z.B. durch Auflisten einiger Daten:
* list id jahr hebesatz schwelle_380_ueberschritten in 1/30

* Oder schaue dir die Verteilung der neuen Variable an:
* tabulate schwelle_380_ueberschritten

* Oder verifiziere, dass der Wert innerhalb jeder ID konstant ist:
* bysort id: tabulate schwelle_380_ueberschritten
* bysort id: summarize schwelle_380_ueberschritten















/*
UPDATE INFO


--------------------
Wann erfahren Unternehmen typischerweise von der Steuererhöhung das erste Mal? Ergibt es Sinn bereits im Juni wenn veröffentlicht werden sollte etwas anzupassen ? Wenn ja was?



ACHTUNG WICHTIGE ANPASSUNG:
Kapgesellschaft hat immer effekte und ne auswirkung.

Personengesellschaften. Wenn Hebesatz unter 380  Bekommen bei Einkommenssteuer nachlass zu gezahlter Gewerbesteuer.
Paragraph 35 Estg.

Zu den negativen e_personalausgaben:
EÜR betrachtet Geldflüsse
e_personalausg
EÜR bilden Geldströme ab also ergibt Rückstellung nicht viel Sinn, sonst Rückestattung von Versicherungsbeiträgen, Sozialversicherungsbeiträge.


HETEROGENITÄT :
Heterogenität gut vs nicht gut aufgestellte Unternehmen:
Gut auf gestellte vs nivht so gut aufgestlellt untenrhemn. Investitionen kann in beide richtungen gehen. Iwie identifizieren:
Summe betriebseinnahmen und betriebsausgaben anschauen! Verhältnis, wie veärndert sich marge?

Weitere Variable: Entgelte für Schulden anschauen, betrachte Zinssatz!

Bilanzposten sind leider nicht enthalten, deshalb kann man auch nicht so genaue Angaben machen!

Heterogenität Investitionsabzug
Kontroll: Investitionsabzugsbetrag (Als Kontrollvariable), wenn kleines unternehmen und große Investition tätigen, dann begünstigt abschreiben. Bei kleinen Unternehmen gewinn verändert oder Verlust!


Heterogenität Mobil und Immobil:
Mobil und immobile: -> leaf out kann man nicht wirklich etwas dazu sagen.



Welche Unternehmen sollten in Analyse mitaufgenommen werden?
GbR hängt vom Unternehmenszwekc ab, wenn man es als Privatperson betreibt, bspw immobilensektor, dann keine Gewerbesteuer g_fef303 

Rechtsform
11-19 zahlt nicht
29 zahlt auch nicht

Körperschaften

Ab 29 raus 
Ab 30 Kapitalgesellschaften.

Ersmal nur 20,21,22,27  und 28 noch rein.


Bei mischformem ist persgesell aktive gesellschaft. Haften tut kapitalgesllschaft, auf laufende iEinküfte wird einkommenssteur gezahlt. Kapgesellschaft kassiert haftungsvergütung. Diese kann hoch sein, 
Via Höhe gewerbesteuer schauen welche man auch rausnimmt, könnte sein dass sie keine Gewerbesteuer zahlt. ABER es wird erst Gewerbesteuer gezahlt und dann die Vergütung. Dann lasse ich das raus. -> Mischformen erstmal pauschal rauslassen!

Kontorllvariablen:

Größenklasse

Wirtschaftszweig

Wirtschaftliche gut vs schletlaufend. 

Steuerberaterkosten: Effekte wenn ich niedrige oder hohe Steuerberaterkosten habe. werde ich gut oder schlecht beraten? Könnte es sein. Wenn niedriger betrag dann evtl nur ein buchhalter und keinen steuerberater…


Im Vergleich die Kapitalgesellschaften mit reinnehmen.-> Wie als Vergleichsgruppe nutzbar?

Laufende Abschreibung auf bewegliche und unbewegliche -> evtl dafür kontrollieren.




Abhängige Variablen was ergibt Sinn?

gen sigln_g_reing = sign(g_reing)* ln(abs(g_reing)+1) // ohne _trun wie beim rest für einheitlichkeit


gen ln_inv = ln(e_c25187)  // Investitionsabzugsbeträge -> sollten wohl sinken
gen ln_son = ln(e_c25134)  // Sonderabschreibungen 7g -> gibt es vermutlich nicht im entsprechenden Zeitraum , fraglich ob sinnvoll
gen ln_afa_bwg = ln(e_c25130)  // Afa bewegliche WG -> vermutlich verzögerter Effekt
gen ln_afa_ubwg = ln(e_c25136)  // Afa unbewegliche WG -> ebenso verzögerter Effekt
gen ln_erhauf= ln(e_c25225) // Erhaltungsaufwendungen , nur pos Werte -> sofort in voller Höhe, direkter Effekt

gen ln_steube = ln(e_c25194) // Steuerberatung, nur pos Werte -> pos Effekt, da Steuerumschichtung ?
gen sigln_p_einge = sign(p_ef34)* ln(abs(p_ef34)+1)  // Einkünfte aus Gewerbebetrieb, verläuft proportional, sollte sich decken





*/
