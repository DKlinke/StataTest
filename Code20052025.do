// stacked Licht

//TODO am GWAP:


// 12 er reinnehmen
// WErte anschauen die absurd sind und versuchen damit umzugehen...-> EÜR daten von rießen Unternehmen, ab wann wird es seltsam?
// einheltihc winsorizen! obersten untersten 1%
// Heterogenität bei <380 und total anschauen.


// Umgang mit fehlenden Werten bei
		// Prüfe erstmal jahr ags , industry, id
		// dann abhängige Variablen, nutze 3 methoden zum befüllen
			//- as it is
			//- 
			//-
			
// Winsorizing

// Winsorizing mit Basic Funktionen:


//##################### MISSING

Ja, es gibt in Stata mehrere Befehle, um fehlende Werte (Missings) einer Variablen übersichtlich und informativ in einer Tabelle darzustellen. Hier sind einige gängige und nützliche Befehle:

**1. `codebook` mit der Option `tabulate()` oder `missing`:**

  * Der Befehl `codebook` liefert detaillierte Informationen über Variablen, einschließlich der Anzahl fehlender Werte.

  * Mit der Option `tabulate()` oder `missing` (je nach Stata-Version und gewünschtem Detailgrad) kann man sich die Häufigkeiten der einzelnen Werte inklusive der Missings anzeigen lassen.

    **Beispiel:**

    ```stata
    sysuse auto, clear // Beispieldatensatz laden
    codebook rep78, tabulate(10) // Zeigt eine Häufigkeitstabelle mit bis zu 10 Werten, inkl. Missings
    codebook rep78, missing // Fokussiert auf die Darstellung von Missing-Informationen
    ```

**2. `tabulate` mit der Option `missing`:**

  * Der Befehl `tabulate` (oft abgekürzt als `tab`) erstellt Häufigkeitstabellen.

  * Die Option `missing` sorgt dafür, dass fehlende Werte als separate Kategorie in der Tabelle aufgeführt werden.

    **Beispiel:**

    ```stata
    sysuse auto, clear
    tabulate rep78, missing // Erstellt eine Häufigkeitstabelle für rep78 und zeigt Missings explizit an
    ```

**3. `mdesc` (user-written command):**

  * `mdesc` ist ein sehr nützlicher, von Benutzern geschriebener Befehl, der speziell für die Beschreibung von fehlenden Werten entwickelt wurde. Er gibt einen guten Überblick über die Anzahl und den Prozentsatz fehlender Werte pro Variable.

  * Sie müssen diesen Befehl möglicherweise zuerst installieren, falls er noch nicht auf Ihrem System vorhanden ist.

    **Installation (einmalig):**

    ```stata
    ssc install mdesc
    ```

    **Anwendung:**

    ```stata
    sysuse auto, clear
    mdesc rep78 // Zeigt detaillierte Missing-Informationen für die Variable rep78
    mdesc _all // Zeigt Missing-Informationen für alle Variablen im Datensatz
    ```

**4. `missings` (user-written command):**

  * `missings` ist ein weiterer von Benutzern geschriebener Befehl, der verschiedene Tabellen und Grafiken zur Analyse von fehlenden Werten erstellen kann.

  * Auch dieser Befehl muss ggf. zuerst installiert werden.

    **Installation (einmalig):**

    ```stata
    ssc install missings
    ```

    **Anwendung:**

    ```stata
    sysuse auto, clear
    missings table rep78, // Erstellt eine Tabelle mit Missing-Informationen für rep78
    missings table _all // Erstellt eine Tabelle mit Missing-Informationen für alle Variablen
    ```

**5. `inspect`:**

  * Der Befehl `inspect` gibt eine schnelle Übersicht über die Verteilung einer Variablen, einschließlich der Anzahl der fehlenden Werte. Er ist weniger tabellarisch im Sinne einer Häufigkeitstabelle, aber sehr nützlich für einen ersten Überblick.

    **Beispiel:**

    ```stata
    sysuse auto, clear
    inspect rep78
    ```

**Welcher Befehl ist am "schönsten"?**

Die "Schönheit" einer Tabelle ist subjektiv, aber `mdesc` und `missings table` sind oft sehr beliebt, da sie speziell für die übersichtliche Darstellung von Missing-Informationen konzipiert wurden und oft eine klar strukturierte Ausgabe liefern. `tabulate, missing` ist der Standardbefehl und liefert eine saubere, grundlegende Tabelle.

