#! /bin/csh
########################
# EDA environment
########################

# SYNOPSYS #
# scl
export SNPSLMD_LICENSE_FILE=27000@ci-0
# syn
export DC_HOME=/data/eda_tool/syn/T-2022.03-SP2
PATH=$PATH:$DC_HOME/bin
alias dc="dc_shell"
# APR #
# FT
export FT_HOME=/data/eda_tool/FT/FT_Kili_25.1.1_HR1_251111
PATH=$PATH:$FT_HOME/bin/rhel6-64
if [[ `hostname` == "ylzb-r5-test2-flow" ]] ;then
    export GIGA_LICENSE_FILE=8293@123.60.32.51
else
    export GIGA_LICENSE_FILE=8293@192.168.0.8
fi
# LEAPR
export LEAPR_HOME=/data/eda_tool/LEAPR/leapr
PATH=$PATH:$LEAPR_HOME/bin/
export LEDA_LICENSE_FILE=9293@192.168.0.8

cd ../

# foreach dir (run logs output input scr dbs reports)
#     if (! -d $dir) then
#         mkdir $dir
#     endif
# end

rm -rf ./run/*
rm -rf ./logs/*
rm -rf ./dbs/*

cd ./run

#leapr -log ../logs/leapr.log  -files ../scr/flow.tcl
/data/eda_tool/LEAPR/leapr/bin/leapr -log /data/wskyp/logs/leapr.log -files ../scr/flow.tcl
