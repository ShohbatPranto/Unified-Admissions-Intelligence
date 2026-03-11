/* =========================================================
   SQL VALIDATION SCRIPTS
   Global Footprint & Enrolment Funnel
   Purpose:
   Queries used to validate dashboard metrics from the
   master_applicants dataset.
========================================================= */


-- =========================================================
-- TOTAL APPLICANTS
-- Purpose: Retrieve all applicant records to validate
-- overall dataset population used in dashboard visuals.
-- =========================================================
select count(reference_id) from Master_Dataset_for_Applicants;



-- =========================================================
-- TOTAL DEPOSIT PAID
-- Purpose: Count applicants who have paid deposits,
-- validating enrolment commitment metric.
-- =========================================================
select count(connect_deposit_status) from Master_Dataset_for_Applicants
where connect_deposit_status = 'Yes';



-- =========================================================
-- ACCEPTED STUDENTS
-- Purpose: Count applicants assigned SEVIS IDs to validate
-- accepted/enrolled student metric.
-- =========================================================
select count(sevis_id) from master_applicants;


-- =========================================================
-- TOTAL TUITION FEES REVENUE
-- Purpose: Validate total expected tuition revenue by
-- summing tuition fees across applicants.
-- =========================================================
select  sum(tuition_fees) from Master_Dataset_for_Applicants;



-- =========================================================
-- FINANCIAL SURPLUS
-- Purpose: Validate financial surplus metric calculated
-- as total funding sources minus estimated total cost.
-- =========================================================
SELECT 
    sum((
        COALESCE(students_personal_funds,0) +
        COALESCE(funds_from_this_school,0) +
        COALESCE(funds_from_other_sources,0) +
        COALESCE(on_campus_employment,0)
    ) - COALESCE(total_estimated_cost,0)) AS financial_surplus
FROM Master_Dataset_for_Applicants;



-- =========================================================
-- COUNTRY DISTRIBUTION AND SURPLUS
-- Purpose: Validate global footprint by counting applicants
-- per citizenship and associating financial surplus value.
-- =========================================================
select citizenship,
count(reference_id) students,
(SELECT 
    sum((
        COALESCE(students_personal_funds,0) +
        COALESCE(funds_from_this_school,0) +
        COALESCE(funds_from_other_sources,0) +
        COALESCE(on_campus_employment,0)
    ) - COALESCE(total_estimated_cost,0)) AS financial_surplus)
from Master_Dataset_for_Applicants
group by citizenship
order by students desc;

-- =========================================================
-- ENROLMENT FUNNEL SUMMARY
-- Purpose: Validate funnel stages including total
-- applicants, accepted students, and deposits paid.
-- =========================================================
select count(reference_id) Applied,
count(sevis_id) Accepted,
(select count(connect_deposit_status) from Master_Dataset_for_Applicants
where connect_deposit_status = 'Yes') Deposit_Paid
from Master_Dataset_for_Applicants;

-- =========================================================
-- MAJOR DISTRIBUTION PERCENTAGE
-- Purpose: Validate academic program distribution by
-- calculating applicant percentage per major.
-- =========================================================
WITH filtered AS (
    SELECT *
    FROM Master_Dataset_for_Applicants
    WHERE sevis_id IS NOT NULL
      AND TRIM(sevis_id) <> ''
),
major_counts AS (
    SELECT 
        major,
        COUNT(*) AS major_count
    FROM filtered
    WHERE major IS NOT NULL
      AND TRIM(major) <> ''
    GROUP BY major
    ORDER BY COUNT(*) DESC
    LIMIT 10
),
total_count AS (
    SELECT SUM(major_count) AS total
    FROM major_counts
)
SELECT 
    m.major,
    m.major_count,
    ROUND(m.major_count * 100.0 / t.total, 2) AS percentage
FROM major_counts m
CROSS JOIN total_count t
ORDER BY m.major_count DESC;



