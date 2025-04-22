*-------------------------------------------------------------------------------------------------------------------
*   Project Title: THE DETERMINANTS OF TAX COMPLIANCE
*	Code: Analyze full_gwap.dta
/* 
 04_DiD_2xT_stacked.do schätzt dynamisches stacked DiD. Aggregiert also die Effekte über die einzelnen Treatment gruppen. Treatmentgruppe sind jetzt also "n001000" "n000100" und "n000010" Fälle. Kontrollgruppe bleibt unverändert "n000000"


More info see:

https://d2cml-ai.github.io/csdid/examples/csdid_basic.html

https://asjadnaqvi.github.io/DiD/docs/code/06_05_csdid/ 
https://asjadnaqvi.github.io/DiD/docs/01_stata/ -> Überblick über packages und entsprechende reference papers

https://economistwritingeveryday.com/tag/csdid2/


https://www.jonathandroth.com/assets/files/DiD_Review_Paper.pdf

csdid help
*/

*-------------------------------------------------------------------------------------------------------------------


/*
An area of active research presents to the textbook author both the purest terror and the sweetest relief. Whatever I say will almost certainly be outdated by the time you read it. But the inevitability of failure, dang, that’s some real freedom.

When it comes to ways of handling multiple treatment periods in difference-in-differences, where some groups are treated at different times than others (rollout designs), “active area of research” is right! Because concern over the failure of the two-way fixed effects model for rollout designs is relatively recent, at least on an academic time scale, the approaches to solving the problem are fairly new, and it’s not yet clear which will become popular, or which will be proven to have unforeseen errors in them.

I will show two ways of addressing this problem. First, I will show how our approach to dynamic treatment effects can help us fix the staggered rollout problem. Then I’ll discuss the method described in Callaway and Sant’Anna (2020Callaway, Brantly, and Pedro HC Sant’Anna. 2020. “Difference-in-Differences with Multiple Time Periods.” Journal of Econometrics.). More technical details on all of these, as well as discussion of some additional fancy-new estimators, are in Baker, Larcker, and Wang (2021Baker, Andrew C., David F. Larcker, and Charles C. Y. Wang. 2021. “How Much Should We Trust Staggered Difference-in-Differences Estimates?” Social Science Research Network.), which also discusses a third approach called “stacked regression.’’ But there is more coming out regularly about all of this. Hey, maybe even a version of the random-effects Mundlak estimator from Chapter 16 could fix the problem (Wooldridge 2021Wooldridge, Jeffrey M. 2021. “Two-Way Fixed Effects, the Two-Way Mundlak Regression, and Difference-in-Differences Estimators.” SSRN.)! So you’ll probably want to check in on new developments in this area before getting too far with your staggered rollout study.

Models for dynamic treatment effects, modified for use with staggered rollout, can help in the case of staggered difference-in-differences in a few ways.

First, they separate out the time periods when the effects take place. Since our whole problem is overlapping effects in different time periods, this gives us a chance to separate things out and fix our problem.

Second, they’re just plain a good idea when it comes to difference-in-differences with multiple time periods. As described in the Long-Term Effects section, we can check the plausibility of prior trends, and also see how the effect changes over time (and most effects do).

Third, because they do let us see how the treatment effect evolves, and because treatment effects evolving is one of the problems with two-way fixed effects, that gives us another opportunity to separate things out and fix them.

What do I mean by “modified for use with staggered rollout,” then? A few things, all described in Sun and Abraham (2020Sun, Liyang, and Sarah Abraham. 2020. “Estimating Dynamic Treatment Effects in Event Studies with Heterogeneous Treatment Effects.” Journal of Econometrics.).

First, we need to center each group relative to its own treatment period, instead of “calendar time.” This helps make sure that already-treated groups don’t get counted as comparisons. But as pointed out in the Long-Term Effects section, dynamic treatment effects can still get in the way here. So Sun and Abraham (2020) go further. They don’t just use a set of time-centered-on-treatment-time dummies, they interact those dummies with group membership. This really allows you to avoid making any comparisons you don’t want to make, since now your regression model is barely comparing anything. It’s giving each group and time period its own coefficient. The comparisons are then up to you, after the fact. You can average those coefficients together in a way that gives you a time-varying treatment effect.2929 Weighting by group size is standard here. See the paper, or its simpler description in Baker, Larcker, and Wang (2021).

The Sun and Abraham estimator can be estimated in R using the sunab function in the fixest package, or in Stata using the eventstudyinteract package.

The first thing Callaway and Sant’Anna do is focus closely on when each group was treated. What’s one way to deal with all those different treatment periods giving your estimation a hard time? Consider them separately! They consider each treatment period just a little different, and instead of estimating an average treatment-on-the-treated for the whole sample, they estimate “group-time treatment effects,” which are average treatment effects on the group treated in a particular time period, so you end up with a bunch of different effect estimates, one for each time period where the treatment was new to someone.

Now dealing with the treated groups separately by when they were treated, they compare

between each treatment group and the untreated group, and use propensity score matching (as in Chapter 14) to improve their estimate. So each group-time treatment effect is based on comparing the post-treatment outcomes of the groups treated in that period against the never-treated groups that are most similar to those treated groups.

Once you have all those group-time treatment effects, you can summarize them to answer a few different types of questions. You could carefully average them together to get a single average-treatment-on-the-treated.3030 I say “carefully” because you’ll want to do a weighted average with some specially-chosen weights, as described in the paper. You could compare the effects from earlier-treated groups against later-treated groups to estimate dynamic treatment effects. Plenty of options.

The Callaway and Sant’Anna method can be implemented using the R package did. In Stata you can use the csdid package, and in Python there is differences.


*/


