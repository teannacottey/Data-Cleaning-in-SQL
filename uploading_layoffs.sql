-- uploading large csv file unsucessful in Data Import Wizard 

SHOW GLOBAL VARIABLES LIKE 'local_infile';

SET GLOBAL local_infile = true;  

LOAD DATA LOCAL INFILE '/Users/teannaaa/Desktop/data/Data Analyst Bootcamp/Projects/SQL Projects/layoffs.csv' INTO TABLE layoffs 
FIELDS TERMINATED BY ',' 
IGNORE 1 LINES; 