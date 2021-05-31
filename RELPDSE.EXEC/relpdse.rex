/* --------------------  rexx procedure  -------------------- *
 | Name:      RELPDSE                                         |
 |                                                            |
 | Function:  Release space from a PDSE using ADRDSSU.        |
 |                                                            |
 | Syntax:    %relpdse fully-qualified-pdse-dsname            |
 |                                                            |
 | Dependencies: The dataset must *not* be in use.            |
 |                                                            |
 |               STEMEDIT for viewing the results.            |
 |                                                            |
 |               ADRDSSU must be defined in IKJTSOxx in the   |
 |               AUTHPGM section.                             |
 |                                                            |
 | Author:    Lionel B. Dyck                                  |
 |                                                            |
 | History:  (most recent on top)                             |
 |            2021/05/31 LBD - Creation from discussion       |
 |            https://ibmmainframes.com/about61886.html       |
 |            with sample code provided by Pedro              |
 |                                                            |
 * ---------------------------------------------------------- */

  parse arg dataset

  /* ------------------------------------------------------ *
   | Allocate the SYSIN and SYSPRINT DD's to temp datasets. |
   * ------------------------------------------------------ */
  Address TSO
  'alloc f(sysin) spa(1) recfm(f b) lrecl(80) blksize(3120)' ,
    'unit(3390) new reuse'
  'alloc f(sysprint) spa(15,15) recfm(v b a) lrecl(121)' ,
    'unit(3390) new reuse blksize(1214)'

  /*   create DFDSS control card */
  reldd = 'REL'random(9999)
  out.1 =" RELEASE INCLUDE("dataset") DDNAME("reldd")   "
  out.0 = 1
  "EXECIO 1 DISKW SYSIN (STEM OUT. FINIS "

  /* CALL DFDSS to release the space */
  "ALLOC F("reldd") DA("dataset") SHR"
  "CALL 'SYS1.LINKLIB(ADRDSSU)'"

  /* ------------------------------------------------------------ *
   | Read in the SYSPRINT report and then free all allocated DD's |
   | used by this exec.                                           |
   * ------------------------------------------------------------ */
  'execio * diskr sysprint (finis stem sysp.'
  "FREE F("reldd" SYSIN SYSPRINT)"

  /* ------------------------------------- *
   | Now view the resulting ADRDSSU Report |
   * ------------------------------------- */
  call stemedit 'view',sysp.,,'PDSE Partial Release'
