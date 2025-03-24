*ssc install causaldata
causaldata organ_donations.dta, use clear download

* Create treatment variable  (nur für California und nach Q32011)
g Treated = state == "California" & ///   
  inlist(quarter, "Q32011","Q42011","Q12012") // Sechs Qs total!

* We will use reghdfe which must be installed with
* ssc install reghdfe

// rate_it = β₀ + β₁ * Treated_it + α_i + γ_t + ε_it  wobei α_i fixed effect für state und γ_t fixed effekt für Quartal ist!


// diese beiden Anwendungen liefern exakt selbes Ergebnis

reghdfe rate Treated, a(state quarter) vce(cluster state) // Standardfehler auf ebene des States clustern, hinzufügen von covariates bedingt sinnvoll, controls die über gruppe variieren aber nicht über die Zeit sind unnötig da bereits gruppenfixed effects inkludiert sind. Aber wenn etwas über zeit variiert und wir überzeugt sind, dassparallel trends nur bedingt auf bestimmte Variblen hält, dann go for it. Es ist aber immer die kritische Frage ob die covariates die treated uund untreated gleichermaßen beeinflusst und ob das treatment spätere Werte der Covariates nicht beeinflusst! Zeige Ergebnisse mit und ohne Covariats falls covariates inkludiert werden!

encode state, gen(state_numeric)
encode quarter, gen(quarter_numeric)
xtset state_numeric quarter_numeric
xtreg rate Treated i.state_numeric i.quarter_numeric, fe robust cluster(state_numeric) // Referenzkategoriewahl ist hier egal!
xtset, clear

