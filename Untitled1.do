// asinh transformation

preserve

* 1. Wende die asinh() Transformation an
generate asinh_epers = asinh(e_personalausg)
* Kurze Prüfung auf Missing Values, falls asinh() fehlschlägt (sollte nicht, aber sicher ist sicher)
* summarize asinh_epers e_personalausg

* 2. Schätze das dynamische DiD-Modell auf der transformierten Variable
* ib2016.jahr bedeutet, dass 2016 das Basisjahr ist.
* Das Modell schätzt den Effekt für jedes Jahr relativ zu 2016.
reghdfe asinh_epers treat##ib2016.jahr if !missing(asinh_epers) & jahr != 2013, ///
    a(ags jahr) vce(cluster ags)

* 3. Berechne eine Basis-Vorhersage für die Interpretation
* Wir brauchen einen repräsentativen Ausgangspunkt auf der asinh-Skala,
* auf den wir die geschätzten Effekte addieren können. Ein guter Kandidat
* ist der durchschnittliche vorhergesagte Wert für die *behandelte Gruppe*
* im *Basisjahr* (2016).

* Erstelle lineare Vorhersage (xb) nur für die Stichprobe, die in der Regression verwendet wurde
predict double linpred if e(sample), xb

* Berechne den Durchschnitt dieser Vorhersage für treat==1 im Jahr 2016
summarize linpred if treat == 1 & jahr == 2016 & e(sample)
scalar base_pred = r(mean) // Durchschnittliche asinh(y) Vorhersage für Treat im Basisjahr

* Überprüfen, ob base_pred berechnet wurde (sollte nicht missing sein)
if missing(base_pred) {
    di as error "Konnte keine Basis-Vorhersage für treat=1, jahr=2016 berechnen. Prüfen Sie die Daten."
    error 498
}

* 4. Extrahiere Koeffizienten und SEs, transformiere zurück und berechne CIs

* Erstelle leere Variablen für die Ergebnisse auf der Originalskala (absolute Änderung)
gen abs_effect = .
gen se_abs_effect = .
gen ci_abs_low = .
gen ci_abs_high = .

* Setze den Effekt für das Basisjahr explizit auf Null
replace abs_effect = 0 if jahr == 2016
replace se_abs_effect = 0 if jahr == 2016
replace ci_abs_low = 0 if jahr == 2016
replace ci_abs_high = 0 if jahr == 2016

* Loop durch die relevanten Jahre (außer Basisjahr 2016 und ausgeschlossenem 2013)
forvalues i = 2014(1)2019 {
    if `i' != 2016 { // Basisjahr überspringen
        * Hole Koeffizient und SE von der asinh-Skala
        scalar beta_i = _b[1.treat#`i'.jahr]
        scalar se_beta_i = _se[1.treat#`i'.jahr]

        * Überprüfen, ob Koeffizienten geholt wurden
        if missing(beta_i) | missing(se_beta_i) {
           di as warn "Fehlender Koeffizient oder SE für Jahr `i'. Überspringe."
           continue // Nächstes Jahr im Loop
        }

        * Berechne vorhergesagte asinh-Werte: kontrafaktisch vs. mit Effekt
        scalar asinh_cf = base_pred          // Vorhersage ohne den Jahreseffekt beta_i
        scalar asinh_with = base_pred + beta_i // Vorhersage mit Jahreseffekt beta_i

        * Transformiere zurück auf die Originalskala y mittels sinh()
        scalar y_cf = sinh(asinh_cf)
        scalar y_with = sinh(asinh_with)

        * Berechne den absoluten Effekt in Einheiten von e_personalausg
        scalar current_abs_effect = y_with - y_cf

        * Berechne SE für den absoluten Effekt mittels Delta-Methode
        * SE(f(beta)) approx = |f'(beta)| * SE(beta)
        * Hier ist f(beta) = sinh(base_pred + beta) - sinh(base_pred)
        * f'(beta) = cosh(base_pred + beta)
        scalar cosh_val = cosh(asinh_with) // = cosh(base_pred + beta_i)
        scalar current_se_abs_effect = abs(cosh_val * se_beta_i)

        * Berechne 95% Konfidenzintervall für den absoluten Effekt
        scalar current_ci_low = current_abs_effect - 1.96 * current_se_abs_effect
        scalar current_ci_high = current_abs_effect + 1.96 * current_se_abs_effect

        * Speichere die berechneten Werte für das Jahr i
        replace abs_effect = current_abs_effect if jahr == `i'
        replace se_abs_effect = current_se_abs_effect if jahr == `i'
        replace ci_abs_low = current_ci_low if jahr == `i'
        replace ci_abs_high = current_ci_high if jahr == `i'
    }
}

