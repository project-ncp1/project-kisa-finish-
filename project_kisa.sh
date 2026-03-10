#!/bin/bash
export PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:$PATH
#KISA UNIX 취약점 자동 스캐너 v1.0(U-07계정관리)
#작성자 : Kimjoon-Yeong(정보 보안 엔지니어 준비생)

. function.sh 
LS_MAC=false
TARGET_FILE="$1"
if [[ $# -eq 0 ]];then
	echo "사용법:$0 <파일경로>"
	exit 1
fi

OS_TYPE=$(uname)
if [[ "$OS_TYPE" == darwin* ]]; then
	GROUP_OK="root|wheel"
	echo "macOS 모드: wheel 그룹 허용 중..."
else
	GROUP_OK="root"
	echo "Linux 모드: root 그룹만 허용"
fi

mkdir -p logs
REPORT="logs/project-kisa-$(date +%Y%m%d-%H%M%S).txt"
echo "===KISA U-07 계정관리 취약점 진단 시작===" > "$REPORT"
echo "대상 시스템: $(hostname) | $(date)" >> "$REPORT"

check_root_login() {
	INFO "U-07-01: 루트 계정 확인 중..." 

	if [[ "$OSTYPE" == darwin* ]]; then
		OK "PASS: macOS 루트 정상"
	else
		if [ -f /etc/shadow ]; then
			if grep "^root:" /etc/shadow 2>/dev/null | grep -q "!!"; then
				OK "PASS: 루트 비활성화"
			else
				FAIL "FAIL: 루트 활성화" 
			fi
		else
			WARN "주의!: /etc/shadow 파일 없음" 
		fi
	fi
}

check_root_login

FIN "U-07 /etc/shadow의 root계정 활성화/비활성화 및 etc/shadow 파일 유무 진단 완료!"
BAR
#쉐도우 파일 점검
check_shadow_perm() { 
	INFO "U-08: /etc/shadow 소유자/권한 확인 중..."
	if [[ "$OSTYPE" == darwin* ]];then
		echo "PASS:macOS환경 (/etc/shadow 없음)" | tee -a "$REPORT"
		return
	fi

	if [ ! -f /etc/shadow ]; then
		WARN "경고: /etc/shadow 파일없음"
	 소유자 및 권한 확인 완료	return
	fi

	OWNER=$(stat -c "%U" /etc/shadow 2>/dev/null)
	MODE=$(stat -c "%a" /etc/shadow 2>/dev/null)

	if [ "$OWNER" = "root" ] && [ "$MODE" -le 400 ]; then
		OK "PASS:소유자 root, 권한 ${MODE} (400이하)" 
	else
		FAIL "실패:소유자 ${OWNER}, 권한 ${MODE}"
		FAIL " 해결책:sudo chown root /etc/shadow && sudo chmod 400 /etc/shadow"
	fi
	}
check_shadow_perm

FIN "U-08 /etc/shadow 소유자 및 권한 확인 완료"
BAR
# 호스트 점검
check_hosts_perm(){
	INFO "U-09 etc/hosts 소유자/권한 확인 중..." 
	local FILE=${1:-"/etc/hosts"}

	if [ ! -f"$FILE" ];then
		echo"파일없음:$FILE"
		return 1 ###1을 쓰는 이유 return 1은 실패했다 라는걸 알려줌
	fi

	local OWNER=$(ls -l "$FILE" | awk '{print$3}')
	local MODE=$(stat -c %a "$FILE" 2>/dev/null || stat -f %Lp "$FILE" 2>/dev/null | cut -c5 || echo "999")

	if [ "$OWNER" = "root" ] && [ "$MODE" -le 600 ] 2>/dev/null; then
		OK "PASS:소유자root, 권한 $MODE (600이하)"
	else
		FAIL "실패:소유자 $OWNER, 권한 $MODE -root/600 수정 필요"
	fi
	}

check_hosts_perm
FIN "U-09 /etc/hosts 소유자/권한  진단 완료"
BAR
#그룹 점검
check_group_perm(){ 
	INFO "U-10 파일 및 디렉터리 소유자 설정 점검"
	
	if [ ! -e "$TARGET_FILE" ]; then
		WARN "대상 파일 없음: $TARGET_FILE"
		return 1
	fi

	# 소유자 / 그룹 확인

	OWNER=$(stat -c %U "$TARGET_FILE" 2>/dev/null || stat -f %Su "$TARGET_FILE")
	GROUP=$(stat -c %G "$TARGET_FILE" 2>/dev/null || stat -f %Sg "$TARGET_FILE")


	if [[ "$GROUP_OK" == "root|wheel" ]]; then
		if [[ "$OWNER" == "root" && ( "$GROUP" == "root" || "$GROUP" == "wheel" ) ]];then
			OK "[PASS]그룹:$FILE_GROUP (macOS 허용 설정)"
		else
			FAIL "[FAIL]그룹:$FILE_GROUP (root/wheel 필요)"
		fi
	else
		if [[ "$OWNER" == "root" && "$GROUP" == "root" ]]; then
			OK "소유자:$OWNER 그룹:$GROUP"
		else
			FAIL "소유자:$OWNER 그룹:$GROUP (root/root 필요)"
		fi
	fi


}

check_group_perm
FIN "U-10 파일 및 디렉터리 소유자 설정 점검완료"
BAR



INFO "U-15 : World Writable 파일 점검시작..."
# World Writable 파일 점검

cat << EOF >> "$REPORT"
[양호]:시스템 중요 파일에 world writable 파일이 존재하지 않거나, 존재 시 설정 이유를 확인하고 있는 경우
[취약]:시스템 중요 파일에 world writable 파일이 존재하나 해당 설정 이유를 확인하고 있지 않은 경우
EOF

WW_FILES=$(find / -xdev -type f -perm -002 2>/dev/null | grep -vE "/tmp/|proc/|/dev/|sys/" | head -20)

if [ -z "$WW_FILES" ]; then
	OK "시스템에 불필요한 world writable 파일이 없습니다."
else
	WARN "World writable 파일 존재(목록 확인 필요)"
	echo "취약 파일 목록:" | tee -a "$REPORT"
	echo "$WW_FILES" | while read file; do
		if [ -f "$file" ]; then
			PERM=$(stat -c %A "$file" 2>/dev/null || stat -f %A "$file" 2>/dev/null)
			OWNER=$(stat -c %U "$file" 2>/dev/null || stat -f %Su "$file" 2>/dev/null)
			echo "$file (권한: $PERM, 소유자: $OWNER)" | tee -a "$REPORT"
		fi
	done
fi

FIN "U-15 : World Writable 파일 점검완료"
BAR

INFO "U-20 Anonymous FTP 비활성화 진단 시작..."

check_u_20_anon_ftp() {
	VULN_COUNT=0
	VULN_VSFTPD=0
	
	echo "[U-20] Anonymous FTP 비활성화 점검 결과" >> "$REPORT"
#1. /etc/passwd에 ftp/anoymous 계정 체크
	FTP_USER=$(grep -i '^ftp\|^anonymous' /etc/passwd 2>/dev/null)
	if [ -n "$FTP_USER" ]; then
		WARN "취약: /etc/passwd에 ftp/anonymous 계정 존재 -> userdel ftp/anonymous 필요"
		VULN_COUNT=1
	else
		OK "양호: ftp/anonymous 계정 없음" 
	fi

#2. vsftpd.conf 체크 (anonymous_enable=NO 여부)
VSFTPD_CONF="/etc/vsftpd.conf /etc/vsftpd/vsftpd.conf"
VULN_VSFTPD=0
for conf in $VSFTPD_CONF; do
	if [ -f "$conf" ]; then
		ANON_SETTING=$(grep '^anonymous_enable' "$conf" 2>/dev/null | grep -i 'YES' || echo "NO")
		if echo "$ANON_SETTING" | grep -q 'YES'; then
			WARN "취약: $conf 에 anonymous_enable=YES -> NO로 변경 필요"
			VULN_VSFTPD=1
		else
			OK "양호: $conf anonymous_enable 비활성 또는 NO" 
		fi
	else
		INFO "$conf 파일  없음 (FTP 서버 미설치 = 양호)"
	fi
done

#3. proftpd.conf 체크 (Anonymous 섹션 존재 여부)
PROFTPD_CONF="/etc/proftpd.conf"
if [ -f "$PROFTPD_CONF" ]; then
	ANON_SECTION=$(grep -i '<Anonymous' "$PROFTPD_CONF" 2>/dev/null)
	if [ -n "$ANON_SECTION" ]; then
		WARN "취약: $PROFTPD_CONF에 <Anonymous> 섹션 존재 -> 주석 처리 필요" 
	else
		OK "양호: $PROFTPD_CONF Anonymous 섹션 없음 또는 주석" 
	fi
fi

#4. FTP 서비스 실행 여부 간단 체크 (ps로 ftp 프로세스)
FTP_RUNNING=$(ps aux 2>/dev/null | grep -E '(vsftpd|proftpd|ftpd)' | grep -v grep)
if [ -n "$FTP_RUNNING" ]; then
	INFO "FTP 서비스 실행 중: $FTP_RUNNING - 수동으로 anonymous 테스트 권장 (ftp localhost, anonymous 로그인
	시도)" 
else
	OK "양호 : FTP 서비스 미실행" 
fi

echo >> "$REPORT"
}
check_u_20_anon_ftp

FIN "U-20 Anonymous FTP 비활성화 진단 끝!"
BAR
