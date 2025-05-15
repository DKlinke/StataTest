*-------------------------------------------------------------------------------------------------------------------
*   Project Title: THE DETERMINANTS OF TAX COMPLIANCE
*	Code: Prepare full_gwap.dta
/*  
 01_preperation.do bereitet den Datensatz full_gwap.dta für die Analyse auf, es werden neue variablen erstellt oder variablen umbenannt
*/
*-------------------------------------------------------------------------------------------------------------------

*-------------------------------------------------------------------------------------------------------------------

/* 
**********************
* Original Variablen:*
**********************
	jahr
	id
	wz08

Gewerbesteuer:
	g_fef14       g_fef19       g_fef21       g_fef303      g_fef310      g_fef311_round  g_fef316      g_k2131       g_k6516       g_k6520       g_k6524       g_k65282
	g_fef17       g_fef20       g_fef301      g_fef307      g_fef311      g_fef315      g_k2110       g_k2152       g_k6517       g_k6522       g_k65277      g_wz08

EÜR:
	e_c15111  e_c20111  e_c25120  e_c25130  e_c25134  e_c25138  e_c25181  e_c25187  e_c25199  e_c25218  e_c25225  e_c30111  e_c65121  e_c65140  e_ef14    e_ef19    e_wz08
	e_c20102  e_c20159  e_c25123  e_c25131  e_c25136  e_c25180  e_c25182  e_c25194  e_c25217  e_c25219  e_c25281  e_c65120  e_c65130  e_ef13    e_ef15    e_ums

UmsatzsteuerVeranlagung:
	v_ef4   v_wz08  v_ef16  v_ums

Personengesellschaften:
	p_ef34

******************************************************************
*Umbenannte Variablen (und daraus neu erzeugte variablen:		 *
******************************************************************

	rename g_fef307 g_ags 
	rename v_ef4 v_ags
	rename e_ef13 e_ags
	gen ags = g_ags

	rename g_fef303 g_rechtsform 
	rename v_ef16 v_rechtsform
	rename e_ef14 e_rechtsform
	gen rechtsform = g_rechtsform

	rename g_fef17 g_gk 
	rename e_ef15 e_gk 
	gen gk = g_gk

	rename g_fef311 hebesatz
	rename g_fef301 zerlegung 
	rename e_c25120 e_persausg
	rename e_c65120 e_rohgs1 // Rohgewinnsatz 1
	rename e_c65121 e_rohgs2 // Rohgewinnsatz 2
	rename e_c65130 e_halbreings // Halbreingewinnsatz
	rename e_c65140 e_reings // Reingewinnsatz 
	rename e_c25219 stpfgew // Steuerpfl. Gewinn

******************************************************************
*Neu generierte Variablen:										 *
******************************************************************
	g_reing = g_k6520 - g_fef315 + g_fef316 // Reingewinn = Gewerbeertrag - Hinzurechnungen + Kürzungen 
	g_reings = g_reing / v_ums * 100 // Reingewinnsatz = Reingewinn/Umsatz *100
	bundesland
	
	davon taxchange variablen:
	// Dummy variablen für hike bzw. drop der Steuer
		taxhike  "Tax Hike Indicator"
		taxdrop  "Tax Drop Indicator"
		changes = taxdrop + taxhike // entspricht 1 wenn es in der periode eine Anderung gab 

	// Anzahl der tax hikes bzw. drops für jede municipality im Zeitraum 2013 bis 2019
		n_hikes "Number of Hikes"
		n_drops  "Number of Drops"


	// Steuerrate und Veränderung absolut (Prozentpunkte) und relativ (Prozent)
		messzahl = 0.035  
		taxrate = hebesatz * messzahl
		taxchange "Tax Change in Prozentpunkten"
		log_net = log(1-(taxrate/100)) - log(1-(L.taxrate/100)) net of tax
		
*/
*-------------------------------------------------------------------------------------------------------------------
 
*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block I: Orgiginal Daten laden und ggf. Variablenname anpassen
*	----
*	-------------------------------------------------------------------------------------------------------------------

//Pfaddefinition siehe 00_masterSD

