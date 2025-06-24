// Alternativer Schätzverfahren
// Stata 18: didregress nutzen, kann beides auch bacon decomposition: https://www.stata.com/stata-news/news38-3/heterogeneous-DID/ schaut vielversprechend aus, diese Version ist  vorinstalliert !
// Traditionelle Ressource TWFE Estimation: https://www.stata.com/manuals/causaldidregress.pdf#causaldidregress 
// Postestimation commands: https://www.stata.com/manuals/causaldidregresspostestimation.pdf#causaldidregresspostestimation
// HEterogeneous effects estimation: xthdidregess:   https://www.stata.com/manuals/causalxthdidregress.pdf

/*

TODO:

- Prüfe ob folgende packages vorhanden:
ssc install did_multiplegt, replace
ssc install did_multiplegt_dyn, replace

- Prüfe ob xtdidregress mit bacondecomp funktioniert

- Prüfe ob xthdidregress funktioniert





Struktur:


Wie genau muss D ausschauen?
mach die xtdidregress variante:
Mach eine Bacondecomposition für mainspec

Mach die Xthdidregress variante:

gibt es einen unterschied zum kontinuierlichen Fall? taxhike binär vs taxhike continuous?

*/


*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Lade Daten
*	----
*	-------------------------------------------------------------------------------------------------------------------

use "$neudatenpfad/DiD_prep.dta", clear

keep if nogew_basesum == 0 
keep if inlist(pattern_tax, "n000000","n001000","n000100","n000010")



*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block 1 :  Allgemeine Vorbereitung
*	----
*	-------------------------------------------------------------------------------------------------------------------


sort id jahr 
xtset id jahr


foreach v in taxhike  {  //taxchange ggf. hinzufügen 
 // Leads
 gen dummy_m2_`v' = F2.`v'
 gen dummy_m1_`v' = F1.`v'

 // Lags
 gen dummy_0_`v' = L0.`v'
 gen dummy_p1_`v' = L1.`v'
 gen dummy_p2_`v' = L2.`v'
 
 replace dummy_m1_`v' = 0	// reference period
}


// Optional fehelnde Werte an Rändern zu null machen (hier nur für 2018 treatmentgruppe relevant) 
foreach var in dummy_m2_taxhike dummy_m1_taxhike dummy_0_taxhike dummy_p1_taxhike dummy_p2_taxhike {
	replace `var' = 0 if missing(`var')
}
 
/*
foreach var in dummy_m2_taxchange dummy_m1_taxchange dummy_0_taxchange dummy_p1_taxchange dummy_p2_taxchange {
	replace `var' = 0 if missing(`var')
}
*/


// Dummys

global x_lbt_hike c.dummy_m2_taxhike c.dummy_m1_taxhike c.dummy_0_taxhike c.dummy_p1_taxhike c.dummy_p2_taxhike   // u.a. c. statt i. damit die Variablen nicht umbenannt werden müssen, spielt bei bereits vorliegendem dummy keine rolle
// ggf. tbd: global x_lbt_change

// Fixed Effects
global fixed_effects1 "id jahr_X_bundesland jahr_X_industry"
global fixed_effects2 "id jahr_X_bundesland jahr_X_industry2" // closest to Licht 2024 FE
global fixed_effects3 "id jahr_X_county jahr_X_industry2"   
global fixed_effects4 "id jahr_X_county jahr_X_industry"    
// Globales Makro, das die NAMEN der FE-Globals enthält
*global fe_spec_names "fixed_effects1 fixed_effects2 fixed_effects3 fixed_effects4"


*Für kurzen Durchlauf

*##################################################################################################################################################################################################
	global dependent_vars "ln_e_pers_mir ah_stpfgew ln_fobi_mir ln_inv ln_afa_bwg ln_afa_ubwg ln_afa_imm ln_steube_mir e_rohgs1_t e_rohgs2_t e_halbreings_t e_reings_t ah_p_einge ah_gew ln_hinz_mir ln_kür_mir ln_zins_mir ah_abggewerer ah_bmg g_reings_t ah_g_reing "           																																//#
*##################################################################################################################################################################################################




//*****************************************
//*****************************************
//*****************************************
// Führe eine Bacon Decomposition durch 
//*****************************************
//*****************************************
//*****************************************
// Optimal wäre es das bacondecomp ado File direkt laden zu lassen. Jedoch nur mit zeitlichem Vorlauf möglich. Nutze daher den Weg über xtdidregress (erst ab Stata Version 17 möglich)

