#!/bin/bash

RESULT="/tmp/result.log"
TMP1=$(basename "$0").log

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
BLUEGREEN='\033[1;36m'
WHITE='\033[0;37m'
BAR(){
	printf "${BLUE}=%.0s${NC}" {1..80}
	echo
}

OK() {
	echo -e "${GREEN}[OK] $1${NC}" | tee -a "$REPORT"
}

WARN() {
	echo -e "${YELLOW}[WARN] $1${NC}" | tee -a "$REPORT"
}

INFO() {
	echo -e "${WHITE}[INFO] $1${NC}" | tee -a "$REPORT"
}
FAIL() {
	echo -e "${RED}[FAIL] $1${NC}" | tee -a "$REPORT"
}

FIN() {
	echo -e "${BOLD}${BLUEGREEN}[FIN] $1${NC}" | tee -a "$REPORT"
}

