#!/bin/bash
# example usage: 
#   shetlv.sh cbb_conf etlv
# mix and match 'etlv' as needed  
#  (e)xtract 
#  (t)ransform
#  (l)oad
#  (v)iew 
# requires:  curl, pup, postgresql (with user as superuser)
# ETL(V) script
#   extract, transform, load, (preview)  
#   (curl) -> cat | pup | paste -> (psql) 
#          made with ❤️ 
# author: Patrick Ryan 2020
#
# todo: create interactive tool
# todo: add usage, validations
# todo: other db support
# todo: browser plugin -> config file -> sheltv.sh
#
### colors
RED='\033[0;31m';
YELLOW='\033[1;33m';
GREEN='\033[0;32m';
CYAN='\033[0;36m';
PURPLE='\033[0;35m';
NC='\033[0m'; # No Color

### config
datadir="data/";    # stores html, csv results
db="odds";          # postres db
contest=$1;         # table   (ex: cbb_conf)
html="$contest-latest.html";
csv="$contest-latest.csv";

### URL to extract
# (ex: draftkings cbb conference winner odds)
url="https://sportsbook.draftkings.com/leagues/basketball/3230960?category=team-futures&subcategory=conference-winner";
### see pup (https://github.com/ericchiang/pup) for html selectors (use dev tools to inspect elements)
selector="div.sportsbook-outcome-cell__body text{}";

# extract
#   (modify $url to fit)
if [[ $2 =~ "e" ]]; then
    echo -e "${CYAN}e${NC}xtract ${YELLOW}$contest${NC}";
    curl -s $url > $datadir$html;
fi
# transform    
#   (modify paste command to create good csv)
if [[ $2 =~ "t" ]]; then
    echo -e "${PURPLE}t${NC}ransform ${YELLOW}$contest${NC}";
    cat $datadir$html | pup $selector | paste -d, - - > $datadir$csv;
fi
# load
#   (modify schema to fit)
if [[ $2 =~ "l" ]]; then
    echo -e "${GREEN}l${NC}oad ${YELLOW}$contest${NC}";
    psql postgres -c "create database odds;";
    psql $db -c "create table $contest(id serial primary key, team text, american integer,ts timestamp);";
    psql $db -c "\copy $contest(team,american) from './data/$csv' delimiter ',' csv";
    psql $db -c "update $contest set ts = now();"
fi
# view (preview)
if [[ $2 =~ "v" ]]; then
    echo -e "${RED}v${NC}iew ${YELLOW}$contest${NC}"
    psql $db -c "select * from $contest limit 5;"
fi