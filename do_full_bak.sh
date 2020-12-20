#!/bin/bash

# definizioni  varianili
USER="admin"
PASS=`cat /etc/psa/.psa.shadow`
ODIR="bak-db" #folder temporanea per mysql
OWWW="domini"
SITI="/var/www/vhosts/" #path base plesk
DCUR=$PWD # folder corrente
LINE="----------------------------------------"

#:<<REM
clear
echo "[ MySQL backup ]"
echo $LINE

rm -rf $ODIR $OWWW bak

mysql -u $USER -p$PASS -e "show databases" \
    | grep -Ev 'Database|information_schema|performance_schema|mysql|psa|phpmyadmin|horde|apsc|roundcubemail' \
    | while read dbname;
do
  echo " ... dumping $dbname"
  mkdir -p $ODIR
  mysqldump -u $USER -p$PASS $dbname > ./$ODIR/$dbname.sql
done
tar czf $ODIR.tar.gz $ODIR
rm -rf $ODIR
echo $LINE
echo "[ MySQL backup ] OK"
echo $LINE
echo " "
#REM

mkdir -p $OWWW

echo "[ BACKUPS SITI ]"
echo $LINE

mysql -u $USER -p$PASS -se "USE psa;select name,h.www_root as hfolder from domains as d inner join hosting as h on d.id = dom_id;" \
    | while read -r dominio hfolder;
do

        sitepath=${hfolder#"$SITI$dominio/"} # elimina l'url base dela percorso completo restituisce httpdocs o la cartella subdomain

        echo " ... $dominio"

        cd $SITI # posizionamento nella cartella base di plesk

        if [ $sitepath == "httpdocs" ]
        then
		cd $dominio/$sitepath
                # tar czf $DCUR/$OWWW/$dominio.tar.gz $dominio/$sitepath

        else
                # dominio=$(expr match "$dominio" '.*\.\(.*\..*\)') # elimina il III livello dal dominio
                topdominio=${dominio#*.}  # altro metodo per il III livello
                subsitepath=${hfolder#"$SITI$topdominio/"}
		cd $topdominio/$subsitepath
                #tar czf $DCUR/$OWWW/$dominio.tar.gz $topdominio/$subsitepath
        fi
	
	tar czf $DCUR/$OWWW/$dominio.tar.gz *

done

cd $DCUR # ritoro alla cartella iniziale
tar czf $OWWW.tar.gz $OWWW
rm -rf $OWWW

mkdir -p bak
mv *.tar.gz bak


echo $LINE
echo "[ SITI ] ok"
echo $LINE
echo " "
