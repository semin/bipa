// =============================================================================
// CD-HI/CD-HIT
//
// Cluster Database at High Identity
//
// CD-HIT clusters protein sequences at high identity threshold.
// This program can remove the high sequence redundance efficiently.
//
// program written by
//                                      Weizhong Li
//                                      UCSD, San Diego Supercomputer Center
//                                      La Jolla, CA, 92093
//                                      Email liwz@sdsc.edu
//
//                 at
//                                      Adam Godzik's lab
//                                      The Burnham Institute
//                                      La Jolla, CA, 92037
//                                      Email adam@burnham-inst.org
// =============================================================================

#include "cd-hi.h"

// information
char cd_hit_ref1[] = "\"Clustering of highly homologous sequences to reduce thesize of large protein database\", Weizhong Li, Lukasz Jaroszewski & Adam GodzikBioinformatics, (2001) 17:282-283";
char cd_hit_ref2[] = "\"Tolerating some redundancy significantly speeds up clustering of large protein databases\", Weizhong Li, Lukasz Jaroszewski & Adam Godzik Bioinformatics, (2002) 18:77-82";
char cd_hit_ref3[] = "\"Cd-hit: a fast program for clustering and comparing large sets of protein or nucleotide sequences\", Weizhong Li & Adam Godzik Bioinformatics, (2006) 22:1658-1659";
//

int DIAG_score[MAX_DIAG];

void bomb_error(char *message) {
  cerr << "\nFatal Error\n";
  cerr << message << endl;
  cerr << "\nProgram halted !! \n\n";
  exit (1);
} // END void bomb_error

void bomb_error(char *message, char *message2) {
  cerr << "\nFatal Error\n";
  cerr << message << " " << message2 << endl;
  cerr << "\nProgram halted !! \n\n";
  exit (1);
} // END void bomb_error


void bomb_warning(char *message) {
  cerr << "\nWarning\n";
  cerr << message << endl;
  cerr << "\nIt is not fatal, but may affect your results !! \n\n";
} // END void bomb_warning


void bomb_warning(char *message, char *message2) {
  cerr << "\nWarning\n";
  cerr << message << " " << message2 << endl;
  cerr << "\nIt is not fatal, but may affect your results !! \n\n";
} // END void bomb_warning


//quick_sort calling (a, 0, no-1)
int quick_sort (int *a, int lo0, int hi0 ) {
  int lo = lo0;
  int hi = hi0;
  int mid;
  int tmp;

  if ( hi0 > lo0) {
    mid = a[ ( lo0 + hi0 ) / 2 ];

    while( lo <= hi ) {
      while( ( lo < hi0 ) && ( a[lo] < mid ) ) lo++;
      while( ( hi > lo0 ) && ( a[hi] > mid ) ) hi--;
      if( lo <= hi ) {
        tmp=a[lo]; a[lo]=a[hi]; a[hi]=tmp;
        lo++; hi--;
      }
    } // while

    if( lo0 < hi ) quick_sort(a, lo0, hi );
    if( lo < hi0 ) quick_sort(a, lo, hi0 );
  } // if ( hi0 > lo0)
  return 0;
} // quick_sort


//quick_sort_idx calling (a, idx, 0, no-1)
//sort a with another array idx
//so that idx rearranged
int quick_sort_idx (int *a, int *idx, int lo0, int hi0 ) {
  int lo = lo0;
  int hi = hi0;
  int mid;
  int tmp;

  if ( hi0 > lo0) {
    mid = a[ ( lo0 + hi0 ) / 2 ];

    while( lo <= hi ) {
      while( ( lo < hi0 ) && ( a[lo] < mid ) ) lo++;
      while( ( hi > lo0 ) && ( a[hi] > mid ) ) hi--;
      if( lo <= hi ) {
        tmp=a[lo];   a[lo]=a[hi];     a[hi]=tmp;
        tmp=idx[lo]; idx[lo]=idx[hi]; idx[hi]=tmp;
        lo++; hi--;
      }
    } // while
  
    if( lo0 < hi ) quick_sort_idx(a, idx, lo0, hi );
    if( lo < hi0 ) quick_sort_idx(a, idx, lo, hi0 );
  } // if ( hi0 > lo0)
  return 0;
} // quick_sort_idx


//quick_sort_idx calling (a, idx, 0, no-1)
//sort a with another array idx
//so that idx rearranged
int quick_sort_idx2 (int *a, int *b, int *idx, int lo0, int hi0 ) {
  int lo = lo0;
  int hi = hi0;
  int mid;
  int tmp;

  if ( hi0 > lo0) {
    mid = a[ ( lo0 + hi0 ) / 2 ];

    while( lo <= hi ) {
      while( ( lo < hi0 ) && ( a[lo] < mid ) ) lo++;
      while( ( hi > lo0 ) && ( a[hi] > mid ) ) hi--;
      if( lo <= hi ) {
        tmp=a[lo];   a[lo]=a[hi];     a[hi]=tmp;
        tmp=b[lo];   b[lo]=b[hi];     b[hi]=tmp;
        tmp=idx[lo]; idx[lo]=idx[hi]; idx[hi]=tmp;
        lo++; hi--;
      }
    } // while

    if( lo0 < hi ) quick_sort_idx2(a, b, idx, lo0, hi );
    if( lo < hi0 ) quick_sort_idx2(a, b, idx, lo, hi0 );
  } // if ( hi0 > lo0)
  return 0;
} // quick_sort_idx2


//quick_sort_a_b_idx
//sort a list by a first priority
//           and b second priority
//another idx go with them
int quick_sort_a_b_idx (int *a, int *b, int *idx, int lo0, int hi0 ) {

  //first sort list by a
  quick_sort_idx2(a, b, idx, lo0, hi0);

  //then sort segments where elements in a is same
  int i, j, k;
  int bb = lo0;

  for (i=bb+1; i<=hi0; i++) {
    if ( a[i] == a[i-1] ) {
      ;
    }
    else {
      if ( i-1 > bb ) quick_sort_idx(b, idx, bb, i-1);
      bb = i;
    } 
  }

  // last segment
  if ( hi0 > bb ) quick_sort_idx(b, idx, bb, hi0);

  return 0;
} // quick_sort_a_b_idx


void format_seq(char *seq) {
  int i, j, k;
  char c1;
  int len = strlen(seq);

  for (i=0,j=0; i<len; i++) {
    c1 = toupper(seq[i]);
    if ( isalpha(c1) ) seq[j++] = c1;
  }
  seq[j] = 0;
} // END void format_seq


////For smiple len1 <= len2, len2 is for existing representative
////walk along all diag path of two sequences,
////find the diags with most aap
////return top n diags
////added on 2006 11 13
////band 0                      XXXXXXXXXXXXXXXXXX               seq2, rep seq
////                            XXXXXXXXXXXXXXX                  seq1
////band 1                      XXXXXXXXXXXXXXXXXX               seq2, rep seq
////                             XXXXXXXXXXXXXXX                 seq1
////extreme right (+)           XXXXXXXXXXXXXXXXXX               seq2, rep seq
////    band = len2-1                            XXXXXXXXXXXXXXX seq1
////band-1                      XXXXXXXXXXXXXXXXXX               seq2, rep seq
////                           XXXXXXXXXXXXXXX                   seq1
////extreme left (-)            XXXXXXXXXXXXXXXXXX               seq2, rep seq
////              XXXXXXXXXXXXXXX   band = -(len1-1)             seq1
////index of diag_score = band+len1-1;
int diag_test_aapn(int NAA1, char iseq2[], int len1, int len2, int *taap,
        INTs *aap_begin, INTs *aap_list, int &best_sum,
        int band_width, int &band_left, int &band_right, int required_aa1) {
  int i, i1, j, k, l, m, n;
  int *pp;
  int nall = len1+len2-1;
  static int diag_score[MAX_DIAG]; 

  for (pp=diag_score, i=nall; i; i--, pp++) *pp=0;

  int bi, bj, c22;
  INTs *bip;
  int len11 = len1-1;
  int len22 = len2-1;
  i1 = len11;
  for (i=0; i<len22; i++,i1++) {
//    c22 = iseq2[i]*NAA1 + iseq2[i+1];
    c22 = iseq2[i]*NAA1+ iseq2[i+1];
    if ( (j=taap[c22]) == 0) continue;
    bip = aap_list+ aap_begin[c22];     //    bi = aap_begin[c22];
    for (; j; j--, bip++) {  //  for (j=0; j<taap[c22]; j++,bi++) {
      diag_score[i1 - *bip]++;
    }
  }

  //find the best band range
//  int band_b = required_aa1;
  int band_b = required_aa1-1 >= 0 ? required_aa1-1:0;  // on dec 21 2001
  int band_e = nall - required_aa1;
  int band_m = ( band_b+band_width-1 < band_e ) ? band_b+band_width-1 : band_e;
  int best_score=0;
  for (i=band_b; i<=band_m; i++) best_score += diag_score[i];
  int from=band_b;
  int end =band_m;
  int score = best_score;  
  for (k=from, j=band_m+1; j<band_e; j++) {
    score -= diag_score[k++]; 
    score += diag_score[j]; 
    if ( score > best_score ) {
      from = k;
      end  = j;
      best_score = score;
    }
  }
  for (j=from; j<=end; j++) { // if aap pairs fail to open gap
    if ( diag_score[j] < 5 ) { best_score -= diag_score[j]; from++;}
    else break;
  }
  for (j=end; j>=from; j--) { // if aap pairs fail to open gap
    if ( diag_score[j] < 5 ) { best_score -= diag_score[j]; end--;}
    else break;
  }

//  delete [] diag_score;
  band_left = from-len1+1; 
  band_right= end-len1+1;
  best_sum = best_score;
  return OK_FUNC;
}
// END diag_test_aapn
 