/*
Normales vorgehen
ssc install bacondecomp, replace
bacondecomp Y D, detail
ereturn list
mat list e(sumdd)


bacondecomp abhängige_variable, treat(behandlungsvariable) time(zeitvariable) id(panel_id_variable) [options] // Dokumentation siehe: https://asjadnaqvi.github.io/DiD/docs/code/06_02_bacon/ 
*/


*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
* BEISPIEL EINE ABHÄNGIGE VARIABLE Abhängige Variable: ah_stpfgew (als Beispiel)
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------


// Block 1: Daten laden und vorbereiten
//-------------------------------------------------------------------------------
// Annahme: Sie haben Ihre do-files "01_0_prep.do" und "01_1_DiD_prep.do" bereits
// ausgeführt und der finale Datensatz ist gespeichert.
// Passen Sie ggf. den Pfad an, falls $neudatenpfad hier nicht definiert ist.

use "$neudatenpfad/DiD_prep.dta", clear

// Wir fokussieren uns auf die Steuererhöhungen, wie in Ihrem Code
keep if inlist(pattern_tax, "n000000","n001000","n000100","n000010")

// Das Panel deklarieren
xtset id jahr


// Block 2: Treatment-Variable für xtdidregress erstellen
//-------------------------------------------------------------------------------
// xtdidregress und seine Post-Estimation-Befehle benötigen eine einzige Variable,
// die den Treatment-Status anzeigt (0 vor Behandlung, 1 ab Behandlung).

gen treatment_year = .
replace treatment_year = 2016 if pattern_tax == "n001000"
replace treatment_year = 2017 if pattern_tax == "n000100"
replace treatment_year = 2018 if pattern_tax == "n000010"
label variable treatment_year "Jahr der erstmaligen Steuererhöhung"

gen treated_hike = (jahr >= treatment_year) & (treatment_year != .)
label variable treated_hike "Treatment-Status (1=nach Steuererhöhung, 0=davor/Kontrolle)"


// Block 3: Schätzung des aggregierten TWFE-Modells (entspricht reghdfe-Spezifikation)
//-------------------------------------------------------------------------------
// Wir schätzen das DiD-Modell mit den komplexen Fixed Effects als Kovariaten.
// Dies ist die Voraussetzung für die nachfolgenden Tests.
// Annahme: Die Variablen 'county_num' und 'industry_base2' existieren aus 01_1_DiD_prep.do
// Passen Sie ggf. an, falls Sie industry_base3 o.ä. verwenden wollen.


xtdidregress ah_stpfgew i.jahr_X_county i.jahr_X_industry2 (treated_hike), group(id) time(jahr) vce(cluster ags)

               
// Block 4: Diagnostische Tests nach der Schätzung
//-------------------------------------------------------------------------------
// Diese Tests basieren auf dem gerade geschätzten, aggregierten Modell.

// Test 4.1: Parallel-Trends-Annahme (linearer Trend)
estat ptrends
// H0: Die linearen Trends der Kontroll- und Behandlungsgruppe sind in der 
// Vorbehandlungsperiode parallel. Ein hoher p-Wert ist hier erwünscht.


// Test 4.2: Granger-Kausalitätstest (Test auf Antizipationseffekte)
estat granger
// H0: Es gibt keine statistisch signifikanten Effekte VOR der Behandlung.
// Ein hoher p-Wert ist auch hier erwünscht.


// Test 4.3: Bacon Decomposition (Zerlegung des TWFE-Effekts)
estat bdecomp
estat bdecomp, graph notable noheader
// Zeigt, wie sich der aggregierte Effekt aus den verschiedenen 2x2-Vergleichen
// zusammensetzt. Die Grafik visualisiert die problematischen Vergleiche
// (treated vs. treated) und deren Gewichtung.


