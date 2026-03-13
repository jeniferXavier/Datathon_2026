--===============================================
---  Demographics Cleaning ----
--===============================================
-- =========================================
-- 1. CREATE CLEAN TABLE
-- =========================================

CREATE TABLE Demographics AS
SELECT DISTINCT
	id,
	
	NULLIF(TRIM(study_id), '') AS study_id,
	
	NULLIF(TRIM(condition), '') AS condition,
	
	CASE
		WHEN TRIM(disease_comment) IN ('', '-') THEN NULL
		ELSE TRIM(disease_comment)
	END AS disease_comment,
	
	CASE
		WHEN age_at_diagnosis BETWEEN 0 AND 120 THEN age_at_diagnosis
		ELSE NULL
	END AS age_at_diagnosis,
	
	CASE
		WHEN age BETWEEN 0 AND 120 THEN age
		ELSE NULL
	END AS age,
	
	CASE
		WHEN height BETWEEN 120 AND 220 THEN height
		ELSE NULL
	END AS height,
	
	CASE
		WHEN weight BETWEEN 30 AND 250 THEN weight
		ELSE NULL
	END AS weight,
	
	CASE
		WHEN LOWER(TRIM(gender)) IN ('male', 'm') THEN 'Male'
		WHEN LOWER(TRIM(gender)) IN ('female', 'f') THEN 'Female'
		ELSE NULL
	END AS gender,
	
	CASE
		WHEN LOWER(TRIM(handedness)) = 'left' THEN 'Left'
		WHEN LOWER(TRIM(handedness)) = 'right' THEN 'Right'
		WHEN LOWER(TRIM(handedness)) = 'ambidextrous' THEN 'Ambidextrous'
		ELSE NULL
	END AS handedness,
	
	appearance_in_kinship,

	---if appearance_in_kinship is FALSE, you can safely assume that appearance_in_first_grade_kinship is also FALSE. 
	---Clinically, if it's not in the extended family, it's definitely not in the immediate family. 
	--You can use this logic to fill in those 288 missing values we found earlier.
	CASE 
		WHEN appearance_in_first_grade_kinship IS NULL AND appearance_in_kinship = FALSE THEN FALSE
		ELSE appearance_in_first_grade_kinship
	END AS appearance_in_first_grade_kinship,
	-- ADDED: Integrated Family History Risk Column
	CASE 
		WHEN appearance_in_first_grade_kinship = TRUE THEN 'High Risk (Immediate Family)'
		WHEN appearance_in_kinship = TRUE AND appearance_in_first_grade_kinship = FALSE THEN 'Moderate Risk (Extended Family)'
		WHEN appearance_in_kinship = FALSE THEN 'No Family History (Sporadic)'
		ELSE 'Unknown'
	END AS family_history_risk,
	CASE
		WHEN TRIM(effect_of_alcohol_on_tremor) IN ('Unknown', 'No effect', 'Improvement', 'Worsening')
			THEN TRIM(effect_of_alcohol_on_tremor)
		WHEN effect_of_alcohol_on_tremor IS NULL OR TRIM(effect_of_alcohol_on_tremor) = ''
			THEN 'Unknown'
		ELSE 'Unknown'
	END AS effect_of_alcohol_on_tremor

FROM Demographics_raw;

----===============================================
--- DATA TYPECHANGE----
--=============================================

ALTER TABLE Demographics
ALTER COLUMN id TYPE INTEGER 
USING id::INTEGER;

--====================================================
---Renaming Columns--------
--=======================================================

ALTER TABLE Demographics
RENAME COLUMN id TO patient_id;

ALTER TABLE demographics
RENAME COLUMN appearance_in_kinship TO has_kinship;

ALTER TABLE demographics
RENAME COLUMN appearance_in_first_grade_kinship TO has_kinship_first_degree;

---=========================================
---- update HEIGHT & WEIGHT AND ADDED New Column BMI-----
---============================================

-- Professional Imputation: Replace impossible height with the female cohort median
UPDATE Demographics
SET height = 167
WHERE patient_id = 227;


ALTER TABLE Demographics
ADD COLUMN bmi NUMERIC(5,2);

UPDATE Demographics
SET bmi = ROUND(weight / POWER(height / 100.0, 2), 2)
WHERE height IS NOT NULL
  AND weight IS NOT NULL;

  -- =========================================