**Zusätzliche Tipps für eine "schöne" Darstellung:**

  * **Labels:** Stellen Sie sicher, dass Ihre Variablen und ggf. die Werte-Label gut definiert sind, das verbessert die Lesbarkeit jeder Tabelle.
  * **Export:** Für Berichte oder Publikationen können Sie die Tabellen mit Befehlen wie `putexcel` (für Excel), `estout` (für LaTeX/Word, nach `estimates store`) oder durch Kopieren und Einfügen (z.B. als HTML-Tabelle aus dem Results-Fenster) exportieren und dort weiter formatieren.
  * **Graphische Darstellung:** Neben Tabellen können auch Grafiken (z.B. mit `missings patterns` oder `visdat` - beides user-written) sehr hilfreich sein, um Muster von fehlenden Werten zu visualisieren.

Probieren Sie die verschiedenen Befehle aus, um herauszufinden, welcher für Ihre spezifischen Bedürfnisse und ästhetischen Präferenzen am besten geeignet ist.






*-------------------------------------------------------------------------------
* Manuelles Winsorisieren einer Variable in Stata
* Kompatibel mit Stata 16 und Stata 18
*-------------------------------------------------------------------------------

clear all // Vorsicht: Löscht alle Daten im Speicher! Nur verwenden, wenn nötig.
// global neudatenpfad "DEIN_PFAD_HIER" // Beispiel

* Annahme: Dein Datensatz ist bereits geladen oder wird hier geladen.
* Ersetze dies mit deinem tatsächlichen Ladebefehl.
// Beispiel: use "$neudatenpfad/Temp/DiD_prep_transformed.dta", clear
// Lade hier deinen Datensatz:
// Zum Testen erstelle ich hier eine Dummy-Variable.
// ERSETZE DIESEN TEIL MIT DEINEM DATENLADEBEFEHL
/*
set obs 1000
gen id = _n
expand 7 // Simuliere Panelstruktur
bysort id: gen jahr = 2013 + _n -1
xtset id jahr
gen var_to_winsorize = rnormal(100, 50) + (runiformint(1,100) > 95) * rnormal(500,100) - (runiformint(1,100) > 95) * rnormal(500,100)
label variable var_to_winsorize "Beispielvariable zum Winsorisieren"
*/
*-------------------------------------------------------------------------------
* 1. Definition der zu winsorisierenden Variable und der Perzentile
* BITTE PASSE DIESE MAKROS AN DEINE BEDÜRFNISSE AN!
*-------------------------------------------------------------------------------
global variable_to_winsorize "g_reing" // Name der Variable
global lower_percentile 1                       // Unteres Perzentil (z.B. 1 für 1%)
global upper_percentile 99                      // Oberes Perzentil (z.B. 99 für 99%)

* Name für die neue winsorisierte Variable
local winsorized_var_name "${variable_to_winsorize}_w${lower_percentile}${upper_percentile}"

*-------------------------------------------------------------------------------
* 2. Berechnung der Perzentilwerte
* Wir verwenden `_pctile` für Robustheit in Programmen.
* Alternative: `centile`.
*-------------------------------------------------------------------------------
di _n as yellow "Berechne Perzentile für Variable: ${variable_to_winsorize}"

// Stelle sicher, dass die Variable numerisch ist
capture confirm numeric variable ${variable_to_winsorize}
if _rc != 0 {
    di as error "Variable ${variable_to_winsorize} ist nicht numerisch oder existiert nicht."
    exit 198 // Fehlercode für Syntaxfehler
}

// Berechne das untere Perzentil
qui _pctile ${variable_to_winsorize}, p(${lower_percentile})
if missing(r(r1)) {
    di as error "Konnte das untere Perzentil (${lower_percentile}) für ${variable_to_winsorize} nicht berechnen."
    di as error "Möglicherweise hat die Variable zu viele fehlende Werte oder keine Varianz."
    exit 498 // Fehlercode für "no observations" oder ähnliches
}
scalar p_lower = r(r1)
di as text "  Unteres Perzentil (${lower_percentile}%): " as result p_lower