/*
	noch anpassen:
	
	- mehr Variablen aufnehmen!
	
	- truncaten nur für kontrollvariablen oder um ergebnisse nicht durch extreme Werte beeinflussen zu lassen, Methode dann auch immer auf vollsampel durchführen! z.B. via keep if popg >= popgallwp05 & popg <= popgallwp95 & !missing(popg)  quantile erhält man z.B. über centile variablenname, centile(5 95) in r(c_1) ist das 5% und in r(c_2) das 95% gespeichert.
	
	- Ausreiserbehandlung replace logdiff = . if logdiff < ld_p1oder> ld_p99`
	
	- Winsorizen nur für grafiken! gen be_winz = besch_lj   replace be_winz = 4000 if besch_lj > 4000 & besch_lj != .
	
	- Mischformen rausnehmen:
	Mischformen zählen auch zu den Personengesellschaften. Grundsätzlich ist bei diesen Mischformen die Personengesellschaft operativ tätig, die Kapitalgesellschaft dient nur dazu, Haftung zu begrenzen. D.h., dass die Gewerbesteuer im Endeffekt von der Personengesellschaft zu zahlen ist, was ja unseren Anforderungen entspricht. Man muss allerdings dennoch vorsichtig sein, da i.d.R. auch Gewinnanteile von der Personengesellschaft an die Kapitalgesellschaft abfließen, was die Möglichkeit der Gewerbesteueranrechnung im Vergleich zu reinen Personengesellschaften verzerren kann. Daher würde ich die Mischformen eher nicht einbeziehen.
	GmbH & Co.KG GmbH & Co.OHG   AG & Co.KG AG& Co.OHG  
	

	
	*/




*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block 1:  Stacked DiD using csdid (and crdid?)
*	----
*	-------------------------------------------------------------------------------------------------------------------

// TODO: verlgeiche einzel treatmentgruppen ergebnisse mit den bisherigen.
// zeige gesamtergebnsise 
// berechne gesamtergebnsise selbst indem einzel ergebnsise aggregiert werden

// csdid eine treatmentgruppe multiple time periods
gen behandlungsjahr2017 = .
replace behandlungsjahr2017 = 0 if inlist(pattern_tax,"n000000")
replace behandlungsjahr2017 = 2017 if inlist(pattern_tax,"n000100")

// ...  csdid geht von einer "staggered adoption" aus, bei der eine Einheit, sobald sie behandelt wird, für alle Folgeperioden behandelt bleibt 

//csdid stacked time periods

//gvar erstellen

gen behandlungsjahr = .
replace behandlungsjahr = 0 if inlist(pattern_tax,"n000000")
replace behandlungsjahr = 2016 if inlist(pattern_tax,"n001000")
replace behandlungsjahr = 2017 if inlist(pattern_tax,"n000100")
replace behandlungsjahr = 2018 if inlist(pattern_tax,"n000010")  // 2015 2014 2019 noch einfügen? 


// Check:
* Überprüfung (wichtig!):
* Stellen Sie sicher, dass die Variable für jede Firma konstant ist
bysort id (jahr): assert erstes_behandlungsjahr[1] == erstes_behandlungsjahr[_N]
* Schauen Sie sich die Verteilung an. Sie sollten nur die Werte 0 und 2017 sehen.
tabulate erstes_behandlungsjahr
* Wenn andere Werte als 0 und 2017 auftauchen, überprüfen Sie Ihre 'steuererhoehung'-Variable und die Logik oben.


csdid ln_stpfgew, ivar(id) time(jahr) gvar(erstes_behandlungsjahr)
// csdid outcome_var [covariates], ivar(unit_id) time(time_period) gvar(first_treatment_period) [options]
// wenn covariates eingeschlossen wird options benötigt, notyet wählt statt nevertreated die not yet treated als kontrollgruppe:  csdid lemp lpop, ivar(countyreal) time(year) gvar(first_treat) notyet method(ipw)
estat event
csdid_plot, vertical title("Dynamische Effekte der Steuererhöhung") xtitle("Jahre relativ zur Steuererhöhung (Jahr 0 = 2017)")


