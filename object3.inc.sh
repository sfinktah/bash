#!/usr/bin/env bash
BASEDIR=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)
. ${BASEDIR}/include upvars classes

## Definition of class Object 

class Object

function Object.__construct
{
	scope
	var $this.type="Object (Object constructor)"
	var $this.length="-1"
}

# Object.length the function, is not related to Object.length the property.
function Object.length
{
	scope
	local __isArrayObject=0
 	$this.isArray && __isArrayObject=1
 	$this.isOject && __isArrayObject=1

	$this.isCollection && {
		eval echo \"\$\{\#$this\[@\]\}\"
		return
	}

	$this.isString && {
		local value; $this.getValue value
		echo "${#value}"
		return
	}

	$this.isNumeric && return 1
	return 1	# incase there are other types
}



function Object.keys
{
	scope
	local e="$( declare -p $this )"; eval "declare -A E=${e#*=}"
	KEYS=( "${!E[@]}" )
}

function Object.keys.toString
{
	scope
	$this.keys
	for key in "${keys[@]}" 
	do
		echo -n "${key}"
	done
}


function Object.toString
{
	scope
	local type; put $this.type into type
	echo "[object $type]"
}

function Object.isObject
{
	scope
	local type; put $this.type into type
	[[ $type == Object ]]
	return
}

function Object.isArray
{
	scope
	local type; put $this.type into type
	[[ $type == Array ]]
	return
}

function Object.isCollection
{
	$this.isObject && return 0
	$this.isArray && return 0
	return 1
}

function Object.isString
{
	scope
	local type; put $this.type into type
	[[ $type == String ]] && return 0
	return 1
}

function Object.isUndefined
{
	scope
	local type; put $this.type into type
	[[ $type == undefined ]] && return 0
	return 1
}

function Object.setType
{
	scope
	local type; type=$1; shift
	var $this.type="$type"
}

function Object.setValue
{
	scope
	local value; value=$1; shift
	var $this.value="$value"
}

function Object.printValue
{
	scope
	local value; put $this.value into value
	echo "$value"
}

function Object.getValue
{
	scope
	local varname=$1
	local value; put $this.value into value
	upvar $varname "$value"
}

function Object.get2
{
	scope
	local varname=$1
	local value; put $this.value into value
	upvar $varname "$value"
	echo "$value"
}

function Object.get
{
	scope
	local __key; __key=$1; shift

	eval echo "\${$this[$__key]}"
	# eval echo \$this["$__key"]
}

function Object.set
{
	scope
	local __key; __key=$1; shift
	local __value; __value=$1; shift

	declare -g $this["$__key"]="$__value"
}


endclass

class ObjectInstance
function ObjectInstance.__construct {
	scope
	var $this.poo="poo"
}

function ObjectInstance.test
{
	## Instantiate "o" as a Object
	new Object ObjectInstance

#	ObjectInstance.isString && echo fail || echo pass
#	ObjectInstance.isUndefined && echo pass || echo fail
#
#	ObjectInstance.setType String

	echo -n "ObjectInstance "
	ObjectInstance.isString && echo "is a string" || echo "is not a string"

	echo -n "ObjectInstace type is "; ObjectInstance.toString

	ObjectInstance.printValue
	local value; ObjectInstance.getValue value; echo "Value is: $value"

	## Output:
	##
	##	pass
	##	pass
	##	pass
	##	Test
	##	Value is: Test
}
endclass
new Object ObjectInstance

class Test

function Test.__construct
{
	scope
	var $this.poo="poo"
}
function Test.test2
{
	new ObjectInstance Test
#	Test.setValue "Child named Poop"
#	Test.set type "Test Type"
#	pset Test.poo = "Test Poo"
#	Test.set poo "Poo"

	echo


	ObjectInstance.setValue ObjectInstanceValue
	Object.setValue ObjectValue
	Test.setValue TestValue

	echo

	echo -n "Test.toString: "; Test.toString
	echo -n "ObjectInstance.printValue: "; ObjectInstance.printValue

	echo

	local value; ObjectInstance.getValue value; echo "ObjectInstance.Value is: $value"
	local value; Object.getValue value; echo "Object.Value is: $value"
	local value; Test.getValue value; echo "Test.Value is: $value"

	echo -n "Object.toString: "; Object.toString
	echo -n "ObjectInstance.toString: "; ObjectInstance.toString
	# local value; Test.getValue value; echo "Test.getValue is: $value"

	# echo -n "ObjectInstance.printValue is: "; ObjectInstance.printValue
	# local value; ObjectInstance.getValue value; echo "ObjectInstance.getValue is: $value"

	# Object.test

	# declare -p
}


endclass
ObjectInstance.test
Test.test2
