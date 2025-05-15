*-------------------------------------------------------------------------------------------------------------------
*   Project Title: THE DETERMINANTS OF TAX COMPLIANCE
*	Code: Analyze full_gwap.dta
/* 
 04_DiD_prep_2x2.do Bereitet DiD vor und schätzt Standard_DiD_2x2_'Treat`cohort 	
*/
*-------------------------------------------------------------------------------------------------------------------

*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block 1 :  DiD Vorbereitung
*	----
*	-------------------------------------------------------------------------------------------------------------------

if $FDZ == 0 { // Nutze Mod File oder Testfile an privatem Arbeitsplatz
	*use "$neudatenpfad/Temp/Random.dta", clear
    *use "$datenpfad/${dateiname}", clear
	*use "$neudatenpfad/Temp/chatDiD.dta", replace
}
else {
    use "$neudatenpfad/Temp/preperation_allyears.dta", clear  // nutze balanced full panel im Ordner Temp
}


*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------	
* STEP 1: Code für Pattern erstellen (spezfisch für ein balanciertes panel, ist bei unbalancierten ggf. nochmal anzupassen)
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
	// Pattern für Steuererhöhung(=1) keine Veränderung (=0) Verringerung (=-1). Für 2013 keine Veränderung berechenbar weil es sich um das erste Jahr handelt (=n) by id (ist ähnlich zu pattern, das man mit xtdescribe erhält). Der Code ist so geschrieben, dass auch für variable ranges von Jahren funktioniert, insofern keine Lücken enthalten sind. Wenn ausgewählte Jahre nicht vorhanden sind, dann wird "." eingefügt.
	
	summarize jahr, meanonly // festlegen der range(also Jahre)
	local max = r(max)
	local min = r(min)
	local range = r(max) - r(min) + 1
	local miss : display _dup(`range') "." //  string an Punkten kreieren entsprechend der range
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

	// Behalte nur die folgenden pattern 
	keep if inlist(pattern_tax,  "n001000", "n000010", "n000100", "n000000")
	
	
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
* STEP 2: Behandlungs und Kontrollgruppe festlegen
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
* Drop moving firms 
*	-------------------------------------------------------------------------------------------------------------------
	by id (ags), sort: gen byte moved = (ags[1] != ags[_N]) // solche ids die unterschiedliche ags haben, sich also dem treatment potentiell (un)absichtlich entziehen werden gedropped
	tab pattern_tax moved if inlist(pattern_tax, "n001000", "n000010", "n000100", "n000000"), row
	tab pattern_tax moved, col
	*drop if moved == 1 // Achtung moved für spätere Analyse evtl. noch interessant, falls ja hier auskommentieren und im model if moved != 1 hinzufügen

*	-------------------------------------------------------------------------------------------------------------------
* Drop rechtsform changing firms 
*	-------------------------------------------------------------------------------------------------------------------
	
	// wie viele Unternehmen ändern mindestens einmal ihre Rechtsform?
	bysort id (jahr): egen minrf = min(rechtsform)
	bysort id (jahr): egen maxrf = max(rechtsform)
	gen norfswitch = minrf == maxrf
	drop minrf maxrf
	label var norfswitch "firm keeps legal status"
	tab pattern_tax norfswitch if inlist(pattern_tax, "n001000", "n000010", "n000100", "n000000"), row
	
	// Von welcher in welche Rechtsform wird geswitcht?
	
	sort id jahr 
	gen L_rechtsform =L.rechtsform
	gen rf_changed = (rechtsform != L_rechtsform) & (!missing(L_rechtsform))
	
	gen rf_original = L_rechtsform if rf_changed == 1 
	gen rf_new =rechtsform if rf_changed == 1
	
	by id: egen n_rf_changes =total(rf_changed)
	
	//label
	
	noi disp ""
	noi disp "Häufig. der spezifischen Wechsel von nach (Original -> Neu)"
	tab rf_original rf_new if rf_changed ==1, row missing
	
	*drop L_rechtsform rf_changed rf_original rf_new


	
*	-------------------------------------------------------------------------------------------------------------------
* Gewerbesteuerpflichtigkeit (Zahlt vs zahlt nicht GewSt)
*	-------------------------------------------------------------------------------------------------------------------	
	
	gen nogew =0 
	// replace no gew = 0 if inlist(e_ef19, 03, 04, 08)
	
	replace nogew = 1 if g_k6524 <= 0
	replace nogew = 1 if inlist(e_ef19, 1, 2, 7) // Land und Forst
	replace nogew = 1 if inlist(e_ef19, 5, 6, 9) // Freiberuflich
	
	label var nogew "liability to LBT"
	label define placelb 0 "liable" 1 "not liable"
	label value nogew placelb
	
	
	sort id jahr
	bysort id : egen  sum_nogew = total(nogew)
	gen nogew_basesum = (sum_nogew >= 4)
	drop sum_nogew
	*tab nogew_basesum
	
	// label var label define lable value nogew placelb anpassen
	
	
	/*
	// Zeigt wie die Heuristik verteilt ist, also wie viele beobachtungen je id wie oft als nogew eingeschätzt werden
	bysort id : egen  sum_nogew = total(nogew)
	tab sum_nogew
	*/
	

	
	
*	-------------------------------------------------------------------------------------------------------------------
* Identifiziere hebesatz >380 Fälle  (nur für balanced panel) 
*	-------------------------------------------------------------------------------------------------------------------
	
	* Fall 1: Hebesatz im letzten Jahr der Beobachtung einer id größer als 380
	sort id jahr
	bysort id (jahr): generate byte temp_check = (hebesatz > 380) if _n == _N
	
	bysort id: egen byte hebesatz_lastyear_380 =max(temp_check)
	drop temp_check
	*check wie viele betroffen?
	tab hebesatz_lastyear_380
	
	
	/*
	* Subfall A: Hebesatz überschreitet im Verlauf der Zeit (erstes Jahr vs letztes Jahr) die Schwelle 380
	
	bysort id (jahr): gen double first_year_hebesatz = hebesatz[1]
	bysort id (jahr): gen double last_year_hebesatz = hebesatz[_N]
	gen byte hebesatz_schwelle_380 = (first_year_hebesatz < 380) & (last_year_hebesatz > 380)
	tab hebesatz_schwelle_380
	
	* Subfall B: Hebesatz war bereits im ersten Jahr > 380, wird nochmal angehoben, und ist auch im letzetn Jahr > 380
	gen byte hebesatz_380_380 = (first_year_hebesatz > 380) & (last_year_hebesatz > 380)
	tab hebesatz_380_380
	*/
	
	* Erhöhung der gewerbesteuer sollte bei Personengesellschaften ledliglich Effekte auf Firmen haben die in Gemeinde mit Hebesatz >380 sind. Wenn Personengesellschaften Untersuchungsgegenstand sind, behalte nur Personeengesellschaften die hebesatz über 380 haben
	
	gen persbigger380 = .
	replace persbigger380 = 1 if hebesatz_lastyear_380 == 1 & inlist(rechtsform, 20, 21, 22,23,24,25,26, 27, 28)
	replace persbigger380 = 0 if hebesatz_lastyear_380 == 0 & inlist(rechtsform, 20, 21, 22,23,24,25,26, 27, 28)
	
	// label var und label define label value einfügen
	
	label variable persbigger380 " Keine vollst. GewSt Anrechnung auf die ESt für PersG (Ja =1 /Nein = 0)"
	//Checks:
	tab persbigger380, missing
	tab persbigger380 hebesatz_lastyear_380
	summarize hebesatz if persbigger380 == 1
	summarize hebesatz if persbigger380 == 0
	summarize hebesatz if hebesatz_lastyear_380 == 1
	summarize hebesatz if hebesatz_lastyear_380 == 0
	
*	-------------------------------------------------------------------------------------------------------------------
*  Übernahme der initialen Werte in Firma, damit kein Wechsel über die Zeit -> neue Variable wird mit Zusatz _base abgespeichert
*	-------------------------------------------------------------------------------------------------------------------
	
local basics wz08 gk

foreach b of local basics {
	bysort id (jahr): gen tmp_`b' = `b' if _n == 1
	by id: egen `b'_base = mean(tmp_`b') 
	drop tmp_`b'
}



	


*	-------------------------------------------------------------------------------------------------------------------
* Behandlungs und Kontrollgruppe festlegen.Referenz 2016 Treatment 2017
*	-------------------------------------------------------------------------------------------------------------------
	gen treat2017 = 1 if inlist(pattern_tax, "n000100") // von 2013 bis 2019 beobachtbar, taxchange nur im Jahr 2017, und in den anderen Jahren keine Veränderung
	replace treat2017 = 0 if inlist(pattern_tax, "n000000") // von 2013 bis 2019 beobachtbar, kein taxchange in keinem der Jahre von 2013 bis 2019
	gen post2017 = (jahr >= 2017) // 1 ab 2017 da nach § 16(3) GewStg, Erhöhung bis 30.Juni  festgelegt 
	gen treat_post2017 = treat2017 * post2017 

*	-------------------------------------------------------------------------------------------------------------------
* Behandlungs und Kontrollgruppe festlegen.Referenz 2015 Treatment 2016
*	-------------------------------------------------------------------------------------------------------------------

	gen treat2016 = 1 if inlist(pattern_tax, "n001000") 
	replace treat2016 = 0 if inlist(pattern_tax, "n000000") 
	gen post2016 = (jahr >= 2016) 
	gen treat_post2016 = treat2016 * post2016 

*	-------------------------------------------------------------------------------------------------------------------
* Behandlungs und Kontrollgruppe festlegen.Referenz 2017 Treatment 2018
*	-------------------------------------------------------------------------------------------------------------------

	gen treat2018 = 1 if inlist(pattern_tax, "n000010") 
	replace treat2018 = 0 if inlist(pattern_tax, "n000000") 
	gen post2018 = (jahr >= 2018) 
	gen treat_post2018 = treat2018 * post2018 
	
	
	/* Weitere Auswahlmöglichkeiten für treatment
	* keep if substr(pattern_tax, 1, 3) == "11."  // behält patterns like "11.1...", "11....", etc.
	* keep if substr(pattern_tax, strlen(pattern_tax)-2, 3) == "11."  // behält patterns like "...11.", ".1.11."
	*keep if inlist(pattern_tax, "n000000", "n000100")
	*save "$neudatenpfad/Temp/preperation_xxxx.dta", replace
	*/

	
*	-------------------------------------------------------------------------------------------------------------------
* cohort_group Variablen
*	-------------------------------------------------------------------------------------------------------------------	
	
	capture drop cohort_group
	gen cohort_group = 0 if pattern_tax == "n000000"
	replace cohort_group = 2016 if pattern_tax == "n001000"
	replace cohort_group = 2017 if pattern_tax == "n000100"
	replace cohort_group = 2018 if pattern_tax == "n000010"
			
*	-------------------------------------------------------------------------------------------------------------------
*  Überblick Transformation ausgewählter Variablen
*	-------------------------------------------------------------------------------------------------------------------
	/*
*	e_personalausg
    ln_e_personalausg
    sigln_e_personalausg
	stpfgew 
	ln_stpfgew
	sigln_stpfgew
	g_reing
 
	
	
	e_c25194 Steuerberatung
    e_c25281 Fortbildungskosten
	
tbd e_ums Umsatzsteuerpflichtige Betriebseinnahmen
tbd g_k2110 Gewinn aus gewerbetrieb
tbd g_k6520 abgerundeter Gewerbeertrag 
	p_ef34 Einkünfte aus Gewerbebetrieb


Sätze:

	rename e_c65120 e_rohgs1 // Rohgewinnsatz 1 -> nicht ausreichend gefüllt
	rename e_c65121 e_rohgs2 // Rohgewinnsatz 2 -> nicht ausreichend gefüllt
	rename e_c65130 e_halbreings // Halbreingewinnsatz -> nicht ausreichend gefüllt
	rename e_c65140 e_reings // Reingewinnsatz  -> nicht ausreichend gefüllt
*	inspect g_reings  ->   eig geeignet aber keine Effekte erkennbar 


Investitionsndiaktoren
	e_c25130  Afa bwegeliche WG
	e_c25136  Afa unbewegliche WG
	e_c25134  Sonderabschreibungen §7g
	e_c25187  Investitionsabzugsbeträge
	e_c25225  Erhaltungsaufwendungen
	

*/
	sort id jahr

	gen ln_e_persausg = ln(e_persausg) // entfernt negative Werte
	gen ln_stpfgew =ln(stpfgew)

	gen sigln_stpfgew = sign(stpfgew) * ln(abs(stpfgew)+1)
	gen sigln_e_persausg = sign(e_persausg) * ln(abs(e_persausg)+1)

	gen rel_stpfgew=((stpfgew-L.stpfgew)/abs(stpfgew))*100 // in Prozent
	gen rel_e_persausg=((e_persausg-L.e_persausg)/abs(e_persausg))*100
	
	gen ln_fobi = ln(e_c25281+1) // entfernt negativne Werte in Fortbildungskosten
	
	* g_reings 
	
	centile g_reings, centile(0.5 99.5)
	gen g_reings0_5 = r(c_1)
	gen g_reings99_5 = r(c_2)
	gen g_reings_tru = g_reings if g_reings <= g_reings99_5  & g_reings >= g_reings0_5   // percentile einteilung in Ordnung? zu viele extreme reing sätze
	

	/*
	centile g_reing, centile(0.5 99.5)
	gen g_reing0_5 = r(c_1)
	gen g_reing99_5 = r(c_2)
	gen g_reing_trun = g_reing if  g_reing <= g_reing99_5 & g_reing >= g_reing0_5
	*/
	
	gen sigln_g_reing = sign(g_reing)* ln(abs(g_reing)+1) // ohne _trun wie beim rest für einheitlichkeit
	gen ln_g_reing = ln(g_reing)
	
	gen ln_inv = ln(e_c25187+1)  // Investitionsabzugsbeträge
	
	*gen ln_son = ln(e_c25134)  // Sonderabschreibungen 7g 
	
	gen ln_afa_bwg = ln(e_c25130 + 1)  // Afa bewegliche WG
	gen ln_afa_ubwg = ln(e_c25136 + 1)  // Afa unbewegliche WG
	gen ln_erhauf= ln(e_c25225+1) // Erhaltungsaufwendungen , negative Werte ergeben keinen Sinn, vermutl. falsches Vorzeichen
	
	gen ln_steube = ln(e_c25194+1) // Steuerberatung, nur pos Werte
	gen sigln_p_einge = sign(p_ef34)* ln(abs(p_ef34)+1)  // Einkünfte aus Gewerbebetrieb
	

	// Gewerbesteuer
	
	misstable summarize g_fef315 g_fef316 g_k2131 g_k6516 g_k6520 g_k6524 g_k2110 g_k2152 g_k6517 g_k65277 g_k65282 // g_k65277 g_k65282 g_k2152
	
	misstable summarize g_fef315 g_fef316 g_k2131 g_k6516 g_k6520 g_k6524 g_k2110 g_k6517
	
	
	gen ln_hinz =ln(g_fef315+1)
	gen ln_kür =ln(g_fef316+1)
	gen ln_zins = ln(g_k2131+1)
	gen ln_gew = ln(g_k2110+1)
	gen ln_abggewerer= ln(g_k6520+1)
	
	
*local dependent_vars "e_persausg stpfgew ln_e_persausg sigln_e_persausg rel_e_persausg rel_stpfgew ln_fobi g_reings_tru sigln_g_reing ln_inv ln_son ln_afa_bwg ln_afa_ubwg ln_steube sigln_p_einge"
	
	/* 
	hist e_c25281
	tab e_c25281 bundesland if e_c25281 < 0
	tab e_c25281 rechtsform if e_c25281 < 0
	
	hist g_reings if g_reings < -2000 
	sum g_reings if g_reings < -2000
	
	tab g_reings bundesland if  g_reings < -200000
	tab g_reings rechtsform if  g_reings < -200000
	
	hist g_reings_tru
	
	hist e_c25187
	hist e_c25134
	hist e_c25130
	hist e_c25136
	hist e_c25225
	tab e_c25225 rechtsform if e_c25225 < 0
	
	hist e_c25194 if e_c25194 <0 
	tab e_c25194 rechtsform if e_c25194 <0 
	
	sum p_ef34 if p_ef34 <0
	
	*/
	
*##################################################################################################################################################################################################
	global dependent_vars "ln_stpfgew ln_e_persausg sigln_e_persausg ln_fobi g_reings_tru sigln_g_reing ln_g_reing ln_inv ln_afa_bwg ln_afa_ubwg ln_erhauf ln_steube sigln_p_einge ln_hinz ln_kür ln_zins ln_gew ln_abggewerer"           //#
*##################################################################################################################################################################################################

*##################################################################################################################################################################################################
* MAINSPECIFICATION

	*local keep mainspecification norfswitch == 1 & moved != 1 & persbigger380 == 1 & nogew_basesum != 1
	keep if norfswitch == 1
	keep if moved != 1
	*keep if persbigger380 == 1
	keep if nogew_basesum != 1

*##################################################################################################################################################################################################

*	-------------------------------------------------------------------------------------------------------------------
*  Generate Fixed Effects
*	-------------------------------------------------------------------------------------------------------------------
// industry aus wz08 extrahieren (zunächst Fokus auf Gliederungsebene Gruppen (Stelle 1 bis 3) später für andere Spezifikationen und Validität auch Abteilung, Klasse und Unterklasse denkbar)

	//string: gen industry = substr(wz08,1,3)
	tostring wz08, gen(wz08_str)
	gen industry3 = substr(wz08_str, 1, 3) // 3 Steller
	destring industry3, replace 
	gen industry2 =substr(wz08_str,1, 2) // 2 Steller
	destring industry2, replace
	
// industry_base

	bysort id (jahr): gen tmp_industry = industry3 if _n == 1
	by id: egen industry_base3 = mean(tmp_industry) // entspricht wert aus dem 1. Jahr da der Rest von tmp_b missing Werte ist
	drop tmp_industry
	label var industry_base3 "Industry 3 Steller aus erster Beobachtung"
	
	bysort id (jahr): gen tmp_industry = industry2 if _n == 1
	by id: egen industry_base2 = mean(tmp_industry) // entspricht wert aus dem 1. Jahr da der Rest von tmp_b missing Werte ist
	drop tmp_industry
	label var industry_base2 "Industry 2 Steller aus erster Beobachtung"
	
// Gen Fixed Effects

	// jahr region 
	
	egen jahr_X_bundesland = group(jahr bundesland_num)
	label variable jahr_X_bundesland "Jahr X Bundesland id"
	
	egen jahr_X_county = group(jahr county_num)
	label variable county "Jahr X Landkreis id"
	
	
	// jahr industry wz08 3 Steller
	egen jahr_X_industry = group(jahr industry_base3)
	label variable jahr_X_industry "Jahr X Industry 3 Steller id"
	/*
	egen jahr_X_industry_X_bundesland = group(jahr industry_base3 bundesland_num)
	label variable jahr_X_industry_X_bundesland "Jahr X Bundesland X Industry 3 Steller id"
	*/
	
	// jahr industry wz08 2 Steller
	egen jahr_X_industry2 = group(jahr industry_base2)
	label variable jahr_X_industry2 "Jahr X Industry 2 Steller id"
	/*
	egen jahr_X_industry2_X_bundesland = group(jahr industry_base2 bundesland_num)
	label variable jahr_X_industry2_X_bundesland "Jahr X Bundesland X Industry 2 Steller id"
	*/

*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block 2 :  number of units in each cohort and average outcome over time
*	----
*	-------------------------------------------------------------------------------------------------------------------

*	-------------------------------------------------------------------------------------------------------------------
*  Number of units in each cohort
*	-------------------------------------------------------------------------------------------------------------------

capture drop cohort_group
gen cohort_group = 0 if pattern_tax == "n000000"
replace cohort_group = 2016 if pattern_tax == "n001000"
replace cohort_group = 2017 if pattern_tax == "n000100"
replace cohort_group = 2018 if pattern_tax == "n000010"

/*
capture confirm variable cohort_group
if _rc != 0 {
	di as error "Variable `cohort_group' nicht gefunden. Erstellen!"
	exit
}
*/


