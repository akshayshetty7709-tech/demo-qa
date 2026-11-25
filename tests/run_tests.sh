#!/usr/bin/env bash
# Simple API/page tests for the demo app. No extra tools needed (only bash + curl).
# Usage:   APP_URL=http://<ec2-a-ip>:8085 ./tests/run_tests.sh
# Output:  console summary + reports/junit.xml (Jenkins reads this with the junit step)
# Exit code: 0 = all passed, 1 = at least one failed.

APP_URL="${APP_URL:?Please set APP_URL, e.g. APP_URL=http://1.2.3.4:8085}"
APP_URL="${APP_URL%/}"
OUT_DIR="reports"
mkdir -p "$OUT_DIR"

TESTS=0
FAILS=0
CASES=""
SUITE_START=$(date +%s)

xml_escape() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'; }

# run_test "test name" function_name
run_test() {
  local name="$1" fn="$2" start end msg
  start=$(date +%s)
  msg="$($fn 2>&1)"
  local rc=$?
  end=$(date +%s)
  TESTS=$((TESTS + 1))
  if [ $rc -eq 0 ]; then
    echo "PASS  $name"
    CASES="$CASES  <testcase classname=\"demo-app\" name=\"$name\" time=\"$((end - start))\"/>
"
  else
    FAILS=$((FAILS + 1))
    echo "FAIL  $name  -> $msg"
    local esc
    esc="$(printf '%s' "$msg" | xml_escape)"
    CASES="$CASES  <testcase classname=\"demo-app\" name=\"$name\" time=\"$((end - start))\"><failure message=\"$esc\"/></testcase>
"
  fi
}

http_code() { curl -sS --max-time 10 -o /dev/null -w '%{http_code}' "$1"; }
body()      { curl -sS --max-time 10 "$1"; }

# ---------------- the tests ----------------
t_health_200() {
  local c; c="$(http_code "$APP_URL/health")"
  [ "$c" = "200" ] || { echo "expected HTTP 200 but got $c"; return 1; }
}
t_health_body() {
  body "$APP_URL/health" | grep -q '"status":"ok"' || { echo 'body does not contain "status":"ok"'; return 1; }
}
t_home_page() {
  body "$APP_URL/" | grep -q 'Hello from Demo App' || { echo 'home page does not contain "Hello from Demo App"'; return 1; }
}
t_info_has_version() {
  body "$APP_URL/api/info" | grep -q '"version"' || { echo '/api/info has no "version" field'; return 1; }
}
t_greet() {
  body "$APP_URL/api/greet?name=Macha" | grep -q 'Hello, Macha!' || { echo 'greeting for name=Macha is wrong'; return 1; }
}
t_unknown_404() {
  local c; c="$(http_code "$APP_URL/does-not-exist")"
  [ "$c" = "404" ] || { echo "expected HTTP 404 but got $c"; return 1; }
}

echo "Testing $APP_URL"
echo "------------------------------------------------"
run_test "health returns 200"          t_health_200
run_test "health body is ok"           t_health_body
run_test "home page shows greeting"    t_home_page
run_test "info has version"            t_info_has_version
run_test "greet API says hello"        t_greet
run_test "unknown path returns 404"    t_unknown_404
echo "------------------------------------------------"

SUITE_TIME=$(( $(date +%s) - SUITE_START ))
{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo "<testsuite name=\"demo-qa\" tests=\"$TESTS\" failures=\"$FAILS\" errors=\"0\" time=\"$SUITE_TIME\">"
  printf '%s' "$CASES"
  echo '</testsuite>'
} > "$OUT_DIR/junit.xml"

echo "Tests: $TESTS, Failed: $FAILS  (report: $OUT_DIR/junit.xml)"
[ "$FAILS" -eq 0 ]
