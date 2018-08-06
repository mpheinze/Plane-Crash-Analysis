***** -------------------------------------------------------------------- *****
***** ----------------------- PLANE CRASH ANALYSIS ----------------------- *****
***** -------------------------------------------------------------------- *****

* Clearing, path setting and importing data
clear all
cd "C:\Users\heinz\Dropbox\Aktuelt\Plane Crash Analysis"
import delimited "AviationData.txt", delimiter("|") varnames(1) 


***** -------------------------- CLEANING DATA --------------------------- *****

drop v32

* Dropping if non-American
encode country, gen(countryid)
drop if countryid != 168

destring latitude longitude numberofengines totalfatalinjuries ///
totalseriousinjuries totalminorinjuries totaluninjured, replace


* Recoding amateur build dummy
encode amateurbuilt, gen(amateur)
replace amateur = . if amateur == 1
recode amateur (2 = 0) (3 = 1)
label drop amateur
drop amateurbuilt


* Data variables
split eventdate, p(/)
destring eventdate*, replace
drop if eventdate3 < 1982
rename eventdate1 month
rename eventdate2 date
rename eventdate3 year
tostring month, gen(month_str)
replace month_str = "0" + month_str if strlen(month_str)  == 1
capture drop ymonth
egen ymonth = concat(year month_str), punct("-")
drop month_str


* Fatalities
rename totalfatalinjuries fatalities
gen ln_fatalities = ln(fatalities + 0.001)


* Investigation type
encode investigationtype, gen(type)
drop investigationtype



***** -------------------------------------------------------------------- *****
***** ----------------------- DESCRIPTIVE ANALYSIS ----------------------- *****
***** -------------------------------------------------------------------- *****


* ----------- Graph of Proportion of Plane Crashes with Fatalities ----------- *

* Generating dummy variables for death counts
	forvalues i = 1/2 {
	
		local l = `i' - 1
		capture drop fatal_d`i'
		gen fatal_d`i' = .
		
		replace fatal_d`i' = 1 if fatalities > `l' & fatalities != .
		replace fatal_d`i' = 0 if fatalities <= `l'
		replace fatal_d`i' = 0 if fatal_d`i' == .
		
	}
	*

capture drop year_mean1
gen year_mean1 = .

capture drop year_mean2
gen year_mean2 = .

capture drop counter
gen counter = .


	forvalues i = 1/35 {
	
		local y = 1981 + `i'
		
			qui sum fatal_d1 if year == `y'
			replace year_mean1 = r(mean) in `i'
			
			qui sum fatal_d2 if year == `y'
			replace year_mean2 = r(mean) in `i'
			
		replace counter = `y' in `i'
			
	}
	*

twoway (line year_mean1 counter) (line year_mean2 counter), ylabel(0(.1).3) ///
ytitle("Proportion of crashes", margin(medsmall)) xlabel(1980(5)2016) xtitle("Year", ///
margin(medsmall)) graphregion(color(white)) legend(label(1 "Fatalities > 0") ///
label(2 "Fatalities > 1")) title("Proportion of Fatal Plane Crashes", margin(medsmall))



* ------------- Histogram of Monthly Frequency of Plane Crashes -------------- *

*drop if fatal_d1 != 1
*drop if fatal_d2 != 1

encode ymonth, gen(ymonth_num)

histogram ymonth_num, discrete frequency lcolor(gray) graphregion(color(white)) ///
ytitle("Number of crashes", margin(medsmall)) xtitle("Months", margin(medsmall)) ///
xlabel(1(36)413, labels labsize(small) angle(forty_five) valuelabel) ///
title("Monthly Frequency of Plane Crashes", color(black) span margin(medsmall)) ///
subtitle("- with fatalities > 1", color(black) span margin(small)) 



***** -------------------------------------------------------------------- *****
***** -------------------- COLLAPSING DATASET ON DAYS -------------------- *****
***** -------------------------------------------------------------------- *****

* Dropping non-Airplane categories
encode aircraftcategory, gen(tempcat)
drop if tempcat > 2
drop tempcat

* Generating number of crases per month to be meaned out in the collapse
encode eventdate, gen(date_num)
egen ncrash = count(date_num), by(date_num)

* Collaping
collapse (sum) fatalities fatal_d1 totalseriousinjuries (mean) ncrash, ///
by(eventdate)

* Generating time series date varible
split eventdate, p(/)
destring eventdate1 eventdate2 eventdate3, replace
gen date = mdy(eventdate1, eventdate2, eventdate3)
tsset date, format(%tdDD-NN-CCYY)
tsfill
drop eventdate*

* Renaming and ordering dataset
recode fatal_d1 (. = 0)
rename fatal_d1 fatal_crashes
rename totalseriousinjuries injured
rename ncrash crashes
order date crashes injured fatalities

* Replacing filled dates with zeros
replace crashes = 0 if crashes == .
replace injured = 0 if injured == .
replace fatalities = 0 if fatalities == .