* 5. Bereite Daten für den Plot vor
* Behalte nur die Variablen, die für den Plot benötigt werden + Jahr
keep jahr abs_effect ci_abs_low ci_abs_high

* Stelle sicher, dass wir nur einen Wert pro Jahr haben
duplicates drop jahr, force

* Sortiere nach Jahr für den Plot
sort jahr

* 6. Plotte die Ergebnisse (absolute Effekte)
twoway (scatter abs_effect jahr, connect(line) mcolor(blue)) /// Plot der absoluten Effekte
       (rcap ci_abs_low ci_abs_high jahr, lcolor(blue)) /// Konfidenzintervalle
       (function y = 0, range(2014 2019) lcolor(black)), /// Nulllinie
       xline(2016, lpattern(dash) lcolor(gray)) /// Linie für Basisjahr (oder Behandlungsbeginn?)
       title("Dynamischer DiD-Effekt auf Personalausgaben (Absolute Änderung)") /// Titel anpassen
       ytitle("Absolute Änderung in e_personalausg") /// Y-Achsen-Titel
       xtitle("Jahr") /// X-Achsen-Titel
       legend(off)

restore





// Kontrolle für Covariates


Gerne, ich erkläre dir den Inhalt des Blogposts "Selection on observables, covariate-specific trends and conditional parallel trends with difference-in-differences: Pedro's Checklist, Step 4(d)" [source: 860-995] ausführlich und verständlich.

Kontext und Ziel des Blogposts

Dieser Artikel ist Teil einer Serie von Scott Cunningham, die sich mit "Pedro's Checklist" für Difference-in-Differences (DiD) beschäftigt [source: 870]. Konkret geht es um Schritt 4(d) der Checkliste, der sich mit der Selektion in die Behandlung basierend auf beobachtbaren Merkmalen (Observables) und der Conditional Parallel Trends (CPT) Annahme befasst [source: 860].

Der Autor reagiert auf die Beobachtung, dass viele Forscher, nachdem die Probleme von Two-Way Fixed Effects (TWFE) bei gestaffeltem Treatmentbeginn bekannt wurden, dachten, sie könnten TWFE sicher weiter verwenden, solange alle Einheiten gleichzeitig behandelt werden ("no differential timing"), insbesondere wenn sie Kovariaten hinzufügen [source: 868]. Dieser Blogpost will anhand einer Simulation zeigen, dass Standard-TWFE mit additiven Kovariaten auch ohne gestaffelten Beginn zu verzerrten Ergebnissen (Bias) führen kann, und zwar genau dann, wenn bestimmte, realistische Formen von Heterogenität vorliegen [source: 869].

Das Simulations-Setup: Ein realistischeres Szenario

Um dies zu demonstrieren, baut Cunningham ein künstliches Datenset (eine Simulation) mit folgenden Eigenschaften auf [source: 872]:

    Selektion basierend auf Beobachtbarem (Selection on Observables): Die Entscheidung, ob eine Einheit (z.B. eine Person) die Behandlung erhält (z.B. College besucht), hängt von ihren beobachtbaren Merkmalen X ab – im Beispiel von Alter (age) und Notendurchschnitt (gpa) [source: 873, 894]. Personen mit überdurchschnittlichem Alter oder GPA haben eine höhere Behandlungswahrscheinlichkeit [source: 896]. Wichtig ist, dass es für alle Kombinationen von Alter/GPA sowohl Behandelte als auch Unbehandelte gibt ("Overlap" ist gegeben, siehe Verteilung der Propensity Scores in der Abbildung im Post [source: 900]).
    Bedingte Parallele Trends (Conditional Parallel Trends, CPT): Die Parallel-Trends-Annahme gilt hier nicht im einfachen Sinne. Das heißt, die durchschnittliche Entwicklung des unbehandelten Outcomes Y(0) (z.B. Verdienst ohne College) wäre zwischen der Behandlungs- und Kontrollgruppe insgesamt nicht gleich gewesen, weil die Gruppen sich ja systematisch in Alter und GPA unterscheiden und diese Merkmale die Trends beeinflussen [source: 877, 882]. Aber: Die CPT-Annahme gilt per Konstruktion der Simulation. Das bedeutet: Personen mit demselben Alter und demselben GPA hätten sich ohne Behandlung parallel entwickelt, egal ob sie später behandelt wurden oder nicht [source: 877, 883, 892]. Die Trends in Y(0) sind also kovariaten-spezifisch (covariate-specific trends) [source: 907-909, 951, 955].
        Wichtige Abgrenzung: Cunningham betont, dass CPT hier nicht mit der Annahme der "Unkonfundiertheit" (keine Störvariablen) verwechselt werden darf [source: 888, 891]. DiD geht generell schon davon aus, dass zeitkonstante Störvariablen kein Problem sind. CPT adressiert hier spezifisch unterschiedliche Trends, die durch beobachtbare Merkmale X erklärt werden können [source: 892].
    Heterogene Behandlungseffekte: Der kausale Effekt der Behandlung (Y(1) - Y(0), z.B. der Verdienstvorteil durch College) ist nicht für alle gleich, sondern hängt ebenfalls von Alter und GPA ab [source: 872, 910, 948, 949].

