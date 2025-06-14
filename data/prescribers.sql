-- ## Prescribers Project

-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
select 
 npi,
 sum(total_claim_count)
from prescription
group by 1
ORDER BY 2 DESC




-- ANSWER: prescriber npi 1881634483 with 99707 total claims	
	
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT 
	nppes_provider_first_name,
	nppes_provider_last_org_name,
	specialty_description,
	sum(total_claim_count) as total_claims
from prescription
left join prescriber
using (npi)
group by nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
order by total_claims desc;

-- or

select 
   prescription.npi,
   nppes_provider_first_name,
   nppes_provider_last_org_name,
   specialty_description,
   sum(total_claim_count)
from prescription
left join prescriber
using (npi)
group by 1,2,3,4
ORDER BY 4 DESC


--ANSWER: prescriber Bruce Pendley; Family Practice; 99707 total claims

-- 2. 
--    a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT 
	specialty_description,
	sum(total_claim_count) as total_claims
from prescription 
left join prescriber
using (npi)
group by specialty_description
order by total_claims desc;

-- ANSWER: Family Practice; 9752347 total claims

--  b. Which specialty had the most total number of claims for opioids?

select 
	specialty_description,
	sum(total_claim_count) as total_claims
from prescription
left join drug
using (drug_name)
left join prescriber
using(npi)
where opioid_drug_flag = 'Y'
group by specialty_description
order by total_claims desc;


--ANSWER: Nurse Practitioner; 900845



--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

select 
	specialty_description
from prescriber
left join prescription
using (npi)
where npi NOT IN (select npi from prescription)
limit 10;




--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?
SELECT
  	generic_name,
	sum(total_drug_cost)
FROM prescription
left join drug
using (drug_name)
GROUP BY generic_name
ORDER BY sum(total_drug_cost) DESC;

--Answer Insulin


--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT
  	generic_name,
	round(sum(total_drug_cost)/sum(total_day_supply),2) as total_per_day
FROM prescription
left join drug
using (drug_name)
GROUP BY generic_name
ORDER BY total_per_day desc;




-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 
select
    drug_name,
	case 
	    when opioid_drug_flag = 'Y' then 'opioid'
	    when antibiotic_drug_flag = 'Y' then 'antibiotic'
		else 'neither'
	End as drug_type
from drug;



--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

select
	case when opioid_drug_flag = 'Y' then 'opioid'
	     when antibiotic_drug_flag = 'Y' then 'antibiotic'
		 else 'neither' 
	end as drug_type,
	sum(total_drug_cost) ::money AS total_cost
from drug
left join prescription
using (drug_name)
group by drug_type;

--::MONEY is shorthand for 
--cast(sum(total_drug_cost) AS MONEY)



-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
select 
	count(cbsa)
from cbsa
left join fips_county
using (fipscounty)
where state = 'TN';

--42

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
select
    cbsaname,
	sum(population) as total_population
from population
left join cbsa
using (fipscounty)
where cbsaname is not null
group by cbsaname
order by total_population desc;

--Nashville - Davidson - Murfreesboro - Franklin, TN is the largest
--Morristown,tn is the smallest

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

select 
    county,
	population
from population
left join fips_county
using (fipscounty)
where fipscounty not in (
	select fipscounty 
	from cbsa
)
order by population desc;


-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
select
   drug_name,
   total_claim_count as total_claims
from prescription
where total_claim_count >= 3000;



--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

select
   drug_name,
   total_claim_count as total_claims,
   opioid_drug_flag
from prescription
left join drug
using (drug_name)
where total_claim_count >= 3000
group by drug_name, opioid_drug_flag;



--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
select
	nppes_provider_first_name,
	nppes_provider_last_org_name,
   	drug_name,
   	total_claim_count as total_claims,
   	opioid_drug_flag
from prescription
left join drug
using (drug_name)
left join prescriber
using (npi)
where total_claim_count >= 3000;



-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.


select 
	npi,
	drug_name
from prescriber
cross join drug
where nppes_provider_city = 'NASHVILLE'
AND specialty_description = 'Pain Management'
AND opioid_drug_flag = 'Y';





--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

select 
	npi,
	drug_name,
	total_claim_count 
from prescriber
cross join drug
left join prescription
USING (npi,drug_name)
where specialty_description = 'Pain Management'
 	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';

	
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

select 
	npi,
	drug_name,
	coalesce(total_claim_count,'0')
from prescriber
cross join drug
left join prescription
USING (npi,drug_name)
where specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';