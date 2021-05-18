=======================
= After-Action Report =
=======================

Overall, my program unfortunately runs slower than gzip and pigz (as expected)
and after tracing the system calls executed by each program, it's clear why the
performance of Pigzj is compromised. However, before that, an analysis of the
the performance of the three programs is due first.

I tested all 3 programs using the default number of processors first on 4 files
of different sizes. When comparing time, I'm comparing the sum of the user and 
sys outputs from the time command. Each test case is run three times. The first 
file is 5 blocks, and pigz takes about the same time as gzip to compress data 
(an average of 0.0333s compared to 0.0337s respectively) whereas Pigjz took a 
much longer time to compress (taking an average of 0.114s). pigzj runs about 3.42 
times as fast as Pigzj and I thought that this might be due to the time it takes 
to create threads and so the performance might be better with larger files. So 
I tested on a file that was 10 blocks large, and on the module file from the 
project spec that was about 100MB. On the 10 block file, gzip and pigz are still 
comparable but gzip runs a tiny bit slower, compressing at an average of 0.070s 
as opposed to pigz's average 0.067s). On the other hand, Pigzj still runs slower 
than the first two compression methods, averaging about 0.155s to compress a 10 
block file. However, now pigz runs about 2.313 times faster which is an improvement 
so this leads me to believe that there is too much overhead cost when creating 
threads and this cost supersedes the benefits of parallelism. Lastly, looking at 
the largest file I tested on, pigz and gzip nevertheless still perform roughly the
same (7.388s and 7.152s respectively) and Pigzj actually came really close to matching 
their performance speed (7.679s). Not pigz runs 1.07 faster than Pigzj so the larger
the file size, the better that Pigzj will perform as we can see from the data. 

After this, I also tested just pigz and Pigzj where I changed the number of threads
between trials. First I tested on a file whose size was about 6.3 blocks. When I 
increased the number of threads from 1 to 2, both pigz and Pigzj's speeds dropped 
but not by a very large margin. pigz's speed decreased about 3% while Pigzj's speed 
dropped by about 1.9% which isn't a lot. For small files, the number of threads 
doesn't seem to affect performance too much which makes sense as there's not a huge 
demand for parallelism. I saw roughly the same results when testing with 2 and 3
threads on a 10 block large file. Lastly, I tested with 1, 2, and 3 threads on a file
that was 100MB large and the number of threads also didn't largely affect the
compression speed. Going in order from 1 to 3 threads, pigz ran for about 7.091, 7.158,
and 7.150s. In the same manner, Pigzj took roughly 7.554, 7.661, and 7.666s. Based on
these findings, I don't think that the number of threads largely affects the speed 
as the times were pretty close to each other on a large file where parallelism can
be leveraged to increase the process time. On one last note, the compression ratios
for pigz and Pigzj are very close to each other which is a good sign. This means that
the program is at least compressing the data correctly, albeit slowly.

Finally, after analyzing the system calls that my program makes, it's understandable
why it runs slower then gzip. gzip makes 94 system calls whereas Pigzj makes 180 calls,
which is nearly double the number of calls. The overhead that is incurred during context
switching and can be very costly, and here I believe that it is affecting the speed of
my compression program. Based on the data, we can observe that the speed of Pigzj is 
comparable to gzip and pigz when compressing large files. So I think that the overhead
may be due to the cost of creating threads, regulating them, and then waiting for each
thread to join. Looking at pigz and gzip, pigz makes more 23 more system calls and spends
about double the time in kernel mode, however, it still runs slightly faster than gzip. 
This may be because pigz utilizes threads which improves its performance slightly. As 
we saw earlier, the number of threads doesn't play a large role in improving performance. 
So as the size of a file increases, the performance of Pigzj should improve since the
initial overhead cost will be miniscule compared to the performance benefit of using
multiple threads to compress data simultaneously. However there is a bug in my code and
I think it's due to a race condition. When I added the dictionary priming portion of
code to my program, I need a System.err.println to ensure that the program compresses
the file correctly. As the file size gets larger, there will be more print statements
executed which takes time and also screen space. Additionally, currently my program
also runs into an issue when the number of processes specified exceeds the number of
blocks available. So if the number of threads increase but the number of blocks doesn't,
then the program won't compress the file properly. Due to these, I think that pigz would
be the best method to handle increasing file sizes and number of threads. gzip is reliable
as well, however, it isn't multithreaded and so might not perform as fast on larger files. 