/*

. reghdfe rate Treated, a(state quarter) vce(cluster state)
(MWFE estimator converged in 2 iterations)

HDFE Linear regression                            Number of obs   =        162
Absorbing 2 HDFE groups                           F(   1,     26) =      13.42
Statistics robust to heteroskedasticity           Prob > F        =     0.0011
                                                  R-squared       =     0.9793
                                                  Adj R-squared   =     0.9742
                                                  Within R-sq.    =     0.0092
Number of clusters (state)   =         27         Root MSE        =     0.0246

                                 (Std. Err. adjusted for 27 clusters in state)
------------------------------------------------------------------------------
             |               Robust
        rate |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
     Treated |   -.022459   .0061312    -3.66   0.001    -.0350619   -.0098561
       _cons |   .4454641   .0001135  3923.36   0.000     .4452307    .4456974
------------------------------------------------------------------------------

Absorbed degrees of freedom:
-----------------------------------------------------+
 Absorbed FE | Categories  - Redundant  = Num. Coefs |
-------------+---------------------------------------|
       state |        27          27           0    *|
     quarter |         6           1           5     |
-----------------------------------------------------+
* = FE nested within cluster; treated as redundant for DoF computation

Erläuterung der einzelnen Abschnitte:

    (MWFE estimator converged in 2 iterations):
        MWFE steht für "Method of Within-Group Fixed Effects". Dies ist der Algorithmus, den reghdfe verwendet, um die festen Effekte zu schätzen.
        "converged in 2 iterations" bedeutet, dass der Algorithmus nach zwei Iterationen eine Lösung gefunden hat. Dies ist ein Indikator für die Effizienz der Schätzung.

    HDFE Linear regression:
        Dies bestätigt, dass eine lineare Regression mit hochdimensionalen festen Effekten durchgeführt wurde.
        Number of obs = 162: Die Anzahl der Beobachtungen im Datensatz beträgt 162.

    Absorbing 2 HDFE groups:
        Dies gibt an, dass zwei Gruppen von festen Effekten "absorbiert" wurden: state und quarter.
        F(1, 26) = 13.42: Der F-Test für die Signifikanz des Modells. Die 1 steht für die Anzahl der unabhängigen Variablen (Treated) und die 26 für die Freiheitsgrade.
        Prob > F = 0.0011: Der p-Wert des F-Tests. Er ist sehr klein (0.0011), was bedeutet, dass das Modell statistisch signifikant ist.
        R-squared = 0.9793: Das Bestimmtheitsmaß des Modells. Es gibt an, dass 97.93% der Variation in der abhängigen Variablen rate durch das Modell erklärt werden.
        Adj R-squared = 0.9742: Das korrigierte R-Quadrat, das die Anzahl der Variablen im Modell berücksichtigt.
        Within R-sq. = 0.0092: Das R-Quadrat innerhalb der Gruppen (innerhalb der festen Effekte). Es gibt an, wie gut die Variation innerhalb der Gruppen durch das Modell erklärt wird. In diesem Fall ist es relativ niedrig, was darauf hindeutet, dass die festen Effekte einen großen Teil der erklärten Varianz ausmachen.
        Number of clusters (state) = 27: Die Anzahl der Cluster, auf denen die Standardfehler berechnet wurden (27 Bundesstaaten).
        Root MSE = 0.0246: Die Wurzel des mittleren quadratischen Fehlers, ein Maß für die Streuung der Fehlerterme.

    (Std. Err. adjusted for 27 clusters in state):
        Dies bestätigt, dass die Standardfehler auf Ebene des Bundesstaates geclustert wurden, um für mögliche Korrelationen innerhalb der Bundesstaaten zu korrigieren.

    Koeffizienten-Tabelle:
        rate: Die abhängige Variable.
        Treated: Die Behandlungsvariable.
            Coef. = -0.022459: Der geschätzte Effekt der Behandlung auf rate. Ein negativer Koeffizient bedeutet, dass die Behandlung einen negativen Effekt auf rate hat.
            Std. Err. = 0.0061312: Der Standardfehler des Koeffizienten.
            t = -3.66: Der t-Wert, der verwendet wird, um die statistische Signifikanz des Koeffizienten zu testen.
            P>|t| = 0.001: Der p-Wert des t-Tests. Er ist sehr klein (0.001), was bedeutet, dass der Koeffizient statistisch signifikant ist.
            [95% Conf. Interval] = [-0.0350619, -0.0098561]: Das 95%-Konfidenzintervall für den Koeffizienten.
        _cons: Die Konstante (Intercept).
            Da die festen Effekte absorbiert wurden, ist der Intercept hier eher von untergeordneter Bedeutung.

    Absorbed degrees of freedom:
        state:
            Categories = 27: Es gibt 27 Bundesstaaten.
            Redundant = 27: Alle 27 Bundesstaaten wurden als feste Effekte berücksichtigt.
            Num. Coefs = 0: Es wurden keine expliziten Koeffizienten für die Bundesstaaten angezeigt, da sie absorbiert wurden.
            * = FE nested within cluster; treated as redundant for DoF computation: Dies bedeutet, dass die festen Effekte für state innerhalb der Cluster (Bundesstaaten) verschachtelt sind und daher bei der Berechnung der Freiheitsgrade als redundant behandelt werden.
        quarter:
            Categories = 6: Es gibt 6 Quartale.
            Redundant = 1: Ein Quartal wird als Referenzkategorie behandelt.
            Num. Coefs = 5: Es werden Koeffizienten für 5 der 6 Quartale angezeigt (das Referenzquartal wird weggelassen).
-------------------------------------------------------------------------------------------------------------

. xtset state_numeric quarter_numeric
       panel variable:  state_numeric (strongly balanced)
        time variable:  quarter_num~c, 1 to 6
                delta:  1 unit

. xtreg rate Treated i.state_numeric i.quarter_numeric, fe robust cluster(state_numeric)
note: 2.state_numeric omitted because of collinearity
note: 3.state_numeric omitted because of collinearity
note: 4.state_numeric omitted because of collinearity
note: 5.state_numeric omitted because of collinearity
note: 6.state_numeric omitted because of collinearity
note: 7.state_numeric omitted because of collinearity
note: 8.state_numeric omitted because of collinearity
note: 9.state_numeric omitted because of collinearity
note: 10.state_numeric omitted because of collinearity
note: 11.state_numeric omitted because of collinearity
note: 12.state_numeric omitted because of collinearity
note: 13.state_numeric omitted because of collinearity
note: 14.state_numeric omitted because of collinearity
note: 15.state_numeric omitted because of collinearity
note: 16.state_numeric omitted because of collinearity
note: 17.state_numeric omitted because of collinearity
note: 18.state_numeric omitted because of collinearity
note: 19.state_numeric omitted because of collinearity
note: 20.state_numeric omitted because of collinearity
note: 21.state_numeric omitted because of collinearity
note: 22.state_numeric omitted because of collinearity
note: 23.state_numeric omitted because of collinearity
note: 24.state_numeric omitted because of collinearity
note: 25.state_numeric omitted because of collinearity
note: 26.state_numeric omitted because of collinearity
note: 27.state_numeric omitted because of collinearity

Fixed-effects (within) regression               Number of obs     =        162
Group variable: state_nume~c                    Number of groups  =         27

R-sq:                                           Obs per group:
     within  = 0.1013                                         min =          6
     between = 0.0534                                         avg =        6.0
     overall = 0.0120                                         max =          6

                                                F(5,26)           =          .
corr(u_i, Xb)  = 0.0601                         Prob > F          =          .

                                  (Std. Err. adjusted for 27 clusters in state_numeric)
---------------------------------------------------------------------------------------
                      |               Robust
                 rate |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
----------------------+----------------------------------------------------------------
              Treated |   -.022459   .0061312    -3.66   0.001    -.0350619   -.0098561
                      |
        state_numeric |
             Arizona  |          0  (omitted)
          California  |          0  (omitted)
            Colorado  |          0  (omitted)
         Connecticut  |          0  (omitted)
District of Columbia  |          0  (omitted)
             Florida  |          0  (omitted)
              Hawaii  |          0  (omitted)
           Louisiana  |          0  (omitted)
            Maryland  |          0  (omitted)
            Michigan  |          0  (omitted)
           Minnesota  |          0  (omitted)
            Missouri  |          0  (omitted)
             Montana  |          0  (omitted)
            Nebraska  |          0  (omitted)
       New Hampshire  |          0  (omitted)
          New Jersey  |          0  (omitted)
            New York  |          0  (omitted)
      North Carolina  |          0  (omitted)
                Ohio  |          0  (omitted)
        Pennsylvania  |          0  (omitted)
      South Carolina  |          0  (omitted)
           Tennessee  |          0  (omitted)
            Virginia  |          0  (omitted)
          Washington  |          0  (omitted)
           Wisconsin  |          0  (omitted)
             Wyoming  |          0  (omitted)
                      |
      quarter_numeric |
              Q12012  |   .0192392   .0110173     1.75   0.093    -.0034072    .0418857
              Q22011  |    .007263   .0021666     3.35   0.002     .0028095    .0117164
              Q32011  |   .0181614   .0060511     3.00   0.006     .0057232    .0305997
              Q42010  |   .0023963   .0052049     0.46   0.649    -.0083026    .0130952
              Q42011  |   .0140355   .0053191     2.64   0.014      .003102     .024969
                      |
                _cons |   .4352815   .0039474   110.27   0.000     .4271675    .4433955
----------------------+----------------------------------------------------------------
              sigma_u |  .15350408
              sigma_e |  .02463416
                  rho |  .97489313   (fraction of variance due to u_i)
---------------------------------------------------------------------------------------

. 


*/