// Block 5: Event Study / Dynamische Effekte schätzen und darstellen
//-------------------------------------------------------------------------------
// Dies ist die detaillierteste Analyse und entspricht konzeptionell Ihrem 
// reghdfe-Modell mit den lead/lag Dummies. estat grangerplot ist der
// integrierte Weg, dies nach xtdidregress zu tun.
// Wir spezifizieren die Anzahl der Leads und Lags, die wir sehen wollen.
// Ihr Code hatte 2 Leads und 2 Lags, mit t-1 als Referenz. 
// estat grangerplot verwendet standardmäßig t-1 als Referenz.
estat grangerplot, nleads(2) nlags(2) ///
                  title("Event Study: Effekt auf ah_stpfgew") ///
                  xtitle("Jahre relativ zur Steuererhöhung") ///
                  ytitle("Koeffizient (95% CI)") ///
                  graphregion(color(white))
				  
estat grangerplot, nodraw verbose nleads(2) nlags(2)				  
*est _lead3 _lead2 // falls notwendig um 2013 auszuschließen!





*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
* DiD-ANALYSE MIT AUTOMATISCHER ERGEBNISSPEICHERUNG (LOG & GRAFIKEN)
* Abhängige Variable: ah_stpfgew
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------


// Block 1: Daten laden und vorbereiten
//-------------------------------------------------------------------------------
use "$neudatenpfad/DiD_prep.dta", clear
keep if inlist(pattern_tax, "n000000","n001000","n000100","n000010")
xtset id jahr


// Block 2: Treatment-Variable für xtdidregress erstellen
//-------------------------------------------------------------------------------
gen treatment_year = .
replace treatment_year = 2016 if pattern_tax == "n001000"
replace treatment_year = 2017 if pattern_tax == "n000100"
replace treatment_year = 2018 if pattern_tax == "n000010"
label variable treatment_year "Jahr der erstmaligen Steuererhöhung"

gen treated_hike = (jahr >= treatment_year) & (treatment_year != .)
label variable treated_hike "Treatment-Status (1=nach Steuererhöhung, 0=davor/Kontrolle)"




log off
log using "$outputpfad/log_did_analysis_ah_stpfgew.log", replace text

// Block 3: Schätzung des aggregierten TWFE-Modells
//-------------------------------------------------------------------------------
// Annahme: Die Variablen 'jahr_X_county' und 'jahr_X_industry2' existieren
xtdidregress ah_stpfgew i.jahr_X_county i.jahr_X_industry2 (treated_hike), ///
               group(id) time(jahr) vce(cluster ags)


// Block 4: Diagnostische Tests nach der Schätzung
//-------------------------------------------------------------------------------
// Die Textausgaben dieser Tests werden automatisch in der Log-Datei gespeichert.

// Test 4.1: Parallel-Trends-Annahme (linearer Trend)
estat ptrends

// Test 4.2: Granger-Kausalitätstest (Test auf Antizipationseffekte)
estat granger

// Test 4.3: Bacon Decomposition (Zerlegung des TWFE-Effekts)
estat bdecomp

// Grafik der Bacon Decomposition erstellen UND direkt exportieren
estat bdecomp, graph notable noheader
graph export "$outputpfad/Bacon_Decomposition_ah_stpfgew.png", width(1600) replace
display as result "-> Grafik Bacon_Decomposition_ah_stpfgew.png gespeichert."


// Block 5: Event Study / Dynamische Effekte schätzen und darstellen
//-------------------------------------------------------------------------------
// Event Study Plot erstellen UND direkt exportieren
estat grangerplot, nleads(2) nlags(2) ///
                  title("Event Study: Effekt auf ah_stpfgew") ///
                  xtitle("Jahre relativ zur Steuererhöhung") ///
                  ytitle("Coeffizient (95% CI)") ///
				  graphregion(color(white))

graph export "$outputpfad/Event_Study_ah_stpfgew.png", width(1600) replace
display as result "-> Grafik 'Event_Study_ah_stpfgew.png' gespeichert."

// Optional: Tabelle mit den Koeffizienten der Event Study in der Log-Datei anzeigen
*estat grangerplot, nodraw verbose nleads(2) nlags(2)


// Block 6: Abschluss
//-------------------------------------------------------------------------------
// Log-Datei schließen, um die Speicherung abzuschließen
display ""
display as result "Analyse abgeschlossen. Ergebnisse sind im Ordner '$outputpfad' gespeichert:"
display as result "Log-Datei (mit allen Tabellen/Tests): log_did_analysis_ah_stpfgew.log"
display as result "Grafik 1 (Bacon Decomposition):       Bacon_Decomposition_ah_stpfgew.png"
display as result "Grafik 2 (Event Study):               Event_Study_ah_stpfgew.png"