int diag_test_aapn_est(int NAA1, char iseq2[], int len1, int len2, int *taap,
        INTs *aap_begin, INTs *aap_list, int &best_sum,
        int band_width, int &band_left, int &band_right, int required_aa1) {
  int i, i1, j, k, l, m, n;
  int *pp;
  int nall = len1+len2-1;
  static int diag_score[MAX_DIAG]; 
  int NAA2 = NAA1 * NAA1;
  int NAA3 = NAA2 * NAA1;

  for (pp=diag_score, i=nall; i; i--, pp++) *pp=0;

  int bi, bj, c22;
  INTs *bip;
  int len22 = len2-3;
  i1 = len1-1;
  for (i=0; i<len22; i++,i1++) {
    c22 = iseq2[i]*NAA3+ iseq2[i+1]*NAA2 + iseq2[i+2]*NAA1 + iseq2[i+3];
    if ( (j=taap[c22]) == 0) continue;
    bip = aap_list+ aap_begin[c22];     //    bi = aap_begin[c22];
    for (; j; j--, bip++) {  //  for (j=0; j<taap[c22]; j++,bi++) {
      diag_score[i1 - *bip]++;
    }
  }

  //find the best band range
//  int band_b = required_aa1;
  int band_b = required_aa1-1 >= 0 ? required_aa1-1:0;  // on dec 21 2001
  int band_e = nall - required_aa1;
  int band_m = ( band_b+band_width-1 < band_e ) ? band_b+band_width-1 : band_e;
  int best_score=0;
  for (i=band_b; i<=band_m; i++) best_score += diag_score[i];
  int from=band_b;
  int end =band_m;
  int score = best_score;  
  for (k=from, j=band_m+1; j<band_e; j++) {
    score -= diag_score[k++]; 
    score += diag_score[j]; 
    if ( score > best_score ) {
      from = k;
      end  = j;
      best_score = score;
    }
  }
  for (j=from; j<=end; j++) { // if aap pairs fail to open gap
    if ( diag_score[j] < 5 ) { best_score -= diag_score[j]; from++;}
    else break;
  }
  for (j=end; j>=from; j--) { // if aap pairs fail to open gap
    if ( diag_score[j] < 5 ) { best_score -= diag_score[j]; end--;}
    else break;
  }

//  delete [] diag_score;
  band_left = from-len1+1; 
  band_right= end-len1+1;
  best_sum = best_score;
  return OK_FUNC;
}
// END diag_test_aapn_est

////local alignment of two sequence within a diag band
////for band 0 means direction (0,0) -> (1,1)
////         1 means direction (0,1) -> (1,2)
////        -1 means direction (1,0) -> (2,1)
////added on 2006 11 13
////band 0                      XXXXXXXXXXXXXXXXXX               seq2, rep seq
////                            XXXXXXXXXXXXXXX                  seq1
////band 1                      XXXXXXXXXXXXXXXXXX               seq2, rep seq
////                             XXXXXXXXXXXXXXX                 seq1
////extreme right (+)           XXXXXXXXXXXXXXXXXX               seq2, rep seq
////    band = len2-1                            XXXXXXXXXXXXXXX seq1
////band-1                      XXXXXXXXXXXXXXXXXX               seq2, rep seq
////                           XXXXXXXXXXXXXXX                   seq1
////extreme left (-)            XXXXXXXXXXXXXXXXXX               seq2, rep seq
////              XXXXXXXXXXXXXXX   band = -(len1-1)             seq1
////iseq len are integer sequence and its length,
////mat is matrix, return ALN_PAIR class
//
//       band:  -101   seq2 len2 = 17
//                \\\1234567890123456
//              0  \xxxxxxxxxxxxxxxxx
//              1   xxxxxxxxxxxxxxxxx\ most right band = len2-1
//              2   xxxxxxxxxxxxxxxxx
//    seq1      3   xxxxxxxxxxxxxxxxx
//    len1 = 11 4   xxxxxxxxxxxxxxxxx
//              5   xxxxxxxxxxxxxxxxx
//              6   xxxxxxxxxxxxxxxxx
//              7   xxxxxxxxxxxxxxxxx
//              8   xxxxxxxxxxxxxxxxx
//              9   xxxxxxxxxxxxxxxxx
//              0   xxxxxxxxxxxxxxxxx
//                  \
//                   most left band = -(len1-1)
//

int local_band_align(char iseq1[], char iseq2[], int len1, int len2,
                     AA_MATRIX &mat, int &best_score, int &iden_no,
                     int band_left, int band_right) {
  int i, j, k, l, m, n, j1;
  int ii, jj, kk;
  int best_score1, iden_no1, best_i, best_j, best_j1;
  int *gap_array;
  iden_no = 0;

  if ( (band_right >= len2 ) ||
       (band_left  <= -len1) ||
       (band_left  > band_right) ) return FAILED_FUNC;

  // allocate mem for score_mat[len1][len2] etc
  int band_width = band_right - band_left + 1;
  int *(*score_mat), *(*iden_mat);
  if ((score_mat = new int * [len1]) == NULL) bomb_error("Memory");
  if ((iden_mat  = new int * [len1]) == NULL) bomb_error("Memory");
  for (i=0; i<len1; i++) {
    if ((score_mat[i] = new int [band_width]) == NULL) bomb_error("Memory");
    if ((iden_mat[i]  = new int [band_width]) == NULL) bomb_error("Memory");
  }
  //here index j1 refer to band column
  for (i=0; i<len1; i++) for (j1=0; j1<band_width; j1++) score_mat[i][j1] =  0;

  gap_array  = mat.gap_array;
  best_score = 0;
//            seq2 len2 = 17            seq2 len2 = 17      seq2 len2 = 17
//            01234567890123456       01234567890123456    01234567890123456
//      0     xxxxxxxxxxxxxxxxx \\\\\\XXXxxxxxxxxxxxxxx    xXXXXXXXxxxxxxxxx
//      1\\\\\Xxxxxxxxxxxxxxxxx  \\\\\Xxx\xxxxxxxxxxxxx    xx\xxxxx\xxxxxxxx
//      2 \\\\X\xxxxxxxxxxxxxxx   \\\\Xxxx\xxxxxxxxxxxx    xxx\xxxxx\xxxxxxx
// seq1 3  \\\Xx\xxxxxxxxxxxxxx    \\\Xxxxx\xxxxxxxxxxx    xxxx\xxxxx\xxxxxx
// len1 4   \\Xxx\xxxxxxxxxxxxx     \\Xxxxxx\xxxxxxxxxx    xxxxx\xxxxx\xxxxx
// = 11 5    \Xxxx\xxxxxxxxxxxx      \Xxxxxxx\xxxxxxxxx    xxxxxx\xxxxx\xxxx
//      6     Xxxxx\xxxxxxxxxxx       Xxxxxxxx\xxxxxxxx    xxxxxxx\xxxxx\xxx
//      7     x\xxxx\xxxxxxxxxx       x\xxxxxxx\xxxxxxx    xxxxxxxx\xxxxx\xx
//      8     xx\xxxx\xxxxxxxxx       xx\xxxxxxx\xxxxxx    xxxxxxxxx\xxxxx\x
//      9     xxx\xxxx\xxxxxxxx       xxx\xxxxxxx\xxxxx    xxxxxxxxxx\xxxxx\
//      0     xxxx\xxxx\xxxxxxx       xxxx\xxxxxxx\xxxx    xxxxxxxxxxx\xxxxx
//                band_left < 0           band_left < 0        band_left >=0
//                band_right < 0          band_right >=0       band_right >=0
//// init score_mat, and iden_mat (place with upper 'X')

  if (band_left < 0) {  //set score to left border of the matrix within band
    int tband = (band_right < 0) ? band_right : 0;
    //for (k=band_left; k<tband; k++) {
    for (k=band_left; k<=tband; k++) { // fixed on 2006 11 14
      i = -k;
      j1 = k-band_left;
      if ( ( score_mat[i][j1] = mat.matrix[iseq1[i]][iseq2[0]] ) > best_score) 
        best_score = score_mat[i][j1];
      iden_mat[i][j1] = (iseq1[i] == iseq2[0]) ? 1 : 0;
    }
  }

  if (band_right >=0) { //set score to top border of the matrix within band
    int tband = (band_left > 0) ? band_left : 0;
    for (i=0,j=tband; j<=band_right; j++) {
      j1 = j-band_left;
      if ( ( score_mat[i][j1] = mat.matrix[iseq1[i]][iseq2[j]] ) > best_score)
        best_score = score_mat[i][j1];
      iden_mat[i][j1] = (iseq1[i] == iseq2[j]) ? 1 : 0;
    }
  }

  for (i=1; i<len1; i++) {
    for (j1=0; j1<band_width; j1++) {
      j = j1+i+band_left;
      if ( j<1 ) continue;
      if ( j>=len2) continue;

      int sij = mat.matrix[iseq1[i]][iseq2[j]];
      int iden_ij = (iseq1[i] == iseq2[j] ) ? 1 : 0;
      int s1, *mat_row;
      int k0, k_idx;

      // from (i-1,j-1)
      if ( (best_score1 = score_mat[i-1][j1] )> 0 ) {
        iden_no1 = iden_mat[i-1][j1];
      }
      else {
        best_score1 = 0;
        iden_no1 = 0;
      }

      // from last row
      mat_row = score_mat[i-1];
      k0 = (-band_left+1-i > 0) ? -band_left+1-i : 0;
      for (k=j1-1, kk=0; k>=k0; k--, kk++) {
        if ( (s1 = mat_row[k] + gap_array[kk] ) > best_score1 ){
           best_score1 = s1;
           iden_no1 = iden_mat[i-1][k];
        }
      }

      k0 = (j-band_right-1 > 0) ? j-band_right-1 : 0;
      for(k=i-2, jj=j1+1,kk=0; k>=k0; k--,kk++,jj++) {
        if ( (s1 = score_mat[k][jj] + gap_array[kk] ) > best_score1 ){
           best_score1 = s1;
           iden_no1 = iden_mat[k][jj];
        }
      }

      best_score1 += sij;
      iden_no1    += iden_ij;
      score_mat[i][j1] = best_score1;
      iden_mat[i][j1]  = iden_no1;

      if ( best_score1 > best_score ) {
        best_score = best_score1;
        iden_no = iden_no1;
      }
    } // END for (j=1; j<len2; j++)
  } // END for (i=1; i<len1; i++)

  for (i=0; i<len1; i++) {
    delete [] score_mat[i]; 
    delete [] iden_mat[i];
  }
  delete [] score_mat;
  delete [] iden_mat;

  return OK_FUNC;
} // END int local_band_align


