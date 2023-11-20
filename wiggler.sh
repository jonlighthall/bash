echo "press Ctrl-C to exit"
step=1
range=$((2 * step + 1))
start=$((-1 * step))
while [ .true ]; do
    dx=$(($RANDOM % range + start))
    dy=$(($RANDOM % range + start))
    xdotool mousemove_relative -- dx dy
    echo -n "."
    sleep 2m
done
trap "echo ' $(sec2elap $SECONDS)'" EXIT
