#!/bin/bash

LOG_DIR="logs"
QUORUM_EXPLORER_LOG="${LOG_DIR}/quorum-explorer.log"

# Find all running besu processes and terminate them
echo "Stopping all besu nodes..."

# Get the list of process IDs for besu
PIDS=$(ps -ef | grep 'besu' | grep -v 'grep' | awk '{print $2}')

if [ -z "$PIDS" ]; then
    echo "No besu nodes are running."
else
    # Terminate each process with SIGTERM first (graceful shutdown)
    for PID in $PIDS; do
        echo "Stopping besu node with PID $PID"
        kill -15 $PID
    done

    # Give time for processes to shutdown cleanly
    sleep 5

    # Check if any processes are still running and force kill if necessary
    PIDS=$(ps -ef | grep 'besu' | grep -v 'grep' | awk '{print $2}')
    if [ -n "$PIDS" ]; then
        for PID in $PIDS; do
            echo "Force killing besu node with PID $PID"
            kill -9 $PID
        done
    fi
    echo "All besu nodes stopped successfully."
fi

# Find and stop the Quorum Explorer process
echo "Stopping Quorum Explorer..."

# Get the process ID for Quorum Explorer
EXPLORER_PID=$(ps -ef | grep 'npm run dev' | grep -v 'grep' | awk '{print $2}')

# Stop Quorum Explorer process gracefully
if [ -z "$EXPLORER_PID" ]; then
    echo "Quorum Explorer is not running."
else
    echo "Stopping Quorum Explorer with PID $EXPLORER_PID"
    kill -15 $EXPLORER_PID
    sleep 5

    # Force kill if still running
    EXPLORER_PID=$(ps -ef | grep 'npm run dev' | grep -v 'grep' | awk '{print $2}')
    if [ -n "$EXPLORER_PID" ]; then
        echo "Force killing Quorum Explorer with PID $EXPLORER_PID"
        kill -9 $EXPLORER_PID
    fi
    echo "Quorum Explorer stopped successfully."
fi

# Remove the quorum-explorer.log file
if [ -f "$QUORUM_EXPLORER_LOG" ]; then
    echo "Removing Quorum Explorer log file..."
    rm "$QUORUM_EXPLORER_LOG"
    echo "Quorum Explorer log file removed successfully."
else
    echo "Quorum Explorer log file does not exist."
fi
