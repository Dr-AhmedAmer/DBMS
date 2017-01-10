#!/usr/bin/env bash
main_dir="/usr/local/bash_dbms"
users_file="/usr/local/bash_dbms/users_file"
p_key=""


# function uodate_row 
# {
# local re='^[0-9]+$'
# local line_num
# typeset -i line_num
# line_num=$(wc -l < $5)
# 	if [[ -f $5 ]];then
# 		if [[ $3 =~ $re ]] && [[ $3 -le $line_num ]];then
# 			if [[ $3 -ne 1 ]];then
# 				sed -i "$3 d" $5
# 				sed -i "$3 d" $5.index
# 				echo "row $3 deleted"
# 			else
# 				echo "cannot delete table header"
# 			fi
# 		else
# 			echo "non valid number"
# 		fi
# 	else
# 		echo "No table with this name"
# 	fi
# }


function validate_unique_primary_key
{
	local insert_statment=$(echo $* | awk 'BEGIN {FS = " "} { for ( i = 1;i <= NF;i++ ) { if (i = NF) print $i }  } ')
	local temp_values=$(echo $insert_statment | awk 'BEGIN {FS = "("} {print $2}')
	local raw_values=$(echo $temp_values | awk 'BEGIN {FS = ")"} {print $1}')
	local values=($(echo $raw_values | awk 'BEGIN {FS=","}{for(i=1;i<=NF;i++) print $i}'))
	local key=$(cat $4.index | awk 'BEGIN{FS=":"} {print $1}')
	local key_column_values=$(select_column $1 $key $3 $4)
	typeset -i p_key_index
	local p_key_index=$(cat $4.index | awk 'BEGIN{FS=":"} {print $2}')
	echo $key_column_values | grep ${values[$p_key_index]}
	if [[  $? -eq 0 ]];then
		echo "non unique"
	else
		echo "unique"
	fi	

}

#uses global var p_key to create table_name.index 
function set_primary_key
{
	local columns=($(head -1 $3 |awk 'BEGIN{FS=",";OFS=":"}{$1=$1; print $0}'| awk 'BEGIN{FS=":"}{for(i=1;i<=NF;i++) if(i%2) print $i}'))
	declare -A MYMAP
	local iterator
	typeset -i iterator
	typeset -i p_key_index
	iterator=0
	for column in "${columns[@]}"
	do
		if [[ $column == $p_key ]];then
			p_key_index=$iterator
		fi
		iterator=$iterator+1
	done
	echo "$p_key:$p_key_index" > $3.index

}

function choose_primary_key
{
	local flag=0
	local headers=($(get_headers $*))
	headers=($(echo $headers |awk 'BEGIN{FS=",";OFS=":"}{$1=$1; print $0}'| awk 'BEGIN{FS=":"}{for(i=1;i<=NF;i++) if(i%2) print $i}')) 
	echo "select primary key"
	read primary_key
	for key in ${headers[@]}
	do
		if [[ $key == $primary_key ]];then #validates primary key is in table headers
			flag=1
		fi
	done

	if [[ flag -eq 1 ]];then
		echo "primary_key set sucess"
		p_key=$primary_key  # set global var p_key to be used for .index creation
	else
		echo "non-valid primary_key"
	fi

	return $flag

}



function delete_row 
{
local re='^[0-9]+$'
local line_num
typeset -i line_num
line_num=$(wc -l < $5)
	if [[ -f $5 ]];then
		if [[ $3 =~ $re ]] && [[ $3 -le $line_num ]];then
			if [[ $3 -ne 1 ]];then
				sed -i "$3 d" $5
				sed -i "$3 d" $5.index
				echo "row $3 deleted"
			else
				echo "cannot delete table header"
			fi
		else
			echo "non valid number"
		fi
	else
		echo "No table with this name"
	fi
}
function select_column {
	local OFS='BEGIN{OFS=" "}'
	local result=''
	local column_to_select
	column_to_select=$2
	local columns=($(head -1 $4 |awk 'BEGIN{FS=",";OFS=":"}{$1=$1; print $0}'| awk 'BEGIN{FS=":"}{for(i=1;i<=NF;i++) if(i%2) print $i}'))
	local select_columns=($(echo $2|awk 'BEGIN{FS=","}{for(i=1;i<=NF;i++) print $i}'))
	declare -A MYMAP
	typeset -i ind
	typeset -i ind_awk
	ind_awk=0
	ind=0
	for column in "${columns[@]}"
	do
		MYMAP[$column]=$ind
		ind=$ind+1
	done

	for var in "${select_columns[@]}"
	do
		ind_awk=MYMAP[$var]
		ind_awk=$ind_awk+1
		result="$result\$$ind_awk\"  \" "
	done
		if [[ $5 == "emod" ]];then
			echo -e "\n"
	 		gawk -c -F',' "$(echo $OFS){\$1=\$1; print $(echo $result)}" $4  |column -t -s" " | cat -n
	 	else
	 		echo -e "\n"
	 		gawk -c -F',' "$(echo $OFS){\$1=\$1; print $(echo $result)}" $4  |column -t -s" " 
	 fi
	
}

