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


	gen treat = 1 if inlist(pattern_tax, "n000100") // von 2013 bis 2019 beobachtbar, taxchange nur im Jahr 2017, und in den anderen Jahren keine Veränderung
	replace treat = 0 if inlist(pattern_tax, "n000000") // von 2013 bis 2019 beobachtbar, kein taxchange in keinem der Jahre von 2013 bis 2019
	
/*	nur für testdaten
	gen treat = 0
	replace treat = 1 if inlist(pattern_tax, "......n",".....n.","n......") else treat = 0
*/
	
	
	gen post = (jahr >= 2017) // 1 ab 2017 da nach § 16(3) GewStg, Erhöhung bis 30.Juni des Vorjahres festgelegt worden sein muss und entsprechend von Unternehmen antizipiert werden kann. Erhöhung gilt dann zum 1. eines Jahres
	gen treat_post = treat * post 
	
	
	drop if missing(treat) // Droppe alle die nicht relevant sind
	by id (ags), sort: gen byte moved = (ags[1] != ags[_N]) // solche ids die unterschiedliche ags haben, sich also dem treatment potentiell (un)absichtlich entziehen werden gedropped
	tab pattern_tax moved, col
	drop if moved == 1

	
/* Weitere Auswahlmöglichkeiten
	* keep if substr(pattern_tax, 1, 3) == "11."  // behält patterns like "11.1...", "11....", etc.
	* keep if substr(pattern_tax, strlen(pattern_tax)-2, 3) == "11."  // behält patterns like "...11.", ".1.11."
	*keep if inlist(pattern_tax, "n000000", "n000100")
	*save "$neudatenpfad/Temp/preperation_xxxx.dta", replace
*/






*----------------------------------------------------------------------------------------------------------------
*---
* 		STEP 3.1: DiD schätzen
*---
*----------------------------------------------------------------------------------------------------------------

// Y_it = β₀ + β₁ * treat_post_it + α_i + γ_t + ε_it  wobei α_i fixed effect für die ags sind und γ_t fixed effekt für jahr ist und treat_post_it ein Dummy, wenn in post period und treatment gruppe!

/*
The tax hike indicator equals one if at time t municipality m increased the LBT.  specifications additionally can  include 
firm fixed effects (μi) and year fixed effects at the level of industries (ψs,t) and federal states (ϕl,t) to flexibly control for any time-invariant heterogeneity or systematic 
time trends in the probability of investment revisions and the frequency of tax hikes. 
In these specifications, we obtain a (generalized) difference-in-difference (DiD)
estimate.Standard errors are clustered at the municipality level.

*/

//Option 1
	reghdfe e_personalausg treat_post, a(ags jahr) vce(cluster ags) // drops 170 singleton observations
	
	/* identify singleton via
	gen nonmissing= !missing(e_personalausg) & !missing(treat_post)
	bys id: egen count= total(nonmissing)
	browse if count<2
	*/	
	reghdfe stpfgew treat_post, a(ags jahr) vce(cluster ags)

//Option 2 (singletons werden nicht gelöscht)
	encode ags, gen(ags_numeric)
	encode jahr, gen (jahr_numeric)
	xtreg e_personalausg treat_post i.ags_numeric i.jahr, fe robust cluster(ags)  
	
	