////local alignment of two sequence within a diag band
////for band 0 means direction (0,0) -> (1,1)
////         1 means direction (0,1) -> (1,2)
////        -1 means direction (1,0) -> (2,1)
////iseq len are integer sequence and its length,
////mat is matrix, return ALN_PAIR class
////copied from local_band_align, but also return alignment position
int local_band_align2(char iseq1[], char iseq2[], int len1, int len2,
                     AA_MATRIX &mat, int &best_score, int &iden_no,
                     int band_left, int band_right, 
                     int &from1, int &end1, int &from2, int &end2, int &alnln) {
  int i, j, k, l, m, n, j1;
  int ii, jj, kk;
  int best_score1, iden_no1, best_i, best_j, best_j1;
  int best_from1, best_from2, best_alnln;
  int *gap_array;
  iden_no = 0; from1=0; from2=0;

  if ( (band_right >= len2 ) ||
       (band_left  <= -len1) ||
       (band_left  > band_right) ) return FAILED_FUNC;

  // allocate mem for score_mat[len1][len2] etc
  int band_width = band_right - band_left + 1;
  int *(*score_mat), *(*iden_mat);
  int *(*from1_mat), *(*from2_mat), *(*alnln_mat);
  if ((score_mat = new int * [len1]) == NULL) bomb_error("Memory");
  if ((iden_mat  = new int * [len1]) == NULL) bomb_error("Memory");
  if ((from1_mat = new int * [len1]) == NULL) bomb_error("Memory");
  if ((from2_mat = new int * [len1]) == NULL) bomb_error("Memory");
  if ((alnln_mat = new int * [len1]) == NULL) bomb_error("Memory");
  for (i=0; i<len1; i++) {
    if ((score_mat[i] = new int [band_width]) == NULL) bomb_error("Memory");
    if ((iden_mat[i]  = new int [band_width]) == NULL) bomb_error("Memory");
    if ((from1_mat[i] = new int [band_width]) == NULL) bomb_error("Memory");
    if ((from2_mat[i] = new int [band_width]) == NULL) bomb_error("Memory");
    if ((alnln_mat[i] = new int [band_width]) == NULL) bomb_error("Memory");
  }
  //here index j1 refer to band column
  for (i=0; i<len1; i++) for (j1=0; j1<band_width; j1++) score_mat[i][j1] =  0;

  gap_array  = mat.gap_array;
  best_score = 0;

  if (band_left < 0) {  //set score to left border of the matrix within band
    int tband = (band_right < 0) ? band_right : 0;
    //for (k=band_left; k<tband; k++) {
    for (k=band_left; k<=tband; k++) { // fixed on 2006 11 14
      i = -k;
      j1 = k-band_left;
      if ( ( score_mat[i][j1] = mat.matrix[iseq1[i]][iseq2[0]] ) > best_score) {
        best_score = score_mat[i][j1];
        from1 = i; from2 = 0; end1 = i; end2 = 0; alnln = 1;
      }
      iden_mat[i][j1] = (iseq1[i] == iseq2[0]) ? 1 : 0;
      from1_mat[i][j1] = i;
      from2_mat[i][j1] = 0;
      alnln_mat[i][j1] = 1;
    }
  }

  if (band_right >=0) { //set score to top border of the matrix within band
    int tband = (band_left > 0) ? band_left : 0;
    for (i=0,j=tband; j<=band_right; j++) {
      j1 = j-band_left;
      if ( ( score_mat[i][j1] = mat.matrix[iseq1[i]][iseq2[j]] ) > best_score) {
        best_score = score_mat[i][j1];
        from1 = i; from2 = j; end1 = i; end2 = j; alnln = 0;
      }
      iden_mat[i][j1] = (iseq1[i] == iseq2[j]) ? 1 : 0;
      from1_mat[i][j1] = i;
      from2_mat[i][j1] = j;
      alnln_mat[i][j1] = 1;
    }
  }

  for (i=1; i<len1; i++) {
    for (j1=0; j1<band_width; j1++) {
      j = j1+i+band_left;
      if ( j<1 ) continue;
      if ( j>=len2) continue;

      int sij = mat.matrix[iseq1[i]][iseq2[j]];
      int iden_ij = (iseq1[i] == iseq2[j] ) ? 1 : 0;
      int s1, *mat_row;
      int k0, k_idx;

      // from (i-1,j-1)
      if ( (best_score1 = score_mat[i-1][j1] )> 0 ) {
        iden_no1 = iden_mat[i-1][j1];
        best_from1 = from1_mat[i-1][j1];
        best_from2 = from2_mat[i-1][j1];
        best_alnln = alnln_mat[i-1][j1] + 1;
      }
      else {
        best_score1 = 0;
        iden_no1 = 0;
        best_from1 = i;
        best_from2 = j;
        best_alnln = 1;
      }

      // from last row
      mat_row = score_mat[i-1];
      k0 = (-band_left+1-i > 0) ? -band_left+1-i : 0;
      for (k=j1-1, kk=0; k>=k0; k--, kk++) {
        if ( (s1 = mat_row[k] + gap_array[kk] ) > best_score1 ){
           best_score1 = s1;
           iden_no1 = iden_mat[i-1][k];
           best_from1 = from1_mat[i-1][k];
           best_from2 = from2_mat[i-1][k];
           best_alnln = alnln_mat[i-1][k]+kk+2;
        }
      }

      k0 = (j-band_right-1 > 0) ? j-band_right-1 : 0;
      for(k=i-2, jj=j1+1,kk=0; k>=k0; k--,kk++,jj++) {
        if ( (s1 = score_mat[k][jj] + gap_array[kk] ) > best_score1 ){
           best_score1 = s1;
           iden_no1 = iden_mat[k][jj];
           best_from1 = from1_mat[k][jj];
           best_from2 = from2_mat[k][jj];
           best_alnln = alnln_mat[k][jj]+kk+2;
        }
      }

      best_score1 += sij;
      iden_no1    += iden_ij;
      score_mat[i][j1] = best_score1;
      iden_mat[i][j1]  = iden_no1;
      from1_mat[i][j1] = best_from1;
      from2_mat[i][j1] = best_from2;
      alnln_mat[i][j1] = best_alnln;
      if ( best_score1 > best_score ) {
        best_score = best_score1;
        iden_no = iden_no1;
        end1 = i; end2 = j;
        from1 = best_from1; from2 = best_from2; alnln = best_alnln;
      }
    } // END for (j=1; j<len2; j++)
  } // END for (i=1; i<len1; i++)

  for (i=0; i<len1; i++) {
    delete [] score_mat[i]; 
    delete [] iden_mat[i];
    delete [] from1_mat[i];
    delete [] from2_mat[i];
    delete [] alnln_mat[i];
  }
  delete [] score_mat;
  delete [] iden_mat;
  delete [] from1_mat;
  delete [] from2_mat;
  delete [] alnln_mat;

  return OK_FUNC;
} // END int local_band_align2


//class function definition
//char aa[] = {"ARNDCQEGHILKMFPSTWYVBZX"};
//{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,2,6,20};
int aa2idx[] = {0, 2, 4, 3, 6, 13,7, 8, 9,20,11,10,12, 2,20,14,
                5, 1,15,16,20,19,17,20,18, 6};
    // idx for  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P
    //          Q  R  S  T  U  V  W  X  Y  Z
    // so  aa2idx[ X - 'A'] => idx_of_X, eg aa2idx['A' - 'A'] => 0,
    // and aa2idx['M'-'A'] => 12

int BLOSUM62[] = {
  4,                                                                  // A
 -1, 5,                                                               // R
 -2, 0, 6,                                                            // N
 -2,-2, 1, 6,                                                         // D
  0,-3,-3,-3, 9,                                                      // C
 -1, 1, 0, 0,-3, 5,                                                   // Q
 -1, 0, 0, 2,-4, 2, 5,                                                // E
  0,-2, 0,-1,-3,-2,-2, 6,                                             // G
 -2, 0, 1,-1,-3, 0, 0,-2, 8,                                          // H
 -1,-3,-3,-3,-1,-3,-3,-4,-3, 4,                                       // I
 -1,-2,-3,-4,-1,-2,-3,-4,-3, 2, 4,                                    // L
 -1, 2, 0,-1,-3, 1, 1,-2,-1,-3,-2, 5,                                 // K
 -1,-1,-2,-3,-1, 0,-2,-3,-2, 1, 2,-1, 5,                              // M
 -2,-3,-3,-3,-2,-3,-3,-3,-1, 0, 0,-3, 0, 6,                           // F
 -1,-2,-2,-1,-3,-1,-1,-2,-2,-3,-3,-1,-2,-4, 7,                        // P
  1,-1, 1, 0,-1, 0, 0, 0,-1,-2,-2, 0,-1,-2,-1, 4,                     // S
  0,-1, 0,-1,-1,-1,-1,-2,-2,-1,-1,-1,-1,-2,-1, 1, 5,                  // T
 -3,-3,-4,-4,-2,-2,-3,-2,-2,-3,-2,-3,-1, 1,-4,-3,-2,11,               // W
 -2,-2,-2,-3,-2,-1,-2,-3, 2,-1,-1,-2,-1, 3,-3,-2,-2, 2, 7,            // Y
  0,-3,-3,-3,-1,-2,-2,-3,-3, 3, 1,-2, 1,-1,-2,-2, 0,-3,-1, 4,         // V
 -2,-1, 3, 4,-3, 0, 1,-1, 0,-3,-4, 0,-3,-3,-2, 0,-1,-4,-3,-3, 4,      // B
 -1, 0, 0, 1,-3, 3, 4,-2, 0,-3,-3, 1,-1,-3,-1, 0,-1,-3,-2,-2, 1, 4,   // Z
  0,-1,-1,-1,-2,-1,-1,-1,-1,-1,-1,-1,-1,-1,-2, 0, 0,-2,-1,-1,-1,-1,-1 // X
//A  R  N  D  C  Q  E  G  H  I  L  K  M  F  P  S  T  W  Y  V  B  Z  X
//0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19  2  6 20
};