// Berechne das obere Perzentil
qui _pctile ${variable_to_winsorize}, p(${upper_percentile})
if missing(r(r1)) {
    di as error "Konnte das obere Perzentil (${upper_percentile}) für ${variable_to_winsorize} nicht berechnen."
    exit 498
}
scalar p_upper = r(r1)
di as text "  Oberes Perzentil (${upper_percentile}%): " as result p_upper

// Überprüfung, ob unteres Perzentil <= oberes Perzentil ist
if p_lower > p_upper {
    di as warning "Warnung: Unteres Perzentil (" p_lower ") ist größer als oberes Perzentil (" p_upper ")."
    di as warning "Dies kann bei sehr speziellen Verteilungen oder wenigen Datenpunkten passieren."
    // Du könntest hier entscheiden, das Winsorisieren nicht durchzuführen oder eine andere Logik anzuwenden.
    // Fürs Erste machen wir weiter, aber das Ergebnis könnte unerwartet sein.
}

*-------------------------------------------------------------------------------
* 3. Erstellung der winsorisierten Variable
*-------------------------------------------------------------------------------
di _n as yellow "Erstelle winsorisierte Variable: `winsorized_var_name'"

// A. Kopiere die Originalvariable
gen `winsorized_var_name' = ${variable_to_winsorize}
label variable `winsorized_var_name' "${variable_to_winsorize} winsorisiert (P${lower_percentile}-P${upper_percentile})"

// B. Ersetze Werte unterhalb des unteren Perzentils
//    Beachte: Nur ersetzen, wenn die Originalvariable nicht missing ist, um Missings nicht zu Nullen zu machen.
replace `winsorized_var_name' = p_lower if ${variable_to_winsorize} < p_lower & !missing(${variable_to_winsorize})
local changes_lower = r(N)

// C. Ersetze Werte oberhalb des oberen Perzentils
replace `winsorized_var_name' = p_upper if ${variable_to_winsorize} > p_upper & !missing(${variable_to_winsorize})
local changes_upper = r(N)

di as text "  Anzahl der auf unteres Perzentil gesetzten Werte: " as result `changes_lower'
di as text "  Anzahl der auf oberes Perzentil gesetzten Werte: " as result `changes_upper'

// Test
tab e_persausg_w199 if e_persausg_w199 >4
tab e_persausg if e_persausg >4


*-------------------------------------------------------------------------------
* 4. Überprüfung der Transformation (optional)
*-------------------------------------------------------------------------------
di _n as green "Deskriptive Statistiken für Original und winsorisierte Variable:"
summarize ${variable_to_winsorize} `winsorized_var_name', separator(2)

di _n as green "Vergleich der Perzentile (Original vs. Winsorisiert):"
centile ${variable_to_winsorize} `winsorized_var_name', centile(0 1 5 25 50 75 95 99 100)

// Histogramme zur visuellen Überprüfung
capture noisily { // `noisily` um Output zu sehen, falls Fehler
    histogram ${variable_to_winsorize}, name(hist_orig_${variable_to_winsorize}, replace) title("Original ${variable_to_winsorize}") scheme(s1color)
    histogram `winsorized_var_name', name(hist_wins_${winsorized_var_name}, replace) title("`winsorized_var_name'") scheme(s1color)
    // graph combine hist_orig_${variable_to_winsorize} hist_wins_${winsorized_var_name} // Um sie nebeneinander zu sehen
    di as text "Histogramme erstellt (oder versucht zu erstellen)."
}

* Aufräumen der Skalare
scalar drop p_lower p_upper

*-------------------------------------------------------------------------------
* Speichern des Datensatzes (optional)
*-------------------------------------------------------------------------------
// compress
// save "$neudatenpfad/DeinDatensatz_winsorisiert.dta", replace
// di _n as green "Datensatz mit winsorisierter Variable gespeichert."

*exit
*############################################################
















