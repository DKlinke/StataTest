*-------------------------------------------------------------------------------------------------------------------
*   Project Title: THE DETERMINANTS OF TAX COMPLIANCE
*	Code: Analyze full_gwap.dta
/* 
 04_DiD_2xT_stacked.do schätzt dynamisches stacked DiD. Aggregiert also die Effekte über die einzelnen Treatment gruppen. Treatmentgruppe sind jetzt also "n001000" "n000100" und "n000010" Fälle. Kontrollgruppe bleibt unverändert "n000000"
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
 
 
 
 
 
 
 
 
 
 






















