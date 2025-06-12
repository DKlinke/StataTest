
********************************************************************************
* Table B.3: Balance Statistics of Firms in the Treatment and Control Group
********************************************************************************
xtset id jahr
mat Ba = J(5,3,.) // adjust


// Definition der "Treated"-Gruppe für die Balance-Tabelle:
// Firmen, die im nächsten Jahr (t0) eine Steuererhöhung haben (F1_taxhike == 1),
// aber im aktuellen Jahr (t-1) selbst noch keine Steuererhöhung haben (taxhike == 0).
// Die Charakteristika werden für dieses t-1 gemessen.

// Definition der "Control"-Gruppe für die Balance-Tabelle:
// Firmen, die im nächsten Jahr (t0) KEINE Steuererhöhung haben (F1_taxhike == 0),
// und im aktuellen Jahr (t-1) auch keine Steuererhöhung haben (taxhike == 0).
// Die Charakteristika werden für dieses t-1 gemessen.


local r = 1 // Zeilenzähler


	//Alle abhängigen Variablen
	// ln_e_pers_mir ln_e_persausg sigln_e_persausg ah_e_persausg ln_stpfgew sigln_stpfgew ah_stpfgew ln_fobi_mir ln_fobi ln_inv ln_afa_bwg ln_afa_ubwg ln_afa_imm ln_erhauf_mir ln_erhauf ln_steube_mir ln_steube e_rohgs1 e_rohgs2 e_halbreings e_reings sigln_p_einge ah_p_einge ln_gew sigln_gew ah_gew ln_hinz_mir ln_hinz ln_kür_mir ln_kür ln_zins_mir ln_zins sigln_zins ah_zins ln_abggewerer sigln_abggewerer ah_abggewerer ln_bmg sigln_bmg ah_bmg g_reings g_reings_tru ln_g_reing sigln_g_reing ah_g_reing
	
	gen F1taxhike = F1.taxhike