/*
 // Inverse Hyperbolische Sinus (asinh) Transformation
    // Definiert für alle reellen Zahlen (positiv, negativ, null)
    // Verhält sich ähnlich wie ln(2x) für große x, linear um 0
    gen `var'_asinh = asinh(`var')
    label variable `var'_asinh "Inverse Hyperbolische Sinus von `var'"
    di as text "  -> `var'_asinh erstellt (asinh)"

    // B. Winsorizing
    // Verwendet `egen winsor()` aus dem `egenmore` Paket
    // `limits(# #)` gibt die unteren und oberen Perzentile an, auf die winsorisiert wird.
    //---------------------------------------------------------------------------

    // Winsorizing auf 1. und 99. Perzentil
    // Werte unter P1 werden auf P1 gesetzt, Werte über P99 werden auf P99 gesetzt.
    capture egen `var'_w99 = winsor(`var'), limits(1 99)
    if _rc == 0 {
        label variable `var'_w99 "`var' winsorisiert (1. & 99. Perzentil)"
        di as text "  -> `var'_w99 erstellt (Winsorized P1-P99)"
    }
    else {
        di as error "  -> `var'_w99 konnte nicht erstellt werden mit egen winsor(). Stelle sicher, dass 'egenmore' installiert ist."
    }

    // Winsorizing auf 5. und 95. Perzentil
    // Werte unter P5 werden auf P5 gesetzt, Werte über P95 werden auf P95 gesetzt.
    capture egen `var'_w95 = winsor(`var'), limits(5 95)
    if _rc == 0 {
        label variable `var'_w95 "`var' winsorisiert (5. & 95. Perzentil)"
        di as text "  -> `var'_w95 erstellt (Winsorized P5-P95)"
    }
    else {
        di as error "  -> `var'_w95 konnte nicht erstellt werden mit egen winsor()."
    }
    
    // Optional: Einseitiges Winsorizing (z.B. nur obere Ausreißer)
    // `egen `var'_w_upper99 = winsor(`var'), limits(. 99)` // Nur oberes Ende
    // `egen `var'_w_lower1 = winsor(`var'), limits(1 .)`   // Nur unteres Ende
	
	
	
	
    
    // C. Kombination: Erst Winsorisieren, dann Logarithmieren/asinh
    // Dies kann sinnvoll sein, wenn nach dem Winsorisieren immer noch Schiefe besteht
    // oder um sicherzustellen, dass Logarithmen von nicht-extremen positiven Werten genommen werden.
    //---------------------------------------------------------------------------
    
    // Beispiel: Erst auf 1%/99% winsorisieren, dann asinh
    // Wir verwenden die bereits erstellte `var'_w99 Variable
    if _rc == 0 { // Nur wenn `var'_w99 erfolgreich erstellt wurde
        gen `var'_w99_asinh = asinh(`var'_w99)
        label variable `var'_w99_asinh "asinh von `var' (winsor. P1-P99)"
        di as text "  -> `var'_w99_asinh erstellt (asinh nach Winsorizing P1-P99)"
    }
}

*-------------------------------------------------------------------------------
* 3. Überprüfung der Transformationen (Beispiele)
*-------------------------------------------------------------------------------
// Du solltest die Verteilungen vor und nach der Transformation überprüfen,
// z.B. mit summarize und histogram

if "$dependent_vars" != "" { // Nur ausführen, wenn dependent_vars nicht leer ist
    local first_var : word 1 of $dependent_vars
    
    di _n as green "Deskriptive Statistiken für `first_var' und seine Transformationen:"
    summarize `first_var' `first_var'_ln `first_var'_asinh `first_var'_w99 `first_var'_w95 `first_var'_w99_asinh, separator(4)

    di _n as green "Histogramme für `first_var' (Original und Winsorisiert P1-P99):"
    capture histogram `first_var', name(hist_orig_`first_var', replace) title("Original `first_var'")
    capture histogram `first_var'_w99, name(hist_w99_`first_var', replace) title("`first_var' Winsorisiert (P1-P99)")
    // graph combine hist_orig_`first_var' hist_w99_`first_var' // Um sie nebeneinander zu sehen
}

*-------------------------------------------------------------------------------
* 4. Speichern des Datensatzes (optional)
*-------------------------------------------------------------------------------
// compress // Komprimiert den Datensatz, um Speicherplatz zu sparen
// save "$neudatenpfad/Temp/DiD_prep_transformed.dta", replace
// di _n as green "Datensatz mit transformierten Variablen gespeichert."

exit


*/
///#####################################
// Überblick missing values


*-------------------------------------------------------------------------------
* Überprüfung der Variablenverfügbarkeit im Panel (id, jahr)
* Kompatibel mit Stata 16 und Stata 18
*-------------------------------------------------------------------------------

clear all // Vorsicht: Löscht alle Daten im Speicher! Nur verwenden, wenn nötig.
// global neudatenpfad "DEIN_PFAD_HIER" // Beispiel

