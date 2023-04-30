step=1
range=$((2*step+1))
start=$((-1*step))
while [ .true ]; do
    dx=$(($RANDOM % range + start))
    dy=$(($RANDOM % range + start))
    xdotool mousemove_relative -- dx dy
    sleep 1s
done