if $FDZ == 1 {
    use "$datenpfad/${dateiname}", clear
		
	* Prüfen, ob die Variable 'Jahr' beginnend mit Großbuchstaben geschrieben wurde in den FDZ Daten. Falls das so war, umbenennen (dann existiert Abweichung in Variablenbezeichnung zwischen gwap und fdz Daten)
	capture confirm variable Jahr
	if _rc == 0 {
		rename Jahr jahr	
	}
}
else if $FDZ == 0 { // Nutze Random File oder Testfile
	use "$neudatenpfad/Temp/Random.dta", clear
    *use "$datenpfad/${dateiname}", clear

}
else if $FDZ == 2 {
    use "$datenpfad/${dateiname}", clear
}


*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block II: Datenbearbeitung: Selektion, Neudefinition und Umbennung 
*	----
*	-------------------------------------------------------------------------------------------------------------------

*******************************
*  Selektion			      *
*******************************

* Drop wenn id oder hebesatz fehlt

	drop if missing(g_fef311)
	drop if missing(id)

* e_c30111 Liebhaberei Unternehmen droppen

	drop if e_c30111 == 1
	drop e_c30111

* Zerlegungsfälle droppen

	drop if g_fef14 == 1

*Organschaft und Organträger droppen: Gewerbeertrag jeder Organgesellschaft wird getrennt ermittelt und Organträger zur Berechnung des Steuermessbetrags zugerechnet

	drop if inlist(g_fef21, 1, 2, 3)

// Rechtsform
*checked via compare command
	rename g_fef303 g_rechtsform 
	rename v_ef16 v_rechtsform
	rename e_ef14 e_rechtsform
	gen rechtsform = g_rechtsform
	replace rechtsform = v_rechtsform if rechtsform ==. 
	replace rechtsform = e_rechtsform if rechtsform ==. 

// Filtern nach relevanter Rechtsform : Nur Personengesellschaften. Mischformen 
/*

11- 19 zahlt normalerweise keine Gewerbesteuer?
11 Hausgewerbetreibend
12 Sonstige Einzelgewerbetreibend 12er mitreinnehmen die Gewerbesteuer zahlen!
13 Land und Forstwirte
14 Freie Berufe
15 sonstige selbständig tätige Personen
16 Person mit beteiligung an gewerbl Personenegesllschaft

19 Sonstige nat Person

20 = Atypische stille Gesellschaften 
21 = Offene Handelsgesellschaften 
22 = Kommanditgesellschaften 
23 = Gesellschaften mit beschränkter Haftung & Co. KG MISCHFORM
24 = Gesellschaften mit beschränkter Haftung & Co. OHG MISCHFORM
25 = Aktiengesellschaften & Co. KG MISCHFORM
26 = Aktiengesellschaften & Co. OHG MISCHFORM
27 = Gesellschaften bürgerlichen Rechts 
28 = Europäische wirtschaftliche Interessenvereinigung

29 zahlt auch keien gewerbesteuer (ähnliche Gesellschaft: Grundstücksgemeinschaft oder stille Gesellschaft)


30  Kapiptalgesellschaften 
31 AG
32 KG
33 Kolonialgesllschaft
34 Bergrechtliche Gesellschaften
35 GmbH
36 Europäische Aktiengesellschaften
37 Unternehmensgesellschaft (haftungsbeschränkt)
39 SOnstige Kapitalgesellschaft
Ab 40 Genossenschaften und Realgemeinden
AB 50 Versicherungsvereine  sonstige juristische Personen
Ab 60 Nicht rechtsfäige Vereine
ab 70 Banken und Kreditanstalten sowie öfffentlich rechtliche Versorgungsbetriebe
Ab 80 Körperschaften
Ab 90: Ausländische Rechtsformen
*/

	gen persges = 1 if inlist(rechtsform, 20, 21, 22, 27, 28)
	keep if persges == 1
	
	
// AGS 
	rename g_fef307 g_ags 
	rename v_ef4 v_ags
	rename e_ef13 e_ags
	gen ags = g_ags
	replace ags = v_ags if ags==.
	replace ags = e_ags if ags==.
	drop if missing(ags) // Beobachtungen mit fehlender ags löschen



// Größenklasse
	rename g_fef17 g_gk 
	rename e_ef15 e_gk 
	gen gk = g_gk
	replace gk = e_gk if gk==.

// Hebesatz
	rename g_fef311 hebesatz 
	drop if hebesatz < 200 // Beobachtungen ohne sinnvollen hebesatz und fehlende Werte löschen
	drop if missing(hebesatz)

// Anzahl Zerlegungsgemeinden
	rename g_fef301 zerlegung 
	
// Personalausgaben
	rename e_c25120 e_persausg	