* Annahme: Dein Datensatz ist bereits geladen oder wird hier geladen.
* Ersetze dies mit deinem tatsächlichen Ladebefehl für "DiD_prep.dta" oder den relevanten Datensatz.
// Beispiel: use "$neudatenpfad/Temp/DiD_prep.dta", clear
// Lade hier deinen Datensatz:
use "$neudatenpfad/Temp/DiD_prep.dta", clear // Beispielpfad, bitte anpassen!


*-------------------------------------------------------------------------------
* 1. Definition der zu untersuchenden abhängigen Variable(n)
* BITTE PASSE DIESES MAKRO AN DEINE VARIABLE(N) AN!
* Du kannst hier auch mehrere Variablen eintragen, getrennt durch Leerzeichen.
*-------------------------------------------------------------------------------
global abhaengige_variablen "ln_stpfgew" // Ersetze dies mit deiner/deinen abhängigen Variable(n)
                                       // z.B. "stpfgew e_persausg g_reing"

*-------------------------------------------------------------------------------
* 2. Analyse der jährlichen Verfügbarkeit für jede abhängige Variable
*-------------------------------------------------------------------------------

foreach var of global abhaengige_variablen {
    di _n as yellow "********************************************************************************"
    di as yellow "* Analyse der jährlichen Verfügbarkeit für Variable: `var' *"
    di as yellow "********************************************************************************"

    preserve // Sichert den aktuellen Zustand des Datensatzes

    // A. Temporäre Variable erstellen, die anzeigt, ob `var` nicht fehlt
    capture gen byte `var'_present = !missing(`var')
    if _rc != 0 {
        di as error "Variable `var' nicht gefunden oder Problem bei der Erstellung von `var'_present."
        restore
        continue // Springe zur nächsten Variable in der Schleife, falls vorhanden
    }
    label variable `var'_present "1 wenn `var' vorhanden, sonst 0"

    // B. Daten auf Jahresebene aggregieren
    // Zähle Gesamtbeobachtungen (Firma-Jahr-Paare) pro Jahr
    // Zähle Beobachtungen, bei denen `var` vorhanden ist, pro Jahr
    tempfile year_summary_`var'
    collapse (count) total_obs_in_year = id ///
             (sum) non_missing_`var' = `var'_present, by(jahr) fast

    // C. Prozentsatz der gefüllten Beobachtungen berechnen
    gen pct_filled_`var' = (non_missing_`var' / total_obs_in_year) * 100
    label variable pct_filled_`var' "% `var' vorhanden in diesem Jahr"

    // D. Ergebnisse anzeigen
    di _n as green "Jährliche Verfügbarkeit von `var':"
    list jahr total_obs_in_year non_missing_`var' pct_filled_`var', ///
        noobs sepby(jahr) abbreviate(20) ///
        title("Jährliche Verfügbarkeit der Variable: `var'")
        
    format pct_filled_`var' %9.1f

    // E. Optionale grafische Darstellung
    di _n as green "Grafik der jährlichen Verfügbarkeit wird erstellt (pct_filled_`var'_vs_jahr.png)"
    twoway (line pct_filled_`var' jahr, sort connect(L) lcolor(blue) mcolor(blue) msymbol(O)) ///
           , title("Prozentsatz gefüllter Werte für `var' pro Jahr") ///
             ytitle("Prozent gefüllt") xtitle("Jahr") ///
             legend(off) name(graph_`var', replace)
    graph export "$outputpfad/pct_filled_`var'_vs_jahr.png", replace // Pfad anpassen!
    // graph display graph_`var' // Um die Grafik direkt anzuzeigen

    restore // Stellt den ursprünglichen Datensatz wieder her
    di _n
}

*-------------------------------------------------------------------------------
* 3. Analyse der firmenbezogenen Vollständigkeit (Anzahl Jahre mit Daten pro Firma)
* Dies gibt einen Hinweis darauf, ob Firmen systematisch über längere Zeiträume
* keine Daten für die abhängige Variable liefern.
*-------------------------------------------------------------------------------

foreach var of global abhaengige_variablen {
    di _n as yellow "********************************************************************************"
    di as yellow "* Analyse der firmenbezogenen Vollständigkeit für Variable: `var' *"
    di as yellow "********************************************************************************"

    // A. Zählen, für wie viele Jahre jede Firma (`id`) Daten für `var` hat
    capture drop num_years_`var'_present
    bysort id: egen num_years_`var'_present = total(!missing(`var'))
    if _rc != 0 {
        di as error "Problem bei der Berechnung von num_years_`var'_present für `var'."
        continue
    }
    label variable num_years_`var'_present "Anzahl Jahre mit Daten für `var' (pro Firma)"

    // B. Deskriptive Statistik der Anzahl der Jahre mit Daten pro Firma
    di _n as green "Deskriptive Statistik: Anzahl Jahre, für die `var' pro Firma vorhanden ist"
    summarize num_years_`var'_present, detail

    // C. Häufigkeitsverteilung anzeigen (wie viele Firmen haben 0 Jahre Daten, 1 Jahr, etc.)
    di _n as green "Häufigkeitsverteilung: Anzahl Jahre, für die `var' pro Firma vorhanden ist"
    // Wir wollen die Verteilung über die Firmen, nicht über die Firma-Jahr Beobachtungen
    preserve
        bysort id: keep if _n == 1 // Behalte nur eine Beobachtung pro Firma
        tabulate num_years_`var'_present, missing
    restore
    
    // D. Optional: Wie viele Firmen haben in *keinem* Jahr Daten für `var`?
    preserve
        bysort id: keep if _n == 1
        count if num_years_`var'_present == 0
        local firms_no_data_`var' = r(N)
        count
        local total_unique_firms_`var' = r(N)
        if `total_unique_firms_`var' > 0 {
            local pct_firms_no_data_`var' : display %4.1f (`firms_no_data_`var'' / `total_unique_firms_`var'') * 100
            di _n as green "Firmen ohne jegliche Daten für `var': " as result `firms_no_data_`var'' " von " `total_unique_firms_`var'' " (" `pct_firms_no_data_`var'' "%)"
        }
    restore
    di _n
}

