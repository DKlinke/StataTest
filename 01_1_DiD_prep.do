*-------------------------------------------------------------------------------------------------------------------
*   Project Title: THE DETERMINANTS OF TAX COMPLIANCE
*	Code: Analyze full_gwap.dta
/* 
 04_DiD_prep.do Bereitet DiD vor und schätzt Standard_DiD_2x2_'Treat`cohort 	
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
	*use "$neudatenpfad/Temp/preperation_allyears_mitmissinghebesatz.dta", clear
	
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


	keep if inlist(pattern_tax ,"n000000","n001000","n000100","n000010" ) // Kontroll und Treatmentgruppen

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
	tab pattern_tax moved, row
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
	tab nogew_basesum
	
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
	tab hebesatz_lastyear_380 nogew_basesum, col
	
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
	
	replace persbigger380 = 1 if hebesatz_lastyear_380 == 1 & inlist(rechtsform,12, 20, 21, 22,23,24,25,26, 27, 28)
	replace persbigger380 = 0 if hebesatz_lastyear_380 == 0 & inlist(rechtsform, 12, 20, 21, 22,23,24,25,26, 27, 28)
	// label var und label define label value einfügen
	label variable persbigger380 "Keine vollständige Anrechnung der Gewerbesteuer auf die Einkommenssteuer  (1=Ja / 0 =Nein)"
	
	
	
	/*
	// Checks
	tab persbigger380, missing
	tab persbigger380 hebesatz_lastyear_380
	summarize hebesatz if persbigger380 == 1
	summarize hebesatz if persbigger380 == 0
	summarize hebesatz if hebesatz_lastyear_380 == 1
	summarize hebesatz if hebesatz_lastyear_380 == 0
	
	
	*/
	
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
	e_c25131  Afa immaterielle  WG
	e_c25136  Afa unbewegliche WG
	e_c25134  Sonderabschreibungen §7g
	e_c25187  Investitionsabzugsbeträge
	e_c25225  Erhaltungsaufwendungen
	

*/

// TODO: Übersicht Gewerbe vs EÜR Variablen
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
	gen ln_afa_imm = ln(e_c25131+1) // Afa immateriell
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
	
	
	gen ah_g_reing = asinh(g_reing)
	gen ah_p_einge = asinh(p_ef34)
	gen ah_e_persausg = asinh(e_persausg)
	
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
	global dependent_vars "ln_stpfgew ln_e_persausg sigln_e_persausg ln_fobi g_reings_tru sigln_g_reing ln_g_reing ln_inv ln_afa_bwg ln_afa_ubwg ln_steube sigln_p_einge ln_hinz ln_kür ln_zins ln_gew ln_abggewerer ah_e_persausg ah_g_reing ah_p_einge"           //#
*##################################################################################################################################################################################################

*##################################################################################################################################################################################################
* MAINSPECIFICATION

	*local keep mainspecification norfswitch == 1 & moved != 1 & nogew_anr_ein == 1 & nogew_basesum != 1
	keep if norfswitch == 1
	keep if moved != 1
	*keep if persbigger380 == 1
	keep if nogew_basesum != 1

*##################################################################################################################################################################################################

*	-------------------------------------------------------------------------------------------------------------------
*  Generate Fixed Effects
*	-------------------------------------------------------------------------------------------------------------------
// industry aus wz08 extrahieren (zunächst Fokus auf Gliederungsebene Gruppen (Stelle 1 bis 3) und Abteilung (Stelle 1 bis 2) später für andere Spezifikationen und Validität auch, Klasse denkbar)

	// string transformation
	tostring wz08_base, gen(wz08_str)
	replace wz08_str = "0" + wz08_str if strlen(wz08_str) == 4  // wz08_string eine führende null hinzufügen wenn nur vierstellig umwandeln
	
	
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
	

	save "$neudatenpfad/Temp/DiD_prep.dta", replace
	
	
	
	
	//#############################################
	// Versuche fehlende hebesätze aufzufüllen! -> sichert mehr beobachtungen aus e_ variablen!.
	
	
/*
	replace hebesatz =380 if ags == 1 & inlist(jahr,2017,2018,2019)
	replace hebesatz = . if id == 501 & ags == 1
	replace hebesatz = 12 if id == 1 & ags == 1
	sort id jahr
*/


bysort ags jahr: egen korrekter_hebesatz = max(hebesatz)  // richtiger hebesatz für jede ags jahr kombination
replace hebesatz = korrekter_hebesatz if missing(hebesatz) // ersetze fehlende werte mit der korrekten Variante
drop korrekter_hebesatz //Lösche Hilfsvariable
sort id jahr // sortiere datensatz wieder wie vorher