* --------------------------------- Analysis --------------------------------- *

* Generating many deaths dummy
capture drop manydeaths
gen manydeaths = 0
replace manydeaths = 1 if fatalities >= 15

* Generating fatal-to-total crases ratio
capture drop fatalratio
gen fatalratio = fatal_crashes / crashes
recode fatalratio (. = 0)


* ---------------------- Regression Discontinuity Design --------------------- *

capture drop daycount
gen daycount = .

replace daycount = cond(manydeaths == 1, 0, daycount[_n - 1] + 1)
replace daycount = _n if daycount == .

	* Looping backwards through day counter
	global D = 20
	local i = 1
	while `i' <= _N {
		local j = _N - `i' + 1
		local g = daycount[`j']
		local f = daycount[`j'] - $D
			di `j'
			if `g' > $D {
				forvalues k = 1/`f' {
					local h = `j' - `k' + 1
					replace daycount = -`k' in `h'	
				}
				*
			}
			*
		local i = `i' + 1
	}
	*

replace daycount = . if daycount > 20 | daycount < -20


scatter fatalratio daycount, msize(tiny) xline(0) ///
xtitle("") ytitle("")


scatter fatalratio daycount, msize(vsmall) xline(0) xtitle("Days around major plane crash") ///
ytitle("Probability of deadly crash") ///
|| (lfit fatalratio daycount if daycount < 0 & daycount >= -20, color(dkgreen)) ///
|| (lfit fatalratio daycount if daycount > 0 & daycount <= 5, color(dkgreen)) ///
|| (lfit fatalratio daycount if daycount > 5 & daycount <= 10, color(dkgreen)) ///
|| (lfit fatalratio daycount if daycount > 10 & daycount <= 15, color(dkgreen)) ///
|| (lfit fatalratio daycount if daycount > 15 & daycount <= 20, color(dkgreen)) ///
, legend(off) graphregion(color(white)) ///
title("Discontinuity of Probability for New Major Plane Crash", span margin(medsmall)) 

* Mean comparison of groups around cut off
capture drop ratiodummy
gen ratiodummy = .
replace ratiodummy = 1 if daycount < 0 & daycount >= -5
replace ratiodummy = 2 if daycount > 0 & daycount <= 5

ttest fatalratio, by(ratiodummy)
























exit
***** -------------------------------------------------------------------- *****
***** ------------------- COLLAPSING DATASET ON MONTHS ------------------- *****
***** -------------------------------------------------------------------- *****

* Generating number of crases per month to be meaned out in the collapse
egen ncrash = count(ymonth_num), by(ymonth_num)

* Collaping
collapse (sum) fatalities (mean) ncrash ymonth_num, by(ymonth)

* Setting time series properties
rename ymonth_num time
replace time = time + (22 * 12 - 1) // 22 years after 1960-01
order time ymonth ncrash fatalities
tsset time, format(%tmCCYY-NN)

* Standardizing variables
capture drop z_*
egen z_ncrash = std(ncrash)
egen z_fatalities = std(fatalities)

* Generating first differences
capture drop fd_*
gen fd_ncrash = d.ncrash
gen fd_fatalities = d.fatalities

* Standardizing first differenced variables
capture drop z_fd_*
egen z_fd_ncrash = std(fd_ncrash)
egen z_fd_fatalities = std(fd_fatalities)

* Time series line plots
twoway (tsline z_fd_ncrash, lwidth(thin)) (tsline z_fd_fatalities, lwidth(thin))

* Scatter plot of lagged fatalities and number of plane crashes
twoway (scatter ncrash L1.fatalities) (lfit ncrash L1.fatalities)

* Generating seasonal categories
split ymonth, p(-)
drop ymonth1
destring ymonth2, replace
recode ymonth2 (1/3 = 1) (4/6 = 2) (7/9 = 3) (10/12 = 4), gen(season)
rename ymonth2 month

* Generating dummy for > 100 fatalities
capture drop manydeaths
gen manydeaths = 0
replace manydeaths = 1 if fatalities > 100


* ---------------------- Bar Chart of Crashes per Month ---------------------- *

capture drop monthlycrashes
gen monthlycrashes = .

capture drop monthlyfatalities
gen monthlyfatalities = .

capture drop monthindex
gen monthindex = .

	forvalues i = 1/12 {
		
		qui sum ncrash if month	== `i'
			local mean = r(mean)
			qui replace monthlycrashes = `mean' in `i'
		
		qui sum fatalities if month == `i'
			local mean = r(mean)
			qui replace monthlyfatalities = `mean' in `i'
		
		qui replace monthindex = `i' in `i'
		
	}
	*

graph bar (mean) monthlycrashes monthlyfatalities, over(monthindex) ///
ylabel(0(10)80) title("Average Number of Crashes and Fatalities per Month", ///
span margin(medsmall)) graphregion(color(white))



