. misc.inc.sh

PPLIN="OOB:JSCONSOLE:CALLBACK:FB_REGISTRATION_RESPONSE:(['registration_succeeded']='true' ['redirect']='http://www.facebook.com/c.php?email=morinmurray%40yahoo.com' )::1"
PPLIN="OOB:JSCONSOLE:CALLBACK:FB_REGISTRATION_RESPONSE:(['ask_to_login_instead']='kimcantrell308@yahoo.com' )::1"

CB_PREFIX="OOB:JSCONSOLE:CALLBACK:"

FB_REGISTRATION_RESPONSE() {
	declare -A RESPONSE="${1%):*})"
	[ -n "${RESPONSE[ask_to_login_instead]}" ] && termerror "Asked to login instead"
	[ -n "${RESPONSE[registration_succeeded]}" ] && decho "We registered fine"
}

case "$PPLIN" in
	"$CB_PREFIX"* ) 

		CB_PAIR="${PPLIN:${#CB_PREFIX}}"
		CB_NAME="${CB_PAIR%%:*}"
		CB_ARGS="${CB_PAIR#*:}"
		function_exists "$CB_NAME" && $CB_NAME "$CB_ARGS"
esac