/*

6. Interpretation der primären Ausgabe

Der csdid-Befehl gibt standardmäßig eine Tabelle mit den geschätzten ATT(g,t)-Werten aus [source: 72, 76]. Das sind die durchschnittlichen Behandlungseffekte für eine spezifische Kohorte g (die im Jahr g behandelt wurde) in einer spezifischen späteren Zeitperiode t. Sie sehen also viele einzelne Schätzungen.

7. Nächste Schritte: Aggregation und Visualisierung

Da die Anzahl der ATT(g,t)-Schätzungen groß sein kann, bietet csdid Post-Estimation-Befehle zur Aggregation und Visualisierung:

    estat event: Berechnet und zeigt aggregierte Effekte nach "event time" (Zeit relativ zum Behandlungsbeginn) an. Dies ist nützlich, um dynamische Effekte zu sehen (z. B. Effekt 1 Jahr vor Behandlung, im Jahr der Behandlung, 1 Jahr nach Behandlung, etc.) [source: 84 ("event study"), 94, 97]. Oft wird dies auch grafisch dargestellt.
    estat group: Zeigt den durchschnittlichen Effekt für jede Behandlungskohorte (über alle Post-Treatment-Perioden) [source: 91].
    estat time: Zeigt den durchschnittlichen Effekt für jede Kalenderzeitperiode (über alle behandelten Gruppen) [source: 92].
    estat all: Berechnet einen Gesamt-Durchschnittseffekt über alle Gruppen und Zeiträume sowie Tests für Pre-Trends [source: 84 ("simple weighted average"), 88, 89, 90].
    csdid_plot: Erstellt Grafiken der Effekte, oft im Event-Study-Format [source: 63, 99, 100].

* Zeigt die aggregierten Effekte nach 'event time' (Zeit relativ zu 2017)
* T-3 = 2014 vs 2016
* T-2 = 2015 vs 2016
* T-1 = 2016 vs 2016 (Referenz)
* T+0 = 2017 vs 2016 (Effekt im 1. Jahr)
* T+1 = 2018 vs 2016 (Effekt im 2. Jahr)
* T+2 = 2019 vs 2016 (Effekt im 3. Jahr)


Clustern der Standardfehler:

    Der csdid-Befehl berechnet standardmäßig analytische Standardfehler, die auf den Formeln aus Callaway und Sant'Anna (2020) basieren. Diese berücksichtigen die Struktur der Schätzung.
    Man verwendet bei csdid nicht die übliche Option vce(cluster id), wie man es bei reg oder xtreg tun würde. Die Standardfehler von csdid sind bereits so konzipiert, dass sie für die DiD-Schätzung mit Paneldaten (oder wiederholten Querschnitten) unter den Annahmen des Modells gültig sind. Sie berücksichtigen die Variabilität, die sich aus der Schätzung der ATT(g,t)-Parameter ergibt.
    Alternative für Robustheit (empfohlen bei Paneldaten): Bootstrap. Wenn Sie Bedenken wegen der Annahmen der analytischen Standardfehler haben oder eine gängige Methode zur Berücksichtigung der Korrelation von Beobachtungen innerhalb derselben Firma über die Zeit wünschen, können Sie Bootstrap-Standardfehler verwenden. csdid bietet dafür die Option wboot (Wild Bootstrap), die in DiD-Kontexten oft empfohlen wird [source: 75].

So implementieren Sie es mit Wild Bootstrap:
Stata

csdid ln_stpfgew, ivar(id) time(jahr) gvar(erstes_behandlungsjahr) wboot

    Die Verwendung von wboot berechnet die Standardfehler und Konfidenzintervalle mithilfe des Wild-Bootstrap-Verfahrens, das als robust gegenüber Heteroskedastizität und der Cluster-Struktur (Korrelation innerhalb von id) in Paneldaten gilt. Beachten Sie, dass dies rechenintensiver ist und länger dauern kann. Sie können mit reps(#) die Anzahl der Bootstrap-Wiederholungen festlegen (Standard ist oft 999) und mit seed(#) die Ergebnisse reproduzierbar machen [source: 75, example uses rseed].



*/

//automatisierter code für lange liste


* --- Liste der abhängigen Variablen ---
* Passen Sie diese Liste an Ihre Variablennamen an
local dependent_vars "ln_stpfgew var2 var3" // Ersetzen Sie var2, var3 etc. mit Ihren echten Namen

* --- Verzeichnis zum Speichern der Ergebnisse festlegen (optional) ---
* cd "Ihr/Pfad/zum/Speicherort" // Wenn Sie die Dateien in einem bestimmten Ordner speichern möchten

* --- Optionen für csdid (optional, aber empfohlen) ---
* Verwenden Sie wboot für robuste Standardfehler (Wild Bootstrap), die Clusterung auf id-Ebene berücksichtigen
local csdid_options "wboot reps(499) seed(1234)" // reps(499) ist schneller als 999, seed für Reproduzierbarkeit

* --- Schleife über alle abhängigen Variablen ---
foreach depvar of local dependent_vars {

    display as_header "Verarbeite abhängige Variable: `depvar'"

    * 1. csdid Schätzung durchführen
    * Fängt mögliche Fehler ab, falls csdid für eine Variable nicht läuft
    capture csdid `depvar', ivar(id) time(jahr) gvar(erstes_behandlungsjahr) `csdid_options'

    * Prüfen, ob csdid erfolgreich war (error code == 0)
    if _rc == 0 {

        * 2. Event Study Ergebnisse berechnen
        estat event

        * 3. Event Study Tabelle als Excel speichern (mit etable)
        * Verwendet etable (in neueren Stata-Versionen eingebaut) zum Exportieren
        capture etable, showstars ///
                       title("Event Study Results: `depvar'") ///
                       export("event_study_`depvar'.xlsx", replace)
        if _rc == 0 {
             display "Event study table saved as event_study_`depvar'.xlsx"
        } else {
             display as_error "Konnte Event study table nicht als Excel speichern für `depvar'."
        }


        * 4. Event Study Tabelle als LaTeX speichern (mit esttab)
        * Erstellt eine LaTeX-Tabelle der Event Study Ergebnisse nach 'estat event'
        capture esttab using "event_study_`depvar'.tex", ///
                       replace booktabs nogaps           /// // LaTeX Formatierung, booktabs für schöne Linien
                       star(* 0.10 ** 0.05 *** 0.01)  /// // Signifikanzsterne
                       title("Dynamische Behandlungseffekte (ATT) für `depvar' \\label{tab:event_`depvar'}") /// // Titel und LaTeX-Label
                       b(%9.3f) se(%9.3f)              /// // Zahlenformat für Koeffizienten (b) und Standardfehler (se)
                       mtitles("`depvar'")             /// // Spaltentitel (Modelltitel)
                       coeflabels(, nolabel)           /// // Verwendet die Namen aus e(b) (T-3, T-2 etc.) als Zeilennamen
                       addnotes("Standardfehler in Klammern." /// // Eigene Notizen unter der Tabelle
                                "Schätzung basiert auf csdid mit Wild Bootstrap SE (`csdid_options')." ///
                                "Referenzperiode ist das letzte Jahr vor der Behandlung (T-1).")
        if _rc == 0 {
            display "Event study table saved as event_study_`depvar'.tex"
        } else {
            display as_error "Konnte Event study table nicht als LaTeX speichern für `depvar'. Ist 'estout' installiert?"
        }


        * 5. Event Study Plot erstellen und speichern
        * Erstellt den Plot
        csdid_plot, vertical ///
                   title("Dynamische Effekte: `depvar'") ///
                   xtitle("Jahre relativ zur Steuererhöhung (Jahr 0 = 2017)") ///
                   name("plot_`depvar'", replace) // Gibt dem Graphen einen Namen im Speicher

        * Speichert den zuletzt erstellten Graphen als PNG-Datei
        graph export "event_plot_`depvar'.png", replace // Kann auch .pdf, .eps etc. sein
        display "Event study plot saved as event_plot_`depvar'.png"

    }
    else {
        // Fehlermeldung, wenn csdid für diese Variable nicht erfolgreich war
        display as_error "csdid konnte für Variable `depvar' nicht erfolgreich ausgeführt werden. Fehlercode: " _rc
        display as_error "Überspringe Speichern von Tabellen und Plot für `depvar'."
    }

    * Kurze Pause (optional, kann bei vielen Variablen helfen, den Überblick zu behalten)
    sleep 500

} // Ende der Schleife

