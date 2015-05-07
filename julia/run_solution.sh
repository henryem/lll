

for k in 16
do
    for m in 3000
    do
	echo "k=$k m=$m"
        for n in 256
        do
            ./run ./Applications/KsatTests_solution.jl -s "RandomWalkKsatSolver(0.5)" -d "RandomKsatGenerator($k,$n,$m)" -g
        done
    done
done