// Optional: Überprüfe das Ergebnis
quietly bys ags jahr (hebesatz): egen temp_min_hebesatz = min(hebesatz) if !missing(hebesatz)
quietly bys ags jahr (hebesatz): egen temp_max_hebesatz = max(hebesatz) if !missing(hebesatz)
gen dif_hebesatz = .
bys id jahr : replace dif_hebesatz = 1  if temp_min_hebesatz != temp_max_hebesatz & !missing(temp_min_hebesatz) & !missing(temp_max_hebesatz)
bys id jahr : replace dif_hebesatz = 0  if temp_min_hebesatz == temp_max_hebesatz & !missing(temp_min_hebesatz) & !missing(temp_max_hebesatz)
// Zeigt wie viele Beobachtungen unterschiedliche hebesätze für dieselbe ags haben (=1) (wie oft es beobachtungen gibt die gefüllt sind und nicht gefüllt sind (=.) und wie oft die beobachtungen alle den selben hebesatz haben ( =0))
tab dif_hebesatz, missing
drop dif_hebesatz temp_min_hebesatz temp_max_hebesat


	
	
	//#############################################
	// Impute missings 3 Wege
	// Check Missings: https://stackoverflow.com/questions/24660124/how-to-check-for-any-missing-values
	
	
*-------------------------------------------------------------------------------
* 1. Definition der zu imputierenden abhängigen Variablen
*-------------------------------------------------------------------------------
global dv_to_impute "ln_stpfgew ln_e_persausg" // weitere Variablen einfügen!

*-------------------------------------------------------------------------------
* 2. Möglichkeiten mit missings umzugehen
*-------------------------------------------------------------------------------

// Weg 1 nichts unternehmen
// Weg 2 Falls ein Wert in einer id jahr Kombination mindestens einmal vorkommt, setze ihn auf null 
global dv_to_impute "ln_stpfgew ln_e_persausg" // weitere Variablen einfügen!

foreach dv of global dv_to_impute {
	di _n as green "Bearbeite Variable: `var' Fehlenden Werte von NA auf 0 setzen wenn die ID mindestens einen Non Missing Wert hat"
	bysort id (jahr): gen has_`dv' = !missing(`dv') // 1 wenn vorhanden 0 wenn missing
	by id: egen n_com_`dv' = total(has_`dv')   // Gib Anzahl der vorhandenen für vairable dieser id an
	
	*local new_var_name "`dv'_zero_conditional"
    gen `dv'_0_con = `dv'
    replace `dv'_0_con = 0 if missing(`dv') & n_com_`dv' > 0    // wird auf null gesetzt wenn die variable missing ist und insgesamt mindestens 1 wert der variable non missing ist

    label variable `dv'_0_con "`var', Missings als 0 (konditional)"

	drop has_`dv'
}

foreach dv of global dv_to_impute {
	*drop `dv'_0_con
	*drop has_`dv'
	*drop n_com_`dv'
}

//Weg 3 Alle missings in den abhängigen Variablen auf 0 setzen
foreach dv of global dv_to_impute {
	di _n as green "Bearbeite Variable: `var' Fehlenden Werte von NA auf 0 setzen"
    gen `dv'_0= `dv'
    replace `dv'_0 = 0 if missing(`dv')    // wird auf null gesetzt wenn die variable missing ist und insgesamt mindestens 1 wert der variable non missing ist
    label variable `dv'_0 "`var', Alle missings als 0"

}



	//#############################################
	// Plausibilität der abhängigen Variablen klären! -> 
	
	// observations winsorizen win abhängige variable //
	
	global dv_to_win "ln_stpfgew ln_e_persausg" // weitere Variablen einfügen!
	
	local lower_perc 1
	local upper_perc 99


foreach var of global dv_to_win {
    display "Winsorisiere Variable: `var' am `lower_perc'. und `upper_perc'. Perzentil..."
	
	// Perzentilwerte bestimmen und speichern
    centile `var', centile(`lower_perc' `upper_perc')
	local lower = r(c_1)
	local upper = r(c_2)
	// Prüfe existenz der Perzentilwerte 
    if lower == . | downer == . {
        display as error "Konnte Perzentile für `var' nicht bestimmen. Überspringe Variable."
        continue 
    }
	
    // Neue Variable für die winsorisierten Werte  
    generate `var'_w = `var'
    label variable `var'_w "`var' (winsorized `lower_perc'% - `upper_perc'%)"

    // Werte unterhalb/oberhalb des unteren/oberen Perzentils auf den Wert des unteren/oberen Perzentils setzen
    replace `var'_w = `lower' if `var' < `lower' & !missing(`var')
    replace `var'_w = `upper' if `var' > `upper' & !missing(`var')
    
    display as result "-> Neue Variable `var'_w wurde erstellt."
}