// Parallel Trends assumption : if no treatment had in fact occurred, then the difference in outcomes between the treated and untreated groups would not have changed from before the treatment date to afterwards.that difference can’t change from before treatment to after treatment for any reason but treatment.

// prior test: look at prior trend and see if different, oder statistical test um zu sehen ob unterschiedlich und wie sehr unterschiedlich. Teste Y = alpha_g + beta1 * Time + beta2 * Time * Group + epsilon on pre treatment data, where alpha_g is a set of fixed effects for the group. Wenn β2 signifikant von null verschieden ist, bedeutet dies, dass die Trends zwischen den Gruppen vor der Behandlung unterschiedlich waren, was die Annahme paralleler Trends verletzt. Wenn nicht von null unterschiedlich, also keine signifikanz gibt das Indiz, dass die Trends wohl vorher nicht unterschiedlich sind also vermutlich parallel verlaufen bzw besser gesagt: nicht signifikant unterschiedlich verlaufen. 

// original (beides entspricht selbem, nur dass untere die einzelnen effekts zeigt für die Jahre)
reghdfe rate Treated, a(state quarter) vce(cluster state)
reghdfe rate i.quarter_numeric Treated, a(state) vce(cluster state)


// parallel trends test visuell getestet
*Option 1
*ssc install lgraph
preserve
	collapse (mean) rate, by(quarter_numeric Treated) 
	lgraph rate quarter_numeric, by(Treated) xline(3)
restore


