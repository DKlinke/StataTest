*-------------------------------------------------------------------------------------------------------------------
*   Project Title: THE DETERMINANTS OF TAX COMPLIANCE
*	Code: Analyze full_gwap.dta
/* 
 04_DATUM_DiDEvent.do Schätzt erste DiD bzw EventStudien mit zuvor festgelegter Ziel Variable

******************************************************************
* Umbenannte Variablen 		 									 *
****************************************************************** 
	rename e_c25120 e_personalausg
 */
*-------------------------------------------------------------------------------------------------------------------

*-------------------------------------------------------------------------------------------------------------------

// Vorab über Kette der Programm 00 und 01 02 laufen lassen, oder direkt durchlaufen lassen
	use "$neudatenpfad/Temp/preperation.dta", clear
	rename e_c25120 e_personalausg  // Umbenennung übertragen in 03_... .do File
	
	
	
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

	tabulate negative bundesland,col
	tabulate negative rechtsform, col // Rechtsform des Unternehmens


// gaps im Panel
	xtdescribe
	xtdescribe, patterns(150) // Zeigt die häufigsten Muster an.

	
	
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

* STEP 1: Code für Pattern

	// Pattern für Steuererhöhung(=1) keine Veränderung (=0) Verringerung (=-1). Für 2013 keine Veränderung berechenbar weil es sich um das erste Jahr handelt (=n) by id (ist ähnlich zu pattern, das man mit xtdescribe erhält). Der Code ist so geschrieben, dass auch für variable ranges von Jahren funktioniert, insofern keine Lücken enthalten sind. Wenn ausgewählte Jahre nicht vorhanden sind, dann wird "." eingefügt.
	
	summarize jahr, meanonly // festlegen der range(also Jahre)
	local max = r(max)
	local min = r(min)
	local range = r(max) - r(min) + 1
	local miss : display _dup(`range') "." //  string an Punkten kreieren entsprechend der range
	bysort id (jahr) : gen that = "" 
	
	// Erstes vorkommende Jahr in der range
	bysort id (jahr) : replace that = substr("`miss'", 1, jahr[1]-`min') + "n" if _n == 1 & missing(taxhike) // n fürfür change not computable (da erstes Jahr)
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



* STEP 2: Behandlungs und Kontrollgruppe festlegen

	* keep if substr(pattern_tax, 1, 3) == "11."  // behält patterns like "11.1...", "11....", etc.
	* keep if substr(pattern_tax, strlen(pattern_tax)-2, 3) == "11."  // behält patterns like "...11.", ".1.11."
	*keep if inlist(pattern_tax, "n000000", "n000100")
	*save "$neudatenpfad/Temp/preperation_xxxx.dta", replace

	gen treat = 1 if inlist(pattern_tax, "n000100") // von 2013 bis 2019 beobachtbar, taxchange nur im Jahr 2017, und in den anderen Jahren keine Veränderung
	replace treat = 0 if inlist(pattern_tax, "n000000") // von 2013 bis 2019 beobachtbar, kein taxchange in keinem der Jahre von 2013 bis 2019
	gen post = (jahr >= 2018) // 1 ab 2018
	gen treat_post = treat * post 
	
/*
	drop treat
	drop treat_post
	drop post
	gen treat = 1 if inlist(pattern_tax, "n001000") // von 2013 bis 2019 beobachtbar, taxchange nur im Jahr 2016, und in den anderen Jahren keine Veränderung
	replace treat = 0 if inlist(pattern_tax, "n000000")
	gen post = (jahr >= 2017)  // 1 ab 2017
	gen treat_post = treat * post 

*/

* STEP 3: DiD schätzen


xtreg Y Behandlung Post Behandlung_Post, fe robust

reghdfe Y Behandlung Post Behandlung_Post, absorb(id jahr) vce(robust)




























	xtreg stpfgew treat post treat_post, fe
	xtreg e_personalausg treat post treat_post, re
	xtreg g_reings treat post treat_post, re // Problem bei Erst ellung behoben?
	
	xtreg e_personalausg treat post treat_post, re
	reghdfe e_personalausg treat_post, a(treat jahr)
	reghdfe e_personalausg treat_post, a(treat jahr) vce(cluster treat)
	
	reghdfe g_reings treat_post, a(treat jahr) vce(cluster treat) // Problem bei Erstellung behoben?
	
	
/*
* Create treatment variable
g Treated = state == "California" & ///
  inlist(quarter, "Q32011","Q42011","Q12012")

* We will use reghdfe which must be installed with
* ssc install reghdfe
reghdfe rate Treated, a(state quarter) vce(cluster state)

*/


// weitere abhängige Variablen




//"dynamic" DiD graphs


* Interact being in the treated group with jahr, 
* using ib2017 to drop the trepective year (the last one before treatment)
	reghdfe e_personalausg treat##ib2017.jahr, a(treat jahr) vce(cluster treat)



	/* Visualisation
	* Pull out the coefficients and SEs
	g coef = .
	g se = .
	forvalues i = 2013(1)2019 {
		replace coef = _b[1.treat#`i'.jahr] if jahr == `i'
		replace se = _se[1.treat#`i'.jahr] if qjahr == `i'
	}

	* Make confidence intervals
	g ci_top = coef+1.96*se
	g ci_bottom = coef - 1.96*se

	* Limit  to one observation per jahr
	duplicates drop

	* Create connected scatterplot of coefficients
	* with CIs included with rcap 
	* and a line at 0 from function
	twoway (sc coef jahr, connect(line)) ///
	  (rcap ci_top ci_bottom jahr) ///
		(function y = 0, range(1 6)), xtitle("Jahr") ///
		caption("95% Confidence Intervals Shown")
	restore
	*/












*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block III:  ado Files die genutzt werden können für die Analyse mit DiD und Event am GWAP und ToDo
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
// Prüfe Fehler bei Generierung von e_reings *xtreg e_reings treat post treat_post, re
// Gib NA seperat aus
