#ifndef MTLSDCA_SDCA_MT19937AR_H_
#define MTLSDCA_SDCA_MT19937AR_H_

/*
 * Downloaded from:
 * http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/MT2002/CODES/mt19937ar.c
 *
   A C-program for MT19937, with initialization improved 2002/1/26.
   Coded by Takuji Nishimura and Makoto Matsumoto.

   Before using, initialize the state by using init_genrand(seed)
   or init_by_array(init_key, key_length).

   Copyright (C) 1997 - 2002, Makoto Matsumoto and Takuji Nishimura,
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

     1. Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.

     2. Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution.

     3. The names of its contributors may not be used to endorse or promote
        products derived from this software without specific prior written
        permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


   Any feedback is very welcome.
   http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/emt.html
   email: m-mat @ math.sci.hiroshima-u.ac.jp (remove space)
*/

#include <stddef.h>

namespace sdca {

/* Period parameters */
#define MT19937AR_N 624
#define MT19937AR_M 397
#define MT19937AR_MATRIX_A 0x9908b0dfUL   /* constant vector a */
#define MT19937AR_UPPER_MASK 0x80000000UL /* most significant w-r bits */
#define MT19937AR_LOWER_MASK 0x7fffffffUL /* least significant r bits */

static unsigned long mt[MT19937AR_N]; /* the array for the state vector  */
static int mti=MT19937AR_N+1; /* mti==N+1 means mt[N] is not initialized */

/* initializes mt[N] with a seed */
void init_genrand(unsigned long s)
{
    mt[0]= s & 0xffffffffUL;
    for (mti=1; mti<MT19937AR_N; mti++) {
        mt[mti] =
            (1812433253UL * (mt[mti-1] ^ (mt[mti-1] >> 30)) + (unsigned long) mti);
        /* See Knuth TAOCP Vol2. 3rd Ed. P.106 for multiplier. */
        /* In the previous versions, MSBs of the seed affect   */
        /* only MSBs of the array mt[].                        */
        /* 2002/01/09 modified by Makoto Matsumoto             */
        mt[mti] &= 0xffffffffUL;
        /* for >32 bit machines */
    }
}

/* initialize by an array with array-length */
/* init_key is the array for initializing keys */
/* key_length is its length */
/* slight change for C++, 2004/2/26 */
void init_by_array(unsigned long init_key[], unsigned long key_length)
{
    unsigned long i, j, k;
    init_genrand(19650218UL);
    i=1; j=0;
    k = (MT19937AR_N>key_length ? MT19937AR_N : key_length);
    for (; k; k--) {
        mt[i] = (mt[i] ^ ((mt[i-1] ^ (mt[i-1] >> 30)) * 1664525UL))
          + init_key[j] + j; /* non linear */
        mt[i] &= 0xffffffffUL; /* for WORDSIZE > 32 machines */
        i++; j++;
        if (i>=MT19937AR_N) { mt[0] = mt[MT19937AR_N-1]; i=1; }
        if (j>=key_length) j=0;
    }
    for (k=MT19937AR_N-1; k; k--) {
        mt[i] = (mt[i] ^ ((mt[i-1] ^ (mt[i-1] >> 30)) * 1566083941UL))
          - i; /* non linear */
        mt[i] &= 0xffffffffUL; /* for WORDSIZE > 32 machines */
        i++;
        if (i>=MT19937AR_N) { mt[0] = mt[MT19937AR_N-1]; i=1; }
    }

    mt[0] = 0x80000000UL; /* MSB is 1; assuring non-zero initial array */
}

/* generates a random number on [0,0xffffffff]-interval */
unsigned long genrand_int32(void)
{
    unsigned long y;
    static unsigned long mag01[2]={0x0UL, MT19937AR_MATRIX_A};
    /* mag01[x] = x * MATRIX_A  for x=0,1 */

    if (mti >= MT19937AR_N) { /* generate N words at one time */
        int kk;

        if (mti == MT19937AR_N+1)   /* if init_genrand() has not been called, */
            init_genrand(5489UL); /* a default initial seed is used */

        for (kk=0;kk<MT19937AR_N-MT19937AR_M;kk++) {
            y = (mt[kk]&MT19937AR_UPPER_MASK)|(mt[kk+1]&MT19937AR_LOWER_MASK);
            mt[kk] = mt[kk+MT19937AR_M] ^ (y >> 1) ^ mag01[y & 0x1UL];
        }
        for (;kk<MT19937AR_N-1;kk++) {
            y = (mt[kk]&MT19937AR_UPPER_MASK)|(mt[kk+1]&MT19937AR_LOWER_MASK);
            mt[kk] = mt[kk+(MT19937AR_M-MT19937AR_N)] ^ (y >> 1) ^ mag01[y & 0x1UL];
        }
        y = (mt[MT19937AR_N-1]&MT19937AR_UPPER_MASK)|(mt[0]&MT19937AR_LOWER_MASK);
        mt[MT19937AR_N-1] = mt[MT19937AR_M-1] ^ (y >> 1) ^ mag01[y & 0x1UL];

        mti = 0;
    }

    y = mt[mti++];

    /* Tempering */
    y ^= (y >> 11);
    y ^= (y << 7) & 0x9d2c5680UL;
    y ^= (y << 15) & 0xefc60000UL;
    y ^= (y >> 18);

    return y;
}

/* generates a random number on [0,0x7fffffff]-interval */
long genrand_int31(void)
{
    return (long)(genrand_int32()>>1);
}

/* generates a random number on [0,1]-real-interval */
double genrand_real1(void)
{
    return ((double)genrand_int32())*(1.0/4294967295.0);
    /* divided by 2^32-1 */
}

/* generates a random number on [0,1)-real-interval */
double genrand_real2(void)
{
    return ((double)genrand_int32())*(1.0/4294967296.0);
    /* divided by 2^32 */
}

/* generates a random number on (0,1)-real-interval */
double genrand_real3(void)
{
    return (((double)genrand_int32()) + 0.5)*(1.0/4294967296.0);
    /* divided by 2^32 */
}

/* generates a random number on [0,1) with 53-bit resolution*/
double genrand_res53(void)
{
    unsigned long a=genrand_int32()>>5, b=genrand_int32()>>6;
    return ((double)a*67108864.0+(double)b)*(1.0/9007199254740992.0);
}
/* These real versions are due to Isaku Wada, 2002/01/09 added */



/* generates a random number in [0,m-1] */
unsigned int genrand_index(unsigned int m) {
  return static_cast<unsigned int>(genrand_int32()) % m;
}

/* generates a random number in [0,m-1] */
unsigned long genrand_index(unsigned long m) {
  return genrand_int32() % m;
}

/*
 * http://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle#The_modern_algorithm
 */
void rand_permute(unsigned int *array, unsigned int size)
{
  unsigned int i, j, tmp;
  for (i = size - 1; i > 0; i--) {
    j = genrand_index(i+1);
    tmp = array[i]; array[i] = array[j]; array[j] = tmp;
  }
}

void rand_permute(unsigned long *array, unsigned long size)
{
  unsigned long i, j, tmp;
  for (i = size - 1; i > 0; i--) {
    j = genrand_index(i+1);
    tmp = array[i]; array[i] = array[j]; array[j] = tmp;
  }
}

}

#endif // MTLSDCA_SDCA_MT19937AR_H_