function select_all {

	if  [[ "$3" == "from" ]] ; then

		if [[ -f $4 ]];then
			
			if [[ $5 == "emod" ]];then
				echo -e "\n"
				column -t -s "," $4 | cat -n
				echo -e "\n"
			else
				echo -e "\n"
				column -t -s "," $4
				echo -e "\n"
			fi

		else
			echo No table with this name

		fi

	fi
}

function valid_insert_datatype {
	local insert_statment=$(echo $* | awk 'BEGIN {FS = " "} { for ( i = 1;i <= NF;i++ ) { if (i = NF) print $i }  } ')
	local temp_values=$(echo $insert_statment | awk 'BEGIN {FS = "("} {print $2}')
	local raw_values=$(echo $temp_values | awk 'BEGIN {FS = ")"} {print $1}')
	local values=($(echo $raw_values | awk 'BEGIN {FS=","}{for(i=1;i<=NF;i++) print $i}'))
	local data_types=($(get_colum_datatypes $4))
	local re='^[0-9]+$'
	local flag
	local i
	i=0;
	flag=0;

	for value in "${values[@]}"
	do
		if [[ "${data_types[$i]}" == "int" ]];then
			if [[ $value =~ $re ]];then
				flag=1;
			else
				flag=0;
				break;
			fi
		else
			if ! [[ $value =~ $re  ]];then
				flag=1;
			else
				flag=0;
				break;

			fi
		fi
		i=$i+1;
	done

	echo $flag
	 

}


function get_colum_datatypes {

	 local data_types=$(head -1 $1 | awk 'BEGIN{FS=","; OFS=":"}{$1=$1 ;print $0}'|awk 'BEGIN{FS=":"}{for(i=1;i<=NF;i++) if(!(i%2)) print $i }')
	 read -a data_array <<< $data_types
	 echo $data_types

}

function get_colum_count { #get numbers of column to check against during insertion
	local index
	index=0;
	local count_string=$(head -n1 $1 | awk 'BEGIN{FS=","}{print NF}')
	read -a count_array <<<$count_string
	echo ${count_array[@]}
}

function check_insert_syntax { #check insert synatx "insert into table table_name ()"

	if [[ "$2" == "into" ]] && [[ "$3" == "table" ]];then
		table_insert $*;
	else
		echo "syntax error";
	fi


}


 function table_insert {   
 	local check_path=$(check_place)      #get number of colums
 	local check_form=$(check_format $*)
 	local check_num_colum=$(get_colum_count $4)
 	local insert_statment=$(echo $* | awk 'BEGIN {FS = " "} { for ( i = 1;i <= NF;i++ ) { if (i = NF) print $i }  } ') #get number of values
	local temp_values=$(echo $insert_statment | awk 'BEGIN {FS = "("} {print $2}')
	local raw_values=$(echo $temp_values | awk 'BEGIN {FS = ")"} {print $1}')
	local values=$(echo $raw_values | awk 'BEGIN {FS=","}{print NF}')
	read -a values_array <<<$values
	local values_count=$(echo ${values_array[@]})
	local data_types=$(get_colum_datatypes $4)
	local valid_insertion=$(valid_insert_datatype $*)
	local unique_p_key

 	if [[ "$check_path" == "$main_dir" ]];then #check if databse is selected
 		echo choose db first;
 	else

 		if [[ -f $4 ]];then #check if table is present

 			if [[ check_form -eq 1 ]];then #check format (...,...,..)

 				if [[ $check_num_colum -eq $values_count ]];then #check number of colums 
 					
 					if [[ $valid_insertion -eq 1 ]];then
 						unique_p_key=$(validate_unique_primary_key $*)
 						if [[ $unique_p_key == "unique" ]];then
 							echo $raw_values >> $4;
 							echo insert data sucess
 						else
 							echo "insert unique primary_key"

 						fi
 					else
 						echo incompatible data types
 					fi
 				else
 					echo wrong number of colums
 				fi
 			else
 				echo check format;
 			fi
 		else
 			echo no table with this name;
 		fi
 	fi



 }



