#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <parse.h>
#include "rdali.h"
#include "rdsst.h"
#include "rdpsa.h"
#include "rdhbd.h"
#include "utility.h"
#include "tem.h"
#include "tem_j216.h"

/* names for the structural features */
char *j216_feature_name[]={
  "secondary structure and phi angle",
  "solvent accessibility",
  "hydrogen bond to mainchain CO",
  "hydrogen bond to mainchain NH",
  "hydrogen bond to other sidechain/heterogen",
  "cis-peptide bond",
  "hydrogen bond to heterogen",
  "disulphide",
  "mainchain to mainchain hydrogen bonds (amide)",
  "Mainchain to mainchain hydrogen bonds (carbonyl)",
  "DSSP",
  "positive phi angle",
  "percentage accessibility",
  "Ooi number",
};

/*
 * assign_j216_features(int, int *, ALI *,
 *         SST *, PSA *, HBD *, TEM *)
 *
 * Assign features (set j216)
 *
 */
int assign_j216_features (int nstr, int alilen, ALI *aliall,
        int *str_lst, SST *sstall, PSA *psaall, HBD *hbdall, TEM *temall) {

  int i;
  int strtpos, endpos;

  for (i=0; i<nstr; i++) {
    if (VI(V_SEG)) {
       strtpos = aliall[str_lst[i]].seg.strt_seqnum;
       endpos = aliall[str_lst[i]].seg.end_seqnum;
    }
    else {
       strtpos = 0;
       endpos = alilen;
    }
    _j216_0(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _j216_1(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _j216_2(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _j216_3(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _j216_4(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _j216_5(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _j216_6(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _j216_7(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _j216_8(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _j216_9(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _j216_10(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _j216_11(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _j216_12(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _j216_13(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
  }
  return 0;
}

/**********************************************************************************/
int _j216_0 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* secondary structure and phi angle   */

int j, k;
double phi216;
double psi216;
double calpsi;

k = strtpos -1;

tem.feature[0].name = strdup("secondary structure and phi angle");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[0].assign[j] = '-';
    continue;
  }
  k++;


/* adopted from joy216 code */


phi216 = sst.phi[k];
psi216 = sst.psi[k];

if (sst.dssp[k] == 'E') {
	tem.feature[0].assign[j] = 'E';
continue;
}
else if ((sst.dssp[k] == 'H') || (sst.dssp[k] == 'G') || (sst.dssp[k] == 'I')) { 
	tem.feature[0].assign[j] = 'H';
continue;
}
else if (phi216 > 180.0 || psi216 > 180.0) {
	tem.feature[0].assign[j] = 'X';
continue;
}

/* phi216 >= 0 psi216 >0  */

if ((phi216 >= 0.0) && (psi216 > 0.0)) {
	calpsi = 155.0 - ((80.0 * phi216)/180.0);
	if (psi216 <= calpsi) {
		if (psi216 < 10.0) {
			if ((phi216 >= 80.0) && (phi216 <= 90.0)) {
				tem.feature[0].assign[j] = 'l';
continue;
			}
			else {
				tem.feature[0].assign[j] = 'g';
continue;
			}
		}
		else if ((psi216 >= 10.0) && (psi216 < 30.0)) {
			if ((phi216 >= 60.0) && (phi216 <= 90.0)) {
				tem.feature[0].assign[j] = 'l';
continue;
			}
			else {
				tem.feature[0].assign[j] = 'g';
continue;
			}
		}
		else if ((psi216 >= 30.0) && (psi216 < 40.0)) {
			if ((phi216 >= 50.0) && (phi216 <= 90.0)) {
				tem.feature[0].assign[j] = 'l';
continue;
			}
			else {
				tem.feature[0].assign[j] = 'g';
continue;
			}
		}
		else if ((psi216 >= 40.0) && (psi216 < 60.0)) {
			if ((phi216 >= 40.0) && (phi216 <= 80.0)) {
				tem.feature[0].assign[j] = 'l';
continue;
			}
			else {
				tem.feature[0].assign[j] = 'g';
continue;
			}
		}
		else if ((psi216 >= 60.0) && (psi216 < 70.0)) {
			if ((phi216 >= 40.0) && (phi216 <= 70.0)) {
				tem.feature[0].assign[j] = 'l';
continue;
			}
			else {
				tem.feature[0].assign[j] = 'g';
continue;
			}
		}
		else if ((psi216 >= 70.0) && (psi216 < 80.0)) {
			if ((phi216 >= 50.0) && (phi216 <= 60.0)) {
				tem.feature[0].assign[j] = 'l';
continue;
			}
			else {
				tem.feature[0].assign[j] = 'g';
continue;
			}
		}
		else {
			tem.feature[0].assign[j] = 'g';
continue;
		}
	}
	else if (phi216 >= 135.0) {
		tem.feature[0].assign[j] = 'b';
continue;
	}
	else {
		tem.feature[0].assign[j] = 'e';
continue;
	}
}

/* phi216 < 0 psi216 >0  */

else if ((phi216 < 0.0) && (psi216 > 0.0)) {
	if (psi216 <= 45.0) {
		tem.feature[0].assign[j] = 'a';
continue;
	}
	else if (psi216 <= 95.0) {
		tem.feature[0].assign[j] = 't';
continue;
	}
	else if ((psi216 > 95.0) && (phi216 <= -125.0)) {
		calpsi = 4.0909 - ((40.0 * phi216)/55.0);
		if (psi216 <= calpsi) {
			tem.feature[0].assign[j] = 't';
continue;
		}
		else {
			tem.feature[0].assign[j] = 'b';
continue;
		}
	}
	else if ((psi216 > 95.0) && (phi216 > -125.0) && (phi216 <= -105.0)) {
		tem.feature[0].assign[j] = 'b';
continue;
	}
	else if ((psi216 > 95.0) && (phi216 > -105.0)) {
		calpsi = -117.5 - ((85.0 * phi216)/30.0);
		if (psi216 <= calpsi) {
			tem.feature[0].assign[j] = 'b';
continue;
		}
		else {
			tem.feature[0].assign[j] = 'p';
continue;
		}
	}
}

/* phi216 < 0 psi216 <= 0  */

else if ((phi216 < 0.0) && (psi216 <= 0.0)) {
	calpsi = -125.0 - ((40.0 * phi216)/180.0);
	if (psi216 >= calpsi) {
		tem.feature[0].assign[j] = 'a';
continue;
	}
	else if (phi216 <= -105.0) {
		tem.feature[0].assign[j] = 'b';
continue;
	}
	else {
		tem.feature[0].assign[j] = 'p';
continue;
	}
}

/* phi216 > 0 psi216 <= 0  */

else if ((phi216 > 0.0) && (psi216 <= 0.0)) {
	calpsi = -55.0 - ((80.0 * phi216)/180.0);
	if (psi216 >= calpsi) {
		tem.feature[0].assign[j] = 'g';
continue;
	}
	else if (phi216 >= 135.0) {
		tem.feature[0].assign[j] = 'b';
continue;
	}
	else {
		tem.feature[0].assign[j] = 'e';
continue;
	}
}

/* undefined */

else {
	tem.feature[0].assign[j] = 'X';
continue;
}
}

  tem.feature[0].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _j216_1 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* solvent accessibility   */

int j, k;

k = strtpos -1;

tem.feature[1].name = strdup("solvent accessibility");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[1].assign[j] = '-';
    continue;
  }
  k++;

if (psa.missing_atom[k]) {
	tem.feature[1].assign[j] = '1';
continue;




}
else if (psa.side_per[k] <= 7.0) {
	tem.feature[1].assign[j] = '1';
continue;
}
else if (psa.side_per[k] <= 40.0) {
	tem.feature[1].assign[j] = '2';
continue;
}
else {
	tem.feature[1].assign[j] = '3';
continue;
}
}

  tem.feature[1].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _j216_2 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* hydrogen bond to mainchain CO   */

int j, k;

k = strtpos -1;

tem.feature[2].name = strdup("hydrogen bond to mainchain CO");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[2].assign[j] = '-';
    continue;
  }
  k++;

	tem.feature[2].assign[j] = hbd.CO[k];
continue;
}

  tem.feature[2].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _j216_3 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* hydrogen bond to mainchain NH   */

int j, k;

k = strtpos -1;

tem.feature[3].name = strdup("hydrogen bond to mainchain NH");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[3].assign[j] = '-';
    continue;
  }
  k++;

	tem.feature[3].assign[j] = hbd.NH[k];
continue;
}

  tem.feature[3].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _j216_4 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* hydrogen bond to other sidechain/heterogen   */

int j, k;

k = strtpos -1;

tem.feature[4].name = strdup("hydrogen bond to other sidechain/heterogen");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[4].assign[j] = '-';
    continue;
  }
  k++;

if (hbd.side[k] == 'T' || hbd.side_hetero[k] == 'T') {
	tem.feature[4].assign[j] = 'T';
continue;
}
else {
	tem.feature[4].assign[j] = 'F';
continue;
}
}

  tem.feature[4].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _j216_5 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* cis-peptide bond   */

int j, k;

k = strtpos -1;

tem.feature[5].name = strdup("cis-peptide bond");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[5].assign[j] = '-';
    continue;
  }
  k++;

                              
                              

if (k > 0 && sst.omega[k-1] > -90.0 && sst.omega[k-1] < 90.0) {
	tem.feature[5].assign[j] = 'T';
continue;
}
else {
	tem.feature[5].assign[j] = 'F';
continue;
}
}

  tem.feature[5].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _j216_6 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* hydrogen bond to heterogen   */

int j, k;

k = strtpos -1;

tem.feature[6].name = strdup("hydrogen bond to heterogen");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[6].assign[j] = '-';
    continue;
  }
  k++;

	tem.feature[6].assign[j] = hbd.side_hetero[k];
continue;
}

  tem.feature[6].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _j216_7 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* disulphide   */