di _n as green "Analyse der Variablenverfügbarkeit abgeschlossen."
exit




//#### Methode 1:  Alle Missings auf 0 setzen

*-------------------------------------------------------------------------------
* Imputation fehlender Werte in einer abhängigen Variable
* Methode 1: Alle Missings auf 0 setzen
* Methode 2: Missings auf 0 setzen, wenn ID mindestens einen Non-Missing Wert hat
* Kompatibel mit Stata 16 und Stata 18
*-------------------------------------------------------------------------------

clear all // Vorsicht: Löscht alle Daten im Speicher! Nur verwenden, wenn nötig.
// global neudatenpfad "DEIN_PFAD_HIER" // Beispiel

* Annahme: Dein Datensatz ist bereits geladen oder wird hier geladen.
* Ersetze dies mit deinem tatsächlichen Ladebefehl.
// Beispiel: use "$neudatenpfad/Temp/DiD_prep_transformed.dta", clear
// Lade hier deinen Datensatz:
use "$neudatenpfad/Temp/DiD_prep_transformed.dta", clear // Beispielpfad, bitte anpassen!


*-------------------------------------------------------------------------------
* 1. Definition der zu imputierenden abhängigen Variable
* BITTE PASSE DIESES MAKRO AN DEINE VARIABLE AN!
*-------------------------------------------------------------------------------
global dv_to_impute "ln_stpfgew" // Ersetze dies mit deiner abhängigen Variable

* Stelle sicher, dass die Panelstruktur definiert ist (wichtig für Methode 2)
* xtset id jahr // Entkommentiere und passe dies an, falls nicht bereits geschehen

*-------------------------------------------------------------------------------
* Methode 1: Alle fehlenden Werte in `dv_to_impute` auf 0 setzen
* Die neue Variable heißt `dv_to_impute`_zero_all
*-------------------------------------------------------------------------------
di _n as yellow "Methode 1: Alle fehlenden Werte von ${dv_to_impute} auf 0 setzen"

gen ${dv_to_impute}_zero_all = ${dv_to_impute}
replace ${dv_to_impute}_zero_all = 0 if missing(${dv_to_impute})

label variable ${dv_to_impute}_zero_all "${dv_to_impute}, alle Missings als 0"

// Überprüfung (optional)
local anzahl_missings_original = 0
count if missing(${dv_to_impute})
local anzahl_missings_original = r(N)

