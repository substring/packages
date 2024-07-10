#!/bin/bash

# This is a light and not very robust PKGBUILD file patcher in an easily readable syntax
# The input file consists of parameter/operator/value
# parameter: a parameter from PKGBUILD (pkgname, pkgrel etc ...)
# 	If the parameter didn't eist, it is added afted pkgdesc
# operator: can be one of:
#	= to set a value
#	+= to add the value to the existing array
#	++,+++,+++,etc... to increment the value as much as needed
# You can also add full functions, make sure to write them like :
# prepare() {
# ...
# }
# with prepare as the function name you want to add, but you MUST respect braces
# and parenthesis position like here in the example

die() {
  echo "ERROR: $@"
  exit 1
}

parameter_is_array() {
	local source_file="$1"
	local param="$2"

	grep -q "^$param=(" "$source_file"
}

increment_value() {
	local source_file="$1"
	local param="$2"
	local value="$3"

	# Get the original value and make sure it's just a number
	current_val=$(grep "^$param=" "$source_file" | cut -d '=' -f 2)
	# Calculate the new value
	new_value=$((current_val + value))
	#set_value
	set_value "$source_file" "$param" "$new_value"
}

# This one will append $3 to the array of values
add_to_value() {
	local source_file="$1"
	local param="$2"
	local value="$3"

	if parameter_is_array "$source_file" "$param" ; then
		array_add_value "$1" "$2" "$3"
	else
		echo doin git
	fi
}

set_value() {
	local source_file="$1"
	local param="$2"
	local value="$3"

	# First check if the value is an array
	if grep -q "^$param=(" "$source_file" ; then
		array_replace_value "$@"
	# Check the parameter does exist
	elif grep -q "^$param=" "$source_file" ; then
		sed -i "s+^$param=.*+$param=$value+" "$source_file"
	# Ok so add the new parameter at some strategic place
	else
		# sed -i "1 i$param=$value" "$source_file"
		sed -i "/pkgdesc=.*/a $param=$value" "$source_file"
	fi
}

array_replace_value() {
	local source_file="$1"
	local param="$2"
	local value="$3"

	# Get the starting line
	line_start=$(grep -nE "^$param=" "$source_file" | cut -d ':' -f1)
	# Get the ending line of the array
	line_end=$(tail -n +"$line_start" "$source_file" | grep -n ')' | head -1 | cut -d ':' -f1)
	line_end=$((line_start + line_end - 1))
	sed -i -e "$line_end i$param=$value" -e "$line_start,$line_end d" "$source_file"
}

array_add_value() {
	local source_file="$1"
	local param="$2"
	local value="$3"

	# Get the starting line
	line_start=$(grep -nE "^$param=" "$source_file" | cut -d ':' -f1)
	# Get the ending line of the array
	line_end=$(tail -n +"$line_start" "$source_file" | grep -n ')$' | head -1 | cut -d ':' -f1)
	line_end=$((line_start + line_end - 1))
		# Special case: the array is on a single line
	if [[ $line_start == "$line_end" ]] ; then
		sed -i "$line_end s+)$+ $value)+" "$source_file"
	else
		sed -i "$line_end i$value" "$source_file"
	fi
}

get_value() {
	get_field_position 3 "$1"
}

get_delimiter() {
	get_field_position 2 "$1"
}

get_param() {
	get_field_position 1 "$1"
}

get_field_position() {
	field="$1"
	string="$2"
	echo "$string" | sed -E 's#([a-z_]+)[[:space:]]*([+=]+)[[:space:]]*(.*)#\'$field'#'
}

count_increments() {
	sep="$1"
	nb_occurences="$(echo "$sep" | tr -cd '+' | wc -c)"
	echo $((nb_occurences-1))
}

parse_and_do() {
	local pp_file="$1"
	local pkgbuild_file="$2"
	local is_in_function=
	local function_code=

	grep -v '^#' "$pp_file" | grep -v '^$' | while IFS=$'\n' read -r line ; do
		if [[ -z $is_in_function ]] && echo "$line" | grep -qE "[a-zA-Z0-9_]+[[:space:]]*\(\)[[:space:]]*{" ; then
			echo Found a function
			is_in_function=1
			function_code="$line"
			continue
		elif [[ -n $is_in_function ]] && echo "$line" | grep -vE '^[[:space:]]*}[[:space:]]*$' ; then
			function_code="$(echo -n "$function_code\n$line")"
			continue
		elif [[ -n $is_in_function ]] && echo "$line" | grep -E '^[[:space:]]*}[[:space:]]*$' ; then
			function_code="$(echo -n "$function_code\n$line")"
			echo -e "$function_code" >> "$pkgbuild_file"
			is_in_function=
			continue
		fi

		param="$(get_param "$line")"
		separator="$(get_delimiter "$line")"
		value="$(get_value "$line")"
		echo "-> $param$separator$value"

		case $separator in
			"=")
				echo "Setting value"
				set_value "$pkgbuild_file" "$param" "$value"
				;;
			"+=")
				echo "Appending values"
				add_to_value "$pkgbuild_file" "$param" "$value"
				;;
			# Pretty risky one ...
			"++"*)
				increment=$(count_increments "$separator")
				echo "Increment $increment time(s)"
				increment_value "$pkgbuild_file" "$param" "$increment"
				;;
		esac
	done
}

run_tests() {
	get_field_position 1 "pkgrel+++"
	get_field_position 2 "source+='test'"
	get_field_position 2 "source+++++"
	get_field_position 3 "source+='test'"

	separator=$(get_delimiter "source+++")

	case $separator in
		"=")
			echo "Setting value"
			;;
		"+=")
			echo "Appending values"
			;;
		# Pretty risky one ...
		"++"*)
			echo "Increment n times"
			count_increments "$separator"
			;;
	esac
}

input_file="$1"
file_to_modify="$2"
[[ ! -e "$input_file" ]] && die "File $input_file doesn't exist"
[[ ! -e "$file_to_modify" ]] && die "File $file_to_modify doesn't exist"

parse_and_do "$input_file" "$file_to_modify"