-- 3. ADD PRIMARY KEY IF id IS UNIQUE
-- First verify uniqueness
-- =========================================
ALTER TABLE Demographics
ADD CONSTRAINT Demographics_pkey PRIMARY KEY (patient_id);
  

Select * from Demographics


-- =========================================================
-- QUESTIONNAIRE_RESPONSES CLEANING IN ONE TABLE
-- Source table: questionnaire_responses
-- Output table: questionnaire_responses_clean
-- =========================================================
-- =========================================================
-- 1. DROP AND RECREATE CLEAN TABLE FROM SOURCE
-- =========================================================
CREATE TABLE questionnaire_responses AS
SELECT *
FROM questionnaire_responses_raw;

-- =========================================================
-- 2. CLEAN BASIC TEXT COLUMNS
-- =========================================================

UPDATE questionnaire_responses
SET
    resource_type = CASE
        WHEN LOWER(TRIM(resource_type)) = 'questionnaire_response' THEN 'questionnaire_response'
        ELSE LOWER(TRIM(resource_type))
    END,
    study_id = NULLIF(TRIM(study_id), ''),
    questionnaire_id = NULLIF(TRIM(questionnaire_id), ''),
    questionnaire_name = NULLIF(TRIM(questionnaire_name), ''),
    question = NULLIF(TRIM(REGEXP_REPLACE(question, '\s+', ' ', 'g')), '');



	-- =========================================================
-- 3. ADD NEW CLEANING COLUMNS
-- =========================================================
ALTER TABLE questionnaire_responses
ADD COLUMN answer_numeric INT;

ALTER TABLE questionnaire_responses
ADD COLUMN question_category TEXT;

-- =========================================================
-- 4. UPDATING _COLUMNS
-- =========================================================

----------------------------------------
-- ANSWER COLUMNS
-------------------------------------------


UPDATE questionnaire_responses
SET
answer_numeric = CASE
        WHEN CAST(answer AS TEXT) ILIKE 'true' THEN 1
        WHEN CAST(answer AS TEXT) ILIKE 'false' THEN 0
        WHEN CAST(answer AS TEXT) = '1' THEN 1
        WHEN CAST(answer AS TEXT) = '0' THEN 0
        WHEN CAST(answer AS TEXT) ILIKE 'yes' THEN 1
        WHEN CAST(answer AS TEXT) ILIKE 'no' THEN 0
        ELSE NULL
    END;
	-- =========================================================
--   QUESTION CATEGORY
-- =========================================================

UPDATE questionnaire_responses
SET question_category =
    CASE
        WHEN question ILIKE '%sleep%'
          OR question ILIKE '%rest%'
          OR question ILIKE '%dream%'
          OR question ILIKE '%insomnia%' THEN 'Sleep'

        WHEN question ILIKE '%tired%'
          OR question ILIKE '%fatigue%'
          OR question ILIKE '%energy%'
          OR question ILIKE '%exhaust%' THEN 'Fatigue'

        WHEN question ILIKE '%walk%'
          OR question ILIKE '%movement%'
          OR question ILIKE '%balance%'
          OR question ILIKE '%stand%'
          OR question ILIKE '%mobility%'
          OR question ILIKE '%tremor%' THEN 'Mobility'

        WHEN question ILIKE '%memory%'
          OR question ILIKE '%focus%'
          OR question ILIKE '%concentrat%'
          OR question ILIKE '%thinking%'
          OR question ILIKE '%remember%' THEN 'Cognitive'

        WHEN question ILIKE '%anxious%'
          OR question ILIKE '%nervous%'
          OR question ILIKE '%worry%'
          OR question ILIKE '%panic%' THEN 'Anxiety'

        WHEN question ILIKE '%sad%'
          OR question ILIKE '%depress%'
          OR question ILIKE '%hopeless%'
          OR question ILIKE '%down%' THEN 'Depression'

        WHEN question ILIKE '%pain%'
          OR question ILIKE '%ache%'
          OR question ILIKE '%hurt%'
          OR question ILIKE '%sore%' THEN 'Pain'

        WHEN question ILIKE '%daily%'
          OR question ILIKE '%activity%'
          OR question ILIKE '%routine%'
          OR question ILIKE '%task%'
          OR question ILIKE '%household%'
          OR question ILIKE '%dress%'
          OR question ILIKE '%eat%'
          OR question ILIKE '%bathe%' THEN 'Daily Activity'

        WHEN question ILIKE '%social%'
          OR question ILIKE '%people%'
          OR question ILIKE '%family%'
          OR question ILIKE '%friend%' THEN 'Social'

        WHEN question ILIKE '%drink%'
          OR question ILIKE '%alcohol%'
          OR question ILIKE '%smoke%'
          OR question ILIKE '%cigarette%' THEN 'Lifestyle'

        ELSE 'Other'
    END;