int j, k;

k = strtpos -1;

tem.feature[7].name = strdup("disulphide");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[7].assign[j] = '-';
    continue;
  }
  k++;

	tem.feature[7].assign[j] = hbd.disulphide[k];
continue;
}

  tem.feature[7].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _j216_8 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* mainchain to mainchain hydrogen bonds (amide)   */

int j, k;

k = strtpos -1;

tem.feature[8].name = strdup("mainchain to mainchain hydrogen bonds (amide)");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[8].assign[j] = '-';
    continue;
  }
  k++;

	tem.feature[8].assign[j] = hbd.main_mainN[k];
continue;
}

  tem.feature[8].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _j216_9 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* Mainchain to mainchain hydrogen bonds (carbonyl)   */

int j, k;

k = strtpos -1;

tem.feature[9].name = strdup("Mainchain to mainchain hydrogen bonds (carbonyl)");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[9].assign[j] = '-';
    continue;
  }
  k++;

	tem.feature[9].assign[j] = hbd.main_mainO[k];
continue;
}

  tem.feature[9].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _j216_10 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* DSSP   */

int j, k;

k = strtpos -1;

tem.feature[10].name = strdup("DSSP");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[10].assign[j] = '-';
    continue;
  }
  k++;

if (sst.dssp[k] == 'H') {
	tem.feature[10].assign[j] = 'H';
continue;
}
else if (sst.dssp[k] == 'G') {
	tem.feature[10].assign[j] = 'G';
continue;
}
else if (sst.dssp[k] == 'I') {
	tem.feature[10].assign[j] = 'I';
continue;
}
else if (sst.dssp[k] == 'E') {
	tem.feature[10].assign[j] = 'E';
continue;
}
else {
	tem.feature[10].assign[j] = 'C';
continue;
}
}

  tem.feature[10].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _j216_11 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* positive phi angle   */

int j, k;

k = strtpos -1;

tem.feature[11].name = strdup("positive phi angle");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[11].assign[j] = '-';
    continue;
  }
  k++;

if ((sst.phi[k] >= 0.0) && (sst.phi[k] < 180.0)) {
	tem.feature[11].assign[j] = 'T';
continue;
}
else {
	tem.feature[11].assign[j] = 'F';
continue;
}
}

  tem.feature[11].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _j216_12 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* percentage accessibility   */

int j, k;

k = strtpos -1;

tem.feature[12].name = strdup("percentage accessibility");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[12].assign[j] = '-';
    continue;
  }
  k++;

	tem.feature[12].assign[j] = realhex(psa.side_per[k]);
continue;
}

  tem.feature[12].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _j216_13 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* Ooi number   */

int j, k;

k = strtpos -1;

tem.feature[13].name = strdup("Ooi number");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[13].assign[j] = '-';
    continue;
  }
  k++;

	tem.feature[13].assign[j] = inthex(sst.ooi[k]);
continue;
}
  tem.feature[13].assign[alilen] = '\0';
  return (0);
}
