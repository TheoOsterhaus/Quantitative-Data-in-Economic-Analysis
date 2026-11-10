**ECON40341

/* Usefull comands
cd <- change work directory
use <- load df
save <- save df
clear <- clear memory
import excel
import delimited <- any
*/

*import dataset
import excel "C:\Users\toste\SynologyDrive\Studium\Master\Nottingham\Quantitative Data in Economic Analysis\master_data.xlsx", sheet("Data") firstrow clear


/*
summary stat total
summarize GDPgrowth govexpenditure Inflation Trade if sample==1

if exercises
summarize GDPgrowth govexpenditure Inflation Trade if sample==1 & Time>2000
summarize GDPgrowth if CountryName=="Germany" | sample!=0
sum for sample size
summarize GDPgrowth govexpenditure Inflation Trade if sample==1 & Time>2000 | Time<1990

*codebook
codebook CountryName if GDPgrowth!=. & Trade!=. & govexpenditure!=. & Inflation!=.
browse CountryName if GDPgrowth!=. & Trade!=. & govexpenditure!=. & Inflation!=.
*/

**Start
browse

encode CountryCode, generate(CountryID)
order CountryID, after(CountryCode)
codebook CountryName if GDPgrowth!=. & Trade!=. & govexpenditure!=. & Inflation!=.

gen complete = !missing(GDPgrowth, Trade, govexpenditure, Inflation)
bysort CountryCode: egen n_complete = total(complete)

gsort -n_complete

/*
*visualisation
histogram n_complete
scatter GDPgrowth Trade if n_complete >=64

scatter GDPgrowth Inflation if Inflation <500

generate TimeDummy =.
replace TimeDummy=1 if Time >=2000 & Time!=.
replace TimeDummy=0 if Time <2000
generate TimeDummy = cond(Time >= 2000, 1, 0)

twoway (scatter Inflation Time) (lfit Inflation Time) (qfit Inflation Time) if CountryName=="Germany"
*/

*creating the logs
label variable Trade "Trade in Share of GDP"
gen logTrade = log(Trade)
order logTrade, after(Trade)

gen logInflation = log(Inflation + 100)
order logInflation, after(Inflation)

sort CountryName

save "C:\Users\toste\SynologyDrive\Studium\Master\Nottingham\Quantitative Data in Economic Analysis\master_data.dta" , replace

