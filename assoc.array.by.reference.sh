t() 
{
  e="$( declare -p $1 )"
  eval "declare -A E=${e#*=}"
  declare -p E
}

declare -A A='([a]="1" [b]="2" [c]="3" )'
echo -n original declaration:; declare -p A
echo -n running function tst: 
t A

