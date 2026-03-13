----- Created Tables----
---- First_Table_Demographics----
CREATE TABLE Demographics_raw (
    id TEXT,
    study_id TEXT,
    condition TEXT,
    disease_comment TEXT,
    age_at_diagnosis INT,
    age INT,
    height INT,
    weight INT,
    gender TEXT,
    handedness TEXT,
    appearance_in_kinship BOOLEAN,
    appearance_in_first_grade_kinship BOOLEAN,
    effect_of_alcohol_on_tremor TEXT
);

Select * from Demographics_raw

COPY Demographics_raw
FROM 'E:\NUMPY_NINJA\Datathon\Final_Submission_DataDectectives\patients.csv'
DELIMITER ','
CSV HEADER;

------Second_Table_Questionarrie------

CREATE TABLE questionnaire_responses_raw(
    resource_type TEXT,
    subject_id TEXT,
    study_id TEXT,
    questionnaire_id TEXT,
    questionnaire_name TEXT,
    link_id TEXT,
    question TEXT,
    answer TEXT
);

Select * from questionnaire_responses_raw

COPY questionnaire_responses_raw
FROM 'E:\NUMPY_NINJA\Datathon\Final_Submission_DataDectectives\questionnaire_responses.csv'
DELIMITER ','
CSV HEADER;


----- Third_Table_Movement_Timeseries-----
CREATE TABLE movement_Timeseries_raw (
    subject_id INTEGER,
    study_id TEXT,
    device_id TEXT,
    record_id TEXT,
    record_name TEXT,
    device_location TEXT,
	file_name TEXT,

    time_mean DOUBLE PRECISION,

    accelerometer_x_mean DOUBLE PRECISION,
    accelerometer_x_std DOUBLE PRECISION,
    accelerometer_x_range DOUBLE PRECISION,
    accelerometer_x_rms DOUBLE PRECISION,

    accelerometer_y_mean DOUBLE PRECISION,
    accelerometer_y_std DOUBLE PRECISION,
    accelerometer_y_range DOUBLE PRECISION,
    accelerometer_y_rms DOUBLE PRECISION,

    accelerometer_z_mean DOUBLE PRECISION,
    accelerometer_z_std DOUBLE PRECISION,
    accelerometer_z_range DOUBLE PRECISION,
    accelerometer_z_rms DOUBLE PRECISION,

    gyroscope_x_mean DOUBLE PRECISION,
    gyroscope_x_std DOUBLE PRECISION,
    gyroscope_x_range DOUBLE PRECISION,
    gyroscope_x_rms DOUBLE PRECISION,

    gyroscope_y_mean DOUBLE PRECISION,
    gyroscope_y_std DOUBLE PRECISION,
    gyroscope_y_range DOUBLE PRECISION,
    gyroscope_y_rms DOUBLE PRECISION,

    gyroscope_z_mean DOUBLE PRECISION,
    gyroscope_z_std DOUBLE PRECISION,
    gyroscope_z_range DOUBLE PRECISION,
    gyroscope_z_rms DOUBLE PRECISION
);

COPY movement_Timeseries_raw
FROM 'E:\NUMPY_NINJA\Datathon\Final_Submission_DataDectectives\movement_timeseries_summary.csv'
DELIMITER ','
CSV HEADER;

Select * from movement_Timeseries_raw