foreach var in ln_e_pers_mir ln_e_persausg sigln_stpfgew ln_fobi_mir ln_steube {

    // Mittelwert für die "Treated"-Gruppe in t-1 (Treated Gruppe sind die die in in t0 behandelt werden)
	sum `var' if F1taxhike == 1 & L0.taxhike == 0 , d
	mat Ba[`r',1] = round(r(mean),0.01)
	
	// Mittelwert für die "Control"-Gruppe in t-1 (Control Gruppe sind die die in in t0 NICHT behandelt werden)
	sum `var' if F1taxhike == 0 & L0.taxhike == 0 , d
	mat Ba[`r',2] = round(r(mean),0.01)
	
	// T-Test für den Mittelwertunterschied zwischen Treated und Control in t-1
	ttest `var' if L0.taxhike != 1 , by(F1taxhike)
	mat Ba[`r',3] = round(r(p),0.0001)
	
	// Der T-Test stellt eine die Frage: "Sehen Firmen im Zustand 'kurz vor dem Treatment' (F1_taxhike=1) systematisch anders aus als Firmen im Zustand 'nicht kurz vor dem Treatment' (F1_taxhike=0)?".

	local r = `r' + 1 // Gehe zur nächsten Zeile, also nächsten Variable
}
	
// Beschriftung
mat list Ba
mat rownames Ba = "Employees" "Revenues" "Investment" "Donward Revision" "Log Revision Ratio" // anpassen!
mat colnames Ba = "Treated" "Control" "p-value" 

mat list Ba

// Tabelle speichern
//TXT
esttab matrix(Ba) using "$outputpfad/tab_balance_test.txt" , ///
	replace booktabs mlabel(none) label

//TEX
esttab matrix(Ba) using "$outputpfad/tab_balance_test" , ///
	replace booktabs mlabel(none) label

	
*///

*-------------------------------------------------------------------------------
* Implementierung des csdid-Schätzers (Callaway & Sant'Anna, 2021)
* für ein gestaffeltes DiD-Design mit zusätzlichen Fixed Effects
*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
* Schritt 0: Voraussetzungen und Definitionen
*-------------------------------------------------------------------------------

// 1. BENÖTIGTE PAKETE INSTALLIEREN (falls noch nicht geschehen)
// csdid für den Schätzer und reghdfe für die Residualisierung
// Führe diese Zeilen einmal in deinem Stata-Befehlsfenster aus:
// ssc install csdid, replace
// ssc install reghdfe, replace


// 2. VARIABLEN DEFINIEREN (ersetze diese mit deinen Namen)
// Dies macht den restlichen Code leicht anpassbar.

// Deine abhängige Variable, die du untersuchen möchtest
local outcome_var "ln_stpfgew"

// Deine Schlüsselvariablen für das Panel-Design
local id_var "id"            // Firmen-ID
local time_var "jahr"        // Jahresvariable (z.B. 2013, 2014, ...)
local cohort_var "cohortjahr" // Variable, die das erste Treatment-Jahr angibt
                               // WICHTIG: Für die Kontrollgruppe, die nie behandelt wird,
                               // sollte dieser Wert 0 oder fehlend (.) sein. csdid
                               // erkennt dies automatisch als "never-treated".

// Deine zusätzlichen Fixed Effects, deren Einfluss du herausrechnen möchtest
local additional_fes "jahr_X_bundesland jahr_X_industry"


*-------------------------------------------------------------------------------
* Schritt 1: Residualisierung (Kontrolle für zusätzliche Fixed Effects)
*-------------------------------------------------------------------------------
// Der csdid-Befehl kann standardmäßig nur mit Einheiten- und Zeit-FE umgehen.
// Um für zusätzliche FEs wie Jahr-x-Industrie zu kontrollieren, entfernen wir
// deren Einfluss aus der abhängigen Variable, bevor wir sie an csdid übergeben.

display _newline as result "Schritt 1: Erstelle residualisierte abhängige Variable..."

// Wir regredieren die abhängige Variable auf die zusätzlichen Fixed Effects.
// WICHTIG: Wir absorbieren hier nur die ZUSÄTZLICHEN FEs. Nicht die Firmen- oder Jahres-FEs!
// Diese werden später vom csdid-Befehl selbst gehandhabt.
qui reghdfe `outcome_var' `additional_fes'

// Berechne die Residuen dieser Regression.
// predict erstellt eine neue Variable, die den Teil von `outcome_var` enthält,
// der NICHT durch die branchen- und regionenspezifischen Jahrestrends erklärt wird.
// Wir nennen die neue Variable einfach, indem wir "_resid" an den Originalnamen anhängen.
predict `outcome_var'_resid, resid
label variable `outcome_var'_resid "`outcome_var' (Residualized on `additional_fes')"

display as text "-> Variable `outcome_var'_resid wurde erstellt."


*-------------------------------------------------------------------------------
* Schritt 2: Robuste DiD-Schätzung mit csdid
*-------------------------------------------------------------------------------
display _newline as result "Schritt 2: Führe robuste DiD-Schätzung mit csdid durch..."

// csdid schätzt zuerst die gruppenspezifischen durchschnittlichen Effekte (ATT(g,t)).
// Wir führen den Befehl auf unserer neuen, residualisierten Outcome-Variable aus.
//
// - ivar: Panel-ID Variable (deine `id`)
// - time: Zeit-Variable (d
	
	
	

	
	
	


/*
Exzellente Frage! Du hast den Nagel auf den Kopf getroffen und einen Punkt identifiziert, der bei der Interpretation von gestaffelten Difference-in-Differences-Designs (staggered DiD) oft zu Verwirrung führt.

Deine Beobachtung ist 100% korrekt. Der Code macht genau das, was du beschreibst.

Lass uns das anhand deines Beispiels (Treatment 2016) und des Codes auflösen:

Der relevante Code:
sumvar' if F1_taxhike == 0 & taxhike == 0 , d`

Dieser Befehl berechnet den Mittelwert für die Kontrollgruppe im Balance-Test. Eine Beobachtung muss zwei Bedingungen erfüllen, um hier berücksichtigt zu werden:

    taxhike == 0: Im aktuellen Jahr findet keine Steuererhöhung statt.
    F1_taxhike == 0: Im nächsten Jahr findet auch keine Steuererhöhung statt.

Dein Beispiel: Firma mit Treatment in 2016
Jahr	taxhike	F1_taxhike (Event in t+1?)	Erfüllt die Bedingung?	Gehört zu...
2013	0	0	Ja (taxhike==0 & F1_taxhike==0)	Kontrollgruppe
2014	0	0	Ja (taxhike==0 & F1_taxhike==0)	Kontrollgruppe
2015	0	1	Nein (F1_taxhike ist 1)	Treatmentgruppe
2016	1	0	Nein (taxhike ist 1)	(wird ausgeschlossen)
2017	0	0	Ja (taxhike==0 & F1_taxhike==0)	Kontrollgruppe
2018	0	0	Ja (taxhike==0 & F1_taxhike==0)	Kontrollgruppe
2019	0	0	Ja (taxhike==0 & F1_taxhike==0)	Kontrollgruppe

Du siehst also: Die Beobachtungen dieser Firma aus den Jahren 2013, 2014, 2017, 2018 und 2019 fließen tatsächlich in die Berechnung des Mittelwerts für die Kontrollgruppe ein.
Warum ist das so und warum ist es methodisch korrekt?

Hier kommt der entscheidende Punkt zu gestaffelten DiD-Designs: Die Kontrollgruppe ist kein statisches Set von Firmen, sondern ein dynamischer Pool von allen Firmen-Jahr-Beobachtungen, die zu einem bestimmten Zeitpunkt nicht behandelt werden.

    Die Logik des Vergleichs: Der Balance-Test vergleicht den Zustand von Firmen unmittelbar bevor sie behandelt werden (Zustand: $t_{-1}$) mit dem Zustand von Firmen, die sich nicht unmittelbar vor einer Behandlung befinden.
        Die Beobachtung des Unternehmens aus dem Jahr 2014 ist im Zustand "noch nicht kurz vor einer Behandlung" (das ist erst 2015 der Fall) und dient daher als gültige Kontrollbeobachtung für eine Firma, die sich gerade im Zustand "kurz vor der Behandlung" befindet (z.B. eine andere Firma im Jahr 2014, deren Treatment 2015 beginnt).

    Konsistenz mit der Hauptregression: Deine spätere Event-Study-Regression mit reghdfe macht genau den gleichen Vergleich. Sie nutzt Firmen, die "noch nicht" oder "nie" behandelt werden, als Kontrollen für die Firmen, die gerade behandelt werden. Der Balance-Test muss exakt die Vergleichbarkeit der Gruppen so, wie sie im Hauptmodell verwendet werden, prüfen. Andernfalls wäre er kein valider Diagnosetest.

    Die vereinfachte Beschreibung im Appendix: Deine Verwirrung kommt durch die vereinfachte Sprache in der Notiz zur Tabelle B.3 zustande: "...untreated firms...".
        Was ist gemeint? Mit "untreated firms" meinen die Autoren in diesem Kontext nicht "Firmen, die niemals behandelt werden", sondern "Firmen-Jahr-Beobachtungen, die sich im unbehandelten Zustand befinden".
        Die Beobachtung deines Beispielunternehmens im Jahr 2014 ist eine "unbehandelte Beobachtung" und gehört daher zur Kontrollgruppe. Die Beschreibung ist eine pragmatische Verkürzung, die für Kenner der Methode verständlich ist, aber bei genauer Betrachtung – so wie du es getan hast – zu Recht Fragen aufwirft.

Fazit:
Du täuschst dich nicht. Deine Analyse des Codes ist absolut korrekt. Die Beobachtungen von zukünftig behandelten Firmen fließen in die Kontrollgruppe ein. Der springende Punkt ist, dass dies beabsichtigt, methodisch korrekt und Standard für gestaffelte DiD-Analysen ist. Die Beschreibung im Paper ist eine Vereinfachung, die nicht die volle Komplexität der dynamischen Kontrollgruppe widerspiegelt. Du hast hier einen sehr wichtigen Aspekt der Methodik aufgedeckt und verstanden!


*/


*-------------------------------------------------------------------------------
* Schritt 0: Vorbereitung (wie in deinem Code)
*-------------------------------------------------------------------------------

// Annahmen:
// - depvar: Name deiner abhängigen Variable (z.B. "ln_stpfgew")
// - id: Deine Firmen-ID
// - jahr: Deine Jahresvariable
// - cohortjahr: Deine Variable, die das erste Treatment-Jahr für jede Firma angibt (z.B. 2016, 2017, 2018; und 0 oder fehlend für die Kontrollgruppe)
// - jahr_X_bundesland, jahr_X_industry: Deine zusätzlichen Fixed Effects
// - Du musst das csdid-Paket installiert haben: ssc install csdid, replace
// - Du musst das reghdfe-Paket installiert haben: ssc install reghdfe, replace

// Beispiel-Variablennamen (ersetze sie mit deinen)
local depvar "ln_stpfgew"
local id_var "id"
local time_var "jahr"
local cohort_var "cohortjahr"
local additional_fes "jahr_X_bundesland jahr_X_industry"


*-------------------------------------------------------------------------------
* Schritt 1: Residualisierung - Variation der zusätzlichen FEs entfernen
*-------------------------------------------------------------------------------
display "Schritt 1: Erstelle residualisierte abhängige Variable..."

// Wir regredieren die abhängige Variable auf die zusätzlichen FEs.
// reghdfe ist hierfür gut geeignet, auch wenn es hier keine hochdimensionalen FEs sind.
// WICHTIG: Wir absorbieren hier nur die zusätzlichen FEs. Nicht die Firmen- oder Jahres-FEs!
// Die Firmen- und Jahres-FEs werden später vom csdid-Befehl selbst gehandhabt.
qui reghdfe `depvar' `additional_fes'

// Berechne die Residuen und speichere sie in einer neuen Variable.
// Das ist der Teil von `depvar`, der NICHT durch die zusätzlichen FEs erklärt wird.
predict `depvar'_resid, resid
label var `depvar'_resid "`depvar' (Residualized on Year-x-Region and Year-x-Industry FEs)"

display "-> Variable `depvar'_resid wurde erstellt."


*-------------------------------------------------------------------------------
* Schritt 2: Robuste DiD-Schätzung mit csdid auf die residualisierte Variable
*-------------------------------------------------------------------------------
display _newline "Schritt 2: Führe robuste DiD-Schätzung (Callaway & Sant'Anna) durch..."

// csdid schätzt die gruppen-spezifischen durchschnittlichen Effekte (ATT(g,t))
// ivar: Panel-ID Variable
// time: Zeit-Variable
// gvar: Variable, die die Kohorte (erstes Treatment-Jahr) definiert
// Wir verwenden hier die residualisierte Variable `depvar'_resid` als Outcome.
// csdid kontrolliert intern für die Einheiten-FE (id).
csdid `depvar'_resid, ivar(`id_var') time(`time_var') gvar(`cohort_var')

// Um die Event-Study-Koeffizienten zu bekommen, verwenden wir die `agg(event)` Option
// Das aggregiert die ATT(g,t) zu den dynamischen Effekten relativ zum Event-Zeitpunkt.
eststo clear
eststo: csdid `depvar'_resid, ivar(`id_var') time(`time_var') gvar(`cohort_var') agg(event)

display "-> Robuste Event-Study-Koeffizienten wurden geschätzt und gespeichert."


*-------------------------------------------------------------------------------
* Schritt 3: Ergebnisse visualisieren
*-------------------------------------------------------------------------------
display _newline "Schritt 3: Erstelle Plot der robusten Event-Study-Ergebnisse..."

// csdid kommt mit einem eigenen, sehr guten Plot-Befehl
// Er zeigt automatisch die Referenzperiode (t-1) auf Null
csdid_plot, ///
    title("Event Study (Callaway & Sant'Anna) on Residualized Outcome") ///
    subtitle("Effect on `depvar', after accounting for Year-x-Region/Industry Trends") ///
    xtitle("Years Relative to the Tax Reform") ///
    ytitle("Estimated Effect (ATT) Relative to t-1") ///
    note("Notes: 95% confidence intervals from Callaway & Sant'Anna (2021). " ///
         "Outcome variable residualized on `additional_fes'.", size(vsmall) span)

// Ggf. Graph exportieren
// graph export "$outputpfad/EventStudy_CSDID_`depvar'.png", replace width(1600)

