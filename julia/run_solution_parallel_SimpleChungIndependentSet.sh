

for k in 8
do
    for m in 880
    do
	echo "k=$k m=$m"
        for n in 32
        do
        	for run in {1..10}
        	do
            	./run ./Applications/KsatTests.jl -s "ParallelLllKsatSolver(SimpleChungIndependentSetFinder())" -d "RandomKsatGenerator($k,$n,$m)" -e 49 -l $run
        	done
        done
    done
done

