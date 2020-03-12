#!/usr/bin/env bash
. include upvars fds arrays array

# Assign variable one scope above the caller
# Usage: local "$1" && upvar $1 "value(s)"
# Param: $1  Variable name to assign value to
# Param: $*  Value(s) to assign.  If multiple values, an array is
#            assigned, otherwise a single value is assigned.
# NOTE: For assigning multiple variables, use 'upvars'.  Do NOT
#       use multiple 'upvar' calls, since one 'upvar' call might
#       reassign a variable to be used by another 'upvar' call.
# See: http://fvue.nl/wiki/Bash:_Passing_variables_by_reference

# root@proxy ~/dev/gsm/bash $ array_name=A {{{
# + array_name=A
# root@proxy ~/dev/gsm/bash $ declare -A A=([boys]=blue [girls]=pink)
# + A=([boys]=blue [girls]=pink)
# + declare -A A
# root@proxy ~/dev/gsm/bash $ declare -A A="([boys]=blue [girls]=pink)"
# + declare -A 'A=([boys]=blue [girls]=pink)'
# root@proxy ~/dev/gsm/bash $ declare -A A=([boys]=blue\ [girls]=pink)
# + A=([boys]=blue\ [girls]=pink)
# + declare -A A
# root@proxy ~/dev/gsm/bash $ declare -A "A=([boys]=blue [girls]=pink)"
# + declare -A 'A=([boys]=blue [girls]=pink)'
# root@proxy ~/dev/gsm/bash $ e="([boys]=blue [girls]=pink)"
# + e='([boys]=blue [girls]=pink)'
# root@proxy ~/dev/gsm/bash $ eval $array_name=\"\$e\"   
# + eval 'A="$e"'
# ++ A='([boys]=blue [girls]=pink)'
# root@proxy ~/dev/gsm/bash $ A="$e"
# + A='([boys]=blue [girls]=pink)'
# }}}

class mysql

   mysql.server()
   {
      scope
      (( $# )) && propset server "$1" && return

      propget server
      return
   }

   mysql.close()
   {
      if [ -n "$MYSQLFD" ]
      then
         close "$MYSQLFD"
         unset MYSQLFD
      fi
   }

   mysql.connect()
   {
      scope
      $this.server
      echo "Connecting to MySql server: $REPLY" >&2
      open "$REPLY" rw || throw "Unable to open connection to MySqlProxy"
      writeline $FD "BASH" || throw "Couldn't initiate BASH connection with MySqlProxy"
      declare -g MYSQLFD=$FD
   }


   mysql.query()
   {
      scope
      writeline $MYSQLFD "$*"
   }


   unset __MYSQL__FIELDS
   declare -A __MYSQL__FIELDS

   # (['Field']='zid' ['Type']='char(32)' ['Null']='NO' ['Key']='PRI' ['Default']='' ['Extra']='')
   mysql.describe()
   {
      scope
      $this.query "DESCRIBE $*"
      $this.process DESCRIBE "$*"
      declare -p __MYSQL__FIELDS
   }

   mysql.selectshow()
   {
      scope
      $this.connect
      $this.query "$*"
      $this.process SELECT "$*"
   }

   mysql.readline()
   {
      scope
      fgets $MYSQLFD
      return
   }

   mysql.addfield()
   {
      scope
      __MYSQL__FIELDS[$1]="$2"
   }

   mysql.select()
   {
      scope
      $this.connect
      $this.query "$*"
   }

   mysql.update()
   {
      scope
      $this.connect
      $this.query "$*"
   }

   mysql.result()
   {
      $this.readline || return 1
      # echo REPLY: "'$REPLY'"
      [ -z "$REPLY" ] && return 1
      test -v ROW && unset -v ROW
      declare -A -g ROW="$REPLY"
      # declare -A ROW='([status]="UNKNOWN" [errorMsg]="Table '\''beboaccounts.monkeyhole'\'' doesn'\''t exist" [rowsAffected]="-1" [errorCode]="1146" )'
      if [ -n "${ROW[errorMsg]}" -a -n "${ROW[errorCode]}" ]; then
         echo "SQL ERROR ${ROW[errorCode]}: ${ROW[errorMsg]}" >&2
         return 1
      fi
      return 0
   }

   mysql.printrow()
   {
      local this
      local base
      scope
      get_array_by_ref "$1"
      # array.from_declare ROW "$*"
      array.reset E
      array.each E
      for key in "${KEYS[@]}"
      do
         echo -e "$key\t${E[$key]}"
      done | column -s $'\t' -t
      echo
   }

   mysql.process_SELECTSHOW()
   {
      local this
      local base
      scope
      declare -A -g ROW="$*"
      # array.from_declare ROW "$*"
      array.reset ROW
      array.each ROW
      for key in "${KEYS[@]}"
      do
         echo -e "$key\t${ROW[$key]}"
      done | column -s $'\t' -t
      echo
   }

   mysql.process_DESCRIBE()
   {
      scope
      declare -A desc_line="$*"
      echo $this.addfield "${desc_line[Field]}" "${desc_line[Type]}"
      $this.addfield "${desc_line[Field]}" "${desc_line[Type]}"
   }

   mysql.process()
   {
      scope
      while $this.readline 
      do
         echo "$REPLY"
         $this.process_$1 "$REPLY"
      done
   }


   mysql.escape_string()
   {
      local search=( '\'  $'\n' $'\r' \' \" $'\x1a' )
      local replace=( '\\' '\n'  '\r' \\\' \\\" '\Z' )

      local n=${#search[@]}
      local s="$1"

      for (( i=0; i<n; i++ )); do
         s="${s//${search[i]}/${replace[i]}}"
      done

      REPLY="$s"

   }

   mysql.escape_field() 
   {
      REPLY="\`${1//\`/\`\`}\`"	# unchecked
   }

   mysql.escape_string.inline()
   {
      getarg VARNAME
      mysql.escape_string "${!VARNAME}"
      local "$VARNAME" && upvar "$VARNAME" "$REPLY"
   }

   mysql.setvars()
   {
      scope
      array.reset "$1"
      array.each "$1"

      get_array_by_ref "$1"

      local buf

      for key in "${KEYS[@]}"
      do
         mysql.escape_field "$key"
         buf+="$REPLY="
         value="${E[$key]}"
         mysql.escape_string "$value"
         buf+="'$REPLY', "
      done
      SETVARS="${buf%, }"
      # echo $SETVARS
   }

   mysql.test()
   {
      mysql.server /dev/tcp/localhost/3307

      array.new user

      user[username]="${EMAIL}"
      user[uid]="${UID}"

      mysql.setvars user
      mysql.update "INSERT IGNORE INTO user2uid SET ${SETVARS}"

      # mysql.connect
      # mysql.describe accounts

      # mysql.connect
      # mysql.query "INSERT INTO mega SET $SETVARS"
      # dd <&$MYSQLFD 2>/dev/null

      mysql.select "SELECT * FROM accounts WHERE username LIKE 'forrest%'"
      while mysql.result 
      do
      	mysql.printrow ROW
      done
   }
	 
endclass

if [[ $0 = ${BASH_SOURCE[0]} ]]; then
   mysql.test
fi

