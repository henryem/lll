

for k in 2
do
    for n in 4 8 16 32 64
    do
        for m in 2 8 32 128
        do
	    echo "k=$k n=$n m=$m"
            ./run ./Applications/KsatTests_solution.jl -s "RandomWalkKsatSolver(0.5)" -d "RandomKsatGenerator($k,$n,$m)" -g
        done
    done
done

