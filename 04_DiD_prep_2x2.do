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
	*use "$neudatenpfad/Temp/chatDiD.dta", clear
	use "$neudatenpfad/Temp/preperation_allyears.dta", clear
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

*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
* STEP 2: Behandlungs und Kontrollgruppe festlegen
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
* Drop ags changing (i.e. moving) firms 
*	-------------------------------------------------------------------------------------------------------------------
	by id (ags), sort: gen byte moved = (ags[1] != ags[_N]) // solche ids die unterschiedliche ags haben, sich also dem treatment potentiell (un)absichtlich entziehen werden gedropped
	tab pattern_tax moved if inlist(pattern_tax, "n000100", "n000000"), col
	tab pattern_tax moved, col
	*drop if moved == 1 // Achtung moved für spätere Analyse evtl. noch interessant, falls ja hier auskommentieren und im model if moved != 1 hinzufügen
	
	
*	-------------------------------------------------------------------------------------------------------------------
* Drop rechtsform changing firms 
*	-------------------------------------------------------------------------------------------------------------------

* Unterscheide in firms die legal form ändern und die sie behalten
	bysort  id (jahr): egen minrf = min(rechtsform)   // Alternativ by id :
	bysort id (jahr): egen maxrf = max(rechtsform)
	gen norfswitch = minrf == maxrf
	drop minrf maxrf
	label var norfswitch "firm keeps legal status"
	tab norfswitch
	***************************
	*keep if norfswitch == 1 
	***************************
		
	
	// Genauere Analyse der Rechtsformwechsel
	sort id jahr
	gen L_rechtsform = L.rechtsform

	gen rf_changed = (rechtsform != L_rechtsform) & (!missing(L_rechtsform))   // oder == 0

	gen rf_original = L_rechtsform if rf_changed == 1
	gen rf_new = rechtsform if rf_changed == 1

	by id: egen n_rf_changes = total(rf_changed)
	label var n_rf_changes "Anzahl der Rechtsformwechsel pro Unternehmen"

	* Tabellarische Übersicht über die Anzahl der Wechsel pro Unternehmen
	noi disp ""
	noi disp "Verteilung der Anzahl der Wechsel pro Unternehmen:"
	tab n_rf_changes

	* Tabellarische Übersicht über die Art der Wechsel (Von -> Nach)
	noi disp ""
	noi disp "Häufigkeit der spezifischen Wechsel (Originalform -> Neue Form):"
	tab rf_original rf_new if rf_changed == 1, missing

	* Bereinigung
	 drop L_rechtsform rf_changed rf_original rf_new
		
	
			
*	-------------------------------------------------------------------------------------------------------------------
*  Differenzierung Gewerbesteuerpflichtig (Zahlt Gewerbesteuer vs nicht)
*	-------------------------------------------------------------------------------------------------------------------

// Überprüfungsgröße: Wenn g_k6522 (Freibetrag) >0 und nicht missing dann handelt es sich um personengesellschaft, da Kapgesellschaft keine freibeträge

// e_ef19	Zuordnung zu Person und Einkunftsart Kz 15.105  03,04,08 = Gewerbebetrieb    01,02,07 = LUF = LandundForstwirtschaft   05,06,09 = Selbständig , Freiberuflich 


	// Fälle von Unternehmen die Gewerbesteuer zahlen
	gen nogew = 0 
	replace nogew = 0 if inlist(e_ef19, 03,04,08) // & persges == 1 

	// Fälle von Unternehmen die nicht zahlen
	replace nogew = 1 if g_k6524 <= 0 // Keine Bemessungsgrundlage -> keine Gewerbesteuer ,passt der Füllungsgrad von  g_k6524? 
	replace nogew = 1 if inlist(e_ef19, 01,02,07) // & kapges != 1  // LandundForstwirtschaft und keine Kapitalgesellschaft
	replace nogew = 1 if inlist(e_ef19, 05,06,09) // Freiberuflich

	label var nogew "liability to LBT"
	label define placelb 0 " 0 liable" 1 " 1 not liable", replace // 0= Company pays LBT 1= Company does not pay LBT
	label value nogew placelb
	
	
	// Überprüfung ob Unternehmen insgesamt als gewerbesteuer zahlend oder nicht eingestuft wird. Bedingung: wenn Firma mind. Hälfte der beobachteten Jahre nogew=1 hat, dann wird sie insgesamt auf nogew_basesum=1 gesetzt 
	sort id jahr
	bysort id : egen sum_nogew = total(nogew)
	gen nogew_basesum = (sum_nogew >= 4)
	drop sum_nogew

	label var nogew_basesum "Firma mind. 4 Jahre nicht GewStpflichtig (Full Panel 13-19)"
	label define nogew_basesumlb 0 "<4J nicht pflichtig" 1 ">= 4J nicht pflichtig"
	label values nogew_basesum nogew_basesumlb

	