foreach var of global dv_to_win {
drop `var'_w
}

display _newline "Winsorisierung für alle angegebenen Variablen abgeschlossen."


/*
local loe = 1
local upe = 90

local loe = 5
centile ln_stpfgew, centile(`loe' `upe')
local lower = r(c_1)
local upper = r(c_2)

gen lnwtest = ln_stpfgew
replace lnwtest = `upper' if lnwtest > `upper'
replace lnwtest = `lower' if lnwtest < `lower'
scalar list

tab ln_stpfgew if ln_stpfgew > 0.47
tab lnwtest if lnwtest > 0.47

tab lnwtest if lnwtest < -4.7
tab ln_stpfgew if ln_stpfgew < -4.7

sum ln_stpfgew

	centile g_reings, centile(0.5 99.5)
	gen g_reings0_5 = r(c_1)
	gen g_reings99_5 = r(c_2)
	gen g_reings_tru = g_reings if g_reings <= g_reings99_5  & g_reings >= g_reings0_5   // percentile einteilung in Ordnung? zu viele extreme reing sätze
	
*/
	
	// observations droppen
	
	global dv_to_trun "ln_stpfgew ln_e_persausg" // weitere Variablen einfügen!
	
	
	// observations droppen / die ganze id 
	
	global dv_to_drop "ln_stpfgew ln_e_persausg" // weitere Variablen einfügen!
	

/*
*####################################################################################################################################################

// WInsorizing ohne winsor2

*##################################################################################################################################################################################################
*	global dependent_vars "ln_stpfgew ln_e_persausg sigln_e_persausg ln_fobi g_reings_tru sigln_g_reing ln_g_reing ln_inv ln_afa_bwg ln_afa_ubwg ln_steube sigln_p_einge ln_hinz ln_kür ln_zins ln_gew ln_abggewerer ah_e_persausg ah_g_reing ah_p_einge"           //#
*##################################################################################################################################################################################################

local varlist_to_process "IhreVariable1 IhreVariable2 IhreVariable3" 
local lower_perc 1
local upper_perc 99


foreach var of local varlist_to_process {
    display "Winsorisiere Variable: `var' am `lower_perc'. und `upper_perc'. Perzentil..."

    // Perzentile für die aktuelle Variable berechnen (global)
    // 'quietly' unterdrückt die Ausgabe von summarize
    quietly summarize `var', detail 
    
    // Perzentilwerte speichern
    local p_low_value = r(p`lower_perc') 
    local p_high_value = r(p`upper_perc')

    // Sicherheitscheck: Perzentilwerte gefunden wurden
    // wichtig, falls eine Variable z.B. nur aus fehlenden Werten besteht
    // oder zu wenige Beobachtungen für die Perzentilberechnung hat.
    if "`p_low_value'" == "" | "`p_high_value'" == "" {
        display as error "Konnte Perzentile für `var' nicht bestimmen. Überspringe Variable."
        continue // Geht zur nächsten Variable in der Schleife
    }

    // Neue Variable für die winsorisierten Werte erstellen 
   
    generate `var'_w = `var'
    label variable `var'_w "`var' (winsorized `lower_perc'% - `upper_perc'%)"

    // Werte unterhalb des unteren Perzentils auf den Wert des unteren Perzentils setzen
    replace `var'_w = `p_low_value' if `var' < `p_low_value' & !missing(`var')

    // Werte oberhalb des oberen Perzentils auf den Wert des oberen Perzentils setzen
    replace `var'_w = `p_high_value' if `var' > `p_high_value' & !missing(`var')
    
    display as result "-> Neue Variable `var'_w wurde erstellt."
}

display _newline "Winsorisierung für alle angegebenen Variablen abgeschlossen."


*/