local anzahl_missings_zero_all = 0
count if missing(${dv_to_impute}_zero_all)
local anzahl_missings_zero_all = r(N)

local anzahl_nullen_zero_all = 0
count if ${dv_to_impute}_zero_all == 0
local anzahl_nullen_zero_all = r(N)

di as text "  Originalvariable '${dv_to_impute}': " as result `anzahl_missings_original' " fehlende Werte."
di as text "  Neue Variable '${dv_to_impute}_zero_all': " as result `anzahl_missings_zero_all' " fehlende Werte."
di as text "  Anzahl der Nullen in '${dv_to_impute}_zero_all': " as result `anzahl_nullen_zero_all'
summarize ${dv_to_impute} ${dv_to_impute}_zero_all, separator(2)




//#### Methode 2: Falls ein Wert missing ist setze ihn auf null!




*-------------------------------------------------------------------------------
* Methode 2: Fehlende Werte auf 0 setzen, wenn für die ID mindestens
* eine nicht-fehlende Beobachtung über die Jahre existiert.
* Die neue Variable heißt `dv_to_impute`_zero_conditional
*-------------------------------------------------------------------------------
di _n as yellow "Methode 2: Fehlende Werte von ${dv_to_impute} auf 0 setzen, wenn ID Non-Missing hat"

// Schritt 2.1: Prüfen, ob eine ID überhaupt nicht-fehlende Werte hat
// Erstelle eine Hilfsvariable, die für jede ID anzeigt, ob sie mindestens einen nicht-fehlenden Wert hat
tempvar has_non_missing
bysort id: egen byte `has_non_missing' = total(!missing(${dv_to_impute}))
// `has_non_missing` ist > 0, wenn die ID mindestens einen nicht-fehlenden Wert hat, sonst 0.

// Schritt 2.2: Neue Variable erstellen und bedingt imputieren
gen ${dv_to_impute}_zero_conditional = ${dv_to_impute}
replace ${dv_to_impute}_zero_conditional = 0 if missing(${dv_to_impute}) & `has_non_missing' > 0

label variable ${dv_to_impute}_zero_conditional "${dv_to_impute}, Missings als 0 (konditional)"

// Überprüfung (optional)
local anzahl_missings_zero_cond = 0
count if missing(${dv_to_impute}_zero_conditional)
local anzahl_missings_zero_cond = r(N)

local anzahl_nullen_zero_cond = 0
count if ${dv_to_impute}_zero_conditional == 0 & `has_non_missing' > 0
local anzahl_nullen_zero_cond = r(N)

di as text "  Originalvariable '${dv_to_impute}': " as result `anzahl_missings_original' " fehlende Werte."
di as text "  Neue Variable '${dv_to_impute}_zero_conditional': " as result `anzahl_missings_zero_cond' " fehlende Werte."
di as text "  Anzahl der konditional auf 0 gesetzten Werte in '${dv_to_impute}_zero_conditional': " as result `anzahl_nullen_zero_cond'
summarize ${dv_to_impute} ${dv_to_impute}_zero_all ${dv_to_impute}_zero_conditional, separator(3)









// Vergleich der drei Variablen für eine zufällige ID mit Missings (falls vorhanden)
preserve
    bysort id: egen temp_miss_count = total(missing(${dv_to_impute}))
    bysort id: egen temp_non_miss_count = total(!missing(${dv_to_impute}))
    keep if temp_miss_count > 0 & temp_non_miss_count > 0 // Behalte IDs, die für Methode 2 relevant sind
    if _N > 0 {
        sample 1, count // Nimm eine zufällige ID
        di _n as green "Beispielhafte ID zur Überprüfung von Methode 2:"
        list id jahr ${dv_to_impute} ${dv_to_impute}_zero_all ${dv_to_impute}_zero_conditional `has_non_missing' if !missing(id), noobs sepby(id)
    }
    else {
        di _n as yellow "Keine IDs gefunden, die sowohl fehlende als auch nicht-fehlende Werte für ${dv_to_impute} haben."
    }
restore

*-------------------------------------------------------------------------------
* Speichern des Datensatzes (optional)
*-------------------------------------------------------------------------------
// compress
// save "$neudatenpfad/Temp/DiD_prep_imputed.dta", replace
// di _n as green "Datensatz mit imputierten Variablen gespeichert."

*exit