display as_header "Alle abhängigen Variablen verarbeitet."

/*==============================================================================
 Hinweise für LaTeX:
 1.  esttab erstellt ein table fragment. Sie müssen dieses in Ihrer .tex-Datei
     mit \input{event_study_... .tex} in eine table-Umgebung einbinden.
 2.  Für die Option 'booktabs' benötigen Sie in Ihrer LaTeX-Präambel:
     \usepackage{booktabs}
 3.  Passen Sie das Zahlenformat (z.B. b(%9.3f)) und die Notizen an Ihre
     Bedürfnisse an.
 4.  Das LaTeX-Label wird automatisch generiert (z.B. \label{tab:event_ln_stpfgew}),
     sodass Sie im Text mit \ref{tab:event_ln_stpfgew} darauf verweisen können.
==============================================================================*/






*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block 2 :  Stacked DiD using NeumayerKrolageetal. 2019
*	----
*	-------------------------------------------------------------------------------------------------------------------






 
 // More documentation
 
 
 * UPDATE ERROR  in04_did_2xT_continuous
 


Die Fehlermeldung `coefficient c.dosetreat2016#*.jahr not found` im Zusammenhang mit dem `esttab`-Befehl deutet stark darauf hin, dass `esttab` nicht alle Koeffizienten finden kann, die durch dein `keep_pattern` `local keep_pattern "c.\`current_treat_group_var\`#*.jahr _cons"` spezifiziert werden, und zwar über *alle* Schätzungen hinweg, die in `\`estimates_list_cohort\`` gesammelt wurden.

Hier sind die wahrscheinlichsten Ursachen und Lösungsansätze:

1.  **Problem mit dem Wildcard `*` in `keep()` bei `esttab`:**
    * **Ursache:** Der Befehl `reghdfe \`depvar\` c.\`current_treat_group_var\`##ib\`base_year\`.jahr, ...` schätzt Interaktionsterme zwischen deiner kontinuierlichen Treatment-Variable (`c.\`current_treat_group_var\``) und den Jahresdummies (`jahr`). Dabei wird das `base_year` als Referenzkategorie ausgelassen (`ib\`base_year\``). Das bedeutet, Koeffizienten wie `c.dosetreat2016#2017.jahr`, `c.dosetreat2016#2018.jahr` etc. werden geschätzt, aber *nicht* `c.dosetreat2016#\`base_year\`.jahr`.
    * Dein `keep_pattern` `"c.\`current_treat_group_var\`#*.jahr _cons"` verwendet einen Wildcard (`*`), um *alle* Interaktionsterme mit `jahr` (plus die Konstante) auszuwählen. `esttab` versucht nun, diesen Pattern auf *alle* in `\`estimates_list_cohort\`` gespeicherten Modelle anzuwenden.
    * **Das Kernproblem:** Wenn auch nur *eines* der gespeicherten Modelle (z.B. die Regression für eine bestimmte abhängige Variable `depvar`) aus irgendeinem Grund (z.B. Kollinearität, zu wenige Beobachtungen für eine bestimmte Jahr-Kombination in *dieser spezifischen Regression*) *einen* der Interaktionsterme, die der Wildcard `*.jahr` entsprechen *könnte*, *nicht* enthält, dann schlägt `esttab` fehl. `esttab` erwartet beim Auflösen des Wildcards `*`, dass die resultierenden Koeffizientennamen (`c.dosetreat2016#2017.jahr`, `c.dosetreat2016#2018.jahr`, ...) in *jedem* der zu tabellierenden Modelle vorhanden sind. Der Fehler `coefficient ... not found` tritt auf, sobald ein erwarteter Koeffizient in mindestens einem Modell fehlt. Dein Plot-Code funktioniert, weil er die Koeffizienten direkt nach *jeder einzelnen* Regression aus dem *aktuellen* `e(b)`-Matrix extrahiert und nicht versucht, einen konsistenten Satz über *mehrere* gespeicherte Schätzungen hinweg zu finden.

2.  **Mögliche Variation in den geschätzten Koeffizienten:**
    * **Ursache:** Es ist möglich, dass für unterschiedliche abhängige Variablen (`depvar`) leicht unterschiedliche Sätze von Interaktionstermen signifikant geschätzt werden oder aufgrund von Datenproblemen (z.B. fehlende Werte in `depvar`) bestimmte Jahr-Interaktionen wegfallen. Der Wildcard `*` in `keep()` kann damit nicht umgehen, wenn die Menge der tatsächlich vorhandenen `jahr`-Interaktionen über die Modelle in `\`estimates_list_cohort\`` variiert.

**Lösungsvorschläge:**