#checks datatypes during table first creation
 function check_headers_datatype  { 
 		declare -a valid=('int' 'char');
 		local data_types=''
 		local i
 		local k
 		local index
 		index=0
 		local insert_statment=$(echo $* | awk 'BEGIN {FS = " "} { for ( i = 1;i <= NF;i++ ) { if (i = NF) print $i }  } ')
		local temp_headers=$(echo $insert_statment | awk 'BEGIN {FS = "("} {print $2}')
		local headers=$(echo $temp_headers | awk 'BEGIN {FS = ")"} {print $1}')
 		local temp_data_type=$(echo "$headers" |awk -F "," 'BEGIN{ OFS=":"; } {$1=$1; print $0 }')
 		data_types=$(echo $temp_data_type | awk -F ":" '{for(i=1;i<=NF;i++) if (!(i%2)) print$i }')
 		read -a array <<<$data_types
		local flag=non-valid

 		for i in "${array[@]}"
 		do
 			flag=non-valid
 			for k in "${valid[@]}"
 			do
 				if [[ "$k" == "$i"  ]];then
 					flag=valid
 					break
 				fi
 			done
 		done
 		echo $flag

}

#concat table headers
function set_headers { 
	local insert_statment=$(echo $* | awk 'BEGIN {FS = " "} { for ( i = 1;i <= NF;i++ ) { if (i = NF) print $i }  } ')
	local temp_headers=$(echo $insert_statment | awk 'BEGIN {FS = "("} {print $2}')
	local headers=$(echo $temp_headers | awk 'BEGIN {FS = ")"} {print $1}')
	echo $headers >$3


}
#gets table header
function get_headers { 
	local insert_statment=$(echo $* | awk 'BEGIN {FS = " "} { for ( i = 1;i <= NF;i++ ) { if (i = NF) print $i }  } ')
	local temp_headers=$(echo $insert_statment | awk 'BEGIN {FS = "("} {print $2}')
	local headers=$(echo $temp_headers | awk 'BEGIN {FS = ")"} {print $1}')
	echo $headers


}

