***** ------------------ Global Plane Crash - Data Cleaning Script ----------------- *****

* Importing text file
clear all
import delimited ".\scraped_data.txt", delimiter(";;", asstring) 

* Dropping missing stuff
drop if v11 == ""
drop v12
	
	* Renaming variables
	local i = 1
	foreach x in date time location operator flight route type reg cnln aboard fatalities {
		rename v`i' `x'
		local i = `i' + 1
	}
	*

* Cleaning day and year
split date, p(" ")
gen day = substr(date2, 1, 2)
drop date2
rename date3 year
destring year day, replace

* Cleaning month
replace  date1 = "September" in 1
gen temp_month = date(date1, "M")
egen month = group(temp_month)
drop date date1 temp_month
gen date = mdy(month, day, year)
format date %tdDD-NN-CCYY

* Cleaning time variable
capture drop str_time
capture drop date_time
gen str_time = strtrim(ustrright(time, 5))
replace str_time = subinstr(str_time, "Z", "", .)
replace str_time = "." if strlen(str_time) < 5
gen double date_time = date*24*60*60*1000 + clock(str_time, "hm")
format date_time %tcHH:MM
drop time

	* Recoding missing values on string varibles
	foreach var of varlist location-cnln {
		replace `var' = "." if `var' == "?"
	}
	*

* Generating year-month ("YYYY-MM") varible
capture drop str_mnth
capture drop year_mnth
gen str_mnth = "."
replace str_mnth = string(month)
replace str_mnth = "0" + str_mnth if strlen(str_mnth)  == 1
egen year_mnth = concat(year str_mnth), punct("-")
drop str_mnth

* Splitting aboard numbers
split aboard, p(" ")
egen abrd_pass = sieve(aboard3), char(0123456789)
egen abrd_crew = sieve(aboard4), char(0123456789)

* Splitting fatality numbers
split fatalities, p(" ")
egen fatl_pass = sieve(fatalities3), char(0123456789)
egen fatl_crew = sieve(fatalities4), char(0123456789)
destring abrd_* fatl_*, replace
destring aboard1 fatalities1, replace force
rename aboard1 totl_abrd
rename fatalities1 totl_fatl
drop aboard* fatalities*

* Merging total yearly passenger statistics into the data set
merge m:1 year using "total_passengers.dta"
drop _merge

* Ordering, sorting, and saving cleaned data file
order day month year date year_mnth date_time totl_abrd totl_fatl
sort date
save "global_database_clean.dta", replace