-- =========================================================
-- GLOBAL FOOTPRINT & ENROLMENT FUNNEL
-- =========================================================
-- VISA STATUS DISTRIBUTION BY COUNTRY
-- Purpose: Validate visa decision metrics by citizenship,
-- including approved, denied, outreach efforts, appointment
-- scheduled, and null status records. Confirms that
-- dashboard visa funnel metrics align with source data
-- and verifies absence of invalid or inconsistent entries.
-- =========================================================
SELECT 
    citizenship,
    COUNT(CASE WHEN outreach_student_status = 'Visa approved' THEN 1 END) AS approved,
    COUNT(CASE WHEN outreach_student_status = 'Visa denied' THEN 1 END) AS rejected,
    COUNT(CASE WHEN outreach_student_status = 'Outreach efforts' THEN 1 END) AS outreach_efforts,
    COUNT(CASE WHEN outreach_student_status IS NULL THEN 1 END) AS null_values,
    COUNT(CASE WHEN outreach_student_status = 'Appointment Schedule' THEN 1 END) AS Appointment_Schedule,
    COUNT(*) AS grand_total
FROM Master_Dataset_for_Applicants
GROUP BY citizenship
ORDER BY grand_total DESC;

-- =========================================================
-- validate citizenship filter(Zimbabwe)
-- Purpose: Count total applicants, deposits paid, accepted
-- students, tuition revenue, and financial surplus specifically
-- for Zimbabwe. Ensures dashboard country-level KPIs align
-- with source data.
-- =========================================================
SELECT 
    COUNT(reference_id) AS total_applicants, 
    COUNT(CASE 
        WHEN connect_deposit_status = 'Yes' 
        THEN 1 
    END) AS total_deposit, 
    COUNT(sevis_id) AS total_accepted,
    SUM(tuition_fees) AS tuition_revenue_fees, 
    SUM((COALESCE(students_personal_funds,0) +
            COALESCE(funds_from_this_school,0) +
            COALESCE(funds_from_other_sources,0) +
            COALESCE(on_campus_employment,0)) 
        - COALESCE(total_estimated_cost,0)
    ) AS financial_surplus 
FROM Master_Dataset_for_Applicants
WHERE citizenship = 'Zimbabwe';

-- =========================================================
--validate intake filter fall 2024
-- Purpose: Compute KPIs for a specific intake (Fall 2024)
-- to validate dashboard intake-level metrics.
-- =========================================================
SELECT 
    COUNT(reference_id) AS total_applicants, 
    COUNT(CASE 
        WHEN connect_deposit_status = 'Yes' 
        THEN 1 
    END) AS total_deposit, 
    COUNT(sevis_id) AS total_accepted, 
    SUM(tuition_fees) AS tuition_revenue_fees, 
    SUM((COALESCE(students_personal_funds,0) +
            COALESCE(funds_from_this_school,0) +
            COALESCE(funds_from_other_sources,0) +
            COALESCE(on_campus_employment,0)) 
        - COALESCE(total_estimated_cost,0)) AS financial_surplus 
FROM Master_Dataset_for_Applicants
WHERE intake = 'Fall 2024';


-- =========================================================
--validate student visa filter (visa approved)
-- Purpose: Compute KPIs only for students with Visa Approved
-- status. Ensures dashboard visa funnel metrics are aligned
-- with source data.
-- =========================================================
SELECT 
    COUNT(reference_id) AS total_applicants, 
    COUNT(CASE WHEN connect_deposit_status = 'Yes' THEN 1 END) AS total_deposit, 
    COUNT(sevis_id) AS total_accepted, 
    SUM(tuition_fees) AS tuition_revenue_fees, 
    SUM((
        COALESCE(students_personal_funds,0) +
        COALESCE(funds_from_this_school,0) +
        COALESCE(funds_from_other_sources,0) +
        COALESCE(on_campus_employment,0)
        ) - COALESCE(total_estimated_cost,0)) AS financial_surplus 
FROM Master_Dataset_for_Applicants
WHERE TRIM(LOWER(outreach_student_status)) = 'visa approved';