int na2idx[] = {0, 4, 1, 4, 4, 4, 2, 4, 4, 4, 4, 4, 4, 4, 4, 4,
                4, 4, 4, 3, 3, 4, 4, 4, 4, 4};
    // idx for  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P
    //          Q  R  S  T  U  V  W  X  Y  Z
    // so aa2idx[ X - 'A'] => idx_of_X, eg aa2idx['A' - 'A'] => 0,
    // and aa2idx['M'-'A'] => 4
int BLOSUM62_na[] = {
  1,               // A
 -2, 1,            // C
 -2,-2, 1,         // G
 -2,-2,-2, 1,      // T
 -2,-2,-2, 1, 1,   // U
 -2,-2,-2,-2,-2, 1 // N
//A  C  G  T  U  N
//0  1  2  3  3  4
};

void setaa_to_na() {
  int i, j, k;
  for (i=0; i<26; i++) aa2idx[i]   = na2idx[i];
} // END void setaa_to_na


int setiseq(char *seq, int len) {
  for (int i=0; i<len; i++) {
    seq[i] = aa2idx[seq[i] - 'A'];
  }
  return 0;
} // END void SEQ::seq2iseq()


/////////////////
AA_MATRIX::AA_MATRIX() {
  int i, j, k;
  gap = -11;
  ext_gap = -1;
  if ( (gap_array = new int[MAX_GAP]) == NULL ) bomb_error("memory");
  for (i=0; i<MAX_GAP; i++)  gap_array[i] = gap + i * ext_gap;
  k = 0;
  for ( i=0; i<MAX_AA; i++)
    for ( j=0; j<=i; j++)
      matrix[j][i] = matrix[i][j] = BLOSUM62[ k++ ];
} // END AA_MATRIX::AA_MATRIX()


void AA_MATRIX::init() {
  int i, j, k;
  gap = -11;
  ext_gap = -1;
  for (i=0; i<MAX_GAP; i++)  gap_array[i] = gap + i * ext_gap;
  k = 0;
  for ( i=0; i<MAX_AA; i++)
    for ( j=0; j<=i; j++)
      matrix[j][i] = matrix[i][j] = BLOSUM62[ k++ ];
} // END void AA_MATRIX::init()


void AA_MATRIX::set_gap(int gap1, int ext_gap1) {
  int i;
  gap = gap1; ext_gap = ext_gap1;
  for (i=0; i<MAX_GAP; i++)  gap_array[i] = gap + i * ext_gap;
} // END void AA_MATRIX::set_gap


void AA_MATRIX::set_matrix(int *mat1) {
  int i, j, k;
  k = 0;
  for ( i=0; i<MAX_AA; i++)
    for ( j=0; j<=i; j++)
      matrix[j][i] = matrix[i][j] = mat1[ k++ ];
} // END void AA_MATRIX::set_matrix


void AA_MATRIX::set_to_na() {
  int i, j, k;
  gap = -6;
  ext_gap = -1;
  for (i=0; i<MAX_GAP; i++)  gap_array[i] = gap + i * ext_gap;
  k = 0;
  for ( i=0; i<MAX_NA; i++)
    for ( j=0; j<=i; j++)
      matrix[j][i] = matrix[i][j] = BLOSUM62_na[ k++ ];
} // END void AA_MATRIX::set_to_na


IDX_TBL::IDX_TBL(){
  NAA      = 0;
  NAAN     = 0;
  mem_size = 1;
  buffer_size = 100000;
  is_aa       = 1;
} // END IDX_TBL::IDX_TBL


void IDX_TBL::set_dna() {
  is_aa = 0;
} // END IDX_TBL::set_dna

void IDX_TBL::init(int naa, int naan){
  int i, j, k;
  NAA  = naa;
  NAAN = naan;
  buffer_size = 100000;

  if (is_aa) {
    if      ( NAA == 2 ) { mem_size = 25000; }
    else if ( NAA == 3 ) { mem_size = 1200; }
    else if ( NAA == 4 ) { mem_size = 60; }
    else if ( NAA == 5 ) { mem_size = 3; }
    else bomb_error("Something wrong!");
  }
  else {
    if      ( NAA == 2 ) { mem_size = 250000; }
    else if ( NAA == 3 ) { mem_size = 50000; }
    else if ( NAA == 4 ) { mem_size = 10000; }
    else if ( NAA == 5 ) { mem_size = 2000; }
    else if ( NAA == 6 ) { mem_size = 350; }
    else if ( NAA == 7 ) { mem_size = 75; }
    else if ( NAA == 8 ) { mem_size = 15; }
    else if ( NAA == 9 ) { mem_size = 3; }
    else if ( NAA ==10 ) { mem_size = 2; }
    else bomb_error("Something wrong!");
  }

  if ((size     = new int[NAAN])        == NULL) bomb_error("Memory");
  if ((capacity = new int[NAAN])        == NULL) bomb_error("Memory");
  if ((seq_idx  = new int*[NAAN])       == NULL) bomb_error("Memory");
  if ((word_no  = new INTs*[NAAN])      == NULL) bomb_error("Memory");
  if ((buffer   = new int[buffer_size]) == NULL) bomb_error("Memory");

  for (i=0; i<NAAN; i++) {
    size[i]     = 0;
    capacity[i] = 0;
  }

} // END IDX_TBL::init


void IDX_TBL::clean() {
  int i, j, k;
  for (i=0; i<NAAN; i++) size[i]=0;
} // END IDX_TBL::clean


int IDX_TBL::read_tbl(char *filename) {
  int i, j, k;

  ifstream fswap(filename);
  if (! fswap) bomb_error("Can not open ", filename);

  for (i=0; i<NAAN; i++) {
    if ( size[i] > 0 ) {
      delete [] seq_idx[i];
      delete [] word_no[i];
    }

    fswap.read((char *) &size[i], sizeof(int));
    capacity[i] = size[i];
    if (size[i] == 0 ) continue;
    if ((seq_idx[i] = new int[size[i]])  == NULL) bomb_error("Memory");
    if ((word_no[i] = new INTs[size[i]]) == NULL) bomb_error("Memory");

    fswap.read((char *) seq_idx[i], sizeof(int) * size[i]);
    fswap.read((char *) word_no[i], sizeof(INTs) * size[i]);
  }

  fswap.close();
  return OK_FUNC;

} // END int IDX_TBL::read_tbl


int IDX_TBL::write_tbl(char *filename) {
  int i, j, k;
  ofstream fswap(filename);

  if (! fswap) bomb_error("Can not open ", filename);

  for (i=0; i<NAAN; i++) {
    fswap.write ((char *) &size[i], sizeof(int));
    if (size[i] == 0 ) continue;
    fswap.write((char *) seq_idx[i], sizeof(int)  * size[i]);
    fswap.write((char *) word_no[i], sizeof(INTs) * size[i]);
  }
  fswap.close();
  return OK_FUNC;

} // END int IDX_TBL::write_tbl


int IDX_TBL::add_word_list(int aan_no, int *aan_list, 
                           INTs *aan_list_no, int idx) {
  int i, j, k, i1, j1, k1, i0, j0, k0;

  for (j0=0; j0<aan_no; j0++) {
    if ( j1=aan_list_no[j0] ) {
      j = aan_list[j0];

      if ( size[j] == capacity[j] ) { // resize array
        if ( capacity[j] > buffer_size ) {
           delete [] buffer;
           buffer_size = capacity[j];
           if ((buffer = new int[buffer_size]) == NULL) bomb_error("Memory");
        }

        for (k=0; k<size[j]; k++) buffer[k] = seq_idx[j][k];
        if ( capacity[j] >0 ) delete [] seq_idx[j];
        if ((seq_idx[j] = new int[mem_size+capacity[j]]) == NULL)
          bomb_error("Memory");
        for (k=0; k<size[j]; k++) seq_idx[j][k] = buffer[k];

        for (k=0; k<size[j]; k++) buffer[k] = word_no[j][k];
        if ( capacity[j] >0 ) delete [] word_no[j];
        if ((word_no[j] = new INTs[mem_size+capacity[j]]) == NULL)
          bomb_error("Memory");
        for (k=0; k<size[j]; k++) word_no[j][k] = buffer[k];

        capacity[j] += mem_size;
      }
      seq_idx[j][size[j]] = idx;
      word_no[j][size[j]] = j1;
      size[j]++;
    }
  } //  for (j0=0; j0<aan_no; j0++) {

  return OK_FUNC;
} // END int IDX_TBL::add_word_list


// copied from above with only diff if j < 0 ...
int IDX_TBL::add_word_list2(int aan_no, int *aan_list, 
                           INTs *aan_list_no, int idx) {
  int i, j, k, i1, j1, k1, i0, j0, k0;

  for (j0=0; j0<aan_no; j0++) {
    if ( j1=aan_list_no[j0] ) {
      j = aan_list[j0];
      if (j<0) continue; // for those has 'N'
      if ( size[j] == capacity[j] ) { // resize array
        if ( capacity[j] > buffer_size ) {
           delete [] buffer;
           buffer_size = capacity[j];
           if ((buffer = new int[buffer_size]) == NULL) bomb_error("Memory");
        }

        for (k=0; k<size[j]; k++) buffer[k] = seq_idx[j][k];
        if ( capacity[j] >0 ) delete [] seq_idx[j];
        if ((seq_idx[j] = new int[mem_size+capacity[j]]) == NULL)
          bomb_error("Memory");
        for (k=0; k<size[j]; k++) seq_idx[j][k] = buffer[k];

        for (k=0; k<size[j]; k++) buffer[k] = word_no[j][k];
        if ( capacity[j] >0 ) delete [] word_no[j];
        if ((word_no[j] = new INTs[mem_size+capacity[j]]) == NULL)
          bomb_error("Memory");
        for (k=0; k<size[j]; k++) word_no[j][k] = buffer[k];

        capacity[j] += mem_size;
      }
      seq_idx[j][size[j]] = idx;
      word_no[j][size[j]] = j1;
      size[j]++;
    }
  } //  for (j0=0; j0<aan_no; j0++) {

  return OK_FUNC;
} // END int IDX_TBL::add_word_list2