Das Ergebnis: Warum Standard-TWFE versagt

Cunningham schätzt nun den Behandlungseffekt (als Event Study) mit zwei Methoden:

    Standard-OLS/TWFE mit additiven Kontrollen: Er verwendet eine Regression, die Einheits- und Zeit-Fixed-Effects enthält und die Kovariaten (Alter, GPA, Quadrate, Interaktion) linear hinzufügt (reg earnings treat##ib1990.year age gpa age_sq gpa_sq interaction, robust) [source: 918, 919].
        Ergebnis (siehe Plot "OLS vs Truth Event Study" [source: 921]): Diese Methode liefert stark verzerrte Schätzungen [source: 926]. Sowohl die Pre-Trends (die Null sein sollten) als auch die eigentlichen Behandlungseffekte nach 1990 liegen weit daneben [source: 926].
        Grund für die Verzerrung: Der Bias kommt hier nicht vom gestaffelten Timing (das gibt es nicht) oder weil Kovariaten fehlen (sie sind ja im Modell). Er entsteht, weil die Standard-TWFE-Regression implizit annimmt, dass die Behandlungseffekte nicht von den Kovariaten abhängen und dass die Kovariaten die Trends in Y(0) nicht auf die spezifische Weise beeinflussen, wie es hier simuliert wurde (kovariaten-spezifische Trends) [source: 930, 931, 933, 958]. Die einfache additive Kontrolle für Kovariaten reicht nicht aus, um diese komplexere Form der Heterogenität korrekt zu berücksichtigen, was zu den falschen Gewichtungen führt, die schon in Abschnitt 4.3 des Baker et al. Papers diskutiert wurden [source: 958, 961].

    Doubly Robust (DR) Methode (csdid): Er verwendet den csdid-Befehl von Callaway und Sant'Anna, der die DR-Methode implementiert und explizit für CPT und heterogene Effekte ausgelegt ist [source: 934, 936, 943].
        Ergebnis (siehe Plot "CS vs Truth Event Study" [source: 943, 945]): Diese Methode liefert unverzerrte Schätzungen [source: 945]. Die Pre-Trends liegen korrekt bei Null, und die geschätzten Behandlungseffekte für 1991 und 1992 entsprechen den wahren Werten aus der Simulation [source: 945].
        Grund für den Erfolg: Die DR-Methode ist robust gegenüber der hier simulierten Heterogenität (sowohl in den Y(0)-Trends als auch in den Behandlungseffekten), weil sie die Kovariateninformation korrekt nutzt (durch Kombination von Propensity-Score-Gewichtung und Outcome-Regression) [source: 941, 942].

Fazit und Lernpunkte:

    Selektion auf Beobachtbares: Allein die Tatsache, dass die Behandlungswahrscheinlichkeit von beobachtbaren Merkmalen abhängt, zerstört nicht notwendigerweise die (bedingte) Parallel-Trends-Annahme [source: 964].
    Gefahr von Standard-TWFE: Selbst ohne gestaffelten Treatmentbeginn ist die Standard-TWFE-Regression mit additiven Kovatenkontrollen keine sichere Bank. Sie kann stark verzerrte Ergebnisse liefern, wenn (1) die unbehandelten Trends kovariaten-spezifisch sind und/oder (2) die Behandlungseffekte heterogen sind und von denselben Kovariaten abhängen [source: 966].
    Moderne Methoden nutzen: In solchen (realistischen) Szenarien sollte man auf moderne DiD-Schätzer zurückgreifen (wie die DR-Methode in csdid), die explizit dafür entwickelt wurden, mit CPT und Heterogenität umzugehen [source: 968].
    Design vor Schätzung: Die Wahl des Schätzers sollte sich nach dem Verständnis des Selektionsmechanismus und den Annahmen über die Trends richten, nicht umgekehrt [source: 887, 962].

Dieser Blogpost ist also eine wichtige Warnung davor, sich nach der Kritik am gestaffelten TWFE zu früh in Sicherheit zu wiegen und einfach Kovariaten zu einem Standard-TWFE-Modell hinzuzufügen. Auch hier können unter realistischen Bedingungen Probleme auftreten, die robustere Methoden erfordern.



csdid earnings age gpa age_sq gpa_sq interaction, ivar(id) time(year) gvar(treat_date)
Der Befehl `csdid` von Callaway und Sant'Anna verwendet standardmäßig analytische Standardfehler, die auf Einflussfunktionen basieren und robust gegenüber Heteroskedastizität und serieller Autokorrelation auf der Ebene der Einheiten (`gvar`) sind. Er hat **keine** direkte `vce(cluster clustvar)` Option wie viele andere Stata-Befehle (z. B. `reg` oder `xtreg`).

Um Standardfehler zu erhalten, die auf einer höheren Ebene (wie der Gemeindeebene, falls Ihre Beobachtungseinheit z.B. Firmen oder Individuen *innerhalb* von Gemeinden sind) geklustert sind, müssen Sie auf die **Bootstrap-Optionen** von `csdid` zurückgreifen und Stata anweisen, das Resampling auf Gemeindeebene durchzuführen.

Die korrekte Syntax verwendet die Optionen `bstrap` und `cluster()`:

```stata
* Angenommen:
* 'y' ist Ihre abhängige Variable
* 'first_treat_year' ist die Variable, die das Jahr der ersten Behandlung angibt (gvar)
* 'year' ist die Zeitvariable (time)
* 'gemeinde_id' ist die Variable, die die Gemeinde eindeutig identifiziert (Ihre Cluster-Variable)
* [controls] sind optionale Kontrollvariablen

csdid y [controls], time(year) gvar(first_treat_year) ///
                 bstrap cluster(gemeinde_id) reps(500) seed(123)
```

**Erklärung der relevanten Optionen:**

* `bstrap`: Diese Option weist `csdid` an, Standardfehler mittels Bootstrap zu berechnen.
* `cluster(gemeinde_id)`: **Dies ist der entscheidende Teil.** Diese Option, in Verbindung mit `bstrap`, teilt dem Bootstrap-Verfahren mit, dass die Resampling-Einheit nicht die individuelle Beobachtungseinheit (definiert durch `gvar`), sondern die übergeordnete Einheit `gemeinde_id` sein soll. Es werden also ganze Gemeinden (mit allen ihren Beobachtungen über die Zeit) mit Zurücklegen gezogen.
* `reps(500)`: Gibt die Anzahl der Bootstrap-Wiederholungen an. Für verlässliche Standardfehler sollten Sie eine ausreichend hohe Zahl wählen (z.B. 400, 500 oder sogar 1000). Mehr Wiederholungen erhöhen die Rechenzeit.
* `seed(123)`: Setzt den Startwert für den Zufallszahlengenerator, um sicherzustellen, dass Ihre Bootstrap-Ergebnisse reproduzierbar sind. Wählen Sie eine beliebige ganze Zahl.

**Wichtige Punkte:**

1.  **Rechenzeit:** Cluster-Bootstrapping kann, besonders bei großen Datensätzen und vielen Wiederholungen, sehr rechenintensiv sein und lange dauern.
2.  **Anzahl der Cluster:** Die Zuverlässigkeit von Cluster-robusten Standardfehlern (auch über Bootstrap) hängt von einer ausreichend großen Anzahl von Clustern ab. Als Faustregel gelten oft >30 oder >50 Cluster (Gemeinden in Ihrem Fall). Bei sehr wenigen Gemeinden sind die Ergebnisse möglicherweise nicht verlässlich.
3.  **Einheit der Beobachtung:** Stellen Sie sicher, dass Ihre `gemeinde_id` tatsächlich eine höhere Ebene als die Einheit darstellt, die durch `gvar` (und die Panel-Struktur impliziert ist) definiert wird. Wenn Ihre Beobachtungseinheit bereits die Gemeinde ist, dann sind die Standard-Standardfehler von `csdid` bereits auf dieser Ebene robust (bzgl. Autokorrelation etc.), und `cluster(gemeinde_id)` würde dasselbe tun wie der Standard-Bootstrap (Resampling der Gemeinden). Clustering ist relevant, wenn Sie z.B. Firmendaten haben und auf Gemeindeebene clustern wollen.
4.  **Aktuelle Version:** Stellen Sie sicher, dass Sie eine aktuelle Version des `csdid`-Pakets installiert haben (`ssc install csdid, replace` oder `ado update csdid, update`), da Optionen und Verhalten sich ändern können.

Zusammenfassend lässt sich sagen, dass Sie die Kombination aus `bstrap` und `cluster(gemeinde_variable)` benötigen, um mit `csdid` Standardfehler zu erhalten, die auf Gemeindeebene geklustert sind.