/*
Okay, lass uns das aufschlüsseln.

**Was sind Singleton Observations im Kontext von Fixed Effects (FE)?**

Im Kontext von Paneldaten oder Modellen mit Gruppen-Fixed-Effects (wie hier mit `ags` und `jahr`) bezieht sich eine "Singleton Observation" (Einzelbeobachtung) auf eine Beobachtung, die **innerhalb ihrer durch die Fixed Effects definierten Gruppe allein steht**, nachdem fehlende Werte in den Regressionsvariablen berücksichtigt wurden.

Konkret bedeutet das im `reghdfe`-Kontext mit `a(ags jahr)`:

1.  **Identifizierung der Gruppen:** Das Kommando betrachtet die Gruppen, die durch die Kombination der Fixed Effects (`ags` und `jahr`) entstehen. Jede einzigartige Kombination von `ags` und `jahr` könnte theoretisch eine Gruppe sein, oder `reghdfe` kann die Fixed Effects auch sequentiell "absorbieren". Wichtiger ist aber das zugrundeliegende Prinzip für die Identifikation der Koeffizienten.
2.  **Problem der Fixed Effects Schätzung:** Fixed-Effects-Modelle (sowohl `reghdfe` als auch `xtreg, fe`) eliminieren zeitinvariante Störfaktoren, indem sie die Daten quasi "innerhalb" jeder Gruppe betrachten (mathematisch durch De-Meaning oder eine äquivalente Transformation). Um den Effekt von `treat_post` zu schätzen, braucht das Modell **Variation von `treat_post` *innerhalb* der relevanten Gruppe**.
3.  **Singleton = Keine Variation:** Wenn eine Gruppe (definiert durch die Fixed Effects) nach Berücksichtigung fehlender Werte nur noch aus einer einzigen Beobachtung besteht, gibt es *keine* Variation innerhalb dieser Gruppe. Der Fixed Effect für diese Gruppe würde diese eine Beobachtung perfekt erklären. Diese Beobachtung liefert daher **keine Information** zur Schätzung des Koeffizienten von `treat_post` (oder anderen Variablen, die nicht konstant innerhalb der Gruppe sind).
4.  **`reghdfe`'s Umgang:** `reghdfe` ist darauf ausgelegt, mit sehr vielen Fixed Effects effizient umzugehen. Es identifiziert diese Singletons (und oft auch Gruppen, in denen eine der Variablen keine Variation aufweist) explizit und **entfernt sie** aus der Schätzung, da sie mathematisch sowieso keinen Beitrag zur Identifikation der Koeffizienten leisten würden. Deshalb gibt es die Meldung "drops X singleton observations". Es teilt dir mit, wie viele Beobachtungen aufgrund dieser Struktur für die *Koeffizientenschätzung* unbrauchbar waren.

**Unterschied zwischen `reghdfe` und `xtreg, fe` bezüglich Singletons:**

* **Option 1: `reghdfe e_personalausg treat_post, a(ags jahr) vce(cluster ags)`**
    * **Verhalten:** Absorbiert die Fixed Effects für `ags` und `jahr` mithilfe spezieller Algorithmen. Identifiziert explizit Beobachtungen, die aufgrund der FE-Struktur (Singletons) keine Information zur Schätzung von `treat_post` liefern. **Meldet und entfernt** diese Beobachtungen aus der Analyse, die zur Berechnung der Koeffizienten verwendet wird.
    * **Meldung:** `drops 170 singleton observations` – Diese 170 Beobachtungen fielen in Gruppen (definiert durch die `ags`-`jahr`-Struktur), die nach Bereinigung um Missing Values nur diese eine Beobachtung enthielten oder anderweitig keine Variation für die Schätzung boten. Sie wurden für die Koeffizientenschätzung nicht verwendet.
    * *Dein Identifikations-Code-Snippet:* Dieser Code versucht, Singletons auf Basis einer Variable `id` (vermutlich die Panel-ID) zu finden, indem er prüft, ob es weniger als zwei *gültige* Beobachtungen (`nonmissing`) pro `id` gibt. Das ist *eine* mögliche Ursache für Singletons im FE-Kontext, aber `reghdfe`'s Definition bezieht sich auf die Gruppenstruktur der *absorbierten Fixed Effects* (`ags`, `jahr`). Es könnte auch sein, dass eine bestimmte `ags`-`jahr`-Kombination nur einmal vorkommt.

* **Option 2: `xtreg e_personalausg treat_post i.ags_numeric i.jahr_numeric, fe robust cluster(ags)`**
    * **Verhalten:** Dies ist Stata's Standard-Fixed-Effects-Paneldaten-Schätzer. Er führt intern ebenfalls eine Transformation durch (typischerweise De-Meaning), um die Fixed Effects zu eliminieren. Mathematisch gesehen werden Singletons durch diese Transformation ebenfalls uninformativ (alle Variablen werden zu Null nach dem De-Meaning innerhalb einer Singleton-Gruppe).
    * **Meldung:** `xtreg, fe` **meldet das Entfernen von Singletons normalerweise nicht** so explizit wie `reghdfe`. Die Beobachtungen bleiben technisch gesehen Teil des Datensatzes, der an die Prozedur übergeben wird. Sie tragen jedoch aufgrund der internen Fixed-Effects-Transformation (De-Meaning) **nichts** zur Schätzung des Koeffizienten von `treat_post` bei.
    * **"singletons werden nicht gelöscht":** Diese Anmerkung in deinem Code ist insofern richtig, als dass `xtreg` keine explizite Meldung ausgibt, dass sie *ignoriert* oder *gedroppt* wurden. Sie sind aber für die *Schätzung der Steigungskoeffizienten* (wie den von `treat_post`) genauso irrelevant wie bei `reghdfe`. Sie fließen eventuell noch in die Berechnung der Gesamt-Freiheitsgrade ein, was zu minimal anderen Werten bei F-Statistik oder R² führen kann, aber der geschätzte Koeffizient für `treat_post` sollte (abgesehen von numerischen Präzisionsunterschieden) sehr ähnlich sein, da die zugrundeliegende Identifikationsstrategie dieselbe ist.

**Zusammenfassend:**

* **Singletons:** Beobachtungen, die innerhalb ihrer durch die Fixed Effects definierten Gruppe allein stehen und somit keine Variation für die FE-Schätzung liefern.
* **`reghdfe`:** Identifiziert, meldet und entfernt diese für die Koeffizientenschätzung unbrauchbaren Singletons explizit.
* **`xtreg, fe`:** Macht Singletons durch die interne FE-Transformation ebenfalls unbrauchbar für die Koeffizientenschätzung, meldet dies aber üblicherweise nicht explizit.

Der Hauptunterschied liegt also im **expliziten Reporting und Handling** durch den Befehl, nicht darin, ob Singletons *grundsätzlich* zur Schätzung der Koeffizienten in einem FE-Modell beitragen können (das können sie in beiden Fällen nicht). `reghdfe` ist hier transparenter.


*/


