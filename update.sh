#!/bin/bash
# enter your credentials here and in login.properties:
APPLEVENDORID="your-vendor-id"
MYSQLUSER="your-mysql-username"
MYSQLPASSWORD="your-mysql-password"
# set this to a directory where you want the update.log placed
# the default is fine for OSX; Linux/*BSD users might want to
# set this to /var/log or something else
LOGDIR="$HOME/Library/Logs"
# set to YES if you have OS X-style `date' command (supports `-v' flag)
OSXDATE="YES"
# set to YES if your mysql command requires the `--local-infile' flag
# (usually true for Linux/*BSD;  you'll know this if you get the error
# `The used command is not allowed with this MySQL version'
# NOTE: you must also enable this in your mysql server config;
# edit the file /etc/my.cnf, and in the [mysqld] section, add
#      local-infile=1
# then restart mysqld
#      /etc/init.d/mysqld restart
REQUIRES_LOCAL_INFILE="NO"

# ensure that mysql is in this PATH
export PATH=/bin:/usr/bin:/usr/local/bin

cd $(dirname $0)
if [[ -n $1 ]]; then         
	DATE="$1"
else
	if [ "$OSXDATE" = "YES" ]; then
		DATE=$(date -v -1d +%Y%m%d)
	else
		# thanks to:
		# http://www.masaokitamura.com/2009/02/17/how-to-get-yesterdays-date-using-bash-shell-scripting/
		DATE=$(date -d "1 day ago" +%Y%m%d)
	fi
fi
java Autoingestion login.properties $APPLEVENDORID Sales Daily Summary $DATE
FNAME="S_D_${APPLEVENDORID}_${DATE}.txt"
if [ -f "$FNAME.gz" ]; then
	gunzip "$FNAME.gz"
	mysql --user=$MYSQLUSER --password=$MYSQLPASSWORD --database=itunesconnect -e "delete from sales where BeginDate='$DATE' and EndDate='$DATE'"
	if [ "$REQUIRES_LOCAL_INFILE" = "YES" ]; then
		mysql --user=$MYSQLUSER --password=$MYSQLPASSWORD --database=itunesconnect --local-infile=1 -e "load data local infile '$FNAME' into table sales character set utf8 fields terminated by '\t' lines terminated by '\n' ignore 1 lines (Provider,ProviderCountry,SKU,Developer,Title,Version,ProductTypeIdentifier,Units,DeveloperProceeds,@BeginDate,@EndDate,CustomerCurrency,CountryCode,CurrencyOfProceeds,AppleIdentifier,CustomerPrice,PromoCode,ParentIdentifier,Subscription,Period) SET BeginDate=str_to_date(@BeginDate, '%m/%d/%Y'), EndDate=str_to_date(@EndDate, '%m/%d/%Y')"
	else
		mysql --user=$MYSQLUSER --password=$MYSQLPASSWORD --database=itunesconnect -e "load data local infile '$FNAME' into table sales character set utf8 fields terminated by '\t' lines terminated by '\n' ignore 1 lines (Provider,ProviderCountry,SKU,Developer,Title,Version,ProductTypeIdentifier,Units,DeveloperProceeds,@BeginDate,@EndDate,CustomerCurrency,CountryCode,CurrencyOfProceeds,AppleIdentifier,CustomerPrice,PromoCode,ParentIdentifier,Subscription,Period) SET BeginDate=str_to_date(@BeginDate, '%m/%d/%Y'), EndDate=str_to_date(@EndDate, '%m/%d/%Y')"
	fi
	rm $FNAME
	echo "$(date "+%Y-%m-%d %H:%M:%S"): $DATE imported" >> "$LOGDIR/update.log"
else
	echo "$(date "+%Y-%m-%d %H:%M:%S"): no file $FNAME.gz" >> "$LOGDIR/update.log"
fi