di _newline as result "-----------------------------------------------------------------"
di as result "Gesamtzahl eindeutiger Firmen (IDs) pro Kohorte"
di as result "-----------------------------------------------------------------"

bysort id: gen byte _is_first_id_obs = (_n == 1) // erste beobachtung
tabulate cohort_group if _is_first_id_obs 
drop _is_first_id_obs

di _newline as result "-----------------------------------------------------------------"
di as result "Gesamtzahl eindeutiger Firmen (IDs) pro Kohorte"
di as result "Nur Firmen mit nicht fehlenden Werten für die entsprechende Variable"
di as result "-----------------------------------------------------------------"

*local dependent_vars "ln_e_persausg sigln_e_persausg rel_e_persausg rel_stpfgew ln_fobi g_reings_tru sigln_g_reing ln_inv ln_son ln_afa_bwg ln_afa_ubwg ln_steube sigln_p_einge"

foreach depvar of global dependent_vars {
	di _newline as text "---Abhängige Variable: `depvar'"
	
	preserve
	
		keep if !missing(`depvar')  // löscht wenn depvar fehlend
		bysort id: keep if _n == 1  // löscht alle Beobachtungen die zur selben id gehören damit einzeln Unternehmen gezählt werden und nicht alle sieben Jahre
		di as  text " Anzahl Firmen mit nicht fehlendem `depvar': "
		tabulate cohort_group, missing // missing zeigt ids ohne Kohortenzuordnung an die trotzdem in Datensatz sind
		
	restore
		
}

*	-------------------------------------------------------------------------------------------------------------------
*  Evolution of average outcome across cohorts
*	-------------------------------------------------------------------------------------------------------------------


	
*local dependent_vars "ln_e_persausg sigln_e_persausg rel_e_persausg rel_stpfgew ln_fobi g_reings_tru sigln_g_reing ln_inv ln_son ln_afa_bwg ln_afa_ubwg ln_steube sigln_p_einge"
	

di _newline as result "--- Plots der durschnittl Outcome überZeit je Kohorte ---"

foreach depvar of global dependent_vars{
	
	di as text "--- Erstelle Plot für `depvar' ---"
	
	preserve
		di as text "--- 1"
		collapse (mean) mean_`depvar'=`depvar', by(cohort_group jahr)
		di as text "--- 2"
		
		twoway (line mean_`depvar' jahr if cohort_group == 0, sort connect(L) lcolor(blue)) ///
			   (line mean_`depvar' jahr if cohort_group == 2016, sort connect(L) lcolor(red)) ///
			   (line mean_`depvar' jahr if cohort_group == 2017, sort connect(L) lcolor(green)) ///
			   (line mean_`depvar' jahr if cohort_group == 2018, sort connect(L) lcolor(orange)), ///
				title("Mean of `depvar' over Time by cohort", size(medium)) ///
				ytitle("Average `depvar'") ///
				xtitle("Year") ///
				legend(order(1 "Never Treated" 2 "Treat 2016" 3 "Treat 2017" 4 "Treat 2018") rows(1) position(6) size(small)) ///
				graphregion(color(white))
		
		
		local plot_filename "$outputpfad/EvolutionAvgOutcome_`depvar'_by_cohort.png"
		graph export "`plot_filename'", replace width(1000)
		di as text " -> Plot gepeichert als Mean_`depvar'_by_cohort.png "
		
	
	restore
}

di _newline as result "--- Plot Erstellung abgeschlossen ---"



  

	
*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block 3 :  Standard DiD 2x2 schätzen
*	----
*	-------------------------------------------------------------------------------------------------------------------

// Y_it = β₀ + β₁ * treat_post_it + α_i + γ_t + ε_it  wobei α_i fixed effect für die ags sind und γ_t fixed effekt für jahr ist und treat_post_it ein Dummy, wenn in post period und treatment gruppe!

/*
The tax hike indicator equals one if at time t municipality m increased the LBT.  specifications additionally can  include 
firm fixed effects (μi) and year fixed effects at the level of industries (ψs,t) and federal states (ϕl,t) to flexibly control for any time-invariant heterogeneity or systematic time trends in the probability of investment revisions and the frequency of tax hikes. 
In these specifications, we obtain a (generalized) difference-in-difference (DiD)
estimate.Standard errors are clustered at the municipality level.
*/


* Jahre für die einzelnen Tabellen (falls andere Jahre gefordert, vorab Behandlungs und Kontrollgruppe entsprechend bestimmen)
local cohorts_to_run "2016 2017 2018"

* abh. Variablen siehe global dependent_vars
*local dependent_vars "ln_e_persausg sigln_e_persausg rel_e_persausg rel_stpfgew ln_fobi g_reings_tru sigln_g_reing ln_inv ln_son ln_afa_bwg ln_afa_ubwg ln_steube sigln_p_einge"


foreach cohort of local cohorts_to_run {

    di _newline as result "*** Analyzing Treatment Cohort: `cohort' ***"

    *  Kohorten-spezifische Variablen für Durchlauf
    local current_treat_var ""      // Name der treat_post Variable
    local current_pattern ""        // pattern_tax der Treatment-Gruppe
    local current_post_cond ""      // Text für Post-Periode

    if `cohort' == 2016 {
        local current_treat_var "treat_post2016"
        local current_pattern   "n001000"
        local current_post_cond "Post>=2016"
    }
    else if `cohort' == 2017 {
        local current_treat_var "treat_post2017"     
        local current_pattern   "n000100"
        local current_post_cond "Post>=2017"
    }
    else if `cohort' == 2018 {
        local current_treat_var "treat_post2018"
        local current_pattern   "n000010"
        local current_post_cond "Post>=2018"
    }

    //  Sicherheit 1: Überspringe, falls für das Jahr in 'cohorts_to_run' keine Definition existiert
    if "`current_treat_var'" == "" {
        di as error "Keine Definition für Kohorte `cohort' gefunden. Überspringe."
        continue 
    }

    // Sicherheit2: Prüfe, ob die benötigte Treatment-Variable überhaupt existiert
    capture confirm variable `current_treat_var'
    if _rc != 0 {
        di as error "Benötigte Variable `current_treat_var' für Kohorte `cohort' nicht im Datensatz gefunden! Überspringe Kohorte."
        continue 
    }

    * Innere Schleife über abh Variablen, Schätzungen durchführen und speichern
  
    foreach depvar of global dependent_vars {
        capture reghdfe `depvar' `current_treat_var', a(id jahr_X_bundesland jahr_X_industry) vce(cluster ags)   // !***** MODELDEFINITION *****!
        if _rc == 0 {
            estimates store `depvar'_`cohort' // z.B. e_personalausg_2016
        }
        else {
            di as error "ERROR: Failed estimate `cohort' model for DV: `depvar'. Skipp."
        }
    }

    * // Liste der erfolgreichen Schätzungen *nur für diese Kohorte* erstellen
    local estimates_list_cohort ""
    foreach depvar of global dependent_vars {
        capture estimates describe `depvar'_`cohort'
        if _rc == 0 {
            local estimates_list_cohort "`estimates_list_cohort' `depvar'_`cohort'"
        }
    }

    * Regressionstabellen für die entsprechende Kohorte erstellen (wenn Ergebnisse existieren)
    if "`estimates_list_cohort'" != "" {
        di "--- Creating tables for Cohort `cohort' ---"

        * Basis-Dateiname mit Kohorte
        local table_filename "$outputpfad\Standard_DiD_2x2_Treat`cohort'"  // Achtung backslash forwardslash

        * Titel und Notizen 
        local table_title "Standard 2x2 DiD (Treatment Cohort: `cohort')"
        local tex_title "`table_title' \\label{tab:std_did_`cohort'}" // LaTeX Label anpassen
        local table_notes "Notes: FE: AGS, Year. Clustered SEs (AGS). Treat group '`current_pattern'', Control 'n000000'. `current_post_cond'."
        local tex_notes "\\textit{Notes:} FE: AGS, Year. Clustered SEs (AGS) in parentheses. Significance: \\sym{*} \\(p<0.10\\), \\sym{**} \\(p<0.05\\), \\sym{***} \\(p<0.01\\). Treat group '`current_pattern'', Control 'n000000'. `current_post_cond'."

        * TXT Tabelle erstellen
        esttab `estimates_list_cohort' using "`table_filename'.txt", ///
            replace wide plain b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) ///
            title("`table_title'") nonumbers stats(N, fmt(%9.0gc) labels("Observations")) ///
            addnotes("`table_notes'")

        * TEX Tabelle erstellen
        esttab `estimates_list_cohort' using "`table_filename'.tex", ///
            replace booktabs b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) ///
            title("`tex_title'") nonumbers mtitle("") ///
            stats(N, fmt(%9.0gc) labels("Observations")) addnotes("`tex_notes'")

        di "-> Tables saved as `table_filename'.txt and .tex"

    } // Ende if `estimates_list_cohort` != ""
    else {
        di as error "--- No successful estimates found for Cohort `cohort' to create tables ---"
    }

    * Gespeicherte Schätzungen für diese Kohorte löschen, bevor die nächste beginnt
    estimates drop `estimates_list_cohort'

} // Ende äußere Schleife

di _newline as result "*** Standard DID 2x2 für Kohorten beendet***" _newline




*	-------------------------------------------------------------------------------------------------------------------













*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block X :  ado Files die genutzt werden können für die Analyse mit DiD und Event am GWAP und ToDo
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






*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Ausgabe der ags bezirke in denen die beobachtungen liegen.
*	----
*	-------------------------------------------------------------------------------------------------------------------

preserve
	keep ags
	duplicates drop ags, force
	sort ags
	export excel using "$outputpfad\unique_agssample_export.xlsx", firstrow(variables) replace
	di as text "Unique AGS im Sample wurden als .xlsx in den output Ordner exportiert"
restore