1.  **Ersetze den Wildcard durch eine explizite Liste der Koeffizienten:**
    * Dies ist der robusteste Ansatz. Generiere die Liste der zu behaltenden Koeffizienten explizit basierend auf den Jahren in deinem Datensatz, *außer* dem Basisjahr.

    * Füge diesen Code *innerhalb* der `foreach cohort`-Schleife, aber *vor* dem `if "\`estimates_list_cohort\`" != ""` Block ein:

    ```stata
    * // Generiere die Liste der erwarteten Interaktionsterme explizit
    local keep_terms ""
    qui summarize jahr
    local min_year = r(min)
    local max_year = r(max)
    forvalues y = `min_year'(1)`max_year' {
        if `y' != `base_year' {
            // Füge den Koeffizientennamen für dieses Jahr zur Liste hinzu
            local keep_terms "`keep_terms' c.`current_treat_group_var'#`y'.jahr"
        }
    }
    // Füge die Konstante hinzu
    local keep_pattern "`keep_terms' _cons"
    di "DEBUG: Keep pattern set to: `keep_pattern'" // Optional: Zum Debuggen anzeigen
    ```

    * Verwende dann dieses explizit definierte `local keep_pattern` in deinen `esttab`-Befehlen (so wie du es bereits tust, aber jetzt ohne Wildcard).

2.  **Überprüfe die einzelnen Schätzungen:**
    * Um sicherzugehen, dass die Koeffizienten tatsächlich so heißen, wie du denkst, und um zu sehen, ob sie in allen Modellen vorhanden sind, kannst du nach dem `estimates store` Befehl temporär eine Überprüfung einbauen:
        ```stata
        estimates store `est_name'
        di "--- Coefficients stored for `est_name' ---"
        estimates describe `est_name', varlist // Zeigt die Namen der Koeffizienten an
        matrix list e(b) // Zeigt die Koeffizienten und ihre Namen
        local estimates_list_cohort "`estimates_list_cohort' `est_name'"
        ```
    * Schau dir die Ausgabe genau an. Heißen die Interaktionsterme wirklich `c.dosetreat2016#2017.jahr` usw.? Fehlen vielleicht für bestimmte `depvar`-Regressionen einzelne Jahresinteraktionen?

3.  **Stelle sicher, dass `current_treat_group_var` korrekt ist:**
    * Überprüfe, ob die Variable `dosetreat2016` (oder die entsprechende Variable für andere Kohorten) korrekt generiert wurde und im Datensatz existiert, wenn die Regressionen laufen. Dein Code enthält zwar Sicherheitsabfragen dafür (`capture confirm variable`), aber doppelte Kontrolle schadet nicht.

**Zusammenfassend:** Das wahrscheinlichste Problem ist, dass der Wildcard `*` im `keep()`-Pattern von `esttab` fehlschlägt, weil nicht alle durch den Wildcard implizierten Koeffizienten in *jeder einzelnen* der gespeicherten Schätzungen (`\`estimates_list_cohort\``) vorhanden sind. Die beste Lösung ist, den Wildcard durch eine explizit generierte Liste der erwarteten Koeffizientennamen (ohne das Basisjahr) zu ersetzen.


 * ####################################
 * ####################################
 * ####################################
 *####################################
 *TIPP WO Code genau EINZUFÜGEN IST:
 *####################################
 * ####################################
 * ####################################
 * ####################################
 
 Absolut! Hier ist dein Code mit Markierungen, wo du den neuen Code einfügen und was du ändern musst.

**Dein ursprünglicher Code-Ausschnitt (vereinfacht):**

```stata
// ... (Beginn der foreach cohort Schleife) ...

    local estimates_list_cohort ""  // Platzhalter für die Liste der Schätzungen (für Tabelle)

    * Innere Schleife über abh Variablen, Schätzungen durchführen und speichern
    foreach depvar of local dependent_vars {
        di as text "  Processing DV: `depvar' for Cohort: `cohort'"

        capture reghdfe `depvar' c.`current_treat_group_var'##ib`base_year'.jahr, a(ags jahr) vce(cluster ags) // !***** MODELDEFINITION *****!

        if _rc == 0 { // falls Schätzung erfolgreich
            local est_name "`depvar'_`cohort'"
            estimates store `est_name'
            local estimates_list_cohort "`estimates_list_cohort' `est_name'"

            //--------------------------------------------------
            //--- Event Study Plot erstellen und speichern ---
            //--- (Dein Plot-Code hier) ---
            //--------------------------------------------------

        }
        else {
            di as error "ERROR: Failed estimate DynDiD `cohort' model for DV: `depvar'. Skipping."
        }
    } // Ende innere Schleife über abh. Variablen


    //=======================================================================
    // HIER den NEUEN Codeblock zur Generierung von keep_pattern einfügen
    //=======================================================================


    /* <-- Entferne dieses Kommentarzeichen, um den Block zu aktivieren
    * // Regressionstabelle für diese Kohorte erstellen
    if "`estimates_list_cohort'" != "" {
        di "--- Creating Event Study Table for Cohort `cohort' ---"
        local table_filename "$outputpfad\DynDiD_CONT_Treat`cohort'" // Dateiname für die Tabelle angepasst
        // Titel und Notizen für die Tabelle
        local table_title "Dynamic DiD Coefficients (ContinuousTreatment, Cohort: `cohort', Base=`base_year')"
        local tex_title "`table_title' \\label{tab:dyndid_`cohort'}"
        local table_notes "Notes: Shows c.taxchange_fu*Year interaction (continuous) coefficients relative to base year `base_year'. FE: AGS, Year. Clustered SEs (AGS). Treat group '`treat_pattern'', Control 'n000000'."
        local tex_notes "\\textit{Notes:} Shows taxchange\\_fu \(\\times\) Year interaction coefficients relative to base year `base_year', representing effect per unit of treatment intensity. FE: AGS, Year. Clustered SEs (AGS) in parentheses. Significance: \\sym{*} \\(p<0.10\\), \\sym{**} \\(p<0.05\\), \\sym{***} \\(p<0.01\\)."

        // Pattern, um nur die Interaktionsterme (und  Konstante) in der Tabelle zu zeigen
        // ******************************************************************
        // * ALTE ZEILE (auskommentieren oder löschen):
        // local keep_pattern "c.`current_treat_group_var'#*.jahr _cons"    // FEHLER !!! coefficient c.dosetreat2016#*.jahr not found
        // ******************************************************************

        * TXT Tabelle
        esttab `estimates_list_cohort' using "`table_filename'.txt", ///
            replace wide plain b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) ///
            keep(`keep_pattern') order(_cons) nonumbers /// Nun wird das NEUE keep_pattern verwendet
            title("`table_title'") stats(N, fmt(%9.0gc) labels("Observations")) ///
            addnotes("`table_notes'")

        * TEX Tabelle
        esttab `estimates_list_cohort' using "`table_filename'.tex", ///
            replace booktabs b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) ///
            keep(`keep_pattern') order(_cons) nonumbers mtitle("") /// Nun wird das NEUE keep_pattern verwendet
            title("`tex_title'") stats(N, fmt(%9.0gc) labels("Observations")) ///
            addnotes("`tex_notes'")

        di "-> Tables saved as `table_filename'.txt and .tex"
    }
    else {
    di as error "--- No successful estimates found for Cohort `cohort' to create tables ---"
    }

    */ // <-- Entferne dieses Kommentarzeichen, um den Block zu aktivieren


    estimates drop `estimates_list_cohort'

} // Ende der foreach cohort Schleife

di _newline as result "*** Dynamic DiD Analysis Completed ***" _newline
```

