"""Deterministic paired bootstrap and exact signed-rank permutation test."""
import hashlib
import math
import random

def bootstrap(values, key, *, seed, resamples):
    if not values:return None,None
    rng=random.Random(seed+int.from_bytes(hashlib.sha256(key.encode()).digest()[:8],'big'))
    n=len(values); samples=sorted(sum(values[rng.randrange(n)] for _ in range(n))/n for _ in range(resamples))
    def q(p):
        z=(len(samples)-1)*p;lo=math.floor(z);hi=math.ceil(z)
        return samples[lo]+(samples[hi]-samples[lo])*(z-lo)
    return q(.025),q(.975)

def wilcoxon(values):
    x=[v for v in values if v]; n=len(x)
    if not n:return 1.0
    order=sorted(enumerate(x),key=lambda pair:abs(pair[1])); rank2={};i=0
    while i<n:
        j=i+1
        while j<n and abs(order[j][1])==abs(order[i][1]):j+=1
        for k in range(i,j):rank2[order[k][0]]=i+1+j
        i=j
    counts={0:1}
    for rank in rank2.values():
        nxt=counts.copy()
        for value,count in counts.items():nxt[value+rank]=nxt.get(value+rank,0)+count
        counts=nxt
    observed=sum(rank2[i] for i,v in enumerate(x) if v>0)
    lo=sum(c for s,c in counts.items() if s<=observed);hi=sum(c for s,c in counts.items() if s>=observed)
    return min(1.0,2*min(lo,hi)/(2**n))