*Option 2
preserve
	// Mittelwerte von rate für jede Gruppe und jedes Quartal berechnen
	egen rate_mean = mean(rate), by(quarter_numeric Treated)

	// Plot erstellen mit twoway line und scatter für beide Gruppen im selben Plot
	twoway ///
		(line rate_mean quarter_numeric if Treated == 0, sort) /// Linie für Control (in Legende)
		(line rate_mean quarter_numeric if Treated == 1, sort) /// Linie für Treatment (in Legende)
		(scatter rate_mean quarter_numeric if Treated == 0, msymbol(circle) mcolor(black)) /// Marker für Control (schwarz, keine Legende)
		(scatter rate_mean quarter_numeric if Treated == 1, msymbol(triangle) mcolor(black) ) , /// Marker für Treatment (schwarz, keine Legende)
		xline(3) ///
		legend(label(1 "Control Group") label(2 "Treatment Group") order(1 2)) /// Legende hinzufügen
		xtitle("Quarter") ytitle("(mean) rate") /// Achsen betiteln
		title("Parallel Trends Test") /// Graphen betiteln
	
restore


// parallel trends test statistisch getestet
preserve

	// Annahme: Behandlungszeitraum beginnt in quarter_numeric == 5 (ändere dies entsprechend!)
	keep if quarter_num < 3

	gen quarterXstate = quarter_numeric * state_numeric

	// reghdfe mit festen Effekten für state_numeric (Group), Zeittrend (quarter_numeric) und Interaktion
	reghdfe rate quarter_numeric quarterXstate, a(state_numeric) vce(robust)

restore


// placebo testen: Daten vor treatment nutzen, wähle eine zufällige pre treatment periode, oder mehrere und schauen wie wahres treatment sich verhält -> randomization inference, schätze selbes DiD Modell aber Treated sollte entsprechend 1 sein wenn in treated group und nach dem fake Treatment. Wenn man effekt findet obwohl keiner da, dann stimmt etwas mit dem Design nicht!
// Alternativ kann man es statt zeitperioden auch einfach so amchen dass die treated groups gedropped werden und dann eine andere gruppe als treated group gewählt wird (macht jetzt bei unserem bsp nicht so viel sinn)

preserve

	* Use only pre-treatment data
	keep if quarter_num <= 3

	* Create fake treatment variables
	g FakeTreat1 = state == "California" & inlist(quarter, "Q12011","Q22011")
	g FakeTreat2 = state == "California" & quarter == "Q22011"

	* Run the same model as before
	* But with our fake treatment
	reghdfe rate FakeTreat1, a(state quarter) vce(cluster state)
	reghdfe rate FakeTreat2, a(state quarter) vce(cluster state)

restore


// Dynamic DiD long term effects

