#!/bin/bash

#################################################################
# General purpose shell functions
# Author: Brad Boyle (bboyle@email.arizona.edu)
# Date created: 27 June 2016
#################################################################

checkemail()
{
	# Simple email validation function
	# Returns 0 if valid, 2 is missing, 1 if bad
	
	if [ -z "$1" ]; then
		# No email supplied
		#echo "No email supplied"
		return 2
	else 
		email=$1
	
		if [[ "$email" == ?*@?*.?* ]]  ; then
			#echo $email": Valid email"
			return 0
		else
			#echo $email": Bad email"
			return 1
		fi
	fi

}

confirm()
{
	# Echos optional message if supplied
	# Then prompts to continue
	# Stops execution if any reply other than Y or y
	
	if ! [ -z "$1" ]; then 
		echo "$1"
	fi
	 	
	read -p  "Continue? (Y/N): " -r

	if ! [[ $REPLY =~ ^[Yy]$ ]]; then
		echo "Operation cancelled"
		exit 0
	fi

}

echoi()
{
	# Echos message only if first token=true, otherwise does nothing
	# If optionally pass most recent exit code, will abort if error
	# Provides a compact alternative to wrapping echo in if...fi
	# Options:
	# 	-n 	Standard echo -n switch, turns off newline
	# 	-r 	Carriage return without newline (replaces existing line)
	#	-e 	Exit status of last operation. If used, -e MUST be 
	#		followed by $? or $? saved as variable.
	# Gotcha: may behave unexpectedly if message = "true" or true

	# first token MUST be 'true' to continue
	if [ "$1" = true ]; then
		
		shift
		msg=""
		n=" "
		o=""
		while [ "$1" != "" ]; do
			# Get remaining options, treating final 
			# token as message		
			case $1 in
				-n )			n=" -n "	
								shift
								;;
				-r )			n=" -ne "	# Enable backslash (\) options
								o=" \r"		# The \ option to append 
								shift
								;;
				-e )			shift
								rc=$1
								#echo "rc="$rc
								if [[ $rc != 0 ]]; then 
   									kill -s TERM $TOP_PID
								fi
								shift
								;;
				* )            	msg="$1"
								break
								;;
			esac
		done	
		
		echo $n "$msg"$o
	fi
}

check_status_notify()
{
	# Check exit status & take one of the following actions:
	# 1. Fail: 
	#		a. Echos error
	#		b. Send failure notification email (email on only)
	#		c. Stop execution.
	# 2. Success: 
	#		a. Echo supplied success message (email on only)
	# Parameters: 
	#	-s $status	exit status code
	#	-i			echo on (interactive mode) [default: no echo]	 
	#	-n			standard echo -n switch, turns off newline [opt]
	#	-m	$msg	success message to echo [echo on only]
	#	-e $email	failure email address [default: no email]
	#	-h $header	failure email header
	#	-b $body	failure email body
	# Required functions:
	# 	echoi
	# Complete usage:
	# check_status_notify -s $status -r $rc -i -n -m $msg -e $email -h $header -b $body
	
	# Get parameters
	while [ "$1" != "" ]; do
		# Get options, treating final 
		# token as message		
		#send="false"
		case $1 in
			-s )			shift
							status=$1
							;;
			-r )			shift
							rc=$1
							;;
			-i )			shift
							i=$1	
							;;
			-e )			shift
							echomsg=$1	
							;;
			-t )			shift
							elapsed=$1	
							;;
			-n )			n=" -n "	
							;;
			-m )			send="true"
							shift
							email=$1
							;;
			-h )			shift
							header=$1
							;;
			-b )			shift
							body=$1
							;;
		esac
		shift
	done	

	if ! [[ $status = 0 ]]; then 
		if [[ "$m" = "true" ]]; then
			echo "$body"`date` | mail -s "$header" $email; 
		fi
		exit $rc
	else
		echoi $i "done ($elapsed seconds)"
	fi

}

etime()
{
	# Returns elapsed time in seconds
	# Accepts: $prev, previous time 
	# Returns: difference between now and $prev
	
	now=`date +%s%N`
	prev=$1
	elapsed=`echo "scale=2; ($now - $prev) / 1000000000" | bc`
	echo $elapsed
}

exists_table_psql()
{
	#############################################################
	# Uses postgres psql command to check if table $t exists in 
	# schema $s of database $d
	# Returns 't' if table exists, else 'f'
	#
	# Usage:
	# exists_table_psql -u [user] -d [db] -s [schema] -t [table]
	#############################################################
	
	# Get parameters
	while [ "$1" != "" ]; do
		case $1 in
			-u )			shift
							user=$1
							;;
			-d )			shift
							db=$1
							;;
			-s )			shift
							schema=$1
							;;
			-t )			shift
							table=$1	
							;;
		esac
		shift
	done	
	
	sql_table_exists="SELECT EXISTS ( SELECT table_name FROM information_schema.tables WHERE table_name='$table' AND table_schema='$schema') AS exists_table"
	table_exists=`psql -U $user -d $db -lqt -c "$sql_table_exists" | tr -d '[[:space:]]'`
	echo $table_exists
}

exists_schema_psql()
{
	#############################################################
	# Uses postgres psql command to check if schema $s exists in 
	# database $d
	# Returns 't' if schema exists, else 'f'
	#
	# Usage:
	# exists_schema_psql -u [user] -d [db] -s [schema]
	#############################################################
	
	# Get parameters
	while [ "$1" != "" ]; do
		case $1 in
			-u )			shift
							user=$1
							;;
			-d )			shift
							db=$1
							;;
			-s )			shift
							schema=$1
							;;
		esac
		shift
	done	
	
	sql_schema_exists="SELECT EXISTS ( SELECT schema_name FROM information_schema.schemata WHERE schema_name='$schema' ) AS exists_schema"
	schema_exists=`psql -U $user -d $db -lqt -c "$sql_schema_exists" | tr -d '[[:space:]]'`
	echo $schema_exists
}

exists_index_psql()
{
	#############################################################
	# Uses postgres psql command to check if index $i exists in 
	# schema $s of database $d
	# Returns 't' if schema exists, else 'f'
	#
	# Usage:
	# exists_schema_psql -u [user] -d [db] -s [schema] -i [index_name]
	#############################################################
	
	# Get parameters
	while [ "$1" != "" ]; do
		case $1 in
			-u )			shift
							user=$1
							;;
			-d )			shift
							db=$1
							;;
			-s )			shift
							schema=$1
							;;
			-i )			shift
							idx=$1
							;;
		esac
		shift
	done	
	
	sql_index_exists="SELECT EXISTS ( SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE c.relname = '$idx' AND n.nspname = '$schema' ) AS a"
	index_exists=`psql -U $user -d $db -lqt -c "$sql_index_exists" | tr -d '[[:space:]]'`
	echo $index_exists
}

exists_db_psql()
{
	# Uses psql command to check if postgres database $d exists
	# Returns 't' if db exists, else 'f'
	
	if ! psql -lqt | cut -d \| -f 1 | grep -qw $1; then
		echo 'f'
	else
		echo 't'
	fi
}

trim() {
	##########################################
	# Trims leading and trailing whitespace
	##########################################

    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   
    echo -n "$var"
}
