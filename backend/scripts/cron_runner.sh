#!/bin/bash
# backend/scripts/cron_runner.sh
cd /app
python scripts/run_pipeline.py >> /var/log/pipeline.log 2>&1