/*
b) ich habe mir nochmal angeschaut welche Beobachtungen für fehlende Hebesätze nicht gefüllt sind. Direkt zu Beginn werfe ich extrem viele Beobachtungen raus (fast 50% , ich schaue weiterhin nur Personengesellschaften und Sonstige Gewerbetreibende an), die einen fehlenden Hebesatz haben (für jeweils ca 2-4% der ids fehlt der hebesatz in 1,2,3,4,5,6 Jahren für ca 40% in den gesamten 7 Jahren und für ca 50% ist er über alle Jahre komplett vorhanden, ich schaue mir hierfür nur ids an die über alle 7 Jahre im Datensatz enthalten sind) . Die ags ist jedoch quasi für alle diese Beobachtungen  (bis auf ein paar 1000) vorhanden.
Der hebesatz stammt aus der Gewerbesteuerstatistik, deshalb habe ich mir hierfür auch einmal die restlichen abhängigen Variablen aus der Gewerbesteuer, die ich bisher genutzt habe (und die g_ags aus der Gewerbesteuer) angeschaut.  Die fehlenden Werte überlappen sich exakt. Für alle Beobachtungen für die der hebesatz fehlt, fehlen auch die restlichen Variablen aus der Gewerbesteuerstatistik, die ich betrachtet habe. Die Variablen aus der Einkommenssteuerstatistik sind jedoch für diese Beobachtungen teilweise sehr gut gefüllt. Wenn man den hebesatz basierend auf der ags befüllt, kämen für die e_ Variablen (und p_ef34) nochmal 25 bis 105% der Beobachtungen hinzu. Das erklärt dann vermutlich auch den Grund warum die Beobachtungen mit e_ Variablen insgesamt immer so niedrig ausfallen (also auch für die Kapitalgesellschaften).
Das ist in der Tat komisch. Meine Vermutung wäre, dass es sich um Kleinunternehmen handeln könnte, die unter dem Freibetrag von 24500 Euro (die Schwelle war früher evtl niedriger) liegen? Die müssen ggf dennoch die EÜR abgeben. Trift das insb. auf solche Kleinunternehmen zu? Oder sind das Freiberufler o.ä. (ebenfalls keine Gewerbesteuer)? Ggf. könntest du hier mal Rechtsformen und Gewinn checken.
Wenn die Unternehmen schlicht und einfach keine Gewerbesteuer zahlen müssen, dann sollten sie auch nicht im Sample sein. Wenn hingegen bei Gewerbesteuer zahlenden Unternehmen der Hebesatz fehlt, ist das ein Problem. Wenn die ganze Statistik fehlt und die Unternehmen aus irgendeinem Grund nicht gewerbesteuerpflichtig sein könnten, spricht das für ersteres.
Vielleicht könntest du dir das auch noch einmal genauer anschauen, Simon?
Kapitalgesellschaften sind bilanzierungspflichtig und sollten daher keine e-Variablen haben. Daten zur Gewerbesteuer sollten aber eigentlich vorhanden sein. 

Mich würde interessieren, wieso diese Variablen aus der Gewerbesteuerstatistik nicht gefüllt sind und ob hier eine Systematik dahintersteckt. Ich habe bereits geschaut ob es sich dabei um Unternehmen handelt die einfach keine Gewerbesteuer zahlen, das erklärt aber die große Anzahl der fehlenden Werte nicht.
Wo kann ich denn den Code finden der "full_gwap.dta" erzeugt ? Oder ist das derselbe Code der „full.dta“ erzeugt (github)  ? 
Das ist quasi derselbe Code, der Unterschied ist bspw ob die Variable Jahr groß oder klein geschrieben wird. Kann gut sein, dass ich vergessen hatte, den Code für full_gwap zu committen - bin gerade am Handy, kann mir das aber irgendwann anders anschauen und ihn noch einmal hochladen.
Vielleicht ist das Problem auch etwas größer und liegt beim Stabu?
Das wäre suboptimal. Checkt aber erst einmal, ob es einen Grund gibt, warum die keine Gewerbesteuer zahlen.
Ich würde aber nicht ausschließen, dass das StaBu Probleme beim Merge Gewerbesteuer und EüR hatte... Wenn wir keine Erklärung finden, sollten wir nachfragen. 

Ergibt es dann Sinn und ist es unproblematisch möglich ein File das ags und hebesatz über die Jahre enthält an den GWAP zu schicken (um zumindest die e_ Variablen zu „retten“) ? Wenn ich richtig gesehen habe, dann habt ihr das Zusenden eines externen Datensatzes so ähnlich auch mit den Richtsätzen für euer anderes Projekt gemacht? 
Kann man das nicht über andere Unternehmen im gleichen Ort imputieren? Gleiche AGS = gleicher Hebesatz? Wie gesagt nur, wenn wir Grund zur Annahme haben, dass das Unternehmen eigentlich gewerbesteuerpflichtig ist. 
Eigentlich muss man für einen Merge mit einem externen Datensatz zahlen und das dauert dann eine ganze Zeit... Daher würde ich erst einmal andere Wege probieren.

Falls das sehr Zeitintensiv sein sollte, ist es vermutlich besser erstmal alles weiter so zu belassen ?

Für das weiter so belassen scheint die Hinzunahme der gewerbesteuerzahlenden sonstigen Gewerbetreibenden die Ergebnisse etwas ähnlicher zu machen zwischen >380 und <380. Unterschiedliche Gewinnvariablen zeigen für beide Fälle einen positiven Effekt nach der Steuererhöhung. Es gibt nun insgesamt auch mehr signifikante Effekte bei den >380 unternehmen, jedoch unterschiedliche Effekte bei den Ausgaben für Steuerberatung in t 1  >380: positiv    und <380: negativ. 
Interessant! Und teils ein bisschen überraschend.

Das 0 Füllen und Winsorizen hat bisher die Ergebnisse noch nicht so groß verändert. Ich habe hier aber noch nicht alles ausprobiert.
Und wenn du die Beobachtungen droppst statt winsorized?



*/

