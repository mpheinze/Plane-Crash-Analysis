***** ------------------------------------------------------------------------------ *****
***** ----------------- Global Plane Crash Data - Analysis Script ------------------ *****
***** ------------------------------------------------------------------------------ *****


* Clear/path/use
clear all
use ".\global_database_clean.dta"

* Collapsing data on date
collapse (sum) totl_fatl totl_abrd (mean) totl_pass year, by(date)

* Generating time since last crash date
gen time_gap = date - date[_n-1]
gen ln_time_gap = ln(time_gap)

* Generating transformations of fatalities variable
gen ln_totl_fatl = ln(totl_fatl)
gen l1_totl_fatl = totl_fatl[_n-1]
gen ln_l1_totl_fatl = ln(l1_totl_fatl)

* Declaring time series data
tsset date, format(%tdDD-NN-CCYY)

* Generating season dummies
capture drop season
gen season = month(date)
recode season (12 1 2 = 1) (3/5 = 2) (6/8 = 3) (9/11 = 4)


***** ----------------------------- Descrptive Graphics ---------------------------- *****


cd "C:\Users\heinz\Dropbox\Aktuelt\Plane Crash Analysis\Global Data Analysis\Output"

preserve

* Collapsing on year
collapse (sum) totl_fatl (mean) totl_pass, by(year)

* Genrating variables
capture drop deth_rate
gen deth_rate = (totl_fatl / totl_pass) * 1000000

* Standardized variables
egen z_death = std(deth_rate)
egen z_pass = std(totl_pass)

* Bar chart of fatalities per year
twoway (bar totl_fatl year, fcolor(navy8) lcolor(navy8)) (lowess totl_fatl year), ///
ytitle("Antal omkomne", margin(medsmall)) ylabel(, format(%9,0gc)) xtitle("År", ///
margin(medsmall)) xlabel(1910(10)2020) title("Årligt antal omkomne i flystyrt", ///
span margin(medsmall)) legend(on order(1 "Antal omkomne" 2 "Lowess plot")) ///
graphregion(color(white))

* Saving graph
graph export ".\fatalities_per_year.png", as(png) replace

* Death rate per year
twoway line deth_rate year if inrange(year, 1970, 2015), xlabel(1970(5)2015) ///
title("Dødsraten for globale passagerflyvninger", margin(medsmall) span) ///
note("Dødrate: Antal passagerer transporteret over antal omkomne ved flyulykker per år.", ///
span size(small) margin(medsmall)) graphregion(color(white)) xtitle("Årstal", ///
margin(medsmall)) ytitle("Dødsrate (-e06)", margin(medsmall)) ylabel(#10, angle(forty_five) ///
format(%9.1f))

* Saving graph
graph export ".\death_rate_year.png", as(png) replace

* Standardized line graphs
twoway (line z_pass year) (line z_death year) if inrange(year, 1970, 2015), ///
xlabel(1970(5)2015) title("Udvikling i global passagerransport og dødsrate", ///
margin(medsmall) span) subtitle("Standardiserede tidsserier", span) xtitle("Årstal", ///
margin(medsmall)) legend(on order(1 "Totalt antal passagerer transporteret" 2 ///
"Dødsrate")) graphregion(color(white))

* Saving graph
graph export ".\standardized_plots.png", as(png) replace

restore

* Descriptive table
logout, save(tabstat) word replace: tabstat time_gap totl_fatl if totl_fatl > 0,  ///
statistics(count mean median sd min max) columns(statistics)


***** -------------------------- Poisson Model Estimation -------------------------- *****


***** Linear time trend *****
qui poisson time_gap c.ln_l1_totl_fatl##c.ln_l1_totl_fatl date if l1_totl_fatl > 0
qui margins, at(ln_l1_totl_fatl=(0(0.1)6.5))

marginsplot, recast(line) recastci(rarea) plot1opts(lcolor(navy)) ///
ci1opts(lpattern(solid) lcolor(white) fcolor(gray) fintensity(20)) ///
title("Lineær trend", margin(medsmall) position(12)) ylabel(6(1)11) ///
ytitle("Dage siden forrige flystyrt", margin(medsmall)) xlabel(0(1)6.5) ///
xtitle("Antal omkomne i forrige flystyrt (log)", margin(medsmall)) legend(on order(2 ///
"Marginal effekt" 1 "95 % konfidensinterval") size(small)) graphregion(color(white))

* Saving graph
graph save Graph ".\linear_trend.gph", replace

***** Calculating turning point *****
mat B = e(b)
di "The turning point is: ", exp(abs(B[1,1]/(2*B[1,2])))


***** Polynomial time trend *****
poisson time_gap c.ln_l1_totl_fatl##c.ln_l1_totl_fatl c.date##c.date if ///
l1_totl_fatl > 0
margins, at(ln_l1_totl_fatl=(0(0.1)6.5))

