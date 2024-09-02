FROM postgres:15.3-bullseye

RUN apt-get update && apt install -y curl ca-certificates gnupg | curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null

RUN apt-get -y install postgresql-15-cron

COPY 002-setup.sh 003-main.sql /docker-entrypoint-initdb.d/
