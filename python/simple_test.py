#/usr/bin/env python
from mpi4py import MPI
me = MPI.COMM_WORLD.Get_rank()
nproc = MPI.COMM_WORLD.Get_size()
print me, nproc