int IDX_TBL::count_word_no(int aan_no, int *aan_list,
                           INTs *aan_list_no, INTs *look_and_count) {
  int  i, j, k, j0, j1, k1;
  int  *ptr1;
  INTs *ptr2;

  for (j0=0; j0<aan_no; j0++) {
    if ( j1=aan_list_no[j0] ) {
      j = aan_list[j0];
      k1 = size[j];
      ptr1 = seq_idx[j];
      ptr2 = word_no[j];
      for (k=0; k<k1; k++)
        look_and_count[ptr1[k]] += ( j1 < ptr2[k]) ? j1 : ptr2[k] ;
    }
  }

  return OK_FUNC;
} // END int IDX_TBL::count_word_no


// copied from above with only diff if j < 0 ...
int IDX_TBL::count_word_no2(int aan_no, int *aan_list,
                           INTs *aan_list_no, INTs *look_and_count) {
  int  i, j, k, j0, j1, k1;
  int  *ptr1;
  INTs *ptr2;

  for (j0=0; j0<aan_no; j0++) {
    if ( j1=aan_list_no[j0] ) {
      j = aan_list[j0];
      if (j<0) continue; // if met short word has 'N'
      k1 = size[j];
      ptr1 = seq_idx[j];
      ptr2 = word_no[j];
      for (k=0; k<k1; k++)
        look_and_count[ptr1[k]] += ( j1 < ptr2[k]) ? j1 : ptr2[k] ;
    }
  }
                                                                                
  return OK_FUNC;
} // END int IDX_TBL::count_word_no2


// remove seqs whose index is before upper_bound
// those seqs are longer than the seq at upper_bound
// 
int IDX_TBL::pop_long_seqs(int upper_bound) {
  int i, j, k, i1, j1, k1, i0, j0, k0;

  for (i=0; i<NAAN; i++) {
    if ( size[i] == 0 ) continue;

    k = 0;
    for (j=0; j<size[i]; j++) {
      if (seq_idx[i][j] < upper_bound) continue;
      seq_idx[i][k] = seq_idx[i][j];
      word_no[i][k] = word_no[i][j];
      k++;
    }
    size[i] = k;
    //capacity[i] remain unchanged, 
  }
  return OK_FUNC;
} // END int IDX_TBL::add_word_list2

char txt_option_i[] = "\tinput input filename in fasta format, required\n";
char txt_option_i_2d[] = "\tinput filename for db1 in fasta format, required\n";
char txt_option_i2[] = "\tinput filename for db2 in fasta format, required\n";
char txt_option_o[] = "\toutput filename, required\n";
char txt_option_c[] = 
"\tsequence identity threshold, default 0.9\n \
\tthis is the default cd-hit's \"global sequence identity\" calculated as :\n \
\tnumber of identical amino acids in alignment\n \
\tdivided by the full length of the shorter sequence\n";
char txt_option_G[] = 
"\tuse global sequence identity, default 1\n \
\tif set to 0, then use local sequence identity, calculated as :\n \
\tnumber of identical amino acids in alignment\n \
\tdivided by the length of the alignment\n \
\tNOTE!!! don't use -G 0 unless you use alignment coverage controls\n \
\tsee options -aL, -AL, -aS, -AS\n";
char txt_option_g[] =
"\t1 or 0, default 0\n \
\tby cd-hit's default algorithm, a sequence is clustered to the first \n \
\tcluster that meet the threshold (fast cluster). If set to 1, the program\n \
\twill cluster it into the most similar cluster that meet the threshold\n \
\t(accurate but slow mode)\n \
\tbut either 1 or 0 won't change the representatives of final clusters\n";
char txt_option_b[] = "\tband_width of alignment, default 20\n";
char txt_option_M[] = "\tmax available memory (Mbyte), default 400\n";
char txt_option_n[] = "\tword_length, default 5, see user's guide for choosing it\n";
char txt_option_n_est[] = "\tword_length, default 8, see user's guide for choosing it\n";
char txt_option_l[] = "\tlength of throw_away_sequences, default 10\n";
char txt_option_t[] = "\ttolerance for redundance, default 2\n";
char txt_option_d[] =
"\tlength of description in .clstr file, default 20\n \
\tif set to 0, it takes the fasta defline and stops at first space\n";
char txt_option_s[] =
"\tlength difference cutoff, default 0.0\n \
\tif set to 0.9, the shorter sequences need to be\n \
\tat least 90% length of the representative of the cluster\n";
char txt_option_S[] =
"\tlength difference cutoff in amino acid, default 999999\n \
\tf set to 60, the length difference between the shorter sequences\n \
\tand the representative of the cluster can not be bigger than 60\n";
char txt_option_s2[] =
"\tlength difference cutoff for db1, default 1.0\n \
\tby default, seqs in db1 >= seqs in db2 in a same cluster\n \
\tif set to 0.9, seqs in db1 may just >= 90% seqs in db2\n";
char txt_option_S2[] =
"\tlength difference cutoff, default 0\n \
\tby default, seqs in db1 >= seqs in db2 in a same cluster\n \
\tif set to 60, seqs in db2 may 60aa longer than seqs in db1\n";
char txt_option_aL[] = 
"\talignment coverage for the longer sequence, default 0.0\n \
\tif set to 0.9, the alignment must covers 90% of the sequence\n";
char txt_option_AL[] = 
"\talignment coverage control for the longer sequence, default 99999999\n \
\tif set to 60, and the length of the sequence is 400,\n \
\tthen the alignment must be >= 340 (400-60) residues\n";
char txt_option_aS[] = 
"\talignment coverage for the shorter sequence, default 0.0\n \
\tif set to 0.9, the alignment must covers 90% of the sequence\n";
char txt_option_AS[] = 
"\talignment coverage control for the shorter sequence, default 99999999\n \
\tif set to 60, and the length of the sequence is 400,\n \
\tthen the alignment must be >= 340 (400-60) residues\n";
char txt_option_B[] =
"\t1 or 0, default 0, by default, sequences are stored in RAM\n \
\tif set to 1, sequence are stored on hard drive\n \
\tit is recommended to use -B 1 for huge databases\n";
char txt_option_p[] =
"\t1 or 0, default 0\n \tif set to 1, print alignment overlap in .clstr file\n";
char txt_option_r[] =
"\t1 or 0, default 0, by default only +/+ strand alignment\n \
\tif set to 1, do both +/+ & +/- alignments\n";

int print_usage (char *arg) {
  cout << "Usage "<< arg << " [Options] \n\nOptions\n\n";
  cout << "    -i" << txt_option_i;
  cout << "    -o" << txt_option_o;
  cout << "    -c" << txt_option_c;
  cout << "    -G" << txt_option_G;
  cout << "    -b" << txt_option_b;
  cout << "    -M" << txt_option_M;
  cout << "    -n" << txt_option_n;
  cout << "    -l" << txt_option_l;
  cout << "    -t" << txt_option_t;
  cout << "    -d" << txt_option_d;
  cout << "    -s" << txt_option_s;
  cout << "    -S" << txt_option_S;
  cout << "    -aL" << txt_option_aL;
  cout << "    -AL" << txt_option_AL;
  cout << "    -aS" << txt_option_aS;
  cout << "    -AS" << txt_option_AS;
  cout << "    -B" << txt_option_B;
  cout << "    -p" << txt_option_p;
  cout << "    -g" << txt_option_g;
  cout << "    -h print this help\n\n";
  cout << "    Questions, bugs, contact Weizhong Li at liwz@sdsc.edu\n\n";
  cout << "    If you find cd-hit useful, please kindly cite:\n\n";
  cout << "    " << cd_hit_ref1 << "\n";
  cout << "    " << cd_hit_ref2 << "\n\n\n";
  exit(1);
} // END print_usage



int print_usage_2d (char *arg) {
  cout << "Usage "<< arg << " [Options] \n\nOptions\n\n";
  cout << "    -i" << txt_option_i_2d;
  cout << "    -i2"<< txt_option_i2;
  cout << "    -o" << txt_option_o;
  cout << "    -c" << txt_option_c;
  cout << "    -G" << txt_option_G;
  cout << "    -b" << txt_option_b;
  cout << "    -M" << txt_option_M;
  cout << "    -n" << txt_option_n;
  cout << "    -l" << txt_option_l;
  cout << "    -t" << txt_option_t;
  cout << "    -d" << txt_option_d;
  cout << "    -s" << txt_option_s;
  cout << "    -S" << txt_option_S;
  cout << "    -s2" << txt_option_s2;
  cout << "    -S2" << txt_option_S2;
  cout << "    -aL" << txt_option_aL;
  cout << "    -AL" << txt_option_AL;
  cout << "    -aS" << txt_option_aS;
  cout << "    -AS" << txt_option_AS;
  cout << "    -B" << txt_option_B;
  cout << "    -p" << txt_option_p;
  cout << "    -g" << txt_option_g;
  cout << "    -h print this help\n\n";
  cout << "    Questions, bugs, contact Weizhong Li at liwz@sdsc.edu\n\n";
  cout << "    If you find cd-hit useful, please kindly cite:\n\n";
  cout << "    " << cd_hit_ref1 << "\n";
  cout << "    " << cd_hit_ref3 << "\n\n\n";
  exit(1);
} // END print_usage_2d