**1. Neuer Codeblock zum Einfügen:**

Füge diesen Block genau an der Stelle ein, die mit `// HIER den NEUEN Codeblock...` markiert ist:

```stata
    * // Generiere die Liste der erwarteten Interaktionsterme explizit
    local keep_terms ""
    qui summarize jahr
    local min_year = r(min)
    local max_year = r(max)
    forvalues y = `min_year'(1)`max_year' {
        if `y' != `base_year' {
            // Füge den Koeffizientennamen für dieses Jahr zur Liste hinzu
            local keep_terms "`keep_terms' c.`current_treat_group_var'#`y'.jahr"
        }
    }
    // Füge die Konstante hinzu
    local keep_pattern "`keep_terms' _cons"
    // Optional: Zum Debuggen anzeigen lassen, ob der Pattern korrekt aussieht
    // di "DEBUG für Kohorte `cohort': Keep pattern set to: `keep_pattern'"
```

**2. Änderung im alten Code:**

Innerhalb des `if "\`estimates_list_cohort\`" != ""` Blocks (den du wahrscheinlich durch Entfernen von `/*` und `*/` wieder aktivieren möchtest), musst du die Zeile finden, die dein altes `keep_pattern` definiert hat, und sie entweder löschen oder auskommentieren:

**Ändere dies:**

```stata
        // Pattern, um nur die Interaktionsterme (und  Konstante) in der Tabelle zu zeigen
        local keep_pattern "c.`current_treat_group_var'#*.jahr _cons"    // FEHLER !!! coefficient c.dosetreat2016#*.jahr not found
```

**Zu diesem (auskommentiert):**

```stata
        // Pattern, um nur die Interaktionsterme (und  Konstante) in der Tabelle zu zeigen
        // local keep_pattern "c.`current_treat_group_var'#*.jahr _cons"    // FEHLER !!! Wird jetzt oben explizit generiert
```

**Oder lösche die Zeile einfach.**

**Zusammenfassend:**

1.  Füge den neuen Codeblock *nach* der inneren `foreach depvar`-Schleife und *vor* dem `if "\`estimates_list_cohort\`" != ""` Block ein.
2.  Kommentiere die alte Zeile `local keep_pattern ...` *innerhalb* des `if`-Blocks aus oder lösche sie.
3.  Entferne die `/*` und `*/` um den gesamten `esttab`-Block, um ihn wieder zu aktivieren.

Jetzt wird `esttab` mit einer expliziten Liste von Koeffizientennamen aufgerufen, die auf den tatsächlichen Jahren (ohne Basisjahr) basiert, was den Fehler beheben sollte.
 
 


 * ####################################
 * ####################################
 * ####################################
 *####################################
 *Codes für number of units in each cohort:
 *####################################
 * ####################################
 * ####################################
 * ####################################

Alles klar, hier ist ein Stata-Code, der dir die Anzahl der eindeutigen Firmen (`id`) pro Kohorte (2016, 2017, 2018 Treatment und Never Treated) ausgibt, sowohl insgesamt als auch für jede deiner abhängigen Variablen einzeln.

**Annahmen:**

1.  Deine Firmen-Identifikationsvariable heißt `id`.
2.  Du hast bereits eine Variable erstellt, die die Kohorte für jede Firma eindeutig identifiziert. Nennen wir sie hier `cohort_group`. (Falls nicht, siehe Kommentar im Code, wie du sie erstellen könntest, z.B. basierend auf `pattern_tax`).

**Der Code:**

```stata
*-------------------------------------------------------------------------------
* Zähle eindeutige Firmen (IDs) pro Kohorte
*-------------------------------------------------------------------------------

clear // Vorsicht: Löscht aktuelle Daten, wenn nötig. Lade deine Daten vorher.
* use "dein_datensatz.dta", clear // Lade hier deine Daten

// --- Vorbereitung ---

// Annahme: Deine Firmen-ID-Variable heißt 'id'
// Annahme: Du hast eine Variable 'cohort_group', die die Kohorte definiert.
//          z.B.: 0 = Never Treated, 2016 = Treat 2016, usw.

/* // Falls du 'cohort_group' noch nicht hast, erstelle sie hier, z.B. so:
capture drop cohort_group
gen cohort_group = .
replace cohort_group = 0 if pattern_tax == "n000000" // Beispiel: Never Treated
replace cohort_group = 2016 if pattern_tax == "n001000" // Beispiel: Treat 2016
replace cohort_group = 2017 if pattern_tax == "n000100" // Beispiel: Treat 2017
replace cohort_group = 2018 if pattern_tax == "n000010" // Beispiel: Treat 2018
label define cohort_lbl 0 "Never Treated" 2016 "Treat 2016" 2017 "Treat 2017" 2018 "Treat 2018"
label values cohort_group cohort_lbl
*/