log close
log on




*+++++++ FOREACH SCHLEIFE!!!

*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
* DiD-ANALYSE IN EINER SCHLEIFE FÜR MEHRERE ABHÄNGIGE VARIABLEN
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------

// Block 0: Globale Einstellungen
//-------------------------------------------------------------------------------
// Annahme: $outputpfad ist in Ihrer Master-Datei definiert.

// HIER DEFINIEREN SIE IHRE ABHÄNGIGEN VARIABLEN
// Fügen Sie einfach alle gewünschten Variablennamen mit Leerzeichen getrennt hinzu.
global dependent_vars "ah_stpfgew ln_e_pers_mir g_reings_t"


// Block 1: Daten laden und vorbereiten (wird nur einmal ausgeführt)
//-------------------------------------------------------------------------------
use "$neudatenpfad/DiD_prep.dta", clear
keep if inlist(pattern_tax, "n000000","n001000","n000100","n000010")
xtset id jahr


// Block 2: Treatment-Variable erstellen (wird nur einmal ausgeführt)
//-------------------------------------------------------------------------------
gen treatment_year = .
replace treatment_year = 2016 if pattern_tax == "n001000"
replace treatment_year = 2017 if pattern_tax == "n000100"
replace treatment_year = 2018 if pattern_tax == "n000010"
label variable treatment_year "Jahr der erstmaligen Steuererhöhung"

gen treated_hike = (jahr >= treatment_year) & (treatment_year != .)
label variable treated_hike "Treatment-Status (1=nach Steuererhöhung, 0=davor/Kontrolle)"


// Block 3: Start der Schleife über alle abhängigen Variablen
//-------------------------------------------------------------------------------
log off

// Die Schleife wird für jede Variable im globalen Makro 'dependent_vars' einmal durchlaufen.
foreach depvar of global dependent_vars {
	
	log using "$outputpfad/log_did_`depvar'.log", replace text
	
	display as result "--- Processing Dependent Variable: `depvar' ---"
	
	


	// Block 3.1: Schätzung des aggregierten TWFE-Modells
	xtdidregress `depvar' i.jahr_X_county i.jahr_X_industry2 (treated_hike), ///
				   group(id) time(jahr) vce(cluster ags)

	
	// Block 3.2: Diagnostische Tests nach der Schätzung
	estat ptrends
	estat granger
	estat bdecomp

	// Grafik der Bacon Decomposition erstellen UND mit spezifischem Namen exportieren
	estat bdecomp, graph notable noheader
	graph export "$outputpfad/BaconDecomp_`depvar'.png", width(1600) replace
	

	// Block 3.3: Event Study / Dynamische Effekte schätzen und darstellen
	estat grangerplot, nleads(2) nlags(2) ///
					  title("Event Study: `depvar'") ///
					  xtitle("Years Relative to Treatment") ///
					  ytitle("Coefficient and 95% CI") ///
					  graphregion(color(white))

	graph export "$outputpfad/EventStudy_`depvar'.png", width(1600) replace
	
	// Optional: Tabelle mit den Koeffizienten der Event Study in der Log-Datei anzeigen
	estat grangerplot, nodraw verbose nleads(2) nlags(2)
	
	log close
	
} 


log on

display ""
display as result "Alle Analysen abgeschlossen. Ergebnisse sind im Ordner '$outputpfad' gespeichert."















*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
* DiD-ANALYSE MIT AUTOMATISCHEM TABELLEN-EXPORT VERSION 2
* Abhängige Variable: ah_stpfgew
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------


// Notwendiges Paket für Tabellenexport prüfen und ggf. installieren
capture ssc install estout
clear


// Block 1: Daten laden und vorbereiten
//-------------------------------------------------------------------------------
use "$neudatenpfad/DiD_prep.dta", clear
keep if inlist(pattern_tax, "n000000","n001000","n000100","n000010")
xtset id jahr


// Block 2: Treatment-Variable für xtdidregress erstellen
//-------------------------------------------------------------------------------
gen treatment_year = .
replace treatment_year = 2016 if pattern_tax == "n001000"
replace treatment_year = 2017 if pattern_tax == "n000100"
replace treatment_year = 2018 if pattern_tax == "n000010"
label variable treatment_year "Jahr der erstmaligen Steuererhöhung"

