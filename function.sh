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

CODE() {
	echo -e "${BOLD}${BLUE}[$(basename "$0")] $1${NC}"
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

SECTION_START() {
	local code="$1"
	local tilte="$2"
	BAR
	CODE "[$code] $title"
	BAR
	echo "==================== $code 진단 시작 ====================" | tee -a "$REPORT"
}
SECTION_END() {
	local code="$1"
	 echo "==================== $code 진단 종료 ====================" | tee -a "$REPORT"
    BAR
}

STEP() {
	echo -e "${BOLD}[-] $1${NC}" | tee -a "$REPORT"
}
