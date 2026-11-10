/*
ECON40341_Assignment
Project		Trade Openness and Economic Growth
Module		ECON40341 Using Quantitative Data in Economic Analysis
Author		Theo Osterhaus
Purpose		Estimate the effect of trade openness on GDP growt using Pooled OLS, FE and RE panel models.
Input		master_data.dta and OGHIST_2026_10_08.xlsx
*/

****setup
clear all
set more off

****load, preparing and cleaning datasets
import excel "C:\Users\toste\SynologyDrive\Studium\Master\Nottingham\Quantitative-Data-in-Economic-Analysis\OGHIST_2026_10_08.xlsx", sheet("Country Analytical History") firstrow clear //Using Country Analytical History as Income-Classification
keep CountryCode J 		//J is the Income Classification for the starting year 1994
save "classification_1994.dta", replace

import excel "C:\Users\toste\SynologyDrive\Studium\Master\Nottingham\Quantitative-Data-in-Economic-Analysis\master_data.xlsx", sheet("Data") firstrow clear
save "master_data.dta", replace //import master_dataset and merging datasets

*preparing and cleaning the dataset
merge m:1 CountryCode using "classification_1994.dta" //merging
tab _merge 				//Taiwan, Yugoslavia, Mayotte, Netherlands Antilles
drop if _merge == 2 	//dropping those missmatches which are not in the master_data

rename J Income 		//rename J as Income-Group
label variable Income "Income group based on GNI (1994)"
encode CountryCode, generate(CountryID)
encode Income, generate(IncomeNum)
xtset CountryID Time 	//creating panel data

*complete-case indicator for all four variables
gen byte complete = !missing(GDPgrowth, Trade, govexpenditure, Inflation)
bysort CountryCode: egen n_complete = total(complete)
gsort -n_complete

****diagnostic plots to create a menaingfull sample
preserve
keep CountryCode Time complete
fillin CountryCode Time  //missing counts as incomplete
replace complete = 0 if _fillin == 1
drop _fillin

sort CountryCode Time
by CountryCode: gen cum = sum(complete) //sum of obs. per country

quietly summarize Time
local tmin = r(min)
local tmax = r(max)

tempfile results
tempname post
postfile `post' L start n_countries using `results', replace

foreach L in 10 15 20 25 30 {
    forvalues s = `tmin'/`=`tmax' - `L' + 1' {
        local e = `s' + `L' - 1
        quietly {
            tempvar c_end c_pre ok
            by CountryCode: egen `c_end' = max(cond(Time == `e', cum, .))
            by CountryCode: egen `c_pre' = max(cond(Time == `s' - 1, cum, .))
            replace `c_pre' = 0 if missing(`c_pre')
            gen byte `ok' = (`c_end' - `c_pre' == `L') & Time == `e'
            count if `ok' == 1
        }
        post `post' (`L') (`s') (r(N))
        drop `c_end' `c_pre' `ok'
    }
}
postclose `post'

use `results', clear
sort L start
save "window_diagnostics.dta", replace

twoway ///
  (line n_countries start if L==10, lcolor(navy)) ///
  (line n_countries start if L==15, lcolor(maroon) lpattern(dash)) ///
  (line n_countries start if L==20, lcolor(forest_green) lpattern(shortdash)) ///
  (line n_countries start if L==25, lcolor(orange) lpattern(longdash)) ///
  (line n_countries start if L==30, lcolor(black) lpattern(dot)), ///
  xline(1995, lcolor(gs10)) ///
  legend(order(1 "T = 10" 2 "T = 15" 3 "T = 20" 4 "T = 25" 5 "T = 30") rows(1) pos(6)) ///
  xtitle("Start year of window") ytitle("Countries with complete data") ///
  title("Balanced-panel coverage by window start and length") ///
  ylabel(, grid angle(0)) graphregion(color(white))
graph export "coverage_by_window.png", replace width(1600)

bysort L (n_countries start): gen best = _n == _N
list L start n_countries if best, noobs sepby(L)

restore


****creating the mainsample based on the diagnostic plots above
local start = 1995	//due to the pont were the countrys with complete data reacht almost a plato
local ende  = 2014 	//T=20

gen byte in_window = inrange(Time, `start', `ende')
gen byte complete_w = in_window & !missing(GDPgrowth, Trade, govexpenditure, Inflation)
bysort CountryID: egen n_complete_w = total(complete_w)
gen sample = in_window & (n_complete_w == 20)

*checking the dirstibution anf if we have selection bias
tab IncomeNum if Time == 1995 //checking the distribution of all obs
tab IncomeNum if sample & Time == 1995 //checking the distribution of the sample obs

****creating the subsamples (Low-, Mid-, Highincome)
gen byte group3 = .
replace group3 = 1 if Income == "L"
replace group3 = 2 if inlist(Income, "LM", "UM")
replace group3 = 3 if Income == "H"
label define g3 1 "Low" 2 "Middle" 3 "High"
label values group3 g3
label variable group3 "Income group 1995 (L / LM+UM / H)"

****Variable construction
xtdescribe if sample == 1
summarize GDPgrowth Trade govexpenditure Inflation if sample == 1, detail

gen logInflation = log(1 + Inflation/100) //steady inflation rate
label variable logInflation "ln(1 + Inflation/100), Inflation in % p.a."
summarize logInflation if sample == 1, detail
