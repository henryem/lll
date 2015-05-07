

for k in 3 4 6 8 16
do
    for m in 512
    do
	echo "k=$k m=$m"
        for n in 4 8 16 32 64 128 256
        do
            ./run ./Applications/KsatTests_solution.jl -s "RandomWalkKsatSolver(0.5)" -d "RandomKsatGenerator($k,$n,$m)"
        done
    done
done