gen treated_hike = (jahr >= treatment_year) & (treatment_year != .)
label variable treated_hike "Treatment-Status (1=nach Steuererhöhung, 0=davor/Kontrolle)"


// Block 3: Schätzung des aggregierten TWFE-Modells
//-------------------------------------------------------------------------------
// Annahme: Die Variablen 'jahr_X_county' und 'jahr_X_industry2' existieren
xtdidregress ah_stpfgew i.jahr_X_county i.jahr_X_industry2 (treated_hike), ///
               group(id) time(jahr) vce(cluster ags)

// WICHTIG: Schätzerergebnisse für späteren Export speichern
estimates store Agg_Model_ah_stpfgew


// Block 4: Diagnostische Tests durchführen und Ergebnisse sichern
//-------------------------------------------------------------------------------
// Die Textausgaben dieser Befehle werden automatisch in der Log-Datei gespeichert.

// Test 4.1: Parallel-Trends-Annahme (linearer Trend)
estat ptrends
// p-Wert für Tabellenexport speichern
scalar p_ptrends = r(p)


// Test 4.2: Granger-Kausalitätstest (Test auf Antizipationseffekte)
estat granger
// p-Wert für Tabellenexport speichern
scalar p_granger = r(p)


// Test 4.3: Bacon Decomposition (Zerlegung des TWFE-Effekts)
// Die detaillierte Tabelle wird in der Log-Datei gespeichert.
estat bdecomp


// Block 5: Event Study / Dynamische Effekte schätzen und speichern
//-------------------------------------------------------------------------------
// Wir verwenden die Optionen 'nodraw' und 'verbose', um nur die Tabelle zu erhalten.
// Die Option 'post' ist entscheidend, damit wir die Ergebnisse mit 'estimates store' speichern können.
estat grangerplot, nodraw verbose nleads(2) nlags(2) post

// Speichern der Event-Study-Ergebnisse für den Tabellenexport
estimates store Event_Study_ah_stpfgew


// Block 6: Gespeicherte Ergebnisse in finale Tabellen exportieren
//-------------------------------------------------------------------------------

// Tabelle 1: Das aggregierte DiD-Modell mit diagnostischen Testergebnissen
esttab Agg_Model_ah_stpfgew using "$outputpfad/Tabelle_1_DiD_Modell.rtf", ///
    replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    *title("Tabelle 1: Aggregiertes DiD-Modell für ah_stpfgew") ///
    *nonumbers mtitles("Modell 1") ///
    coeflabels(treated_hike "ATET (Gewerbesteuererhöhung)") ///
    addnotes("Robuste Standardfehler, geclustert auf AGS-Ebene." ///
             "Fixed Effects für Firma, Jahr-x-Landkreis und Jahr-x-Branche enthalten.") ///
    stats(N N_clust, fmt(%9.0f) labels("Beobachtungen" "Anzahl Cluster (AGS)")) ///
    scalars("p_ptrends" "p-Wert Parallel-Trends-Test" ///
            "p_granger" "p-Wert Granger-Test")

// Tabelle 2: Die Koeffizienten der Event Study
esttab Event_Study_ah_stpfgew using "$outputpfad/Tabelle_2_Event_Study_results.rtf", ///
    replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
   *title("Tabelle 2: Event-Study-Koeffizienten für ah_stpfgew") ///
    *nonumbers mtitles("Event Study") ///
    coeflabels(_lead2 "t-2" _lead1 "t-1 (Referenz)" _lag0 "t0" _lag1 "t+1" _lag2 "t+2") ///
    addnotes("Robuste Standardfehler, geclustert auf AGS-Ebene.") ///
             ("Fixed Effects für Firma, Jahr-x-Landkreis und Jahr-x-Branche enthalten.") ///
    stats(N N_clust, fmt(%9.0f) labels("Beobachtungen" "Anzahl Cluster (AGS)"))






















// Wie kann man log Dateien pausieren und anschließend weitermachen?



//--- Spezieller Block nur für die Bacon Decomposition Tabelle ---

// Schritt 1: Haupt-Log-Datei pausieren
log off

// Schritt 2: Eine neue, separate Log-Datei NUR für die bdecomp-Tabelle starten
// Die Option 'text' erstellt eine einfache .log-Textdatei statt einer .smcl-Datei
log using "$outputpfad/Tabelle_Bacon_Decomposition.log", replace text