// Stelle sicher, dass die Kohortenvariable existiert
capture confirm variable cohort_group
if _rc != 0 {
    di as error "Variable 'cohort_group' nicht gefunden. Bitte erstellen oder Namen anpassen."
    exit // Beendet das Skript, wenn die Variable fehlt
}

// Liste deiner abhängigen Variablen (aus deinem vorherigen Code)
local dependent_vars "e_persausg stpfgew ln_e_persausg sigln_e_persausg rel_e_persausg rel_stpfgew ln_fobi g_reings_tru sigln_g_reing ln_inv ln_son ln_afa_bwg ln_afa_ubwg ln_steube sigln_p_einge"

// --- 1. Gesamtanzahl eindeutiger Firmen pro Kohorte (im gesamten Datensatz) ---
di _newline as result "-------------------------------------------------------------"
di as result "Gesamtanzahl eindeutiger Firmen (IDs) pro Kohorte"
di as result "-------------------------------------------------------------"

// Markiere die erste Beobachtung für jede Firma (ID)
bysort id: gen byte _is_first_id_obs = (_n == 1)

// Tabelliere die Kohorte nur für diese ersten Beobachtungen -> zählt jede Firma nur einmal
tabulate cohort_group if _is_first_id_obs

// Lösche die Hilfsvariable
drop _is_first_id_obs

// --- 2. Anzahl eindeutiger Firmen pro Kohorte FÜR JEDE ABHÄNGIGE VARIABLE ---
di _newline as result "-------------------------------------------------------------------------"
di as result "Anzahl eindeutiger Firmen (IDs) pro Kohorte je abhängiger Variable"
di as result "(Nur Firmen mit nicht-fehlenden Werten für die jeweilige Variable)"
di as result "-------------------------------------------------------------------------"