------------------------------------------
--- Creating NMS_Questions Table-------------
-----------------------------------------------

CREATE TABLE NMS_questions AS
SELECT DISTINCT
link_id,
question,
question_category
FROM questionnaire_responses
ORDER BY link_id;

----------------------------------------------
---Creating Category table ---------
------------------------------------------------

CREATE TABLE  NMS_Category AS 
SELECT
    subject_id,
    SUM(CASE WHEN question_category = 'Sleep' THEN answer_numeric ELSE 0 END) AS sleep_score,
    SUM(CASE WHEN question_category = 'Fatigue' THEN answer_numeric ELSE 0 END) AS fatigue_score,
    SUM(CASE WHEN question_category = 'Mobility' THEN answer_numeric ELSE 0 END) AS mobility_score,
    SUM(CASE WHEN question_category = 'Cognitive' THEN answer_numeric ELSE 0 END) AS cognitive_score,
    SUM(CASE WHEN question_category = 'Anxiety' THEN answer_numeric ELSE 0 END) AS anxiety_score,
    SUM(CASE WHEN question_category = 'Depression' THEN answer_numeric ELSE 0 END) AS depression_score,
    SUM(CASE WHEN question_category = 'Pain' THEN answer_numeric ELSE 0 END) AS pain_score,
    SUM(CASE WHEN question_category = 'Daily Activity' THEN answer_numeric ELSE 0 END) AS daily_activity_score,
    SUM(CASE WHEN question_category = 'Social' THEN answer_numeric ELSE 0 END) AS social_score,
    SUM(CASE WHEN question_category = 'Lifestyle' THEN answer_numeric ELSE 0 END) AS lifestyle_score,
    SUM(answer_numeric) AS total_symptom_score
FROM questionnaire_responses
GROUP BY subject_id
ORDER BY subject_id;

Select * from NMS_category


-- =========================================================
-- 8.Replace 'NMS' with 'Non-Motor Symptoms' in questionnaire_name column
-- ============================================================
UPDATE questionnaire_responses
SET questionnaire_name = 'Non-Motor Symptoms'
WHERE questionnaire_name = 'NMS';

-------------------------------------------------------------
--====Renaming Columns and Table===
----------------------------------------------------------------
ALTER TABLE questionnaire_responses
RENAME TO nms_response;

ALTER TABLE nms_response
RENAME COLUMN subject_id TO patient_id;

ALTER TABLE nms_category
RENAME COLUMN subject_id TO patient_id;

ALTER TABLE nms_questions
RENAME COLUMN link_id TO question_id;

ALTER TABLE nms_response
RENAME COLUMN link_id TO question_id;



Select * from nms_response
-- =========================================================
-- 7.Remove unnecessary columns from questionnaire table
-- Columns to remove:
-- 1. resource_type
-- 2. questionnaire_id
-- =========================================================
ALTER TABLE nms_response
DROP COLUMN IF EXISTS resource_type,
DROP COLUMN IF EXISTS questionnaire_id;

ALTER TABLE nms_response
DROP COLUMN IF EXISTS study_id;

ALTER TABLE nms_response
DROP COLUMN IF EXISTS answer;

ALTER TABLE nms_response
DROP COLUMN IF EXISTS question;

ALTER TABLE nms_response
DROP COLUMN IF EXISTS question_category;

ALTER TABLE nms_response
RENAME COLUMN answer_numeric TO answer;
Select *from nms_response

--================================================================
-- Changing the Data Type----
--==================================================================
ALTER TABLE nms_response
ALTER COLUMN question_id TYPE INTEGER
USING TRIM(question_id)::INTEGER;

ALTER TABLE nms_category
ALTER COLUMN patient_id TYPE INTEGER
USING TRIM(patient_id)::INTEGER;

ALTER TABLE nms_response
ALTER COLUMN patient_id TYPE INTEGER
USING TRIM(patient_id)::INTEGER;

ALTER TABLE nms_questions
ALTER COLUMN question_id TYPE INTEGER
USING TRIM(question_id)::INTEGER;


