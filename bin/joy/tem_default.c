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
#include "tem_default.h"

/* names for the structural features */
char *default_feature_name[]={
  "secondary structure and phi angle",
  "solvent accessibility",
  "hydrogen bond to mainchain CO",
  "hydrogen bond to mainchain NH",
  "hydrogen bond to other sidechain/heterogen",
  "cis-peptide bond",
  "hydrogen bond to heterogen",
  "covalent bond to heterogen",
  "disulphide",
  "mainchain to mainchain hydrogen bonds (amide)",
  "Mainchain to mainchain hydrogen bonds (carbonyl)",
  "DSSP",
  "positive phi angle",
  "percentage accessibility",
  "Ooi number",
};

/*
 * assign_default_features(int, int *, ALI *,
 *         SST *, PSA *, HBD *, TEM *)
 *
 * Assign features (set default)
 *
 */
int assign_default_features (int nstr, int alilen, ALI *aliall,
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
    _default_0(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _default_1(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _default_2(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _default_3(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _default_4(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _default_5(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _default_6(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _default_7(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _default_8(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _default_9(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _default_10(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _default_11(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _default_12(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _default_13(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
    _default_14(aliall[str_lst[i]].sequence, alilen, sstall[i], psaall[i], hbdall[i], temall[i], strtpos, endpos);
  }
  return 0;
}

/**********************************************************************************/
int _default_0 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* secondary structure and phi angle   */

int j, k;

k = strtpos -1;

tem.feature[0].name = strdup("secondary structure and phi angle");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[0].assign[j] = '-';
    continue;
  }
  k++;

if ((sst.phi[k] >= 0.0) && (sst.phi[k] < 180.0)) {
	tem.feature[0].assign[j] = 'P';
continue;
}
else if ((sst.dssp[k] == 'H') || (sst.dssp[k] == 'G') || (sst.dssp[k] == 'I')) { 
	tem.feature[0].assign[j] = 'H';
continue;
}
else if (sst.dssp[k] == 'E') {
	tem.feature[0].assign[j] = 'E';
continue;
}
else {
	tem.feature[0].assign[j] = 'C';
continue;
}
}

  tem.feature[0].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _default_1 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
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
	tem.feature[1].assign[j] = 'T';
continue;
}
else if (psa.side_per[k] > VF(V_PSACUTOFF)) {
	tem.feature[1].assign[j] = 'T';
continue;
}
else {
	tem.feature[1].assign[j] = 'F';
continue;
}
}

  tem.feature[1].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _default_2 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
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
int _default_3 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
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
int _default_4 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
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
int _default_5 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
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
int _default_6 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
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
int _default_7 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* covalent bond to heterogen   */

int j, k;

k = strtpos -1;

tem.feature[7].name = strdup("covalent bond to heterogen");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[7].assign[j] = '-';
    continue;
  }
  k++;

	tem.feature[7].assign[j] = hbd.cov_hetero[k];
continue;
}

  tem.feature[7].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _default_8 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* disulphide   */

int j, k;

k = strtpos -1;

tem.feature[8].name = strdup("disulphide");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[8].assign[j] = '-';
    continue;
  }
  k++;

	tem.feature[8].assign[j] = hbd.disulphide[k];
continue;
}

  tem.feature[8].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _default_9 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* mainchain to mainchain hydrogen bonds (amide)   */

int j, k;

k = strtpos -1;

tem.feature[9].name = strdup("mainchain to mainchain hydrogen bonds (amide)");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[9].assign[j] = '-';
    continue;
  }
  k++;

	tem.feature[9].assign[j] = hbd.main_mainN[k];
continue;
}

  tem.feature[9].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _default_10 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* Mainchain to mainchain hydrogen bonds (carbonyl)   */

int j, k;

k = strtpos -1;

tem.feature[10].name = strdup("Mainchain to mainchain hydrogen bonds (carbonyl)");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[10].assign[j] = '-';
    continue;
  }
  k++;

	tem.feature[10].assign[j] = hbd.main_mainO[k];
continue;
}

  tem.feature[10].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _default_11 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* DSSP   */

int j, k;

k = strtpos -1;

tem.feature[11].name = strdup("DSSP");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[11].assign[j] = '-';
    continue;
  }
  k++;

if (sst.dssp[k] == 'H') {
	tem.feature[11].assign[j] = 'H';
continue;
}
else if (sst.dssp[k] == 'G') {
	tem.feature[11].assign[j] = 'G';
continue;
}
else if (sst.dssp[k] == 'I') {
	tem.feature[11].assign[j] = 'I';
continue;
}
else if (sst.dssp[k] == 'E') {
	tem.feature[11].assign[j] = 'E';
continue;
}
else {
	tem.feature[11].assign[j] = 'C';
continue;
}
}

  tem.feature[11].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _default_12 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* positive phi angle   */

int j, k;

k = strtpos -1;

tem.feature[12].name = strdup("positive phi angle");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[12].assign[j] = '-';
    continue;
  }
  k++;

if ((sst.phi[k] >= 0.0) && (sst.phi[k] < 180.0)) {
	tem.feature[12].assign[j] = 'T';
continue;
}
else {
	tem.feature[12].assign[j] = 'F';
continue;
}
}

  tem.feature[12].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _default_13 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* percentage accessibility   */

int j, k;

k = strtpos -1;

tem.feature[13].name = strdup("percentage accessibility");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[13].assign[j] = '-';
    continue;
  }
  k++;

	tem.feature[13].assign[j] = realhex(psa.side_per[k]);
continue;
}

  tem.feature[13].assign[alilen] = '\0';
  return (0);
}
/**********************************************************************************/
int _default_14 (char *sequence, int alilen, SST sst, PSA psa, HBD hbd, TEM tem, int strtpos, int endpos) {
             /* Ooi number   */

int j, k;

k = strtpos -1;

tem.feature[14].name = strdup("Ooi number");

for (j=0; j<alilen; j++) {
  if (sequence[j] == ' ' || sequence[j] == '-' || sequence[j] == '/') {
    tem.feature[14].assign[j] = '-';
    continue;
  }
  k++;

	tem.feature[14].assign[j] = inthex(sst.ooi[k]);
continue;
}
  tem.feature[14].assign[alilen] = '\0';
  return (0);
}
