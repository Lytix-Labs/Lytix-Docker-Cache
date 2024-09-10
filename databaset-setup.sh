#!/bin/bash

# Check if a database URL is provided as an argument
if [ $# -eq 0 ]; then
    echo "Error: No database URL provided."
    echo "Usage: $0 <database_url>"
    exit 1
fi

# Store the database URL from the first argument
DB_URL="$1"
SUPPORT_EMAIL="support@lytix.co"


# SQL command to create the cache table
CREATE_UNLOGGED_TABLE_SQL="
CREATE UNLOGGED TABLE cache (
    id serial PRIMARY KEY,
    key text UNIQUE NOT NULL,
    value jsonb,
    inserted_at timestamp DEFAULT CURRENT_TIMESTAMP,
    max_age interval NOT NULL);
"

# Run the PSQL command
echo "Creating cache table..."
psql "$DB_URL" -c "$CREATE_UNLOGGED_TABLE_SQL"

# Check if the command was successful
if [ $? -eq 0 ]; then
    echo "Cache table created successfully."
else
    echo "Error: Failed to create cache table. Please reach out to $SUPPORT_EMAIL"
    exit 1
fi

# Now create the index
CREATE_INDEX_SQL="
CREATE INDEX idx_cache_key ON cache (key);
"

# Run the PSQL command
echo "Creating cache index..."
psql "$DB_URL" -c "$CREATE_INDEX_SQL"

# Check if the command was successful
if [ $? -eq 0 ]; then
    echo "Cache index created successfully."
else
    echo "Error: Failed to create cache index. Please reach out to $SUPPORT_EMAIL"
    exit 1
fi


# Now create a way to expire records after max_age
CREATE_EXPIRE_ROWS_SQL="
CREATE OR REPLACE PROCEDURE expire_rows() AS
\$\$
BEGIN
    DELETE FROM cache
    WHERE inserted_at + max_age < CURRENT_TIMESTAMP;
END;
\$\$ LANGUAGE plpgsql;

CALL expire_rows();
"

# Run the PSQL command
echo "Creating cache expiration procedure..."
psql "$DB_URL" -c "$CREATE_EXPIRE_ROWS_SQL"

# Check if the command was successful
if [ $? -eq 0 ]; then
    echo "Cache expiration procedure created successfully."
else
    echo "Error: Failed to create cache expiration procedure. Please reach out to $SUPPORT_EMAIL"
    exit 1
fi

# Now lets create a cron job
CREATE_CRON_JOB_SQL="
-- Create a schedule to run the procedure every minute
SELECT cron.schedule('* * * * *', \$\$CALL expire_rows();\$\$);
"

# Run the PSQL command
echo "Creating cache expiration cron job..."
psql "$DB_URL" -c "$CREATE_CRON_JOB_SQL"


# Check if the command was successful
if [ $? -eq 0 ]; then
    echo "Cache expiration cron job created successfully."
else
    echo "Error: Failed to create cache expiration cron job. Please reach out to $SUPPORT_EMAIL"
    exit 1
fi

# Now cretea a cron job to run the expire_rows procedure every day at 12am
DELETE_CRON_HISTORY_SQL="SELECT cron.schedule('delete-job-run-details', '0 0 * * *', 'DELETE FROM cron.job_run_details WHERE end_time < now() - interval ''24 hours''');"

# Run the PSQL command
echo "Creating cron job to delete cron history..."
psql "$DB_URL" -c "$DELETE_CRON_HISTORY_SQL"

# Check if the command was successful
if [ $? -eq 0 ]; then
    echo "Cron job to delete cron history created successfully."
else
    echo "Error: Failed to create cron job to delete cron history. Please reach out to $SUPPORT_EMAIL"
    exit 1
fi

# Now show the user the cron job created
SHOW_CRON_JOB_SQL="
SELECT * FROM cron.job;
"

# Run the PSQL command
echo "Showing cache expiration cron job..."
psql "$DB_URL" -c "$SHOW_CRON_JOB_SQL"

# Check if the command was successful
if [ $? -eq 0 ]; then
    echo "Cache expiration cron job shown successfully."
else
    echo "Error: Failed to show cache expiration cron job. Please reach out to $SUPPORT_EMAIL"
    exit 1
fi

echo "All done! 🚀. Your PSQL cache has been setup!"