=================
= Configuration =
=================

$ javac Pigjz.java
$ java Pigjz <input.txt >Output.gz

========
= Data =
========

---Using the Default Number of Procesors---

File size: 655360B
|=====================================
|Trial|Time|gzip    |pigz    | Pigzj
|1    |real|0m0.042s|0m0.021s|0m0.386s
|     |user|0m0.031s|0m0.030s|0m0.081s
|     |sys |0m0.002s|0m0.003s|0m0.033s
|     |    |        |        | 
|2    |real|0m0.042s|0m0.021s|0m0.389s
|     |user|0m0.031s|0m0.031s|0m0.085s
|     |sys |0m0.003s|0m0.003s|0m0.030s
|     |    |        |        |
|3    |real|0m0.041s|0m0.020s|0m0.385s
|     |user|0m0.033s|0m0.030s|0m0.089s
|     |sys |0m0.001s|0m0.003s|0m0.024s
|=====================================

File size: 827416B
|=====================================
|Trial|Time|gzip    |pigz    | Pigzj
|1    |real|0m0.087s|0m0.035s|0m0.599s
|     |user|0m0.079s|0m0.078s|0m0.133s
|     |sys |0m0.001s|0m0.007s|0m0.034s
|     |    |        |        | 
|2    |real|0m0.086s|0m0.034s|0m0.499s
|     |user|0m0.079s|0m0.082s|0m0.136s
|     |sys |0m0.001s|0m0.003s|0m0.030s
|     |    |        |        |
|3    |real|0m0.087s|0m0.034s|0m0.600s
|     |user|0m0.077s|0m0.081s|0m0.132s
|     |sys |0m0.004s|0m0.004s|0m0.038s
|=====================================

File size: 1350720B
|=====================================
|Trial|Time|gzip    |pigz    | Pigzj
|1    |real|0m0.090s|0m0.043s|0m1.017s
|     |user|0m0.067s|0m0.059s|0m0.115s
|     |sys |0m0.005s|0m0.011s|0m0.042s
|     |    |        |        | 
|2    |real|0m0.084s|0m0.034s|0m1.008s
|     |user|0m0.066s|0m0.060s|0m0.119s
|     |sys |0m0.004s|0m0.005s|0m0.035s
|     |    |        |        |
|3    |real|0m0.081s|0m0.034s|0m1.009s
|     |user|0m0.066s|0m0.061s|0m0.123s
|     |sys |0m0.002s|0m0.005s|0m0.031s
|=====================================

File size: 125942959B
|=====================================
|Trial|Time|gzip    |pigz    | Pigzj
|1    |real|0m7.797s|0m2.227s|0m52.570s
|     |user|0m7.314s|0m7.111s|0m7.426s
|     |sys |0m0.069s|0m0.038s|0m0.243s
|     |    |        |        | 
|2    |real|0m7.595s|0m2.229s|0m42.315s
|     |user|0m7.324s|0m7.138s|0m7.375s
|     |sys |0m0.069s|0m0.048s|0m0.303s
|     |    |        |        |
|3    |real|0m7.802s|0m2.212s|0m49.808s
|     |user|0m7.324s|0m7.082s|0m7.420s
|     |sys |0m0.063s|0m0.040s|0m0.270s
|=====================================

---Changing the Number of Procesors---

*cr = compression ratio = compressed filesize / original filesize in bytes