int print_usage_est (char *arg) {
  cout << "Usage "<< arg << " [Options] \n\nOptions\n\n";
  cout << "    -i" << txt_option_i;
  cout << "    -o" << txt_option_o;
  cout << "    -c" << txt_option_c;
  cout << "    -G" << txt_option_G;
  cout << "    -b" << txt_option_b;
  cout << "    -M" << txt_option_M;
  cout << "    -n" << txt_option_n_est;
  cout << "    -l" << txt_option_l;
  cout << "    -t" << txt_option_t;
  cout << "    -d" << txt_option_d;
  cout << "    -s" << txt_option_s;
  cout << "    -S" << txt_option_S;
  cout << "    -aL" << txt_option_aL;
  cout << "    -AL" << txt_option_AL;
  cout << "    -aS" << txt_option_aS;
  cout << "    -AS" << txt_option_AS;
  cout << "    -B" << txt_option_B;
  cout << "    -p" << txt_option_p;
  cout << "    -g" << txt_option_g;
  cout << "    -r" << txt_option_r;
  cout << "    -h print this help\n\n";
  cout << "    Questions, bugs, contact Weizhong Li at liwz@sdsc.edu\n\n";
  cout << "    If you find cd-hit useful, please kindly cite:\n\n";
  cout << "    " << cd_hit_ref1 << "\n";
  cout << "    " << cd_hit_ref3 << "\n\n\n";
  exit(1);
} // END print_usage_est


int print_usage_est_2d (char *arg) {
  cout << "Usage "<< arg << " [Options] \n\nOptions\n\n";
  cout << "    -i" << txt_option_i_2d;
  cout << "    -i2"<< txt_option_i2;
  cout << "    -o" << txt_option_o;
  cout << "    -c" << txt_option_c;
  cout << "    -G" << txt_option_G;
  cout << "    -b" << txt_option_b;
  cout << "    -M" << txt_option_M;
  cout << "    -n" << txt_option_n_est;
  cout << "    -l" << txt_option_l;
  cout << "    -t" << txt_option_t;
  cout << "    -d" << txt_option_d;
  cout << "    -s" << txt_option_s;
  cout << "    -S" << txt_option_S;
  cout << "    -s2" << txt_option_s2;
  cout << "    -S2" << txt_option_S2;
  cout << "    -aL" << txt_option_aL;
  cout << "    -AL" << txt_option_AL;
  cout << "    -aS" << txt_option_aS;
  cout << "    -AS" << txt_option_AS;
  cout << "    -B" << txt_option_B;
  cout << "    -p" << txt_option_p;
  cout << "    -g" << txt_option_g;
  cout << "    -r" << txt_option_r;
  cout << "    -h print this help\n\n";
  cout << "    Questions, bugs, contact Weizhong Li at liwz@sdsc.edu\n\n";
  cout << "    If you find cd-hit useful, please kindly cite:\n\n";
  cout << "    " << cd_hit_ref1 << "\n";
  cout << "    " << cd_hit_ref3 << "\n\n\n";
  exit(1);
} // END print_usage_est_2d


int print_usage_div (char *arg) {
  cout << "Usage "<< arg << " [Options] \n\nOptions\n\n";
  cout << "Options " << endl << endl;
  cout << "    -i in_dbname, required" << endl;
  cout << "    -o out_dbname, required" << endl;
  cout << "    -div number of divide, required " << endl;
  cout << "    -dbmax max size of your db\n\n\n";
  exit(1);
} // END print_usage_div



int db_seq_no_test(ifstream &in1) {
  char c0, c1;
  int no = 0;

  c0 = '\n';
  while(1) {
    if ( in1.eof()) break;
    in1.read(&c1, 1);
    if ( c1 == '>' && c0 == '\n') no++;
    c0 = c1;
  }
  return no;
}


int db_read_in (ifstream &in1, char *db_bin_swap, 
                int seq_swap, int length_of_throw, 
                int & NR_no, char *NR_seq[], int *NR_len) {

  char raw_seq[MAX_SEQ], raw_des[MAX_DES];
  char buffer1[MAX_LINE_SIZE];
  raw_seq[0] = raw_des[0] = buffer1[0] = 0;
  int read_in = 0;

  ofstream bindb[16];
  int bin_no = 0;
  int total_letter_bin = 0;
  char db_bin_swap_over[MAX_FILE_NAME];
  if (seq_swap) {
    bindb[bin_no].open(db_bin_swap);
    if (! bindb[bin_no]) bomb_error("Can not open", db_bin_swap);
  }
  int jj = -1;

  NR_no = 0;
  while(1) {
    if ( in1.eof()) break;
    in1.getline(buffer1, MAX_LINE_SIZE-2, '\n');

    if ( buffer1[0] == '>') {
      if ( read_in ) { // write previous record
         format_seq(raw_seq);

         if ( strlen(raw_seq) > length_of_throw ) {
           NR_len[NR_no] = strlen(raw_seq);
           if (seq_swap) {
            setiseq(raw_seq, NR_len[NR_no]);
            total_letter_bin += sizeof(int) + NR_len[NR_no];
            // so that size of file < MAX_BIN_SWAP about 2GB
            if ( total_letter_bin >= MAX_BIN_SWAP) {
              bindb[bin_no].write((char *) &jj, sizeof(int)); // signal
              bindb[bin_no].close();
              sprintf(db_bin_swap_over, "%s.%d",db_bin_swap,++bin_no);
              bindb[bin_no].open(db_bin_swap_over);
              if (! bindb[bin_no]) bomb_error("Can not open", db_bin_swap_over);
              total_letter_bin = 0;
            }
            bindb[bin_no].write((char *) &NR_len[NR_no], sizeof(int));
            bindb[bin_no].write(raw_seq, NR_len[NR_no]);
           }
           else {
             if ( (NR_seq[NR_no] = new char[strlen(raw_seq)+2] ) == NULL )
               bomb_error("memory");
             strcpy( NR_seq[NR_no], raw_seq);
           }
           NR_no++;
         }
      }
      strncpy(raw_des, buffer1, MAX_DES-2);
      raw_seq[0] = 0;
    }
    else {
      read_in = 1;
      if ( strlen(raw_seq)+strlen(buffer1) >= MAX_SEQ-1 )
        bomb_error("Too long sequence found, enlarge Macro MAX_SEQ");
      strcat(raw_seq, buffer1);
    }
  } // END while(1);

  if (1) { // the last record
    format_seq(raw_seq);

    if ( strlen(raw_seq) > length_of_throw ) {

      NR_len[NR_no] = strlen(raw_seq);
      if (seq_swap) {
       setiseq(raw_seq, NR_len[NR_no]);
       bindb[bin_no].write((char *) &NR_len[NR_no], sizeof(int));
       bindb[bin_no].write(raw_seq, NR_len[NR_no]);

      }
      else {
        if ( (NR_seq[NR_no] = new char[strlen(raw_seq)+2] ) == NULL )
          bomb_error("memory");
        strcpy( NR_seq[NR_no], raw_seq);
      }
      NR_no++;
    }
  }
  in1.close();
  if (seq_swap) bindb[bin_no].close();
  
  return 0;
} // END db_read_in


// modified from above, but only readin length
int db_read_in_len (ifstream &in1, int length_of_throw, 
                int & NR_no, int *NR_len) {

  char raw_seq[MAX_SEQ], raw_des[MAX_DES];
  char buffer1[MAX_LINE_SIZE];
  raw_seq[0] = raw_des[0] = buffer1[0] = 0;
  int read_in = 0;

  NR_no = 0;
  while(1) {
    if ( in1.eof()) break;
    in1.getline(buffer1, MAX_LINE_SIZE-2, '\n');

    if ( buffer1[0] == '>') {
      if ( read_in ) { // write previous record
         format_seq(raw_seq);
         if ( strlen(raw_seq) > length_of_throw ) {
           NR_len[NR_no] = strlen(raw_seq);
           NR_no++;
         }
      }
      strncpy(raw_des, buffer1, MAX_DES-2);
      raw_seq[0] = 0;
    }
    else {
      read_in = 1;
      if ( strlen(raw_seq)+strlen(buffer1) >= MAX_SEQ-1 )
        bomb_error("Too long sequence found, enlarge Macro MAX_SEQ");
      strcat(raw_seq, buffer1);
    }
  } // END while(1);

  if (1) { // the last record
    format_seq(raw_seq);
    if ( strlen(raw_seq) > length_of_throw ) {
      NR_len[NR_no] = strlen(raw_seq);
      NR_no++;
    }
  }
  in1.close();
  
  return 0;
} // END db_read_in_len


// modified from above, but skip length_of_throw and format_seq
int db_read_in_lenf (ifstream &in1, int & NR_no, int *NR_len) {

  char buffer1[MAX_LINE_SIZE];
  buffer1[0] = 0;
  int read_in = 0;
  int this_len = 0;

  NR_no = 0;
  while(1) {
    if ( in1.eof()) break;
    in1.getline(buffer1, MAX_LINE_SIZE-2, '\n');

    if ( buffer1[0] == '>') {
      if ( read_in ) NR_len[NR_no++] = this_len;
      this_len = 0;
    }
    else {
      read_in = 1;
      this_len += strlen(buffer1);
    }
  } // END while(1);

  if ( read_in ) NR_len[NR_no++] = this_len;
  in1.close();
  
  return 0;
} // END db_read_in_len