-----==========================================
----Primary key & Foriegn Key Relationship
--===============================================
=============================================
ALTER TABLE nms_questions
ADD CONSTRAINT pk_nms_questions
PRIMARY KEY (question_id);

ALTER TABLE nms_response
ADD CONSTRAINT pk_nms_response
PRIMARY KEY (patient_id, question_id);

ALTER TABLE nms_category
ADD CONSTRAINT pk_nms_category
PRIMARY KEY (patient_id);

ALTER TABLE nms_response
ADD CONSTRAINT fk_question
FOREIGN KEY (question_id)
REFERENCES nms_questions(question_id);

ALTER TABLE nms_category
ADD CONSTRAINT fk_patient
FOREIGN KEY (patient_id)
REFERENCES demographics(patient_id);

ALTER TABLE nms_response
ADD CONSTRAINT fk_patient_response
FOREIGN KEY (patient_id)
REFERENCES demographics(patient_id);

ALTER TABLE nms_category
ADD CONSTRAINT fk_patient_category
FOREIGN KEY (patient_id)
REFERENCES demographics(patient_id);

-- =========================================================
-- 9. VALIDATION CHECKS
-- =========================================================

select * from nms_category
select * from nms_questions
select * from nms_response




-- =========================================================
-- MOVEMENT DATA CLEANING + FINAL LONG FORMAT TABLE
-- =========================================================

------------------------------------------------------------
-- CREATE CLEAN TABLE
------------------------------------------------------------

DROP TABLE IF EXISTS movement_timeseries;

CREATE TABLE movement_timeseries AS
WITH movement_clean AS (
    SELECT DISTINCT
        LPAD(subject_id::text, 3, '0') AS subject_id,
        NULLIF(TRIM(study_id), '') AS study_id,
        NULLIF(TRIM(device_id), '') AS device_id,
        NULLIF(TRIM(record_id), '') AS record_id,
        NULLIF(TRIM(record_name), '') AS record_name,
        CASE
            WHEN LOWER(TRIM(device_location)) IN ('left','left side','left_hand','left hand') THEN 'Left'
            WHEN LOWER(TRIM(device_location)) IN ('right','right side','right_hand','right hand') THEN 'Right'
            ELSE INITCAP(TRIM(device_location))
        END AS device_location,
        NULLIF(TRIM(file_name), '') AS file_name,
        ROUND(time_mean::numeric, 3) AS time_mean,

        ROUND(accelerometer_x_mean::numeric, 3) AS accelerometer_x_mean,
        ROUND(accelerometer_x_std::numeric, 3) AS accelerometer_x_std,
        ROUND(accelerometer_x_range::numeric, 3) AS accelerometer_x_range,
        ROUND(accelerometer_x_rms::numeric, 3) AS accelerometer_x_rms,

        ROUND(accelerometer_y_mean::numeric, 3) AS accelerometer_y_mean,
        ROUND(accelerometer_y_std::numeric, 3) AS accelerometer_y_std,
        ROUND(accelerometer_y_range::numeric, 3) AS accelerometer_y_range,
        ROUND(accelerometer_y_rms::numeric, 3) AS accelerometer_y_rms,

        ROUND(accelerometer_z_mean::numeric, 3) AS accelerometer_z_mean,
        ROUND(accelerometer_z_std::numeric, 3) AS accelerometer_z_std,
        ROUND(accelerometer_z_range::numeric, 3) AS accelerometer_z_range,
        ROUND(accelerometer_z_rms::numeric, 3) AS accelerometer_z_rms,

        ROUND(gyroscope_x_mean::numeric, 3) AS gyroscope_x_mean,
        ROUND(gyroscope_x_std::numeric, 3) AS gyroscope_x_std,
        ROUND(gyroscope_x_range::numeric, 3) AS gyroscope_x_range,
        ROUND(gyroscope_x_rms::numeric, 3) AS gyroscope_x_rms,

        ROUND(gyroscope_y_mean::numeric, 3) AS gyroscope_y_mean,
        ROUND(gyroscope_y_std::numeric, 3) AS gyroscope_y_std,
        ROUND(gyroscope_y_range::numeric, 3) AS gyroscope_y_range,
        ROUND(gyroscope_y_rms::numeric, 3) AS gyroscope_y_rms,

        ROUND(gyroscope_z_mean::numeric, 3) AS gyroscope_z_mean,
        ROUND(gyroscope_z_std::numeric, 3) AS gyroscope_z_std,
        ROUND(gyroscope_z_range::numeric, 3) AS gyroscope_z_range,
        ROUND(gyroscope_z_rms::numeric, 3) AS gyroscope_z_rms
    FROM movement_timeseries_raw
),

