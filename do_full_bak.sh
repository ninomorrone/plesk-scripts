#!/bin/bash

# definizioni  varianili
USER="admin"
PASS=`cat /etc/psa/.psa.shadow`
ODIR="bak-db" #folder temporanea per mysql
OWWW="domini"
SITI="/var/www/vhosts/" #path base plesk
DCUR=$PWD # folder corrente

#:<<REM
clear && echo " ---------- [ MySQL backup ] ----------"
rm -rf $ODIR $OWWW

# rm -f $ODIR.tar.gz
# rm -rf *.tar.gz

mysql -u $USER -p$PASS -e "show databases" \
    | grep -Ev 'Database|information_schema|performance_schema|mysql|psa|phpmyadmin|horde|apsc|roundcubemail' \
    | while read dbname;
do
  echo " ... dumping $dbname"
  mkdir -p $ODIR
  mysqldump -u $USER -p$PASS $dbname > ./$ODIR/$dbname.sql
done
echo " "
echo " ---------- [ Comprimo il backup ] ----------"
tar czf $ODIR.tar.gz $ODIR
rm -rf $ODIR
echo " "
echo "***********************************"
echo "***     Backup DB ok            ***"
echo "***********************************"
echo " "
#REM

mkdir -p $OWWW

mysql -u $USER -p$PASS -se "USE psa;select name,h.www_root as hfolder from domains as d inner join hosting as h on d.id = dom_id;" \
    | while read -r dominio hfolder;
do

        sitepath=${hfolder#"$SITI$dominio/"} # elimina l'url base dela percorso completo restituisce httpdocs o la cartella subdomain

        echo " ---------- [Backup  $dominio] ----------"

        cd $SITI # posizionamento nella cartella base di plesk

        if [ $sitepath == "httpdocs" ]
        then
                tar czf $DCUR/$OWWW/$dominio.tar.gz $dominio/$sitepath

        else
                # dominio=$(expr match "$dominio" '.*\.\(.*\..*\)') # elimina il III livello dal dominio
                topdominio=${dominio#*.}  # altro metodo per il III livello
                subsitepath=${hfolder#"$SITI$topdominio/"}
                tar czf $DCUR/$OWWW/$dominio.tar.gz $topdominio/$subsitepath
        fi

done

cd $DCUR # ritoro alla cartella iniziale
tar czf $OWWW.tar.gz $OWWW
rm -rf $OWWW

echo "***********************************"
echo "***     Backup DOMINI OK        ***"
echo "***********************************"