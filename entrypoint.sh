#!/bin/bash

log() {
  echo "$(date '+%Y/%m/%d %H:%M:%S') - $*"
}

#CONFIG_JSON="db.json"

# json config update
# usage: update_config <config_file.json>
update_config() {
  db_config="$1"
  db_envs=$(set | awk -F= '/^DB_/ { print $1}')

  if [ ! -f "${db_config}" ]; then
    log "WARNING: CONFIG ${db_config} NOT FOUND!"
    return 1
  fi
  log "PROCESSING JSON CONFIG: ${db_config}"

  tmp_config="${db_config}.tmp"
  cat "${db_config}" > "${tmp_config}" && \
  for varName in ${db_envs}; do
    varValue="$(eval echo '$'{$varName} | sed -e 's#\\#\\\\#g' -e 's#"#\\"#g' )"
    log UPDATING ENV: ${varName} # =${varValue}=
    jq ".variables |= map(select(.name == \"${varName}\").value |= \"${varValue}\")" "${tmp_config}" > "${tmp_config}.swp" && \
      mv -f "${tmp_config}.swp" "${tmp_config}" || return 1
  done
  mv -f "${tmp_config}" "${db_config}" || return 1
}

# call hop http service
# usage: hop_curl <url_path>
hop_curl() {
  curl -f -LI -u "$HOP_SERVER_USER:$HOP_SERVER_PASSWORD" "http://localhost:${HOP_SERVER_PORT}/$1" > /dev/null
  return $?
}

# wait for HOP server to startup or die
wait_server() {
  for attempt in {1..9}; do
    log "WAITING SERVER FOR 10 SEC, ATTEMPT $attempt/9"
    sleep 10;
    hop_curl "hop/status/" && return 0
  done
  log "ERROR: NO SERVER FOUND, EXITING"
  exit 1
}

# run startup HOP jobs using env JOBS_ON_STARTUP
run_startup_jobs() {
  for job in ${JOBS_ON_STARTUP}; do
    log "JOBS: ON STARTUP $job"
    "${DEPLOYMENT_PATH}/hop-run.sh" \
          -r "${HOP_RUN_CONFIG}" \
          -j "${HOP_PROJECT_NAME}" \
          -e "${HOP_ENVIRONMENT_NAME}" \
          -f "${job}"
  done
}

# run once HOP jobs using env JOBS_RUN_ONCE and exit container
run_once_jobs() {
  if [ "$RUNONCE" == true ]; then
    for job in ${JOBS_RUN_ONCE}; do
      log "JOBS: RUN ONCE $job"
      "${DEPLOYMENT_PATH}/hop-run.sh" \
             -r "${HOP_RUN_CONFIG}" \
             -j "${HOP_PROJECT_NAME}" \
             -e "${HOP_ENVIRONMENT_NAME}" \
             -f "${job}"
    done
    exit 0
  fi
}

# schedule HOP jobs using env JOBS_CRON
# syntax: JOBS_CRON="<cron_schedule_without_space>@<project_file_name1> <second_cron_schedule>@<project_file_name1> ..."
# example: JOBS_CRON="*/1_*_*_*_*@repeated/job_every_minute.hwf" - run repeated/job_every_minute.hwf every minute
schedule_cron_jobs() {
  if [ -n "${JOBS_CRON}" ]; then
    CRONTAB_FILE=crontab.tmp
    CRONTAB_RUN=${DEPLOYMENT_PATH}/cron-run

    echo "#!/bin/bash" > "${CRONTAB_RUN}"

    printenv | sed 's/^\([^=]*\)=\(.*\)$/export \1="\2"/g' >> "${CRONTAB_RUN}"
    echo "cd \"${HOP_PROJECT_FOLDER}\"" >> "${CRONTAB_RUN}"
    echo "gosu hop \"${DEPLOYMENT_PATH}/hop-run.sh\" \\
      -r \"${HOP_RUN_CONFIG}\" \\
      -e \"${HOP_ENVIRONMENT_NAME}\" \$*" >> "${CRONTAB_RUN}"
    chmod +x "${CRONTAB_RUN}"

    echo "# Automatically generated file, do not edit! Check JOBS_CRON env variable" > ${CRONTAB_FILE}
    for job in ${JOBS_CRON}; do
      job_cron=$(echo $job | cut -d "@" -f 1 | sed -e "s#_# #g")
      job=$(echo $job | cut -d "@" -f 2)
      log "JOBS: CRONTAB $job_cron $job"
      if [ ! -f "${HOP_PROJECT_FOLDER}/${job}" ]; then
        log "WARNING! File not found: ${HOP_PROJECT_FOLDER}/${job}"
      fi
      echo "$job_cron \"${CRONTAB_RUN}\" -j \"${HOP_PROJECT_NAME}\" -f \"${job}\" > /proc/1/fd/1 2>&1" >> ${CRONTAB_FILE}
    done
    crond
    cat ${CRONTAB_FILE} | crontab - || exit 1
    return 0
  fi
  return 1
}

# main run cycle
trapper() {
  # switch to unprivileged hop user
  exec gosu hop "$@" &
  pid="$!"
  log "RUNNING ENTRYPOINT PID=${pid}"

  [ -f /var/run/crond.pid ] && cron_pid="$(cat /var/run/crond.pid)"

  # wait for the server and do basic job/workflow schedule
  wait_server
  run_once_jobs
  run_startup_jobs
  schedule_cron_jobs

  log "WAITING FOR SIGINT/SIGTERM SIGNAL PID=${pid}"
  # catch all signals that come from outside the container to be able to exit gracefully
  trap "log 'STOPPING ENTRYPOINT PID=$pid'; kill -SIGTERM $pid $cron_pid" SIGINT SIGTERM
  while kill -0 $pid $cron_pid; do
    wait
  done
}

################################################################################
# main entrypoint

cd "${HOP_PROJECT_FOLDER}"

for config in ${CONFIG_JSON}; do
  update_config "${config}"
done

trapper /opt/hop/load-and-execute.sh "$@"

# exit code check
if [ -f /tmp/exitcode.txt ]; then
  EXIT_CODE=$(cat /tmp/exitcode.txt)
  exit "${EXIT_CODE}"
else
  exit 7
fi
# eof