// weitere abhängige Variablen testen?



*----------------------------------------------------------------------------------------------------------------
*---
* 		STEP 3.2: Dynamic DiD long term effects (each year, heterogeneous treatment effect) schätzen
*---
*----------------------------------------------------------------------------------------------------------------
preserve 

	* Interact being in the treated group with jahr, use ib3 to drop (the last jahr before treatment)
	reghdfe e_personalausg treat##ib2016.jahr, a(ags jahr) vce(cluster ags)

	g coef = .
	g se = .
	forvalues i = 2013(1)2019 {  //ggf. Jahre anpassen
		replace coef = _b[1.treat#`i'.jahr] if jahr == `i'  
		replace se = _se[1.treat#`i'.jahr] if jahr == `i'
	}
	
	* Confidence intervals
	g ci_top = coef+1.96*se
	g ci_bottom = coef - 1.96*se

	* Nur eine observation pro Jahr behalten
	keep jahr coef se ci_*
	duplicates drop

	* Create connected scatterplot of coefficients
	* with CIs included with rcap 
	* and a line at 0 from function
	
	sort jahr  // hinzugefügt
	twoway (sc coef jahr, connect(line)) ///  Plottete geschätzte coeffizienten (also dependent variable) gegen zeit, ohne Verbindung einfach twoway (sc coef jahr)
	  (rcap ci_top ci_bottom jahr) ///
		(function y = 0, range(2013 2019)), xline(2016.5, lpattern(dash) lcolor(black)) xtitle("Jahr") /// horizontale Linie und verticale Linie wird hinzugefügt
		caption("95% Confidence Intervals Shown") ///
		legend(off) /// Legende ausblenden
restore










// Warum sollte es einen Effekt geben? -> Antwort Für die Dynamische DiD Schätzung auch noch für unterschiedliche patterns durch. Vergleiche zum Beispeil n000000 mit n001000 oder n010000 oder n000010







// Lasse das Jahr 2013 komplett weg bei Grafik und Berechnung und auch bei Tests ob Pre Trends erfüllt sind ? 


//OPTION1:

preserve

    // *** Änderung 1: Füge 'if jahr != 2013' zur Regression hinzu ***
    reghdfe e_personalausg treat##ib2016.jahr if jahr != 2013, a(ags jahr) vce(cluster ags)

    // Nach der Regression, prüfe die Koeffizientennamen (insbesondere für die Interaktionen)
    // mit: ereturn display

    g coef = .
    g se = .
    // *** Änderung 2: Passe die Schleife an, um 2013 zu überspringen ***
    // Starte die Schleife bei 2014 oder überspringe 2013 explizit, wenn nötig.
    // Hier starten wir einfach bei 2014, da 2013 nicht mehr in der Regression war.
    forvalues i = 2014(1)2019 {
        // Stelle sicher, dass die Koeffizientennamen _b[1.treat#`i'.jahr] noch stimmen
        // Es kann sein, dass sie sich leicht ändern, z.B. zu _b[1.treat#c.`i'.jahr]
        // Überprüfe dies mit 'ereturn display' nach der Regression!
        // Angenommen, die Namen bleiben im Format:
        if `i' != 2016 { // Das Basisjahr (2016) hat keinen expliziten Interaktionsterm
           replace coef = _b[1.treat#`i'.jahr] if jahr == `i'
           replace se = _se[1.treat#`i'.jahr] if jahr == `i'
        }
        // Setze den Wert für das Basisjahr explizit auf 0
        else if `i' == 2016 {
           replace coef = 0 if jahr == `i'
           replace se = 0 if jahr == `i' // SE ist für den Referenzpunkt auch 0
        }
    }

    // Berechne Konfidenzintervalle
    g ci_top = coef + 1.96 * se
    g ci_bottom = coef - 1.96 * se

    // Behalte nur relevante Variablen und eine Zeile pro Jahr
    // Wichtig: Nur Jahre behalten, die auch in der Analyse waren
    keep if jahr != 2013
    keep jahr coef se ci_*
    duplicates drop

    // Sortiere für korrekte Linienverbindung
    sort jahr

    // *** Änderung 3: Passe den Grafikbereich an ***
    twoway (scatter coef jahr, connect(l)) /// // oder (sc coef jahr, connect(line))
           (rcap ci_top ci_bottom jahr) ///
           (function y = 0, range(2014 2019)), /// // Range angepasst
           xline(2016.5, lpattern(dash) lcolor(black)) xtitle("Jahr") ///
           caption("95% Confidence Intervals Shown, Year 2013 excluded") /// // Caption angepasst
           legend(off)

restore

// *** Änderung 4: Pre-Trend-Tests anpassen ***
// Wenn du Pre-Trend-Tests durchführst (z.B. F-Test, ob die Koeffizienten vor 2016 gemeinsam Null sind),
// musst du diese ebenfalls anpassen, um nur die relevanten Jahre (hier 2014, 2015) einzubeziehen.
// Beispiel nach der reghdfe-Regression (Namen ggf. anpassen!):
// test (1.treat#2014.jahr = 0) (1.treat#2015.jahr = 0)



//OPTION2:
preserve

    // *** Änderung 1: Lösche Beobachtungen für 2013 ***
    drop if jahr == 2013

    // Führe die Regression auf den verbleibenden Daten durch
    reghdfe e_personalausg treat##ib2016.jahr, a(ags jahr) vce(cluster ags)

    // Überprüfe Koeffizientennamen mit: ereturn display

    g coef = .
    g se = .
    // *** Änderung 2: Passe die Schleife an ***
    forvalues i = 2014(1)2019 { // Start bei 2014
         if `i' != 2016 {
            // Namen ggf. anpassen (siehe ereturn display)
            replace coef = _b[1.treat#`i'.jahr] if jahr == `i'
            replace se = _se[1.treat#`i'.jahr] if jahr == `i'
        }
        else if `i' == 2016 {
           replace coef = 0 if jahr == `i'
           replace se = 0 if jahr == `i'
        }
    }

    // Berechne Konfidenzintervalle
    g ci_top = coef + 1.96 * se
    g ci_bottom = coef - 1.96 * se

    // Behalte Variablen und eine Zeile pro Jahr (2013 ist schon weg)
    keep jahr coef se ci_*
    duplicates drop

    // Sortiere für korrekte Linienverbindung
    sort jahr

    // *** Änderung 3: Passe den Grafikbereich an ***
    twoway (scatter coef jahr, connect(l)) ///
           (rcap ci_top ci_bottom jahr) ///
           (function y = 0, range(2014 2019)), /// // Range angepasst
           xline(2016.5, lpattern(dash) lcolor(black)) xtitle("Jahr") ///
           caption("95% Confidence Intervals Shown, Year 2013 excluded") ///
           legend(off)

restore

// *** Änderung 4: Pre-Trend-Tests anpassen ***
// Wie in Methode 1, der Test muss die Koeffizienten für 2014 und 2015 prüfen.
// Beispiel nach reghdfe:
// test (1.treat#2014.jahr = 0) (1.treat#2015.jahr = 0)



// Interessante Zahlen:

// Wie hoch war Mittel der Erhöhungen?




*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block II.2:  Covairates hinzufügen
*	----
*	-------------------------------------------------------------------------------------------------------------------	

// VARIANTE 1: Zeitveränderliche Kovariaten hinzufügen (NICHT empfohlen!)
// Entspricht Logik von Eq. 4.3, kontrolliert primär für Delta-X, problematisch bei Bad Controls & Heterogenität
reghdfe e_personalausg treat##ib2016.jahr covar1 covar2, a(ags jahr) vce(cluster ags)

// VARIANTE 2: Baseline-Kovariaten interagiert hinzufügen (komplexer & immer noch problematisch!)
// Man müsste Interaktionen der Baseline-Kovariaten mit den relativen Zeit-Dummies bilden.
// Diese Variante wird schnell unübersichtlich und löst die fundamentalen Gewichtungsprobleme nicht.
// Beispiel für EINE Baseline-Kovariate 'base_covar' (vereinfacht!):
gen year_rel = jahr - 2016 // Relative Zeit
forval i = 2017/`max_year' { // Annahme: max_year ist das letzte Jahr im Datensatz
    local rel_time = `i' - 2016
    gen interaction_`i' = (jahr == `i') * base_covar
}
// Dann Regression mit diesen vielen Interaktionen... (NICHT empfohlen!)
// reghdfe e_personalausg treat##ib2016.jahr interaction_*, a(ags jahr) vce(cluster ags)



// DURCHÜFHUNG MIT csdid und drdid


ssc install csdid, replace
ssc install drdid, replace // Wird oft von csdid benötigt

// Vorbereitung der Daten: Du brauchst eine Variable, die das erste Jahr angibt, in dem eine Einheit (ags) behandelt wird. Nennen wir sie first_treat_year. Für die Kontrollgruppe kann diese Variable einen hohen Wert (z.B. 9999) oder Missing (.) haben. Dein treat-Dummy ist hierfür nicht direkt geeignet.

// Beispiel: Erstellen von first_treat_year, wenn treat=1 ab 2017 gilt
egen min_jahr_if_treat = min(jahr), by(ags) cond(treat == 1)
gen first_treat_year = min_jahr_if_treat if treat == 1
replace first_treat_year = 9999 if missing(first_treat_year) // Oder einen anderen Wert für Kontrollgruppe
drop min_jahr_if_treat



// Schätzung mit csdid, Methode: Doubly Robust (DR), mit Kovariaten
// Kontrolliert automatisch für CPT mittels DR
csdid e_personalausg covar1 covar2, time(jahr) gvar(first_treat_year) method(dr) vce(cluster ags)

/*
e_personalausg: Outcome
covar1 covar2: Deine Kovariaten (typischerweise Baseline-Werte oder zeitinvariante)
time(jahr): Variable, die die Zeit angibt
gvar(first_treat_year): Variable, die das erste Behandlungsjahr angibt
method(dr): Wählt die Doubly Robust Methode (empfohlen). Alternativen: reg (für RA), ipw (für IPW).
vce(cluster ags): Clustert die Standardfehler.

*/


// event study Plott

estat event
// Optional: Fenster anpassen, z.B. 5 Jahre vor bis 5 Jahre nach Treatment
// estat event, window(-5 5) graphoptions(xtitle("Event time"))

/*    ieser Befehl berechnet und plottet die ATT(t) für jede relative Zeitperiode zum Treatmentbeginn, basierend auf der robusten DR-Schätzung, die die Kovariaten korrekt berücksichtigt.

Zusammenfassung:
Modifiziere nicht deinen reghdfe-Code, um Kovariaten hinzuzufügen, wenn du den Empfehlungen des Papers folgen und ATT(t) unter CPT schätzen möchtest. Verwende stattdessen ein dediziertes Paket wie csdid, das die Methoden RA, IPW oder (bevorzugt) DR implementiert. Dieses Paket ist darauf ausgelegt, die Kovariaten korrekt gemäß der im Paper beschriebenen Logik zu berücksichtigen.
*/







*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block III:  Teste Parallel Trends Assumption und Führe Placebo Tests durch
*	----
*	-------------------------------------------------------------------------------------------------------------------	


*----------------------------------------------------------------------------------------------------------------
*---
* Prior Trends Test: look at prior trend and see if different, oder statistical test um zu sehen ob unterschiedlich und wie sehr unterschiedlich. 
*---
*----------------------------------------------------------------------------------------------------------------


//stat

preserve	
    gen group =.
	//replace group = 2 if treat==1
	//replace group = 1 if treat==0
	keep if post == 0
	gen time_group = jahr * treat 
	reghdfe stpfgew jahr time_group, a(ags) vce(cluster ags) //allows for two different time trends (beta 1 and beta1+beta2), time enters linear, Ziel beta2 ist nicht signifikant ( also nicht unterschiedlich zu null)
restore

//grafisch
preserve
	// Mittelwerte von rate für jede Gruppe und jedes Quartal berechnen
	egen y_mean = mean(e_personalausg), by(jahr treat)

	// Plot erstellen mit twoway line und scatter für beide Gruppen im selben Plot
	twoway ///
		(line y_mean jahr if treat == 0, sort) /// Linie für Control (in Legende)
		(line y_mean jahr if treat == 1, sort) /// Linie für Treatment (in Legende)
		(scatter y_mean jahr if treat == 0, msymbol(circle) mcolor(black)) /// Marker für Control (schwarz, keine Legende)
		(scatter y_mean jahr if treat== 1, msymbol(triangle) mcolor(black) ) , /// Marker für Treatment (schwarz, keine Legende)
		xline(2016.5) ///
		legend(label(1 "Control Group") label(2 "Treatment Group") order(1 2)) /// Legende hinzufügen
		xtitle("Jahr") ytitle("(mean) y") /// Achsen betiteln
		title("Parallel Trends Test") /// Graphen betiteln
	
restore



*----------------------------------------------------------------------------------------------------------------
*---
*	Placebo Test: Daten vor treatment nutzen, wähle eine zufällige pre treatment periode, oder mehrere und schauen wie wahres treatment sich verhält -> randomization inference, schätze selbes DiD Modell aber Treated sollte entsprechend 1 sein wenn in treated group und nach dem fake Treatment. Wenn man effekt findet obwohl keiner da, dann stimmt etwas mit dem Design nicht!
*---
*----------------------------------------------------------------------------------------------------------------


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
/*
Ja, das ist ein interessantes Szenario. Obwohl es auf den ersten Blick kontraintuitiv erscheint (da höhere Steuern normalerweise den Gewinn schmälern und eher zu Kostensenkungen führen sollten), **könnte es unter bestimmten Umständen tatsächlich vorkommen**, dass die Personalausgaben eines Unternehmens kurzfristig, speziell im Jahr *nach* einer Gewerbesteuererhöhung, steigen.

Hier sind einige mögliche Gründe dafür:

1.  **Investitionen in Effizienz und Optimierung:**
    * **Reaktion auf Kostendruck:** Die höhere Steuerlast zwingt das Unternehmen, effizienter zu werden. Im Jahr nach der Erhöhung könnten gezielt Projekte zur Prozessoptimierung, Digitalisierung oder Automatisierung gestartet werden. Diese Projekte erfordern möglicherweise kurzfristig zusätzliches Personal (Projektmanager, IT-Spezialisten, Berater) oder intensive Schulungen für bestehendes Personal, was die Personalkosten temporär erhöht, bevor langfristige Einsparungen realisiert werden.
    * **Steuerberatung/Optimierung:** Das Unternehmen könnte verstärkt externe Berater oder interne Spezialisten einsetzen, um die Steuerlast legal zu minimieren oder Fördermittel zu akquirieren. Diese Beratungs- und Personalkosten fallen dann im Folgejahr an.

2.  **Planung von Restrukturierungen oder Verlagerungen:**
    * Wenn die Steuererhöhung als untragbar angesehen wird, könnte das Unternehmen im Folgejahr beginnen, strategische Alternativen wie eine Restrukturierung oder sogar eine Verlagerung von Unternehmensteilen zu prüfen. Die Planung solcher Maßnahmen bindet internes Personal (Management, Controlling) und erfordert oft externe Experten (Berater, Anwälte), was die Personalkosten kurzfristig steigert, bevor tatsächliche Einsparungen (z.B. durch Stellenabbau an diesem Standort) wirksam werden.

3.  **Strategische Personalentscheidungen:**
    * **Halten von Schlüsselpersonal:** In Erwartung schwierigerer Zeiten oder um bei einer möglichen Restrukturierung die besten Mitarbeiter zu halten, könnte das Management im Jahr nach der Steuererhöhung gezielt Gehaltserhöhungen oder Boni für unverzichtbares Personal beschließen.
    * **Vorgezogene Lohnverhandlungen:** Gewerkschaften oder Betriebsräte könnten gerade wegen der angekündigten oder erfolgten Steuererhöhung (und dem antizipierten Druck auf Löhne) versuchen, im Folgejahr noch schnell bessere Tarifabschlüsse oder Einmalzahlungen durchzusetzen, bevor das Unternehmen den Gürtel enger schnallt.

4.  **Zeitliche Verlagerung von Ausgaben:**
    * Unternehmen könnten bestimmte geplante Ausgaben oder Investitionen, die Personalressourcen binden (z.B. große IT-Projekte, Einführung neuer Produkte), aus dem Jahr der Steuererhöhung (um die Liquidität zu schonen) in das Folgejahr verschieben. Das führt dann dort zu einem Anstieg der Personalkosten.

5.  **Investitionen in Automatisierung (Paradoxe Wirkung):**
    * Als Reaktion auf die höheren (relativen) Kosten des Faktors Arbeit durch die Steuererhöhung könnte das Unternehmen beschließen, stärker in Automatisierung zu investieren. Die *Implementierungsphase* solcher Projekte im Folgejahr kann jedoch paradoxerweise kurzfristig mehr oder teureres Personal (Techniker, Programmierer, Schulungspersonal) erfordern, bevor langfristig Personal eingespart wird.

**Wichtig ist:**

* Dies sind **kurzfristige Effekte**, die oft mit strategischen Reaktionen oder Planungsphasen zusammenhängen.
* Sie treten **nicht zwangsläufig** auf und hängen stark von der spezifischen Situation des Unternehmens, seiner Finanzkraft, seiner Branche und der Höhe der Steuererhöhung ab.
* Der **grundlegende ökonomische Druck** einer höheren Steuerlast wirkt langfristig eher dämpfend auf die Personalkosten (durch geringere Neueinstellungen, Stellenabbau oder moderatere Lohnsteigerungen), es sei denn, das Unternehmen kann die Mehrkosten vollständig über höhere Preise weitergeben oder durch Effizienzsteigerungen kompensieren.

Zusammenfassend lässt sich sagen: Ja, ein kurzfristiger Anstieg der Personalkosten im Jahr *nach* einer Gewerbesteuererhöhung ist plausibel, wenn er durch spezifische unternehmerische Reaktionen wie Effizienzprojekte, Restrukturierungsplanungen oder strategische Personalmaßnahmen ausgelöst wird. Es ist jedoch eher eine temporäre Anomalie als der erwartete langfristige Trend.
*/

// 02 Block II : Ausgabe der sample ags 
* -------------------------------------------------------------------------------------------------------------------
* ---- NEUER CODEBLOCK ZUM EXPORTIEREN DER UNIQUE AGS WERTE ----
* -------------------------------------------------------------------------------------------------------------------

// Dieser Block extrahiert die eindeutigen Werte der Variable 'ags' aus dem aktuell geladenen Datensatz
// und speichert sie in einer Excel-Datei.

preserve // Sichert den aktuellen Zustand des Datensatzes (wichtig!)

// 1. Nur die Variable 'ags' behalten. Alle anderen Variablen werden temporär entfernt.
keep ags

// 2. Duplikate entfernen. Nach diesem Schritt enthält jede Zeile einen eindeutigen 'ags'-Wert.
duplicates drop ags, force

// 3. Optional: Sortieren der AGS-Werte für eine übersichtlichere Excel-Datei.
sort ags

// 4. Exportieren der verbleibenden Daten (nur die unique 'ags') nach Excel.
//    Passe den Pfad und Dateinamen "C:\Pfad\zu\deiner\Datei\unique_ags_export.xlsx" an deine Bedürfnisse an.
//    'sheet("UniqueAGS")' benennt das Tabellenblatt in Excel.
//    'firstrow(variables)' schreibt den Variablennamen ('ags') in die erste Zeile der Excel-Datei als Überschrift.
//    'replace' erlaubt das Überschreiben einer existierenden Datei mit demselben Namen.
export excel using "unique_ags_export.xlsx", sheet("UniqueAGS") firstrow(variables) replace

// Optional: Eine Bestätigung im Stata-Ergebnisfenster anzeigen.
di as text "Eindeutige AGS-Werte wurden erfolgreich nach 'unique_ags_export.xlsx' exportiert."

restore // Stellt den ursprünglichen Datensatz wieder her, der vor 'preserve' existierte.



// Prüfe Fehler bei Generierung von e_reings *xtreg e_reings treat post treat_post, re



// Gib NA seperat aus TEST
codebook varname1 varname2 varnameX 
misstable summarize varname1
inspect varname1