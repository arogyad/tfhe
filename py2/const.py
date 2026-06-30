import numpy as np

q = 2**64
p = 4
t = 2
delta = 2**62

n = 500
N = 512

l = 2
B = 1024
beta_bits = 10
# k = 1

sg_lwe = 2**(-15)
sg_rlwe = 2**(-25)


j_idx = np.arange(N, dtype=np.float64)
twst = np.exp(-1j * np.pi * j_idx / N) # numpy seems to run ftt for X^{n} - 1, but i need X^{n} + 1
itwst = np.exp(1j * np.pi * j_idx / N)