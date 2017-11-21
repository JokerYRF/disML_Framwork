#!/bin/bash
# $1 is the number of PSs
# $2 is the number of workers
# $3 is the optimizer of model
# $4 is the targted_loss of model
# $5 is the tensorflow port
# $6 is the ml_model
# $7 batch size
# ps.sh run in ssd42

get_ps_conf(){
    ps=""
    for(( i=42; i > 42-$1; i-- ))
    do
        if [ $i -lt 10 ]
        then
            ps="$ps,ssd0$i:"$2
        else
            ps="$ps,ssd$i:"$2
        fi
    done
        ps=${ps:1}
};

get_worker_conf(){
    worker=""
    for(( i=42-$1; i > 42-$1-$2; i-- ))
    do
        if [ $i -lt 10 ]
        then
            worker="$worker,ssd0$i:"$3
        else
            worker="$worker,ssd$i:"$3
        fi
    done
    worker=${worker:1}
};

for(( i=0; i<$2; i++ ))
do
{
    echo "0">temp$i
}
done

echo "release port occpied!"
kill_cluster_pid.sh 6 42 $5

get_ps_conf $1 $5
echo $ps
get_worker_conf $1 $2 $5
echo $worker

for(( i=42; i>42-$1-$2; i-- ))
do
{
    if [ $i == 42 ]
    then
        python /root/code/disML_Framwork/disML_Framwork.py $ps $worker --job_name=ps --task_index=0
    else
        ip=""
        if [ $i -lt 10 ]
        then
            ip="ssd0"$i
        else
            ip="ssd"$i
        fi
        #ssh ssd$i "source activate tensorflow"
        n=`expr 42 - $1`
        if [ $i -gt $n ]
        then
            index=`expr 42 - $i`
            ssh $ip python /root/code/disML_Framwork/disML_Framwork.py $ps $worker --job_name=ps --task_index=$index
        else
            index=`expr 42 - $1 - $i`
            if [ $index != 0 ]
            then
                sleep 0.5
            fi
            ssh $ip python /root/code/disML_Framwork/disML_Framwork.py $ps $worker --job_name=worker --task_index=$index --targeted_loss=$4 --ML_model=$6 --optimizer=$3 --n_intra_threads=$7 --Batch_size=$8 --num_Features=$9>> /root/code/$index".temp"
            echo "worker"$index" complated"
            echo "1">temp$index
        fi
    fi
}&
done

while true
do
    flag=0
    for(( i=0; i<$2; i++ ))
    do
    {
        tem=`cat temp$i`
        flag=`expr $tem + $flag`
    }
    done
    if [ $flag == $2 ]
    then
        kill_cluster_pid.sh 16 42 $5
        break
    fi
done
rm -f temp*
rm -f /root/code/*.temp
echo "work done"