// Schritt 3: Den Befehl ausführen, dessen Ausgabe wir isoliert speichern wollen
estat bdecomp

// Schritt 4: Die separate bdecomp-Log-Datei schließen und speichern
log close

// Schritt 5: Die ursprüngliche Haupt-Log-Datei wieder aktivieren und fortsetzen
log on



//*****************************************
//*****************************************
//*****************************************
// Führe eine alternative Schätzung mit xthdidregess durch wenn verdacht naheliegt, dass heterogene Treatment Effekte vorliegen (wahrscheinlich der Fall)  (Out of the scope of Master Thesis?)
//*****************************************
//*****************************************
//*****************************************













//*****************************************
//*****************************************
//*****************************************
*-------------------------------------------------------------------------------
* Vorbereitung für Event Study mit kontinuierlichem Treatment (taxchange) -> Mein Fall.
*-------------------------------------------------------------------------------
//*****************************************
//*****************************************
//*****************************************


// Wir erstellen nun die Event-Time-Variablen für 'taxchange'.
// Jede dieser Variablen wird den Wert von 'taxchange' aus dem Event-Jahr enthalten,
// aber nur für die jeweilige relative Zeitperiode aktiv sein.

// Annahme: Die Variable 'taxchange' ist bereits in deinem Datensatz vorhanden
// und hat nur im Jahr der Steueränderung einen Wert, der nicht Null ist.

// Erstelle die relativen Zeit-Variablen für taxchange
foreach v in taxchange {
  // Leads: Nehmen den Wert von taxchange aus der Zukunft
  gen tc_m2 = F2.`v' // In t-2 hat diese Variable den Wert von taxchange aus t0
  gen tc_m1 = F1.`v' // In t-1 hat diese Variable den Wert von taxchange aus t0

  // Lags: Nehmen den Wert von taxchange aus der Gegenwart/Vergangenheit
  gen tc_0  = L0.`v' // In t0 hat diese Variable den Wert von taxchange aus t0
  gen tc_p1 = L1.`v' // In t+1 hat diese Variable den Wert von taxchange aus t0
  gen tc_p2 = L2.`v' // In t+2 hat diese Variable den Wert von taxchange aus t0

  // Referenzperiode t-1 auf Null setzen, um Koeffizienten relativ dazu zu schätzen
  replace tc_m1 = 0
}

// Optionale Bereinigung von fehlenden Werten an den Rändern des Panels
foreach var of varlist tc_m* tc_0 tc_p* {
    replace `var' = 0 if missing(`var')
}

// Globales Makro für die neuen kontinuierlichen Event-Study-Variablen
global x_lbt_change c.tc_m2 c.tc_m1 c.tc_0 c.tc_p1 c.tc_p2


*-------------------------------------------------------------------------------
* Beispielhafte Anwendung in deiner Schleifenstruktur
*-------------------------------------------------------------------------------

// Du würdest dann deine bestehende Schleife anpassen oder eine neue erstellen,
// die das neue Global `$x_lbt_change` verwendet.

// Beispielhafter Aufruf für eine abhängige Variable und eine FE-Spezifikation:

local depvar "ln_stpfgew"    // Beispiel-Outcome
local fe_spec "$fixed_effects1" // Beispiel-FE

di "Schätze Event Study mit kontinuierlichem Treatment für `depvar'"
eststo clear

// Verwende das neue Global für die Regressoren
reghdfe `depvar' $x_lbt_change if persbigger380 == 1, absorb(`fe_spec') vce(cluster ags)
estimates store s_`depvar'_change

// Der Plot-Befehl muss ebenfalls an die neuen Variablennamen angepasst werden
coefplot s_`depvar'_change ///
    , keep(tc_m2 tc_m1 tc_0 tc_p1 tc_p2) ///
    coeflabels(tc_m2="-2" tc_m1="-1" tc_0="0" tc_p1="1" tc_p2="2") ///
    omitted ///
    vert ///
    connect(L) ///
    yline(0,lcolor(black) lpattern(dash) lwidth(thin)) ///
    ytitle("Marginal Effect of a 1p.p. Tax Change (Rel. to t-1)") ///
    xtitle("Years Relative to the Tax Reform") ///
    title("Event Study with Continuous Treatment: Effect on `depvar'")