foreach depvar of local dependent_vars {
    di _newline as text "--- Abhängige Variable: `depvar' ---"
    
    preserve // Sichert den aktuellen Datenzustand im Speicher

    // 1. Behalte nur Beobachtungen, bei denen die aktuelle abhängige Variable NICHT fehlt
    keep if !missing(`depvar')
    
    // 2. Behalte nur eine Beobachtung pro Firma (ID), um Firmen zu zählen
    //    (innerhalb der Gruppe von Beobachtungen mit gültiger abhängiger Variable)
    bysort id: keep if _n == 1

    // 3. Zähle die verbleibenden Firmen pro Kohorte
    di as text "Anzahl Firmen mit nicht-fehlendem `depvar':"
    tabulate cohort_group, missing // 'missing' zeigt an, falls es IDs ohne Kohortenzuordnung gibt

    restore // Stellt den ursprünglichen Datenzustand wieder her
}

di _newline as result "--- Zählung abgeschlossen ---"

// Optional: Räume lokale Makros auf
// local drop dependent_vars

```

**Erklärung:**

1.  **Vorbereitung:**
    * Stellt sicher, dass eine Variable `cohort_group` existiert (oder gibt eine Fehlermeldung aus). Du musst diese Variable möglicherweise zuerst erstellen, wie im auskommentierten Beispiel gezeigt (passe die Logik an deine tatsächlichen Treatment-Variablen an).
    * Definiert die Liste deiner abhängigen Variablen in einem Local Macro `dependent_vars`.

2.  **Gesamtanzahl:**
    * `bysort id: gen byte _is_first_id_obs = (_n == 1)`: Erstellt eine Hilfsvariable, die nur für die allererste Zeile jeder Firma (`id`) den Wert 1 hat.
    * `tabulate cohort_group if _is_first_id_obs`: Zählt, wie oft jede Kohorte (`cohort_group`) bei diesen "ersten Zeilen" vorkommt. Das entspricht der Anzahl eindeutiger Firmen pro Kohorte im gesamten Datensatz.

3.  **Anzahl pro abhängiger Variable:**
    * `foreach depvar of local dependent_vars { ... }`: Startet eine Schleife, die jeden Variablennamen in deiner Liste durchgeht.
    * `preserve`: Sichert den aktuellen Zustand der Daten. Alle Änderungen innerhalb von `preserve` und `restore` sind temporär.
    * `keep if !missing(\`depvar\`)`: Entfernt alle Zeilen, in denen die *aktuelle* abhängige Variable (`depvar`) einen fehlenden Wert hat.
    * `bysort id: keep if _n == 1`: Behält von den verbleibenden Zeilen wieder nur die erste Zeile pro Firma (`id`). Jetzt haben wir pro Firma maximal eine Zeile, und nur von den Firmen, die für die aktuelle `depvar` mindestens einen gültigen Wert haben.
    * `tabulate cohort_group, missing`: Zählt die verbleibenden Firmen pro Kohorte. Die Option `missing` würde auch Firmen auflisten, die nach dem Filtern keine Kohortenzuordnung mehr hätten (sollte nicht passieren, wenn `cohort_group` vollständig ist).
    * `restore`: Lädt den ursprünglichen Datensatz wiederher, bevor die Schleife mit der nächsten abhängigen Variable beginnt.

Dieser Code gibt dir eine klare Übersicht über die Verteilung deiner Firmen auf die Kohorten, sowohl insgesamt als auch für die spezifische Stichprobe, die für die Analyse jeder einzelnen abhängigen Variable relevant ist.



 * ####################################
 * ####################################
 * ####################################
 *####################################
 *Codes für evolution of average outomes across cohorts
 *####################################
 * ####################################
 * ####################################
 * ####################################



Okay, hier ist ein Stata-Code, der für jede deiner abhängigen Variablen einen Plot erstellt. Jeder Plot zeigt den durchschnittlichen Wert der Variable über die Jahre (`jahr`) getrennt für jede deiner vier Kohorten (Never Treated, Treat 2016, Treat 2017, Treat 2018).

**Annahmen:**

1.  Deine Daten sind geladen.
2.  Du hast eine Variable für das Jahr, die `jahr` heißt.
3.  Du hast die Firmen-ID `id`.
4.  Du hast die Kohortenvariable `cohort_group` (numerisch: 0 für Never Treated, 2016, 2017, 2018 für die Treatment-Kohorten) und diese Variable hat passende Labels (siehe Code vom vorherigen Schritt).

**Der Code:**

```stata
*-------------------------------------------------------------------------------
* Plotte Durchschnitt der Outcomes über Zeit pro Kohorte
*-------------------------------------------------------------------------------

// --- Vorbereitung ---

// Annahme: Daten sind geladen.
// Annahme: Variablen 'jahr' und 'cohort_group' (mit Labels) existieren.

// Liste deiner abhängigen Variablen
local dependent_vars "e_persausg stpfgew ln_e_persausg sigln_e_persausg rel_e_persausg rel_stpfgew ln_fobi g_reings_tru sigln_g_reing ln_inv ln_son ln_afa_bwg ln_afa_ubwg ln_steube sigln_p_einge"

// Optional: Pfad zum Speichern der Grafiken definieren
// global outputpfad "C:\dein\pfad\fuer\grafiken" // Passe den Pfad an

// --- Plotting-Schleife ---
di _newline as result "--- Erstelle Plots der durchschnittlichen Outcomes über Zeit pro Kohorte ---"

foreach depvar of local dependent_vars {
    di as text "Erstelle Plot für: `depvar'"

    preserve // Sichert den aktuellen Datenzustand im Speicher

    // 1. Berechne den Durchschnitt der abhängigen Variable pro Kohorte und Jahr
    //    Dies erstellt temporär einen neuen, kleinen Datensatz nur mit den Durchschnitten.
    //    Fehlende Werte in `depvar` werden bei der Mittelwertbildung ignoriert.
    collapse (mean) mean_`depvar'`=`depvar', by(cohort_group jahr)

    // 2. Erstelle den Linien-Plot
    //    Wir zeichnen für jede Kohorte eine eigene Linie in den gleichen Graphen.
    twoway (line mean_`depvar' jahr if cohort_group == 0, sort connect(L) lcolor(blue)) ///      // Linie für Never Treated (Kohorte 0)
           (line mean_`depvar' jahr if cohort_group == 2016, sort connect(L) lcolor(red)) ///       // Linie für Treat 2016
           (line mean_`depvar' jahr if cohort_group == 2017, sort connect(L) lcolor(green)) ///     // Linie für Treat 2017
           (line mean_`depvar' jahr if cohort_group == 2018, sort connect(L) lcolor(orange)), ///   // Linie für Treat 2018
           title("Mean of `depvar' over Time by Cohort", size(medium)) /// // Titel des Graphen
           ytitle("Average `depvar'") /// // Titel der Y-Achse
           xtitle("Year") /// // Titel der X-Achse
           legend(order(1 "Never Treated" 2 "Treat 2016" 3 "Treat 2017" 4 "Treat 2018") rows(1) size(small)) /// // Legende anpassen
           graphregion(color(white)) // Optional: Weißer Hintergrund für bessere Lesbarkeit

    // 3. Optional: Grafik speichern (z.B. als PNG)
    // graph export "${outputpfad}/Mean_`depvar'_by_Cohort.png", replace width(1000)
    // di as text " -> Plot gespeichert als Mean_`depvar'_by_Cohort.png"

    restore // Stellt den ursprünglichen, vollständigen Datenstand wieder her
}

di _newline as result "--- Plot-Erstellung abgeschlossen ---"

// Optional: Räume lokale Makros auf
// local drop dependent_vars
```

**Erklärung:**

1.  **Vorbereitung:** Lädt die Liste der abhängigen Variablen und definiert optional einen Speicherpfad für die Grafiken.
2.  **Schleife:** Geht jede abhängige Variable (`depvar`) in der Liste durch.
3.  **`preserve`:** Sichert den aktuellen Datensatz, damit die Änderungen durch `collapse` nur temporär sind.
4.  **`collapse`:** Berechnet den Durchschnitt (`mean`) der aktuellen `depvar` für jede Kombination aus `cohort_group` und `jahr`. Das Ergebnis ist ein neuer Datensatz mit nur drei Variablen: `cohort_group`, `jahr` und `mean_\`depvar\`` (wobei `\`depvar\`` der Name der jeweiligen abhängigen Variable ist).
5.  **`twoway`:** Erstellt den Plot:
    * Es werden vier `line`-Befehle innerhalb von `twoway (...)` kombiniert, einer für jede Kohorte (`if cohort_group == ...`).
    * `sort` stellt sicher, dass die Punkte korrekt nach Jahr verbunden werden.
    * `connect(L)` verbindet die Punkte mit Linien.
    * `lcolor(...)` weist jeder Kohorte eine eigene Farbe zu.
    * `title()`, `ytitle()`, `xtitle()` definieren die Beschriftungen des Graphen.
    * `legend(...)` erstellt eine Legende. `order(...)` legt die Reihenfolge und die Beschriftung der Einträge fest (wichtig, damit die Farben den richtigen Kohorten zugeordnet werden). `rows(1)` sorgt dafür, dass die Legende horizontal angeordnet wird.
    * `graphregion(color(white))` setzt einen weißen Hintergrund.
6.  **`graph export` (auskommentiert):** Wenn du die Zeile aktivierst (Kommentarzeichen `//` entfernst) und `$outputpfad` definiert hast, wird der erstellte Graph als PNG-Datei gespeichert.
7.  **`restore`:** Lädt den ursprünglichen Datensatz wieder, bevor die Schleife mit der nächsten abhängigen Variable weitergeht.

Dieser Code sollte dir für jede deiner Outcome-Variablen eine übersichtliche Grafik liefern, die die Trends der Durchschnittswerte über die Zeit für alle deine Kohorten vergleicht.










