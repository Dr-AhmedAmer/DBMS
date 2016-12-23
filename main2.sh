main_dir="/usr/local/bash_dbms"
users_file="/usr/local/bash_dbms/users_file"



# function table_insert {




# }


 function check_headers_datatype  {

 		local insert_statment=$(echo $* | awk 'BEGIN {FS = " "} { for ( i = 1;i <= NF;i++ ) { if (i = NF) print $i }  } ')
		local temp_headers=$(echo $insert_statment | awk 'BEGIN {FS = "("} {print $2}')
		local headers=$(echo $temp_headers | awk 'BEGIN {FS = ")"} {print $1}')
 		local data_type=$(echo $headers | awk 'BEGIN{ FS = "," } {print $0}' |awk 'BEGIN{ FS = "*" } {for(i=1;i<=NF;i++) if(i=2) print $i}' )
 		echo $data_type



}





function table_headers_insert { #inserting table headers

	local insert_statment=$(echo $* | awk 'BEGIN {FS = " "} { for ( i = 1;i <= NF;i++ ) { if (i = NF) print $i }  } ')
	local temp_headers=$(echo $insert_statment | awk 'BEGIN {FS = "("} {print $2}')
	local headers=$(echo $temp_headers | awk 'BEGIN {FS = ")"} {print $1}')
	echo $headers

}


function check_format { # checks for (.... ....,..... ...,...... ....) fromat

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


function process_command { #processes commands and redirects workflow according 

	if [[ "$1" == "create" ]];then
		creator $*
	fi

	if [[ "$1" == "use" ]];then

		use $*
	fi

	if [[ "$1" == "check" ]];then

		check_place
	fi

	if [[ "$1" == "insert" ]] && [[ "$2" == "into" ]];then

		table_insert $*
	fi

	if [[ "$1" == "show" ]];then

		show $*
	fi

	if [[ "$1" == "remove" ]];then

		remove $*
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


function check_place { # for internal testing 

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
	ls -l $(pwd) | awk 'BEGIN{FS=" "}{if($0!="")print $9}'
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


function use { #changes working directory to the selected database dir 

	if test -e "$main_dir"/""$2"" ;then

		cd "$main_dir"/""$2""
		sleep 0.01
		echo -e "\033[33;34m Database changed to $2"
		echo -en "\e[0m"

	else
		echo database not exits
	fi
}



function creator {  #recieves any create command then redirects 

	if [[ "$2" == "table" ]];then
		table_creator $*
		elif [[ "$2" == "database" ]]; then
		 	database_creator $*
	fi
}

function table_creator {     #checks if user is assigned to database and creates a new file for every table

	local code1=$(check_place)
	local check
	if [[ $code1 == "$main_dir" ]]; then

		echo 'You must select database first'
	else
		check=$(check_format $*)
		local table="$(pwd)"/"$3" 

		if [[ check -eq 1 ]]; then
			if [ ! -f  $table ]; then
				check=$(check_headers_datatype $*)
				echo $check
				create=$(table_headers_insert $* > $3)
				sleep .01
				echo -e "\033[33;34m table $3 created"
				echo -en "\e[0m"
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


function database_creator { #checks if there is adirectory already matching the to be created database , creates new dir for every DB

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




function cmd_loop {  #command prompt for input

	clear
	echo Please Enter commands:
	local cmd_raw=$(get_command) 

	while [[ $cmd_raw != "exit" ]]  ; do	
		process_command $cmd_raw
		cmd_raw=$(get_command)
	done
}

function get_command { #get command from user

	local input
	read input

	echo $input | awk 'BEGIN{FS = " "}{ for(i = 1; i <= NF; i++) { print $i; } }'		

}




function create_user { #creates new user and adds his/her login info to users_file

	echo Please Enter login name :
	read login_name
	echo Please Enter password :
	read password
	echo "$login_name:$password">$users_file
	cd "$main_dir"
}

function login {
	clear
	echo Please Enter login name :
	read login_name
	echo Please Enter password :
	read password
	if awk 'BEGIN{FS=":"}{if($1=="'"$login_name"'") print $1}' $users_file | grep $login_name >/dev/null &&
	awk 'BEGIN{FS=":"}{if($2=="'"$password"'") print $2}' $users_file | grep $password >/dev/null ; then
	echo "You are now logged in as $login_name"
	cd "$main_dir"
	sleep 0.01
	cmd_loop
	else
	login
	fi	
}

function first_login {    #check if main dir is present and redirects user to login or create user according to result
	
	if [[ ! -e $main_dir ]];then  
		initialize_env
		echo You have to creat a root user:
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