// g_k6524 Der Betrag (also  Gewerbeertrag zu ermitteln, der die objektive Ertragskraft ), der nach Abzug des Freibetrags für die Berechnung der Gewerbesteuer übrig bleibt	

// teste ggf: g_k2110	Gewinn aus Gewerbebetrieb + g_fef315	Summe Hinzurechnungen - g_fef316	Summe Kürzungen = ungefährt abgerundeter Gewerbeertrag?   oder fehlt noch g_k2152	Von der Gewerbesteuer befreiter Anteil am Gewinn aus Gewerbebetrieb (Kz 21.10), g_k6516	Gewerbeertrag vor Anrechnung der Gewerbeverluste (einschl. Gewerbeertrag der Organgesellschaften), g_k6517	Angerechnete Gewerbeverluste (Verlustverbrauch § 10a GewStG) (K 65.17 bzw. K 37.17)

// teste ggf: ist g_k6520 (abgerundeter Gewerbeertrag) -g_k6522 (Freibetrag) =g_k6524  ?


/*
Weitere Befreiungen und Sonderregelungen gelten für bestimmte Genossenschaften wie Wald- und Laubgenossenschaften, staatliche Lotterieunternehmen, Krankenhäuser und Pflegeheime, die bestimmte soziale Kriterien erfüllen, gemeinnützige Körperschaften, bestimmte Vereine und Genossenschaften sowie kleine Fischereibetriebe §3 GewStG
*/


*----------------------------------------------------------------------------------------------------------------
* Keine vollständige Gewerbesteueranrechnung auf die Einkommenssteuer ist möglich
*----------------------------------------------------------------------------------------------------------------
// Identifiziere hebesatz >380 Fälle
	* Fall 1: Hebesatz im letzten Jahr der Beobachtung einer id größer als 380
	sort id jahr
	bysort id (jahr): generate byte temp_check = (hebesatz > 380) if _n == _N
	bysort id: egen byte hebesatz_lastyear_380 =max(temp_check)
	drop temp_check
	
	*check wie viele betroffen?
	tab hebesatz_lastyear_380
	
	/*
	* Subfall A (evtl. für spätere Analysen spannend): Hebesatz überschreitet im Verlauf der Zeit (erstes Jahr vs letztes Jahr) die Schwelle 380
	
	bysort id (jahr): gen double first_year_hebesatz = hebesatz[1]
	bysort id (jahr): gen double last_year_hebesatz = hebesatz[_N]
	gen byte hebesatz_schwelle_380 = (first_year_hebesatz < 380) & (last_year_hebesatz > 380)
	tab hebesatz_schwelle_380
	
	* Subfall B (evtl. für spätere Analysen spannend): Hebesatz war bereits im ersten Jahr > 380, wird nochmal angehoben, und ist auch im letzetn Jahr > 380
	gen byte hebesatz_380_380 = (first_year_hebesatz > 380) & (last_year_hebesatz > 380)
	tab hebesatz_380_380
	*/
	
	* Erhöhung der gewerbesteuer sollte bei Personengesellschaften ledliglich Effekte auf Firmen haben die in Gemeinde mit Hebesatz >380 sind. Wenn Personengesellschaften Untersuchungsgegenstand sind, behalte nur Personengesellschaften die hebesatz über 380 haben.
	
	gen nogew_anr_ein = 0
	replace nogew_anr_ein = 1 if hebesatz_lastyear_380 == 1 & inlist(rechtsform, 20, 21, 22, 23, 24, 25, 26, 27, 28)
	label var nogew_anr_ein  "Keine vollständige Gewerbesteueranrechnung auf Einkommenssteuer"
	label define geweinlb 0 "vollst. Anr. der GewSt auf ESt möglich" 1 "Keine vollst. Anr. mögl. da hebesatz > 380 und persges", replace 
	label value nogew_anr_ein geweinlb
	
	
	 	