preserve 
	causaldata organ_donations.dta, use clear download
	g California = state == "California"

	* Interact being in the treated group with Qtr, 
	* using ib3 to drop the third quarter (the last one before treatment)
	reghdfe rate California##ib3.quarter_num, ///  Interagiert die Variable California mit den Dummy-Variablen für jedes Quartal (quarter_num), wobei das dritte Quartal (ib3.quarter_num) als Referenzkategorie ausgelassen wird.
		a(state quarter_num) vce(cluster state)

	* There's a way to graph this in one line using coefplot
	* But it gets stubborn and tricky, so we'll just do it by hand
	* Pull out the coefficients and SEs
	g coef = .
	g se = .
	forvalues i = 1(1)6 {  // entsprechend anpassen zu 2013 bis 2019
		replace coef = _b[1.California#`i'.quarter_num] if quarter_num == `i'  // Ersetzt die fehlenden Werte in coef durch die geschätzten Koeffizienten für die Interaktion von California mit jedem Quartal.
		replace se = _se[1.California#`i'.quarter_num] if quarter_num == `i'
	}
	
	/*
	Aufschlüsselung:

    _b[...]:
        _b ist ein Systemparameter in Stata, der eine Liste der Koeffizienten enthält, die in der letzten Regression geschätzt wurden.
        Wenn du eine Regression (z. B. regress, reghdfe, xtreg, etc.) ausführst, speichert Stata die geschätzten Koeffizienten in _b.
        _b[...] ist die Syntax, um auf einen bestimmten Koeffizienten in dieser Liste zuzugreifen.

    1.California#\i'.quarter_num`:
        Dies ist der Name des Koeffizienten, auf den du zugreifen möchtest. Er gibt an, welcher spezifische Koeffizient aus der Regressionsausgabe abgerufen werden soll.
        Lassen wir diesen Namen aufgliedern:
            1.California: Dies bezieht sich auf die Interaktion der Variable California mit den Quartalen. 1. ist eine Standard Stata Nomenklatur die verwendet wird, wenn eine Dummy Variable Interagiert wird. Es bedeutet so viel wie „die Variable California“.
            #: Dies ist der Interaktionsoperator in Stata, der angibt, dass wir die Interaktion zwischen California und den Quartalen betrachten.
            \i': Dies ist eine lokale Makro-Variable die verwendet wird um Variablen innerhalb einer Schleife (loop) zu erstellen. Hier steht`i'für den aktuellen Wert der Laufvariableniin derforvalues-Schleife. Wenni1 ist, ist das Ergebnis1.California#1.quarter_num. Wenni2 ist, ist das Ergebnis1.California#2.quarter_num` usw. Das ist sehr wichtig. Die Schleife, gibt es ja nicht einfach so, sondern wir brauchen die Schleife, da für jedes Quartal eine eigener Interaktionseffekt geschätzt wurde. Entsprechend haben wir viele Koeffizienten.
            quarter_num: Dies ist der Name der Variable, die die Quartalsnummern enthält.
        Zusammengenommen repräsentiert 1.California#\i'.quarter_numden Koeffizienten für die Interaktion zwischenCaliforniaund dem aktuellen Quartali`.

Beispiel:

    Wenn i in der Schleife den Wert 1 hat, ist 1.California#\i'.quarter_numgleichbedeutend mit1.California#1.quarter_num. Dies entspricht dem geschätzten Effekt der Interaktion zwischenCalifornia` und dem ersten Quartal.
    Wenn i den Wert 4 hat, ist 1.California#\i'.quarter_numgleichbedeutend mit1.California#4.quarter_num, was dem geschätzten Effekt der Interaktion zwischenCalifornia` und dem vierten Quartal entspricht.

Zweck:

    Dieser Ausdruck wird verwendet, um die geschätzten Koeffizienten für die Interaktion zwischen California und jedem Quartal abzurufen und sie in der Variable coef zu speichern.
    Dadurch können wir die geschätzten Effekte im Zeitverlauf darstellen.

Zusammenfassend ruft _b[1.California#\i'.quarter_num]den spezifischen Koeffizienten aus den vorherigen Regressionsergebnissen ab, der die Interaktion zwischenCalifornia` und dem aktuellen Quartal darstellt. Und das für jedes Quartal innerhalb der Laufvariablen i (innerhalb der Schleife).
	
	_b[...] (Koeffizienten):

    Wie bereits erklärt, speichert _b die geschätzten Koeffizienten aus der letzten Regression.
    Wenn du eine Regression durchführst, berechnet Stata die Koeffizienten, die die Beziehung zwischen den unabhängigen und abhängigen Variablen am besten beschreiben.
    _b[...] ermöglicht dir, auf diese geschätzten Koeffizienten zuzugreifen.
    Im Ausdruck _b[1.California#\i'.quarter_num]rufst du den Koeffizienten für die Interaktion zwischenCaliforniaund dem aktuellen Quartali` ab.

2. _se[...] (Standardfehler):

    _se speichert die Standardfehler der geschätzten Koeffizienten aus der letzten Regression.
    Der Standardfehler misst die Genauigkeit, mit der der Koeffizient geschätzt wird.
    Ein kleiner Standardfehler bedeutet, dass der Koeffizient präziser geschätzt wurde, während ein großer Standardfehler auf größere Unsicherheit hinweist.
    _se[...] ermöglicht dir, auf diese Standardfehler zuzugreifen.
    Im Ausdruck _se[1.California#\i'.quarter_num]rufst du den Standardfehler des Koeffizienten für die Interaktion zwischenCaliforniaund dem aktuellen Quartali` ab.
	
	*/

	* Make confidence intervals
	g ci_top = coef+1.96*se
	g ci_bottom = coef - 1.96*se

	* Limit ourselves to one observation per quarter
	keep quarter_num coef se ci_*
	duplicates drop

	* Create connected scatterplot of coefficients
	* with CIs included with rcap 
	* and a line at 0 from function
	twoway (sc coef quarter_num, connect(line)) ///  Plottete geschätzte coeffizienten (also dependent variable) gegen zeit
	  (rcap ci_top ci_bottom quarter_num) ///
		(function y = 0, range(1 6)), xline(3, lpattern(dash) lcolor(black)) xtitle("Quarter") /// horizontale Linie und verticale Linie wird hinzugefügt
		caption("95% Confidence Intervals Shown") ///
		legend(off) // Legende ausblenden
restore



//was wenn multiple kontroll und mutliple treat gruppen?
// was wenn wir auf ags ebene clustern wollen aber in einer ags mehrere id Unternehmen sind? Probleme?