----------------------------------------------------------------------------------
File size: 827416B

-p 1
|=====================================
|Trial|Time|pigz    |Pigzj
|1    |real|0m0.089s|0m0.146s
|     |user|0m0.072s|0m0.143s
|     |sys |0m0.001s|0m0.019s
|     |    |        |        
|2    |real|0m0.089s|0m0.147s
|     |user|0m0.082s|0m0.138s
|     |sys |0m0.001s|0m0.025s
|     |    |        |        
|3    |real|0m0.089s|0m0.146s
|     |user|0m0.079s|0m0.131s
|     |sys |0m0.004s|0m0.031s
|     |    |        |
|cr   |    |0.39    |0.39
|=====================================

-p 2
|=====================================
|Trial|Time|pigz    |Pigzj
|1    |real|0m0.050s|0m0.609s
|     |user|0m0.081s|0m0.137s
|     |sys |0m0.005s|0m0.029s
|     |    |        |        
|2    |real|0m0.053s|0m0.523s
|     |user|0m0.079s|0m0.139s
|     |sys |0m0.006s|0m0.023s
|     |    |        |        
|3    |real|0m0.050s|0m0.709s
|     |user|0m0.068s|0m0.143s
|     |sys |0m0.006s|0m0.023s
|     |    |        |
|cr   |    |0.39    |0.39
|=====================================

----------------------------------------------------------------------------------
File size: 1350720B

-p 2
|=====================================
|Trial|Time|pigz    |Pigzj
|1    |real|0m0.043s|0m1.014s
|     |user|0m0.053s|0m0.121s
|     |sys |0m0.006s|0m0.026s
|     |    |        |        
|2    |real|0m0.048s|0m0.819s
|     |user|0m0.061s|0m0.116s
|     |sys |0m0.004s|0m0.031s
|     |    |        |        
|3    |real|0m0.046s|0m0.817s
|     |user|0m0.059s|0m0.108s
|     |sys |0m0.005s|0m0.036s
|     |    |        |
|cr   |    |0.82    |0.83
|=====================================

-p 3
|=====================================
|Trial|Time|pigz    |Pigzj
|1    |real|0m0.039s|0m0.807s
|     |user|0m0.062s|0m0.119s
|     |sys |0m0.003s|0m0.030s
|     |    |        |        
|2    |real|0m0.039s|0m1.010s
|     |user|0m0.057s|0m0.112s
|     |sys |0m0.007s|0m0.039s
|     |    |        |        
|3    |real|0m0.039s|0m0.806s
|     |user|0m0.062s|0m0.115s
|     |sys |0m0.003s|0m0.032s
|     |    |        |
|cr   |    |0.82    |0.83
|=====================================

----------------------------------------------------------------------------------
File size: 125942959B

-p 1
|=====================================
|Trial|Time|pigz    |Pigzj
|1    |real|0m7.496s|0m7.601s
|     |user|0m6.985s|0m7.287s
|     |sys |0m0.065s|0m0.216s
|     |    |        |        
|2    |real|0m7.602s|1m7.847s
|     |user|0m7.089s|0m7.367s
|     |sys |0m0.078s|0m0.278s
|     |    |        |        
|3    |real|0m7.479s|0m7.580s
|     |user|0m6.993s|0m7.277s
|     |sys |0m0.064s|0m0.236s
|     |    |        |
|cr   |    |0.34    |0.34
|=====================================

-p 2
|=====================================
|Trial|Time|pigz    |Pigzj
|1    |real|0m3.951s|0m53.076s
|     |user|0m7.046s|0m7.413s
|     |sys |0m0.082s|0m0.245s
|     |    |        |        
|2    |real|0m3.897s|1m6.023s
|     |user|0m7.120s|0m7.390s
|     |sys |0m0.083s|0m0.256s
|     |    |        |        
|3    |real|0m3.982s|0m58.475s
|     |user|0m7.048s|0m7.413s
|     |sys |0m0.095s|0m0.266s
|     |    |        |
|cr   |    |0.34    |0.34
|=====================================