*	-------------------------------------------------------------------------------------------------------------------
*  Übernehmen der initialen Werte der Firmenwahl, damit keine wechsel in bestimmten bereichen -> wz08 , gk 
*	-------------------------------------------------------------------------------------------------------------------	
	
* Gibt initiellen Wert der Firma im ersten Jahr und übernimmt diesen Wert für alle weiterfolgenden Jahre. Variable heist dann varname_base
local basics wz08 gk
foreach b of local basics {
	bysort id (jahr): gen tmp_`b' = `b' if _n ==1
	by id: egen `b'_base = mean(tmp_`b') // entspricht wert aus erstem jahr da der rest von tmp_`b' missing werte ist
	drop tmp_`b'
	local get: variable  label `b' // nachfolgend Variablenbeschriftung
	label var `b'_base "initial `get'"
	local get2: variable  label `b'_base
	local get3 : subinstr local get2 " (mean)" ""
	label var `b'_base "`get3'"
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
* cohort_group Variable
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

		
*	-------------------------------------------------------------------------------------------------------------------
*  Überblick Transformation ausgewählter Variablen
*	-------------------------------------------------------------------------------------------------------------------
	/*
*	
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
*	inspect g_reings  ->   theoretisch geeignet


Investitionsindikatoren
	e_c25130  Afa bwegeliche WG
	e_c25136  Afa unbewegliche WG
	e_c25134  Sonderabschreibungen §7g
	e_c25187  Investitionsabzugsbeträge
	e_c25225  Erhaltungsaufwendungen
	Erhaltungsaufwendungen (in Cent) Aufwendungen (Reparaturen,Wartungen und Renovierungen), die zur Erhaltung des Werts und der Funktionsfähigkeit von Wirtschaftsgütern des Anlagevermögens dienen und als Betriebsausgaben in der EÜR abzugsfähig sind. (Frühindikator für Abwanderung bzw. Erstreaktion auf HS-Anpassung)

*/

	sort id jahr

	gen ln_e_persausg = ln(e_persausg) // entfernt negative Werte, die keinen Sinn ergeben
	gen ln_stpfgew =ln(stpfgew)

	gen sigln_stpfgew = sign(stpfgew) * ln(abs(stpfgew)+1)
	gen sigln_e_persausg = sign(e_persausg) * ln(abs(e_persausg)+1)

	gen rel_stpfgew=((stpfgew-L.stpfgew)/abs(stpfgew))*100 // in Prozent
	gen rel_e_persausg=((e_persausg-L.e_persausg)/abs(e_persausg))*100
	
	gen ln_fobi = ln(e_c25281) // entfernt negative Werte in Fortbildungskosten, die keinen Sinn ergeben
	
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
	gen ln_inv = ln(e_c25187)  // Investitionsabzugsbeträge

	gen ln_afa_bwg = ln(e_c25130)  // Afa bewegliche WG
	gen ln_afa_ubwg = ln(e_c25136)  // Afa unbewegliche WG
	gen ln_erhauf= ln(e_c25225) // Erhaltungsaufwendungen , nur pos Werte
	
	gen ln_steube = ln(e_c25194) // Steuerberatung, nur pos Werte
	gen sigln_p_einge = sign(p_ef34)* ln(abs(p_ef34)+1)  // Einkünfte aus Gewerbebetrieb
	
	
* asinh() Transformation statt sigln Transformation asinh(y)=ln(y+(y^2+1)^0.5​) : siehe Norton(2022), Achtung Einheit ( Euro, tausend Euro, 10k € 100k€) wirkt sich auf Ergebnis aus

	* Neue Variable mit asinh()-Transformation erstellen
	gen ihs_g_reing = asinh(g_reing)
	gen ihs_p_einge = asinh(p_ef34)
	gen ihs_stpfgew = asinh(stpfgew)
	gen ihs_e_persausg = asinh(e_persausg)


/*
* Regression mit der transformierten Variable schätzen, bzw interpretation der Effekte
//tbd

* Residuen der Regression speichern
predict double ehat, residual

* Duan's Smearing Faktor berechnen (Mittelwert der exp. Residuen)
egen double duan = mean(exp(ehat)) if e(sample)

* Durchschnittliche Marginaleffekte auf der Originalskala von 'y' berechnen
margins, dydx(*) expression(0.5 * (exp(xb()) * duan - (1 / (exp(xb()) * duan)))) vce(delta)

* Optional: Residuen und Duan-Faktor löschen, wenn nicht mehr benötigt
 drop ehat duan
 
 
 
* Annahmen:
* - Sie haben die Regression geschätzt:
* regress y_ihs i.treat##i.post [andere_variablen], vce(robust)
* - Sie haben den Duan-Faktor berechnet:
* predict double ehat, residual
* egen double duan = mean(exp(ehat)) if e(sample)

* Berechne den DiD-Effekt auf der Originalskala von 'y'
* Die Option r.treat##r.post (oder c.treat##c.post, je nach Variable)
* fordert die Berechnung der Unterschiede über die Interaktion an.
margins r.treat##r.post, ///
        expression(0.5 * (exp(predict(xb)) * duan - (1 / (exp(predict(xb)) * duan)))) vce(delta)

* Alternativ, falls treat/post nicht als Faktorvariablen spezifiziert wurden:
* margins, dydx(treat) at(post=(0 1)) ///
* expression(0.5 * (exp(predict(xb)) * duan - (1 / (exp(predict(xb)) * duan)))) ///
* vce(delta)
* (Dieser zweite Ansatz berechnet den Effekt von 'treat' für post=0 und post=1,
* die Differenz dieser beiden Effekte ist der DiD)
* Interpretation:
Im Output des ersten (und üblicheren) margins-Befehls suchen Sie nach dem Kontrast, der der doppelten Differenz entspricht. Dieser ist oft als 1.treat#1.post (oder ähnlich, abhängig von Ihren Variablennamen und ob Sie Faktorvariablen i. verwendet haben) gekennzeichnet.
Der geschätzte Wert für diesen Kontrast ist Ihr DiD-Schätzer (ATT) auf der Originalskala Ihrer abhängigen Variable y.
Beispiel: Wenn der Wert für 1.treat#1.post im margins-Output 1500 ist und y der Reingewinn in Euro war, lautet die Interpretation: "Die Behandlung führte im Durchschnitt zu einem um 1500 Euro höheren Reingewinn bei den behandelten Einheiten im Vergleich zu dem, was sie ohne Behandlung gehabt hätten (relativ zur Kontrollgruppe)."
*/


*	-------------------------------------------------------------------------------------------------------------------
*  Dependent Variables and Main specification 
*	-------------------------------------------------------------------------------------------------------------------
	
*### DEPENDENT VARIABLES ########################################################################################################################
	global dependent_vars "ln_stpfgew ln_e_persausg sigln_e_persausg  ln_fobi g_reings_tru sigln_g_reing ln_inv ln_afa_bwg ln_afa_ubwg ln_erhauf ln_steube sigln_p_einge"          
*#################################################################################################################################################

*### MAIN SPEC ########################################################################################################################

	local mainspecification norfswitch == 1 & moved != 1 & nogew_anr_ein == 1 & nogew_basesum != 1 // mainspecification enthält alle die nie die rechtsform gewechselt haben, alle die nie ihren standort gewechselt haben, alle die die Gewerbesteuer nicht vollständig auf die Einkommenssteuer anrechnen können, alle die nicht keine Gewerbesteuer zahlen müssen (Landwirte, Bemessungsgrundlage von 0 oder kleiner ). die ersten beiden Punkte beziehen sich auf Entzug des Treatments, die zweiten beiden darauf ob praktisch überhaupt von der Gewerbesteuererhöhung betroffen. 
	
	keep `mainspecification'

	
	//reghdfe `yvar' `xvars' `mainspecification', absorb(`fe') vce(cluster `clvar')
	
	