int sort_seqs_divide_segs (int seq_swap,
                           int NR_no, int *NR_len, int *NR_idx, char *NR_seq[],
                           long long mem_limit, int NAAN,
                           int &SEG_no, int *SEG_b, int *SEG_e, 
                           char db_swap[MAX_SEG][MAX_FILE_NAME],
                           char db_out[]) {
  int i, j, k, i1;

  // *************************************     change all the NR_seq to iseq
  int len, len1, len2, len22;
  long long total_letter=0;
  int max_len = 0, min_len = 99999;
  for (i=0; i<NR_no; i++) {
    len = NR_len[i];
    total_letter += len;
    if (len > max_len) max_len = len;
    if (len < min_len) min_len = len;
    if (! seq_swap) setiseq(NR_seq[i], len);
  }
  if (max_len >= 65536) 
    bomb_warning("Some seqs longer than 65536, you may define LONG_SEQ");
  cout << "longest and shortest : " << max_len << " and " << min_len << endl;
  cout << "Total letters: " << total_letter << endl;
  // END change all the NR_seq to iseq

  // **************************** Form NR_idx[], Sort them from Long to short
  int *size_no;
  int *size_begin;
  if ((size_no = new int[max_len-min_len+1]) == NULL ) bomb_error("Memory");
  if ((size_begin = new int[max_len-min_len+1]) == NULL ) bomb_error("Memory");

  for (i=max_len; i>=min_len; i--) {
    size_no[max_len - i] = 0;
    size_begin[max_len - i] = 0;
  }
  for (i=0; i<NR_no; i++)  size_no[max_len - NR_len[i]]++;
  for (i=max_len; i>=min_len; i--) {
    if (size_no[max_len-i] ==0) continue;
    for (j=max_len; j>i; j--)
      size_begin[max_len-i] += size_no[max_len-j];
  }
  for (i=max_len; i>=min_len; i--) size_no[max_len - i] = 0;
  for (i=0; i<NR_no; i++) {
    j = max_len-NR_len[i];
    NR_idx[ size_begin[j] + size_no[j]] = i;
    size_no[j]++;
  }
  delete []size_no; delete []size_begin;
  cout << "Sequences have been sorted" << endl;
  // END sort them from long to short

  //RAM that can be allocated
  if (seq_swap) mem_limit -=                29*NR_no + 16 * NAAN;
  else          mem_limit -= total_letter + 29*NR_no + 16 * NAAN;
  
  if ( mem_limit <= 1000000 ) bomb_error("not enough memory, change -M option");

  //RAM can hold how many letters
  if (seq_swap) mem_limit /= sizeof (int) + sizeof (INTs) + 2*sizeof(char);
  else          mem_limit /= sizeof (int) + sizeof (INTs);

  SEG_no=0; j=0; k=0;
  for (i1=0; i1<NR_no; i1++) {
    i = NR_idx[i1];
    len = NR_len[i];
    j += len;
    if ( j>mem_limit ) {
      SEG_b[SEG_no] = k;
      SEG_e[SEG_no] = i1;
      sprintf(db_swap[SEG_no], "%s.SWAP.%d",db_out,SEG_no);
      j=0; k=i1+1;
      SEG_no++;
      if ( SEG_no >= MAX_SEG ) 
        bomb_error("Too many segments, enlarge Macro MAX_SEG or -M option");
    }
  }
  if ( SEG_no == 0 ) {
    SEG_b[SEG_no] = 0;
    SEG_e[SEG_no] = NR_no-1;
    sprintf(db_swap[SEG_no], "%s.SWAP.%d",db_out,SEG_no);
    SEG_no++;
  }
  else if ( SEG_e[SEG_no-1] != NR_no-1 ) { // last Segment
    SEG_b[SEG_no] = k;
    SEG_e[SEG_no] = NR_no-1;
    sprintf(db_swap[SEG_no], "%s.SWAP.%d",db_out,SEG_no);
    SEG_no++;
  }
  if (SEG_no > 1) cout << "Sequences divided into " << SEG_no << " parts\n";

   return 0;
}// END sort_seqs_divide_segs


int db2_seqs_divide_segs (int seq_swap,
                           int NR_no, int *NR_len, char *NR_seq[],
                           long long mem_limit, int NAAN,
                           int &SEG_no, int *SEG_b, int *SEG_e) {
  int i, j, k, i1;

  // *************************************     change all the NR_seq to iseq
  int len, len1, len2, len22;
  long long total_letter=0;
  int max_len = 0, min_len = 99999;
  for (i=0; i<NR_no; i++) {
    len = NR_len[i];
    total_letter += len;
    if (len > max_len) max_len = len;
    if (len < min_len) min_len = len;
    if (! seq_swap) setiseq(NR_seq[i], len);
  }
  if (max_len >= 65536) 
    bomb_warning("Some seqs longer than 65536, you may define LONG_SEQ");

  cout << "longest and shortest : " << max_len << " and " << min_len << endl;
  cout << "Total letters: " << total_letter << endl;
  // END change all the NR_seq to iseq


  //RAM that can be allocated
  if (seq_swap) mem_limit -=                29*NR_no + 16 * NAAN;
  else          mem_limit -= total_letter + 29*NR_no + 16 * NAAN;
  
  if ( mem_limit <= 1000000 ) bomb_error("not enough memory, change -M option");

  //RAM can hold how many letters
  if (seq_swap) mem_limit /= sizeof (int) + sizeof (INTs) + 2*sizeof(char);
  else          mem_limit /= sizeof (int) + sizeof (INTs);

  SEG_no=0; j=0; k=0;
  for (i1=0; i1<NR_no; i1++) {
    i = i1;
    len = NR_len[i];
    j += len;
    if ( j>mem_limit ) {
      SEG_b[SEG_no] = k;
      SEG_e[SEG_no] = i1;
      j=0; k=i1+1;
      SEG_no++;
      if ( SEG_no >= MAX_SEG ) 
        bomb_error("Too many segments, enlarge Macro MAX_SEG or -M option");
    }
  }

  if ( SEG_no == 0 ) {
    SEG_b[SEG_no] = 0;
    SEG_e[SEG_no] = NR_no-1;
    SEG_no++;
  }
  else if ( SEG_e[SEG_no-1] != NR_no-1 ) { // last Segment
    SEG_b[SEG_no] = k;
    SEG_e[SEG_no] = NR_no-1;
    SEG_no++;
  }
  if (SEG_no > 1) cout << "Sequences divided into " << SEG_no << " parts\n";

  return 0;
}// END db2_seqs_divide_segs



int cut_fasta_des(char *des1) {
  int i, len;
  len = strlen(des1);
  for (i=0; i<len; i++) {
    if ( isspace(des1[i]) ) {
      return (i+2);
    }
  }
  return len+2;

}// END cut_fasta_des


int db_read_and_write (ifstream &in1, ofstream &out1, 
                       int length_of_throw, int des_len,
                       char *NR_seq[], int *NR_clstr_no) {

  char raw_seq[MAX_SEQ], raw_des[MAX_DES], raw_seq1[MAX_SEQ];
  char buffer1[MAX_LINE_SIZE];
  raw_seq[0] = raw_des[0] = buffer1[0] = 0;
  int read_in = 0;
  int NR_no1 = 0;
  int des_len1 = 0;

  while(1) {
    if ( in1.eof()) break;
    in1.getline(buffer1, MAX_LINE_SIZE-2, '\n');
    if ( buffer1[0] == '>' || buffer1[0] == ';') {
      if ( read_in ) { // write last record
         strcpy(raw_seq1, raw_seq);
         format_seq(raw_seq1);

         if ( strlen(raw_seq1) > length_of_throw ) {
           if (NR_clstr_no[NR_no1] >= 0 ) out1 << raw_des << "\n" << raw_seq;
           des_len1 = (des_len > 0) ? des_len : cut_fasta_des(raw_des);
           if ((NR_seq[NR_no1] = new char[des_len1] ) == NULL )
             bomb_error("memory");
           strncpy(NR_seq[NR_no1], raw_des, des_len1-2);
           NR_seq[NR_no1][des_len1-2]=0;
           NR_no1++;
         }
      }
      strncpy(raw_des, buffer1, MAX_DES-2);
      
      raw_seq[0] = 0;
    }
    else {
      read_in = 1;
      strcat(raw_seq, buffer1); strcat(raw_seq,"\n");
    }
  } // END while(1);

  if (1) { // the last record
    strcpy(raw_seq1, raw_seq);
    format_seq(raw_seq1);

    if ( strlen(raw_seq1) > length_of_throw ) {
      if (NR_clstr_no[NR_no1] >= 0 ) out1 << raw_des << "\n" << raw_seq;
      des_len1 = (des_len > 0) ? des_len : cut_fasta_des(raw_des);
      if ((NR_seq[NR_no1] = new char[des_len1] ) == NULL )
        bomb_error("memory");
      strncpy(NR_seq[NR_no1], raw_des, des_len1-2);
      NR_seq[NR_no1][des_len1-2]=0;
      NR_no1++;
    }
  }

  return 0;
} // END db_read_and_write



int db_read_des(ifstream &in1, 
                int length_of_throw, int des_len, char *NR_seq[]) {

  char raw_seq[MAX_SEQ], raw_des[MAX_DES], raw_seq1[MAX_SEQ];
  char buffer1[MAX_LINE_SIZE];
  raw_seq[0] = raw_des[0] = buffer1[0] = 0;
  int read_in = 0;
  int NR_no1 = 0;
  int des_len1 = 0;

  while(1) {
    if ( in1.eof()) break;
    in1.getline(buffer1, MAX_LINE_SIZE-2, '\n');
    if ( buffer1[0] == '>' || buffer1[0] == ';') {
      if ( read_in ) { // write last record
        strcpy(raw_seq1, raw_seq);
        format_seq(raw_seq1);

        if ( strlen(raw_seq1) > length_of_throw ) {
          des_len1 = (des_len > 0) ? des_len : cut_fasta_des(raw_des);
          if ((NR_seq[NR_no1] = new char[des_len1] ) == NULL )
            bomb_error("memory");
          strncpy(NR_seq[NR_no1], raw_des, des_len1-2);
          NR_seq[NR_no1][des_len1-2]=0;
          NR_no1++;
        }
      }
      strncpy(raw_des, buffer1, MAX_DES-2);
      raw_seq[0] = 0;
    }
    else {
      read_in = 1;
      strcat(raw_seq, buffer1); strcat(raw_seq,"\n");
    }
  } // END while(1);

  if (1) { // the last record
    strcpy(raw_seq1, raw_seq);
    format_seq(raw_seq1);

    if ( strlen(raw_seq1) > length_of_throw ) {
      des_len1 = (des_len > 0) ? des_len : cut_fasta_des(raw_des);
      if ((NR_seq[NR_no1] = new char[des_len1] ) == NULL )
        bomb_error("memory");
      strncpy(NR_seq[NR_no1], raw_des, des_len1-2);
      NR_seq[NR_no1][des_len1-2]=0;
      NR_no1++;
    }
  }

  return 0;
} // END db_read_des