// Gewinnsätze von EÜR
	rename e_c65120 e_rohgs1 // Rohgewinnsatz 1
	rename e_c65121 e_rohgs2 // Rohgewinnsatz 2
	rename e_c65130 e_halbreings // Halbreingewinnsatz
	rename e_c65140 e_reings // Reingewinnsatz 
	rename e_c25219 stpfgew // Steuerpfl. Gewinn

// Gewinnsätze von Gewerbesteuer
	gen g_reing = g_k6520 - g_fef315 + g_fef316 // Gewerbeertrag - Hinzurechnungen + Kürzungen 
	gen g_reings = g_reing / v_ums * 100 // Reingewinnsatz = Reingewinn/Umsatz *100
	
	
// ags mit führenden nullen und bundesland
	tostring ags, generate(ags_string) // String Formatierung um führende nullen einzufügen
	replace ags_string = "0" + ags_string if strlen(ags_string) == 7 // führende 0en hinzufügen
	generate bundesland = substr(ags_string, 1, 2)
	destring bundesland, gen(bundesland_num)
	
	
	gen county = substr(ags_string, 1, 5)
	destring county, gen(county_num)
	
	gen west = .
	replace west = 1 if inrange(bundesland_num, 1, 10)
	replace west = 0 if inrange(bundesland_num, 11, 16)
	

*******************************
*  Panel Definition		      *
*******************************
	sort id jahr
		*duplicates report id jahr // Zeigt duplikate
		*duplicates examples id jahr, list // list ggf. weglassen, anschließend browse if _d == 1
	xtset id jahr
	


*******************************
*  Taxchange Variablen        *
*******************************
	
* Dummy variablen für hike bzw. drop der Steuer

	gen taxhike = hebesatz > L.hebesatz & L.hebesatz != . // 1 falls in dieser Periode größerer Hebesatz als in letzter Periode (und letzte Periode nicht NA)
	replace taxhike = . if L.hebesatz == .
	label variable taxhike "Tax Hike Indicator"
	
	gen taxdrop = hebesatz < L.hebesatz & L.hebesatz != . // 1 falls in dieser Periode kleinerer Hebesatz als in letzter Periode (und letzte Periode nicht NA)
	replace taxdrop = . if L.hebesatz == .
	label variable taxdrop "Tax Drop Indicator"
	
* Anzahl der tax hikes bzw. drops für jede municipality im Zeitraum 2013 bis 2019
	
	egen n_hikes = sum(taxhike) ,by(ags)
	label variable n_hikes "Number of Hikes"
	
	egen n_drops = sum(taxdrop) ,by(ags)
	label variable n_hikes "Number of Drops"


// Steuerrate und Veränderung absolut (Prozentpunkte) und relativ (Prozent)
	
	gen messzahl = 0.035  // seit 2008 bei 3.5 % konstant geblieben. Gewerbeertrag wird mal messzahl mal hebesatz gerechnet um die genaue Gewerbesteuer zu berechnen. In diesem Fall sind die Änderungen nur durch hebesatz getrieben da Jahre zwischen 2013 und 2019 und in dieser Periode keine Messzahländerung betroffen.

	gen taxrate = hebesatz * messzahl
	gen taxchange = taxrate - L.taxrate  if L.taxrate != .
	label variable taxchange "Tax Change in Prozentpunkten"
	
	gen changes = taxdrop + taxhike // entspricht 1 wenn es in der periode eine Anderung gab 
	
	* new net-of tax
	gen log_net = log(1-(taxrate/100)) - log(1-(L.taxrate/100))  if L.taxrate != .
	replace log_net = 0 if taxchange == 0 // (um sicher zu gehen) 
	

	save "$neudatenpfad/Temp/preperation.dta", replace
	

********************************************
*  DID EventStudy Variablen Vorbereitung   *
********************************************

	* use "$neudatenpfad/Temp/preperation.dta", clear


	
// OPTION 1:  Behalte nur volle id Jahr Kombinationen

	preserve 
		by id: gen n_years =_N  // Gibt für jede id die Anzahl der Beobachtungen, also Anzahl der Jahre die sie auftaucht in n_years aus
		tab n_years
		keep if n_years == 7
		save "$neudatenpfad/Temp/preperation_allyears.dta", replace
	restore

/*
// OPTION 2: Erstelle pattern variablen wie  bei xtdescribe (sodass Datensatz nach Bedarf gefiltert werden kann) (für spätere Analysen)

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

*/




*log close

*exit





*	-------------------------------------------------------------------------------------------------------------------
*