*#################################################################################################################################################

*	-------------------------------------------------------------------------------------------------------------------
*  Generate Fixed Effects
*	-------------------------------------------------------------------------------------------------------------------
// industry aus wz08 extrahieren (zunächst Fokus auf Gliederungsebene Gruppen (Stelle 1 bis 3) später für andere spezifikationen und Validität auch Abteilung, Klasse und Unterklasse denkbar)

	//string: gen industry = substr(wz08,1,3)
	tostring wz08, gen(wz08_str)
	gen industry = substr(wz08_str, 1, 3)
	destring industry, replace //transf. num Var

// industry_base

	bysort id (jahr): gen tmp_industry = industry if _n == 1
	by id: egen industry_base = mean(tmp_industry) // entspricht wert aus erstem jahr da der rest von tmp_`b' missing werte ist
	drop tmp_industry
	label var industry_base "Industry aus erster Beobachtung"
	
// Fixed Effects

	egen jahr_X_bundesland = group(jahr bundesland_num)
	label variable jahr_X_bundesland "Jahr X Bundesland id"
	egen jahr_X_industry = group(jahr industry_base) 
	label variable jahr_X_industry "Jahr X Industry id"
	egen jahr_X_industry_X_bundesland = group(jahr industry_base bundesland_num)
	label variable jahr_X_industry_X_bundesland "Jahr X Bundesland Y Industry id"

	
	