// get index of a element of a sorted list using 2-div method
// calling get_index_of_sorted_list (list, begin_no, end_no, element)
// list is a sorted list in order of increasing
int get_index_of_sorted_list (int *list, int b, int e, int element) {

  int mid = (b+e) / 2;
  int mid_v = list[mid];

  while( e > b+1 ) {
    mid = (b+e) / 2;
    mid_v = list[mid];

    if      (element > mid_v) { b = mid; }
    else if (element < mid_v) { e = mid; }
    else                      { break; }
  }

  if      (element == mid_v   ) { return mid; }
  else if (element == list[e] ) { return e;   }
  else if (element == list[b] ) { return b;   }
  else                          { return -1;  }
} // END get_index_of_sorted_list


// get index of a element of a sorted list using 2-div method
// calling get_index_of_2_sorted_list (list, list2, begin_no, end_no, element)
// list is a sorted list in order of increasing
// if index of list is same, check list2
int get_index_of_2_sorted_list (int *list, int *list2, int b, int e,
                                int element, int element2) {
  int i = get_index_of_sorted_list(list, b, e, element);
  if ( i == -1 ) { return -1; }

  int bb = i;
  int ee = i;

  while (1) {
    if (bb == b) break;
    if (list[bb] == list[bb-1] ) {bb--;}
    else {break;}
  }

  while(1) {
    if (ee == e) break;
    if (list[ee] == list[ee+1] ) {ee++;}
    else {break;}
  }

  i = get_index_of_sorted_list(list2, bb, ee, element2);
  return i;
} // END get_index_of_2_sorted_list


// read in a segment of sequence
int read_swap_iseq1(int NR_no, char *NR_seq[], char *NR_seg, 
                   int sgj, char *bindbname) {
  int i, j, k, i1, j1, k1;
  char raw_seq1[MAX_SEQ];
  int NR_no1;
  int len1;

  ifstream fswap(bindbname);
  if (! fswap) bomb_error("Can not open file", bindbname);
  for (i=0; i<NR_no; i++) {
    fswap.read((char *) &len1, sizeof(int));
    if (NR_seg[i] == sgj) {
      if ( (NR_seq[i] = new char[len1+2] ) == NULL ) bomb_error("memory");
      fswap.read(NR_seq[i], len1);
    }
    else {
      fswap.read(raw_seq1, len1);
    }
  }
  fswap.close();
  return OK_FUNC;
} // END read_swap_iseq


int free_swap_iseq1(int NR_no, char *NR_seq[], char *NR_seg, int sgj) {
  int i, j, k, i1, j1, k1;

  for (i=0; i<NR_no; i++) {
    if (NR_seg[i] == sgj) {
      delete [] NR_seq[i];
      NR_seq[i] = NULL;
    }
  }
  return OK_FUNC;
} // END free_swap_iseq

int remove_tmp_files(int SEG_no, char db_swap[MAX_SEG][MAX_FILE_NAME], 
                     int seq_swap, char db_bin_swap[]) {
  char cmd[256];
  int i, j, k;

  if (seq_swap) {
    strcpy(cmd, "rm -f ");
    strcat(cmd, db_bin_swap);
    system(cmd);
  }

  for (i=0; i<SEG_no-2; i++) {
    strcpy(cmd, "rm -f ");
    strcat(cmd, db_swap[i]);
    system(cmd);
  }
  return 0;
} // END remove_tmp_files


int remove_tmp_files_db2(int seq_swap, char db_bin_swap[]) {
  char cmd[256];
  int i, j, k;
                                                                                
  if (seq_swap) {
    strcpy(cmd, "rm -f ");
    strcat(cmd, db_bin_swap);
    system(cmd);
  }
  return 0;
} // END remove_tmp_files_db2

void show_cpu_time(tms &CPU_begin, tms &CPU_end) {
  int  ClockTicksPerSecond, total_seconds;
//  ClockTicksPerSecond = (int)sysconf(_SC_CLK_TCK);
//  ClockTicksPerSecond = (int)(100);
  ClockTicksPerSecond = CLOCK_TICKS;

  total_seconds = (CPU_end.tms_utime - CPU_begin.tms_utime) 
                  / ClockTicksPerSecond;

  cout << "Total CPU time " << total_seconds << endl;
} // END  show_current_cpu_time


int read_swap_iseq(int sgj, char *bindbname, 
                   int NR_no, char *NR_seg, char *(*NR_seq)) {
  int i, j, k, i1, j1, k1;
  char raw_seq1[MAX_SEQ];
  int NR_no1;
  int len1;
                                                                                
  int total_letter_bin = 0;
  int bin_no = 0;
  char db_bin_swap_over[MAX_FILE_NAME];
                                                                                
  ifstream fswap(bindbname);
  if (! fswap) bomb_error("can not open file", bindbname);
  for (i=0; i<NR_no; i++) {
    fswap.read((char *) &len1, sizeof(int));
    if (len1 == -1 ) {
      fswap.close();
      sprintf(db_bin_swap_over, "%s.%d",bindbname,++bin_no);
      fswap.open(db_bin_swap_over);
      if (! fswap) bomb_error("Can not open", db_bin_swap_over);
      fswap.read((char *) &len1, sizeof(int));
    }
    if (NR_seg[i] == sgj) {
      if ( (NR_seq[i] = new char[len1+2] ) == NULL ) bomb_error("memory");
      fswap.read(NR_seq[i], len1);
    }
    else {
      fswap.read(raw_seq1, len1);
    }
  }
  fswap.close();
  return OK_FUNC;
} // END read_swap_iseq

int free_swap_iseq(int sgj, int NR_no, char *NR_seg, char *(*NR_seq)) {
  int i, j, k, i1, j1, k1;
                                                                                
  for (i=0; i<NR_no; i++) {
    if (NR_seg[i] == sgj) {
      delete [] NR_seq[i];
      NR_seq[i] = NULL;
    }
  }
  return OK_FUNC;
} // END free_swap_iseq


int lower_bound_length_rep(int len, double opt_s,  int opt_S,
                                    double opt_aL, int opt_AL) {
  int len_need_to_match = 99999999;
  double r1 = (opt_s > opt_aL) ? opt_s : opt_aL;
  int    a2 = (opt_S < opt_AL) ? opt_S : opt_AL;
  if (r1 > 0.0) len_need_to_match = (int) ( ((float) len)  / r1);
  if ((len+a2) < len_need_to_match)  len_need_to_match = len+a2;

  return len_need_to_match;
} // END lower_bound_length_rep


void cal_aax_cutoff(double &aa1_cutoff, double &aa2_cutoff, double &aan_cutoff,
                     double NR_clstr, int tolerance, int naa_stat_start_percent,
                     int naa_stat[5][61][4], int NAA) {
    aa1_cutoff = NR_clstr;
    aa2_cutoff = 1 - (1-NR_clstr)*2;
    aan_cutoff = 1 - (1-NR_clstr)*NAA;
    if (tolerance==0) return; 

    int clstr_idx = (int) (NR_clstr * 100) - naa_stat_start_percent;
    if (clstr_idx <0) clstr_idx = 0;
    double d2  = ((double) (naa_stat[tolerance-1][clstr_idx][3]     )) / 100;
    double dn  = ((double) (naa_stat[tolerance-1][clstr_idx][5-NAA] )) / 100;
    aa2_cutoff = d2 > aa2_cutoff ? d2 : aa2_cutoff;
    aan_cutoff = dn > aan_cutoff ? dn : aan_cutoff;
    return;
} // END cal_aax_cutoff


void update_aax_cutoff(double &aa1_cutoff, double &aa2_cutoff, double &aan_cutoff,
                     int tolerance, int naa_stat_start_percent,
                     int naa_stat[5][61][4], int NAA, int iden) {
  double NR_clstr;
  NR_clstr = ((double)(iden)) / 100.0;
  if (NR_clstr > 1.0) NR_clstr = 1.00;

  double aa1_t, aa2_t, aan_t;
  cal_aax_cutoff(aa1_t, aa2_t, aan_t, NR_clstr, tolerance, naa_stat_start_percent,
                 naa_stat, NAA);
  if (aa1_t > aa1_cutoff) aa1_cutoff = aa1_t;
  if (aa2_t > aa2_cutoff) aa2_cutoff = aa2_t;
  if (aan_t > aan_cutoff) aan_cutoff = aan_t;
  return;  
} // END update_aax_cutoff


void calc_required_aax(int &required_aa1, int &required_aa2, int &required_aan,
                       double aa1_cutoff, double aa2_cutoff, double aan_cutoff,
                       int len_eff, int NAA) {
  required_aa1 = int (aa1_cutoff* (double) len_eff);
  required_aa2 = (aa1_cutoff > 0.95) ?
                 len_eff-2  +1-(len_eff-required_aa1)*2   :
                 int (aa2_cutoff* (double) len_eff);
  required_aan = (aa1_cutoff > 0.95) ?
                 len_eff-NAA+1-(len_eff-required_aa1)*NAA :
                 int (aan_cutoff* (double) len_eff);
} // END calc_required_aax


void calc_required_aaxN(int &required_aa1, int &required_aas, int &required_aan,
                       double aa1_cutoff, double aas_cutoff, double aan_cutoff,
                       int len_eff, int NAA, int ss) {
    required_aa1 = int (aa1_cutoff* (double) len_eff);
    required_aas = (aa1_cutoff > 0.95) ?
                   len_eff-ss  +1-(len_eff-required_aa1)*ss   :
                   int (aas_cutoff* (double) len_eff);
    required_aan = (aa1_cutoff > 0.95) ?
                   len_eff-NAA+1-(len_eff-required_aa1)*NAA :
                   int (aan_cutoff* (double) len_eff);
} // END calc_required_aaxN

/////////////////////////// END ALL ////////////////////////

