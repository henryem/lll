

for k in 8
do
    for m in 1080 1280
    do
	echo "k=$k m=$m"
        for n in 32
        do
            ./run ./Applications/KsatTests_solution.jl -s "RandomWalkKsatSolver(0.5)" -d "RandomKsatGenerator($k,$n,$m)" -g
        done
    done
done