movement_long AS (

SELECT
    subject_id::integer AS patient_id,
    record_name AS movement,
    device_location AS side,
    'Accelerometer' AS sensor,
    'X' AS axis,
    accelerometer_x_rms AS rms,
    accelerometer_x_std AS std,
    time_mean AS frequency,
    accelerometer_x_mean AS amplitude,
    CASE
        WHEN accelerometer_x_rms IS NULL THEN NULL
        WHEN accelerometer_x_rms < 1 THEN 0
        WHEN accelerometer_x_rms < 3 THEN 1
        WHEN accelerometer_x_rms < 6 THEN 2
        ELSE 3
    END AS tremor_rating
FROM movement_clean

UNION ALL

SELECT
    subject_id::integer,
    record_name,
    device_location,
    'Accelerometer',
    'Y',
    accelerometer_y_rms,
    accelerometer_y_std,
    time_mean,
    accelerometer_y_mean,
    CASE
        WHEN accelerometer_y_rms IS NULL THEN NULL
        WHEN accelerometer_y_rms < 1 THEN 0
        WHEN accelerometer_y_rms < 3 THEN 1
        WHEN accelerometer_y_rms < 6 THEN 2
        ELSE 3
    END
FROM movement_clean

UNION ALL

SELECT
    subject_id::integer,
    record_name,
    device_location,
    'Accelerometer',
    'Z',
    accelerometer_z_rms,
    accelerometer_z_std,
    time_mean,
    accelerometer_z_mean,
    CASE
        WHEN accelerometer_z_rms IS NULL THEN NULL
        WHEN accelerometer_z_rms < 1 THEN 0
        WHEN accelerometer_z_rms < 3 THEN 1
        WHEN accelerometer_z_rms < 6 THEN 2
        ELSE 3
    END
FROM movement_clean

UNION ALL

SELECT
    subject_id::integer,
    record_name,
    device_location,
    'Gyroscope',
    'X',
    gyroscope_x_rms,
    gyroscope_x_std,
    time_mean,
    gyroscope_x_mean,
    CASE
        WHEN gyroscope_x_rms IS NULL THEN NULL
        WHEN gyroscope_x_rms < 1 THEN 0
        WHEN gyroscope_x_rms < 3 THEN 1
        WHEN gyroscope_x_rms < 6 THEN 2
        ELSE 3
    END
FROM movement_clean

UNION ALL

SELECT
    subject_id::integer,
    record_name,
    device_location,
    'Gyroscope',
    'Y',
    gyroscope_y_rms,
    gyroscope_y_std,
    time_mean,
    gyroscope_y_mean,
    CASE
        WHEN gyroscope_y_rms IS NULL THEN NULL
        WHEN gyroscope_y_rms < 1 THEN 0
        WHEN gyroscope_y_rms < 3 THEN 1
        WHEN gyroscope_y_rms < 6 THEN 2
        ELSE 3
    END
FROM movement_clean

UNION ALL

SELECT
    subject_id::integer,
    record_name,
    device_location,
    'Gyroscope',
    'Z',
    gyroscope_z_rms,
    gyroscope_z_std,
    time_mean,
    gyroscope_z_mean,
    CASE
        WHEN gyroscope_z_rms IS NULL THEN NULL
        WHEN gyroscope_z_rms < 1 THEN 0
        WHEN gyroscope_z_rms < 3 THEN 1
        WHEN gyroscope_z_rms < 6 THEN 2
        ELSE 3
    END
FROM movement_clean
)

SELECT
    ROW_NUMBER() OVER() AS s_no_pk,
    *
FROM movement_long;
=======================================================
ALTER TABLE movement_timeseries
ADD CONSTRAINT movement_timeseries_pkey
PRIMARY KEY (s_no_pk);

ALTER TABLE movement_timeseries
ADD CONSTRAINT uq_movement
UNIQUE (patient_id, movement, side, sensor, axis);

ALTER TABLE movement_timeseries
ADD CONSTRAINT fk_patient_movement
FOREIGN KEY (patient_id)
REFERENCES demographics (patient_id);

------------------------------------------------------------
-- Validation
------------------------------------------------------------

Select * from movement_Timeseries