* 1st plot
marginsplot, recast(line) recastci(rarea) plot1opts(lcolor(navy)) ///
ci1opts(lpattern(solid) lcolor(white) fcolor(gray) fintensity(20)) ///
title("Kvadratisk trend", margin(medsmall) position(12)) ylabel(6(1)11) ///
ytitle("Dage siden forrige flystyrt", margin(medsmall)) xlabel(0(1)6.5) ///
xtitle("Antal omkomne i forrige flystyrt (log)", margin(medsmall)) legend(on order(2 ///
"Marginal effekt" 1 "95 % konfidensinterval") size(small)) graphregion(color(white))

* Saving graph
graph save Graph ".\polynomial_trend.gph", replace

***** Polynomial time trend *****
poisson time_gap c.ln_l1_totl_fatl##c.ln_l1_totl_fatl c.date##c.date if ///
l1_totl_fatl > 0
margins, at(ln_l1_totl_fatl=(0(0.1)6.5))

* 2nd plot
marginsplot, recast(line) recastci(rarea) plot1opts(lcolor(navy)) ///
ci1opts(lpattern(solid) lcolor(white) fcolor(gray) fintensity(20)) ///
title("Forventede antal dage mellem flystyrt", margin(medsmall) span) ///
ytitle("Dage siden forrige flystyrt", margin(medsmall)) xlabel(0(1)6.5) ///
xtitle("Antal omkomne i forrige flystyrt (log)", margin(medsmall)) legend(on order(2 ///
"Marginal effekt" 1 "95 % konfidensinterval") size(small)) graphregion(color(white))

* Saving graph
graph export ".\polynomial_trend.png", as(png) replace

***** Calculating turning point *****
mat B = e(b)
di "The turning point is: ", round(exp(abs(B[1,1]/(2*B[1,2]))),1)


****** Combining graphs *****
grc1leg linear_trend.gph polynomial_trend.gph, legendfrom(linear_trend.gph) ///
graphregion(color(white)) ycommon col(2) iscale(0.8) ///
title("Forventede antal dage mellem flystyrt")

* Saving graph
graph export ".\marginal_effects.png", as(png) replace

* Marginal effects
qui poisson time_gap c.ln_l1_totl_fatl##c.ln_l1_totl_fatl c.date##c.date if ///
l1_totl_fatl > 0

qui margins, dydx(ln_l1_totl_fatl) at(ln_l1_totl_fatl=(0(0.1)6.5)) atmeans
marginsplot, recast(line) recastci(rarea) plot1opts(lcolor(navy)) ///
ci1opts(lpattern(solid) lcolor(white) fcolor(gray) fintensity(20)) ///
title("Marginale effekter", margin(medsmall) span) graphregion(color(white)) ///
ytitle("Effekt på periodens længde", margin(medsmall)) xlabel(0(1)6.5) ///
xtitle("Antal omkomne i forrige flystyrt (log)", margin(medsmall)) legend(on order(2 ///
"Marginal effekt" 1 "95 % konfidensinterval") size(small))

graph export ".\dydx_effects.png", as(png) replace


***** ---------------------- Poisson Estimation Output Table ----------------------- *****


* Linear trend
qui poisson time_gap c.ln_l1_totl_fatl##c.ln_l1_totl_fatl date if l1_totl_fatl > 0
outreg2 using linear_trend.doc, addstat("Pseudo R-squared", `e(r2_p)', ///
"Log likelihood", `e(ll)') replace

* Polynomial trend
qui poisson time_gap c.ln_l1_totl_fatl##c.ln_l1_totl_fatl c.date##c.date if ///
l1_totl_fatl > 0
outreg2 using linear_trend.doc, addstat("Pseudo R-squared", `e(r2_p)', ///
"Log likelihood", `e(ll)') append


sum ln_l1_totl_fatl if l1_totl_fatl > 0
local min = r(min)
local max = r(max)
poisson time_gap c.ln_l1_totl_fatl##c.ln_l1_totl_fatl c.date##c.date if ///
l1_totl_fatl > 0
margins, at(ln_l1_totl_fatl=(`min' `max'))
mat T = r(table)
di T[1,2] - T[1,1]

poisson time_gap c.ln_l1_totl_fatl##c.ln_l1_totl_fatl c.date##c.date if ///
l1_totl_fatl > 0 & year > 1912

margins, at(ln_l1_totl_fatl=(0(0.1)6.5))
marginsplot

poisson time_gap c.ln_l1_totl_fatl##c.ln_l1_totl_fatl c.date##c.date if ///
l1_totl_fatl > 0

preserve
collapse (mean) bigcrash, by(year)
twoway bar bigcrash year