# checks for (.... ....,..... ...,...... ....) fromat
function check_format {

	local insert_statment=$(echo $* | awk 'BEGIN {FS = " "} { for ( i = 1;i <= NF;i++ ) { if (i = NF) print $i }  } ')
	local first_insert_instance=$(echo $insert_statment | awk 'BEGIN {FS = ","} { for ( i = 1;i <= 1;i++ ) { if (i = 1) print $i }  } ')
	local first_char=$(echo $first_insert_instance | awk 'BEGIN {FS = ""} { for ( i = 1;i <= 1;i++ ) { if (i = 1) print $i }  } ')
	local input=$*
	local i=$((${#input}-1))
	local last_char=$(echo "${input:$i:1}")
	local flag=0;

	if [[ "$(echo $first_char)" == "(" ]] && [[ "$(echo $last_char)" == ")" ]];then
		flag=1
		echo $flag
	else
		echo $flag 
	fi

}

#processes commands and redirects workflow according 
function process_command { 

	if [[ "$1" == "create" ]];then
		creator $*
	fi

	if [[ "$1" == "use" ]];then
		use $*
	fi

	if [[ "$1" == "check" ]];then
		check_place
	fi


	if [[ "$1" == "show" ]];then
		show $*
	fi

	if [[ "$1" == "remove" ]];then
		remove $*
	fi


	if [[ "$1" == "insert" ]];then

		check_insert_syntax $*
	fi

	if [[ "$1" == "select" ]] && [[ "$2" == "all" ]];then

		select_all $*
	fi

	if [[ "$1" == "select" ]] && [[ "$2" != "all" ]];then

		select_column $*
	fi

	if [[ "$1" == "clear" ]];then

		clear
	fi
	if [[ "$1" == "delete" ]] && [[ "$2" == "row" ]] ;then
		delete_row $*
	fi



}

function remove {
	if [[ "$2" == "table" ]];then
		remove_table $*
		elif [[ "$2" == "database" ]]; then
		 	remove_database $*
	fi

}

function remove_table {
	if [[ $(pwd) != $main_dir ]];then
		if [ -f $3 ];then
			rm $3
			rm $3.index
			echo -e "\033[33;31m tabel $3 removed !"
			echo -en "\e[0m"	
		else
			echo -e "\033[33;31m No tables with this name"
			echo -en "\e[0m"	
		fi
	else
		echo -e "\033[33;31m Select a database first"
		echo -e "\033[33;31m You can use show databases to list availabe databases"
    	echo -en "\e[0m" 
	fi
}

# for internal testing 
function check_place { 
	echo $(pwd)
}

function show {
	if [[ "$2" == "tables" ]];then
		show_tables $*
		elif [[ "$2" == "databases" ]]; then
		 	show_databases $*
	fi

}

function show_tables {
	if [[ $(pwd) != $main_dir ]];then
    	ls -l $(pwd) | awk 'BEGIN{FS=" "}{if($0!="")print $9}'| grep -v .index
	else
		echo -e "\033[33;31m Select a database first"
		echo -e "\033[33;31m You can use show databases to list availabe databases"
    	echo -en "\e[0m" 
	fi
}

function show_databases {
	subdircount=`find "$main_dir"/"" -maxdepth 1 -type d | wc -l`
	if [ $subdircount -eq 1 ];then
        echo -e "\033[33;31m No Databases Found"
        echo -en "\e[0m"
	else
        ls -dl "$main_dir"/*/"" | awk 'BEGIN{FS=" "}{ print $9}' | 
	    awk 'BEGIN{FS="/"}{ print $5 }'
	fi
}

#changes working directory to the selected database dir 
function use {
	if test -e "$main_dir"/""$2"" && [[ "$2" != "" ]] ;then
		cd "$main_dir"/""$2""
		sleep 0.01
		echo -e "\033[33;34m Database changed to $2"
		echo -en "\e[0m"
	else
		echo database not exits
	fi
}

#recieves any create command then redirects 
function creator { 
	if [[ "$2" == "table" ]];then
		table_creator $*
		elif [[ "$2" == "database" ]]; then
		 	database_creator $*
	fi
}

#checks if user is assigned to database and creates a new file for every table
function table_creator {     
	local primary_key_status
	local code1=$(check_place)
	local check
	local check_two
	if [[ $code1 == "$main_dir" ]]; then
		echo 'You must select database first'
	else
		check=$(check_format $*)
		local table="$(pwd)"/"$3" 
		if [[ check -eq 1 ]]; then
			if [ ! -f  $table ]; then
				check_two=$(check_headers_datatype $*)
				if [[ $check_two == "valid" ]];then
					choose_primary_key $* 
					if [[ $? == 1 ]];then
						$(touch $3)	
						create=$(set_headers $* )
						sleep .01
						echo -e "\033[33;34m table $3 created"
						echo -en "\e[0m"
						set_primary_key $*
					else
						echo "primary_key set failed"
						echo "failed to create table $3"
					fi
					
				else
					echo "Non-valid data_types"
				fi
			else
				echo -e "\033[33;31m table already exits"
				echo -en "\e[0m" 
			fi 
		else
			echo -e "\033[33;32m syntax error"
			echo -en "\e[0m" 
		fi
		sleep 0.01 
	fi
}

#checks if there is adirectory already matching the to be created database , creates new dir for every DB
function database_creator { 
	local raw_database_name="${*: -1}"
	local database_path
	local response
	database_path="$main_dir"/"$raw_database_name"
	if [ -d "$database_path" ];then
		echo database already exits
	else
	sleep 0.01
	$(mkdir $database_path) 
	echo "$raw_database_name created"
	echo  Type use database_name to change working database
	fi
}

#command prompt for input
function cmd_loop { 
	clear
	echo Please Enter commands:
	local cmd_raw=$(get_command) 
	while [[ $cmd_raw != "exit" ]]  ; do	
		process_command $cmd_raw
		cmd_raw=$(get_command)
	done
}

#get command from user
function get_command {
	local input
	read input
	echo $input | awk 'BEGIN{FS = " "}{ for(i = 1; i <= NF; i++) { print $i; } }'		
}

#creates new user and adds his/her login info to users_file
function create_user {
    local user=''
    local password=''
    user=$(zenity --title "create new user" --entry --text "enter user name:")
    password=$(zenity --title "create new user" --entry --text "enter user password:")

    echo "$user:$password">$users_file
	cd "$main_dir"
}

function login {
	clear
    login_name=$(zenity --title "user login" --entry --text "enter user name:")
    password=$(zenity --title "user login" --entry --text "enter user password:")
	if awk 'BEGIN{FS=":"}{if($1=="'"$login_name"'") print $1}' $users_file | grep $login_name >/dev/null &&
	awk 'BEGIN{FS=":"}{if($2=="'"$password"'") print $2}' $users_file | grep $password >/dev/null ; then
    zenity --info --text "you are now logged in" 
	cd "$main_dir"
	sleep 0.01
	cmd_loop
	else
	login
	fi	
}

#check if main dir is present and redirects user to login or create user according to result
function first_login {   
	if [[ ! -e $main_dir ]];then  
		initialize_env
        gdialog --msgbox "you have to create user" 5 20
		sleep 1
		clear
		create_user
		cmd_loop
	else
		login
	fi
}

function initialize_env {
	if [[ ! -e $main_dir ]];then  
		sudo mkdir -p $main_dir
		sudo touch $users_file
		sudo chmod 555 $users_file 
		sudo chmod 555 $main_dir
		cd "$main_dir"
	fi
}

first_login