*	-------------------------------------------------------------------------------------------------------------------
*  Generate Heterogenitäten 
*	-------------------------------------------------------------------------------------------------------------------
	
/* Bsp Implementierung:
	reghdfe depvar c.taxhike#i.rec , absorb(plantnum year_X_industry year_X_state) 
	
	// Beispiel für Tabelle C.5 / C.7 
	reghdfe depvar c.taxhike#i.rec#i.umsatzdropf i.umsatzdropf , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017)
	
	Link 2024 verwendet bspw.:
	
	Heterogenitäten:
	Variablen wie Firmengröße (large_emp), Indikatoren für finanzielle Schwierigkeiten (fin_p), Profitabilitätsprobleme (prof_p), Lage in ländlichen Gebieten (land), Volatilität des Umsatzwachstums (high_sd_gr_rev), Häufigkeit früherer Steuererhöhungen (many_hikes, hike_5noyears) oder Rezessionsindikatoren (rec, rec_y), siehe 03_prep.do
	
	Kontrollvariablen:
	keine Kontrollvariablen wegen des Forschungsdesigns mit Investitionsrevision (eliminiert a priori Störfaktoren)
	
	
	Fuest 2018 verwendet bspw.:
	
	Heterogeniätten
	liability, branche, tarifbindung, Profitabilität, Unternehmensgröße, Marktmacht, Betriebsstruktur, Eigentümerstruktur, Heterogeniäten auf Arbeitnehmerebene ...
	
	Kontrollvariablen: 
	lagged Regionale/Kommunale Kontrollvariablen (ökonomische Situation und Fiskalpoliitk der Gemeinden: alq bip popul ...)
	Betriebliche Kontrollvariablen (für Veränderungen auf Betriebsebene die zeitvariierend sind) (z.B. verzöggerte Beschäftigungszahlen)
	Betriebliche Zusammensetzungskontrollvariablen (prüfe ob sich Zusammensetzung der Belegschaft eines BEtriebs über die Zeit ändert, bspw. age, male skill, beschäftigungsart, berufsstatus)
	Individuelle Arbeitnehmermerkmale (Betriebszugehörigkeit, Qualifikation, Beschäftigungsgruppe)
	RobustheitschecksKontrollvariablen:
	
	
*/


*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block 2 :  number of units in each cohort and average outcome over time
*	----
*	-------------------------------------------------------------------------------------------------------------------

*	-------------------------------------------------------------------------------------------------------------------
*  Number of units in each cohort
*	-------------------------------------------------------------------------------------------------------------------

di _newline as result "-----------------------------------------------------------------"
di as result "Gesamtzahl eindeutiger Firmen (IDs) pro Kohorte"
di as result "-----------------------------------------------------------------"

bysort id: gen byte _is_first_id_obs = (_n == 1) 
tabulate cohort_group _is_first_id_obs 
drop _is_first_id_obs

di _newline as result "-----------------------------------------------------------------"
di as result "Gesamtzahl eindeutiger Firmen (IDs) pro Kohorte"
di as result "Nur Firmen mit nicht fehlenden Werten für die entsprechende Variable"
di as result "-----------------------------------------------------------------"


foreach depvar of global dependent_vars {
	di _newline as text "---Abhängige Variable: `depvar'"
	
	preserve
	
		keep if !missing(`depvar')  // löscht wenn depvar fehlend
		bysort id: keep if _n == 1  // löscht alle Beobachtungen die zur selben id gehören damit einzelne Unternehmen gezählt werden und nicht alle sieben Jahre
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
        capture reghdfe `depvar' `current_treat_var', a(id jahr_X_bundesland jahr_X_industry) vce(cluster ags)   // !***** MODELDEFINITION *****! verwende id fixed effects, jahr_X_industry fe und jahr_X_bundesland fe.
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