-p 3
|=====================================
|Trial|Time|pigz    |Pigzj
|1    |real|0m2.767s|0m51.749s
|     |user|0m7.040s|0m7.424s
|     |sys |0m0.096s|0m0.275s
|     |    |        |        
|2    |real|0m4.422s|0m37.582s
|     |user|0m7.034s|0m7.394s
|     |sys |0m0.127s|0m0.234s
|     |    |        |        
|3    |real|0m3.012s|0m57.147s
|     |user|0m7.090s|0m7.415s
|     |sys |0m0.065s|0m0.256s
|     |    |        |
|cr   |    |0.34    |0.34
|=====================================

---strace Results---

File size: 655360B

gzip:
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 34.07    0.000185          46         4           close
 18.05    0.000098           2        34           write
 16.94    0.000092           4        22           read
  9.21    0.000050           4        12           rt_sigaction
  6.81    0.000037           9         4           mprotect
  5.16    0.000028           5         5           mmap
  3.50    0.000019          19         1           munmap
  2.76    0.000015           5         3           fstat
  1.29    0.000007           3         2           openat
  0.74    0.000004           4         1           lseek
  0.74    0.000004           4         1         1 ioctl
  0.74    0.000004           2         2         1 arch_prctl
  0.00    0.000000           0         1           brk
  0.00    0.000000           0         1         1 access
  0.00    0.000000           0         1           execve
------ ----------- ----------- --------- --------- ----------------
100.00    0.000543                    94         3 total

pigz:
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 31.51    0.000454          32        14           read
 22.21    0.000320          24        13         1 futex
 13.05    0.000188          23         8           munmap
  8.95    0.000129           5        22           mmap
  7.15    0.000103           6        15           mprotect
  4.44    0.000064          12         5           clone
  3.40    0.000049           8         6           openat
  2.01    0.000029           4         6           fstat
  1.80    0.000026           4         6           close
  0.97    0.000014           2         6           brk
  0.83    0.000012           4         3           lseek
  0.83    0.000012           4         3           rt_sigaction
  0.62    0.000009           4         2         2 ioctl
  0.56    0.000008           8         1         1 access
  0.56    0.000008           4         2         1 arch_prctl
  0.28    0.000004           4         1           rt_sigprocmask
  0.28    0.000004           4         1           set_tid_address
  0.28    0.000004           4         1           set_robust_list
  0.28    0.000004           4         1           prlimit64
  0.00    0.000000           0         1           execve
------ ----------- ----------- --------- --------- ----------------
100.00    0.001441                   117         5 total

Pigzj:
% time     seconds  usecs/call     calls    errors syscall
------ ----------- ----------- --------- --------- ----------------
 99.73    0.030419       15209         2           futex
  0.10    0.000031          10         3           munmap
  0.08    0.000023          23         1           clone
  0.05    0.000016           1        15           mprotect
  0.02    0.000006           0        23           mmap
  0.01    0.000004           4         1           getpid
  0.01    0.000002           0        11           close
  0.00    0.000000           0        12           read
  0.00    0.000000           0        33        30 stat
  0.00    0.000000           0        10           fstat
  0.00    0.000000           0         3           lseek
  0.00    0.000000           0         4           brk
  0.00    0.000000           0         2           rt_sigaction
  0.00    0.000000           0         1           rt_sigprocmask
  0.00    0.000000           0         2         1 access
  0.00    0.000000           0         1           execve
  0.00    0.000000           0         2           readlink
  0.00    0.000000           0         2         1 arch_prctl
  0.00    0.000000           0         1           set_tid_address
  0.00    0.000000           0        49        39 openat
  0.00    0.000000           0         1           set_robust_list
  0.00    0.000000           0         1           prlimit64
------ ----------- ----------- --------- --------- ----------------
100.00    0.030501                   180        71 total
