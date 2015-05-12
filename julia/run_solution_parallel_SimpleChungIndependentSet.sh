

for n in 256
do
    for m in 8 32 128 512
    do
        for k in 2 3 4 8 16
        do
        echo "k=$k m=$m n=$n"
        	for run in 1
        	do
            	./run ./Applications/KsatTests.jl -s "ParallelLllKsatSolver(SimpleChungIndependentSetFinder())" -d "RandomKsatGenerator($k,$n,$m)" -e 77 -l $run
        	done
        done
    done
done

