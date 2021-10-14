* a_assembling.do: This script reads in raw school data from "Directory Information" files, 
*                  merges with "Student Financial Aid and Net Price" files 
*                  and saves "clean_data.dta" as output


** Define locals/paths and get all csv file names
local raw_data="2021 MIT Blueprint Labs Data Task/Data"
local files : dir "`raw_data'/schools" files "*.csv"

* Create tempfile to store data
tempfile main
save `main', replace empty

* Loop to read all csv
foreach x of local files {
	* Import each file
	quietly import delimited "`raw_data'/schools/`x'", clear 
	* Get year variable and numerize
	quietly gen year = regexs(0) if regexm("`x'", "[0-9]+")
	destring year, replace
	* Append each file to masterfile
	append using `main'
	save `main', replace
}

* Load and reshape csv for merge
quietly import delimited "`raw_data'/students/sfa1015.csv", clear 
reshape long scugrad@ scugffn@ scugffp@ fgrnt_p@ fgrnt_a@ sgrnt_p@ sgrnt_a@, i(unitid)j(year)

* Generate new variables
gen grant_state= sgrnt_p * sgrnt_a * scugffn / 100
gen grant_federal= fgrnt_p * fgrnt_a * scugffn / 100
rename scugffn enroll_ftug

* Merge and keep complete observations for a balanced panel
merge 1:1 unitid year using `main'
keep if _merge==3

* Generate variables
rename unitid ID_IPEDS
gen degree_bach = 2
replace degree_bach=1 if instcat==2|instcat==3
gen public = 2
replace public = 1 if control == 1

* Label variable values
label define degree_bach1 1 "four-year colleges" 2 "two-year colleges" 
label values degree_bach degree_bach1  
label define public1 1 "public" 2 "private" 
label values public public1  

* Keep only undergraduate institutions
keep if ugoffer==1
keep if instcat==2|instcat==3|instcat==4

* Keep only selected variables
keep ID_IPEDS year degree_bach public enroll_ftug grant_state grant_federal

* Label variables
label var ID_IPEDS "unique identifier for each institution"
label var year "academic year"
label var degree_bach "bachelor's degree-granting institutions"
label var public "public institutions"
label var enroll_ftug "total number of first-time, full-time undergraduates"
label var grant_state "total amount of state/local grant aid awarded"
label var grant_federal "total amount of federal grant aid awarded"

* Output to dta
save "clean_data.dta", replace