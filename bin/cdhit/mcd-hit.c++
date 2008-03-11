// =============================================================================
// CD-HIT
// http://cd-hit.org/
// http://bioinformatics.burnham-inst.org/cd-hi
// 
// program written by
//                                      Weizhong Li
//                                      UCSD, San Diego Supercomputer Center
//                                      La Jolla, CA, 92093
//                                      Email liwz@sdsc.edu
//                 at
//                                      Adam Godzik's lab
//                                      The Burnham Institute
//                                      La Jolla, CA, 92037
//                                      Email adam@burnham-inst.org
// =============================================================================

#include "cd-hi.h"
#include "cd-hi-init.h"

////////////////////////////////////  MAIN /////////////////////////////////////
int main(int argc, char **argv) {
  int i, j, k, i1, j1, k1, i0, j0, k0, sg_i, sg_j;
  int si, sj, sk;
  char db_in[MAX_FILE_NAME];
  char db_out[MAX_FILE_NAME];
  char db_clstr[MAX_FILE_NAME];
  char db_clstr_bak[MAX_FILE_NAME];
  char db_clstr_old[MAX_FILE_NAME];
  char db_bin_swap[MAX_FILE_NAME];

  // ***********************************    parse command line and open file
  if (argc < 5) print_usage(argv[0]);
  for (i=1; i<argc; i++) {
    if      (strcmp(argv[i], "-i" ) == 0) strncpy(db_in,  argv[++i], MAX_FILE_NAME-1);
    else if (strcmp(argv[i], "-o" ) == 0) strncpy(db_out, argv[++i], MAX_FILE_NAME-1);
    else if (strcmp(argv[i], "-M" ) == 0) option_M  = atoll(argv[++i]) * 1000000;
    else if (strcmp(argv[i], "-l" ) == 0) option_l  = atoi(argv[++i]);
    else if (strcmp(argv[i], "-c" ) == 0) NR_clstr  = atof(argv[++i]);
    else if (strcmp(argv[i], "-b" ) == 0) option_b  = atoi(argv[++i]);
    else if (strcmp(argv[i], "-n" ) == 0) NAA       = atoi(argv[++i]);
    else if (strcmp(argv[i], "-d" ) == 0) des_len   = atoi(argv[++i]);
    else if (strcmp(argv[i], "-t" ) == 0) tolerance = atoi(argv[++i]);
    else if (strcmp(argv[i], "-s" ) == 0) option_s  = atof(argv[++i]);
    else if (strcmp(argv[i], "-S" ) == 0) option_S  = atoi(argv[++i]);
    else if (strcmp(argv[i], "-B" ) == 0) option_B  = atoi(argv[++i]);
    else if (strcmp(argv[i], "-p" ) == 0) option_p  = atoi(argv[++i]);
    else if (strcmp(argv[i], "-g" ) == 0) option_g  = atoi(argv[++i]);
    else if (strcmp(argv[i], "-G" ) == 0) option_G  = atoi(argv[++i]);
    else if (strcmp(argv[i], "-aL") == 0) option_aL = atof(argv[++i]);
    else if (strcmp(argv[i], "-AL") == 0) option_AL = atoi(argv[++i]);
    else if (strcmp(argv[i], "-aS") == 0) option_aS = atof(argv[++i]);
    else if (strcmp(argv[i], "-AS") == 0) option_AS = atoi(argv[++i]);
    else                                  print_usage(argv[0]);
  }
  if (1) {
      if ((NR_clstr > 1.0) || (NR_clstr < 0.4)) bomb_error("invalid clstr");
      if (option_b < 1 ) bomb_error("invalid band width");
      if (NAA < 2 || NAA > 5 ) bomb_error("invalid word length");
      if (des_len < 0 )
        bomb_error("too short description, not enough to identify sequences");
      if ( tolerance < 0 || tolerance > 5 ) bomb_error("invalid tolerance");
      if ((option_s<0) || (option_s>1))
        bomb_error("invalid value for -s");
      if (option_S<0) bomb_error("invalid value for -S");
      if (option_G == 0) option_p = 1;
      if (option_aS < option_aL) option_aS = option_aL;
      if (option_AS > option_AL) option_AS = option_AL;
      if (option_G == 0 && option_aS == 0.0)
        bomb_error("You are using local identity, but no -aS -aL option");
  }
  NR_clstr100 = (int) (NR_clstr * 100 );
  db_clstr[0]=0; strcat(db_clstr,db_out); strcat(db_clstr,".clstr");
  db_clstr_bak[0]=0; strcat(db_clstr_bak,db_out); 
  strcat(db_clstr_bak,".bak.clstr");

  if      ( NAA == 2 ) { NAAN = NAA2; }
  else if ( NAA == 3 ) { NAAN = NAA3; }
  else if ( NAA == 4 ) { NAAN = NAA4; }
  else if ( NAA == 5 ) { NAAN = NAA5; }
  else bomb_error("invalid -n parameter!");

  word_table.init(NAA, NAAN);

  if ( tolerance ) {
    int clstr_idx = (int) (NR_clstr * 100) - naa_stat_start_percent;
    int tcutoff = naa_stat[tolerance-1][clstr_idx][5-NAA];

    if (tcutoff < 5 )
      bomb_error("Too short word length, increase it or the tolerance");
    for ( i=5; i>NAA; i--) {
      if ( naa_stat[tolerance-1][clstr_idx][5-i] > 10 ) {
        cout << "Your word length is " << NAA << ", using "
             << i << " may be faster!" <<endl;
        break;
      }
    }
  }
  else {
   if      ( NR_clstr > 0.85 && NAA < 5)
      cout << "Your word length is " << NAA 
           << ", using 5 may be faster!" <<endl;
    else if ( NR_clstr > 0.80 && NAA < 4 )
      cout << "Your word length is " << NAA 
           << ", using 4 may be faster!" <<endl;
    else if ( NR_clstr > 0.75 && NAA < 3 )
      cout << "Your word length is " << NAA 
           << ", using 3 may be faster!" <<endl;
  }

  if ( option_l <= NAA ) bomb_error("Too short -l, redefine it");

  ifstream in1a(db_in);    if (! in1a) bomb_error("Can not open ", db_in);
  ofstream out1(db_out);   if (! out1) bomb_error("Can not open ", db_out);
  ofstream out2(db_clstr); if (! out2) bomb_error("Can not open ", db_clstr);
  ofstream out2b(db_clstr_bak); if (! out2b) 
                                  bomb_error("Can not open ", db_clstr_bak);
  strcpy(db_bin_swap,db_out); strcat(db_bin_swap,".BINSWAP");

  DB_no = db_seq_no_test(in1a); in1a.close();
  ifstream in1(db_in);
  if ( ! in1) { cout << "Can not open file twice" << db_in << endl; exit(1); }

  if ((NR_len      = new int   [DB_no]) == NULL) bomb_error("Memory");
  if ((NR_idx      = new int   [DB_no]) == NULL) bomb_error("Memory");
  if ((NR90_idx    = new int   [DB_no]) == NULL) bomb_error("Memory");
  if ((NR_clstr_no = new int   [DB_no]) == NULL) bomb_error("Memory");
  if ((NR_iden     = new char  [DB_no]) == NULL) bomb_error("Memory");
  if ((NR_seg      = new char  [DB_no]) == NULL) bomb_error("Memory");
  if ((NR_flag     = new char  [DB_no]) == NULL) bomb_error("Memory");
  if ((NR_seq      = new char *[DB_no]) == NULL) bomb_error("Memory");
  int *Clstr_no, *(*Clstr_list);
  if ((Clstr_no    = new int   [DB_no]) == NULL) bomb_error("Memory");
  if ((Clstr_list  = new int  *[DB_no]) == NULL) bomb_error("Memory");
  if ((NR90f_idx   = new int   [DB_no]) == NULL) bomb_error("Memory");
  if (option_p) {
    if ((NR_info  = new int  *[DB_no]) == NULL) bomb_error("Memory");
  }

  db_read_in(in1, db_bin_swap, option_B, option_l, NR_no, NR_seq, 
               NR_len);
  in1.close();
  cout << "total seq: " << NR_no << endl;

  // ********************************************* init NR_flag
  for (i=0; i<NR_no; i++) {NR_flag[i] = 0; NR_iden[i] = 0;}

  sort_seqs_divide_segs(option_B, NR_no, NR_len, NR_idx, NR_seq, option_M,
                        NAAN, SEG_no, SEG_b, SEG_e, db_swap, db_out);

  for (sg_i=0; sg_i<SEG_no; sg_i++) {
    for (i1=SEG_b[sg_i]; i1<=SEG_e[sg_i]; i1++) {
      i = NR_idx[i1];
      NR_seg[i] = sg_i;
    }
  }


  // *********************************************                Main loop
  char *seqi;
  double aa1_cutoff, aa2_cutoff, aan_cutoff;
  int len, hit_no, has_aa2, iden_no, aan_no, segb;
  int aan_list[MAX_SEQ];
  INTs aan_list_no[MAX_SEQ];
  INTs *look_and_count;
  int len_need_to_match;
  int len_cov;
  int frg1, frg2, segfb;
  int aan_list_backup[MAX_SEQ];
  NR_frag_no = 0; 
  for (i=0; i<NR_no; i++) NR_frag_no += (NR_len[i] - NAA ) / Frag_size + 1;
  int check_this_info[32];
  double check_this_infod[32];
  check_this_info[0]   = option_p;
  check_this_info[10]  = option_G;
  check_this_infod[11] = option_aL;
  check_this_info[12]  = option_AL;
  check_this_infod[13] = option_aS;
  check_this_info[14]  = option_AS;
  check_this_info[20]  = option_g;
  if ((look_and_count= new INTs[NR_frag_no]) == NULL) bomb_error("Memory");

  cal_aax_cutoff(aa1_cutoff, aa2_cutoff, aan_cutoff, NR_clstr,
                 tolerance, naa_stat_start_percent, naa_stat, NAA);
  NR90_no = 0; NR90f_no = 0;
  for (sg_i=0; sg_i<SEG_no; sg_i++) {
    if (SEG_no >1)
      cout << "SEG " << sg_i << " " << SEG_b[sg_i] << " " << SEG_e[sg_i] <<endl;
    if(option_B) read_swap_iseq(sg_i, db_bin_swap, NR_no, NR_seg, NR_seq);

    for (sg_j=sg_i-1; sg_j>=0; sg_j--) {
      // length of first (and also longest) sequence of this segment sg_i
      len = NR_len[ NR_idx[SEG_b[sg_i]] ];
      len_need_to_match = lower_bound_length_rep(len,
        option_s, option_S, option_aL, option_AL);

      // length of last (and also shortest) sequence of segment sg_j
      // if it > len_need_to_match,
      // seqs in sg_i won't be compared to seqs in sg_j
      if ( NR_len[ NR_idx[SEG_e[sg_j]] ] > len_need_to_match ) continue;

      cout << "Reading swap" << endl;
      // reading old segment
      if(option_B) read_swap_iseq(sg_j, db_bin_swap, NR_no, NR_seg, NR_seq);
      if ( sg_j != sg_i-1) word_table.read_tbl(db_swap[sg_j]);
      cout << "Comparing with SEG " << sg_j << endl;
      for (i1=SEG_b[sg_i]; i1<=SEG_e[sg_i]; i1++) {
        i = NR_idx[i1];
        if (NR_flag[i] & IS_REDUNDANT ) continue;
        len = NR_len[i]; seqi = NR_seq[i];
        len_need_to_match = lower_bound_length_rep(len,
          option_s, option_S, option_aL, option_AL);

        frg1 = (len - NAA ) / Frag_size + 1;
        frg2 = (len - NAA + option_b ) / Frag_size + 1;
        has_aa2 = 0;
        iden_no =  NR_iden[i];
        int flag = check_this_short(len, seqi, has_aa2,
               NAA, aan_no, aan_list, aan_list_no,
                            aan_list_backup, look_and_count,
               hit_no, SEG90_b[sg_j], SEG90_e[sg_j],
               frg2, SEG90f_b[sg_j], SEG90f_e[sg_j], iden_no,
               aa1_cutoff, aa2_cutoff, aan_cutoff,
               NR_flag[i], NR_flag, len_need_to_match, check_this_info, check_this_infod);

        if ( flag == 1) {       // if similar to old one delete it
          if (! option_g) {
            if (! option_B) delete [] NR_seq[i];
            NR_flag[i] |= IS_REDUNDANT ;
          }
          NR_clstr_no[i] = -hit_no-1;  // (-hit_no-1) for non representatives
          NR_iden[i] = iden_no;
          if (option_p){
            if ((NR_info[i] = new int [4]) == NULL) bomb_error("Memory");
            NR_info[i][0] = check_this_info[1]+1;
            NR_info[i][1] = check_this_info[2]+1;
            NR_info[i][2] = check_this_info[3]+1;
            NR_info[i][3] = check_this_info[4]+1;
          }
        }
      } //for (i1=SEG_b[sg_i]; i1<=SEG_e[sg_i]; i1++)
      if(option_B) free_swap_iseq(sg_j, NR_no, NR_seg, NR_seq);
    } // for (sg_j=0; sg_j<sg_i; sg_j++)

    if (SEG_no >1) cout << "Refresh Memory" << endl;
    word_table.clean();

    if (SEG_no >1) cout << "Self comparing" << endl;
    segb = NR90_no;
    segfb = NR90f_no;
    for (i1=SEG_b[sg_i]; i1<=SEG_e[sg_i]; i1++) {
      i = NR_idx[i1];

      if ( ! (NR_flag[i] & IS_REDUNDANT) ) {
        len = NR_len[i]; seqi = NR_seq[i];
        len_need_to_match = lower_bound_length_rep(len,
          option_s, option_S, option_aL, option_AL);
        frg1 = (len - NAA ) / Frag_size + 1;
        frg2 = (len - NAA + option_b ) / Frag_size + 1;
        has_aa2 = 0;
        iden_no =  NR_iden[i];
        int flag = check_this_short(len, seqi, has_aa2,
               NAA, aan_no, aan_list, aan_list_no,
                            aan_list_backup, look_and_count,
               hit_no, segb, NR90_no-1, frg2, segfb, NR90f_no-1, iden_no,
               aa1_cutoff, aa2_cutoff, aan_cutoff,
               NR_flag[i], NR_flag, len_need_to_match, check_this_info, check_this_infod);
    
        if ( flag == 1) {       // if similar to old one delete it
          if (! option_B) delete [] NR_seq[i];
          NR_clstr_no[i] = -hit_no-1;  // (-hit_no-1) for non representatives
          NR_iden[i] = iden_no;
          NR_flag[i] |= IS_REDUNDANT ;
          if (option_p){
            if ((NR_info[i] = new int [4]) == NULL) bomb_error("Memory");
            NR_info[i][0] = check_this_info[1]+1;
            NR_info[i][1] = check_this_info[2]+1;
            NR_info[i][2] = check_this_info[3]+1;
            NR_info[i][3] = check_this_info[4]+1;
          }
        }
        else if ((NR_iden[i]>0) && (option_g)) {
          // because of the -g option, this seq is similar to seqs in old SEGs
          NR_flag[i] |= IS_REDUNDANT ;
          if (! option_B) delete [] NR_seq[i];
        }
        else {                  // else add to NR90 db
          NR90_idx[NR90_no] = i;
          NR_clstr_no[i] = NR90_no; // positive value for representatives
          NR_iden[i] = 0;
          NR_flag[i] |= IS_REP;
          add_in_lookup_table_short(aan_no, frg1, aan_list_backup,
                                    aan_list_no);
          NR90f_idx[NR90_no] = NR90f_no;
          NR90f_no += frg1;
          NR90_no++;
        } // else
      } // if ( ! (NR_flag[i] & IS_REDUNDANT) )
  
      if ( (i1+1) % 100 == 0 ) { 
        cout << ".";
        if ( (i1+1) % 1000 == 0 )
          cout << i1+1 << " finished\t" << NR90_no << " clusters" << endl;
      }
    } // for (i1=SEG_b[sg_i]; i1<=SEG_e[sg_i]; i1++) {

    SEG90_b[sg_i] = segb;  SEG90_e[sg_i] = NR90_no-1;
    SEG90f_b[sg_i] = segfb; SEG90f_e[sg_i] = NR90f_no-1;
    // if not last segment
    if ( sg_i < SEG_no-2 ) word_table.write_tbl( db_swap[sg_i] );

    if(option_B) free_swap_iseq(sg_i, NR_no, NR_seg, NR_seq);
  } // for (sg_i=0; sg_i<SEG_no; sg_i++) {
  cout << endl;
  cout << NR_no << " finished\t" << NR90_no << " clusters" << endl;

  if (! option_B) for (i=0; i<NR90_no; i++)  delete [] NR_seq[ NR90_idx[i] ];

  cout << "writing new database" << endl;
  ifstream in1b(db_in);
  if ( ! in1b) { cout << "Can not open file twice" << db_in << endl; exit(1); }
  db_read_and_write(in1b, out1, option_l, des_len, NR_seq, NR_clstr_no);
  in1b.close(); out1.close();

  // write a backup clstr file in case next step crashes
  for (i=0; i<NR_no; i++) {
    j1 = NR_clstr_no[i];
    if ( j1 < 0 ) j1 =-j1-1;
    out2b << j1 << "\t" << NR_len[i] << "aa, "<< NR_seq[i] << "...";
    if ( NR_iden[i]>0 ) {
      out2b << " at ";
      if (option_p)
        out2b << NR_info[i][0] << ":" << NR_info[i][1] << ":"
              << NR_info[i][2] << ":" << NR_info[i][3] << "/";
      out2b << int(NR_iden[i]) << "%" << endl;
    }
    else out2b << " *" << endl;
  }
  out2b.close();

  cout << "writing clustering information" << endl;
  // write clstr information
//  I mask following 3 lines, because it crash when clusters NR
//  I thought maybe there is not a big block memory now, so
//  move the new statement to the begining of program, but because I
//  don't know the NR90_no, I just use DB_no instead
//  int *Clstr_no, *(*Clstr_list);
//  if ((Clstr_no   = new int[NR90_no]) == NULL) bomb_error("Memory");
//  if ((Clstr_list = new int*[NR90_no]) == NULL) bomb_error("Memory");

  for (i=0; i<NR90_no; i++) Clstr_no[i]=0;
  for (i=0; i<NR_no; i++) {
    j1 = NR_clstr_no[i];
    if ( j1 < 0 ) j1 =-j1-1;
    Clstr_no[j1]++;
  }
  for (i=0; i<NR90_no; i++) {
    if((Clstr_list[i] = new int[ Clstr_no[i] ]) == NULL) bomb_error("Memory");
    Clstr_no[i]=0;
  }

  for (i=0; i<NR_no; i++) {
    j1 = NR_clstr_no[i];
    if ( j1 < 0 ) j1 =-j1-1;
    Clstr_list[j1][ Clstr_no[j1]++ ] = i;
  }

  for (i=0; i<NR90_no; i++) {
    out2 << ">Cluster " << i << endl;
    for (k=0; k<Clstr_no[i]; k++) {
      j = Clstr_list[i][k];
      out2 << k << "\t" << NR_len[j] << "aa, "<< NR_seq[j] << "...";

      if ( NR_iden[j]>0 ) {
        out2 << " at ";
        if (option_p)
          out2 << NR_info[j][0] << ":" << NR_info[j][1] << ":"
               << NR_info[j][2] << ":" << NR_info[j][3] << "/";
        out2 << int(NR_iden[j]) << "%" << endl;
      }
      else                  out2 << " *" << endl;
    }
  }
  out2.close();
  cout << "program completed !" << endl << endl;

  times(&CPU_end);
  show_cpu_time(CPU_begin, CPU_end);

  remove_tmp_files(SEG_no, db_swap, option_B, db_bin_swap);
  return 0;
} // END int main

///////////////////////FUNCTION of common tools////////////////////////////

int check_this_short(int len, char *seqi, int &has_aa2,
               int NAA, int& aan_no, int *aan_list, INTs *aan_list_no,
                                     int *aan_list_backup,
               INTs *look_and_count,
               int &hit_no, int libb, int libe, 
               int frg2, int libfb, int libfe, int &iden_no,
               double aa1_cutoff, double aa2_cutoff, double aan_cutoff,
               char this_flag, char *NR_flag, int len_need_to_match,
               int *check_this_info, double *check_this_infod) {

  static int  taap[MAX_UAA*MAX_UAA];
  static INTs aap_list[MAX_SEQ];
  static INTs aap_begin[MAX_UAA*MAX_UAA];

  int i, j, k, i1, j1, k1, i0, j0, k0, c22, sk, mm;
  int len_eff, aln_cover_flag, min_aln_lenS, min_aln_lenL;
  int required_aa1, required_aa2, required_aan;

  len_eff = len;
  aln_cover_flag = 0;
  if (check_this_infod[13] > 0.0) { // has alignment coverage control
    aln_cover_flag = 1;
    min_aln_lenS = (int) (double(len) * check_this_infod[13]);
    if ( len-check_this_info[14] > min_aln_lenS)
      min_aln_lenS = len-check_this_info[14];
  }
  if (check_this_info[10] == 0) len_eff = min_aln_lenS; //option_G==0
  calc_required_aax(required_aa1, required_aa2, required_aan,
                    aa1_cutoff,   aa2_cutoff,   aan_cutoff, len_eff, NAA);

  // check_aan_list
  aan_no = len - NAA + 1;
  if      ( NAA == 2)
    for (j=0; j<aan_no; j++)
      aan_list_backup[j] = aan_list[j] = seqi[j]*NAA1 + seqi[j+1];
  else if ( NAA == 3)
    for (j=0; j<aan_no; j++)
      aan_list_backup[j] = aan_list[j] = 
        seqi[j]*NAA2 + seqi[j+1]*NAA1 + seqi[j+2];
 else if ( NAA == 4)
    for (j=0; j<aan_no; j++)
      aan_list_backup[j] = aan_list[j] =
        seqi[j]*NAA3+seqi[j+1]*NAA2 + seqi[j+2]*NAA1 + seqi[j+3];
  else if ( NAA == 5)
    for (j=0; j<aan_no; j++)
      aan_list_backup[j] = aan_list[j] =
        seqi[j]*NAA4+seqi[j+1]*NAA3+seqi[j+2]*NAA2+seqi[j+3]*NAA1+seqi[j+4];

  else return FAILED_FUNC;
  
  quick_sort(aan_list,0,aan_no-1);
  for(j=0; j<aan_no; j++) aan_list_no[j]=1;
  for(j=aan_no-1; j; j--) {
    if (aan_list[j] == aan_list[j-1]) {
      aan_list_no[j-1] += aan_list_no[j];
      aan_list_no[j]=0;
    }
  }
  // END check_aan_list


  // lookup_aan
  for (j=libfe; j>=libfb; j--) look_and_count[j]=0;
  word_table.count_word_no(aan_no, aan_list, aan_list_no, look_and_count);


  // contained_in_old_lib()
  int band_left, band_right, best_score, band_width1, best_sum, len2, alnln, len_eff1;
  int tiden_no;
  int talign_info[5];
  int best1, sum;
  int len1 = len - 1;
  INTs *lookptr;

  char *seqj;
  int flag = 0;      // compare to old lib
  for (j=libe; j>=libb; j--) {
    len2 = NR_len[NR90_idx[j]];
    if (len2 > len_need_to_match ) continue;
    k = (len2 - NAA) / Frag_size + 1;
    lookptr = &look_and_count[ NR90f_idx[j] ];

    if ( frg2 >= k ) {
      best1=0;
      for (j1=0; j1<k; j1++) best1 += lookptr[j1];
    }
    else {
      sum = 0;
      for (j1=0; j1<frg2; j1++) sum += lookptr[j1];
      best1 = sum;
      for (j1=frg2; j1<k; j1++) {
        sum += lookptr[j1] - lookptr[j1-frg2];
        if (sum > best1) best1 = sum;
      }
    }

    if ( best1 < required_aan ) continue;
    seqj = NR_seq[NR90_idx[j]];

    if (aln_cover_flag) {
      min_aln_lenL = (int) (double(len2) * check_this_infod[11]);
      if ( len2-check_this_info[12] > min_aln_lenL)
        min_aln_lenL = len2-check_this_info[12];
    }
    
    if ( has_aa2 == 0 )  { // calculate AAP array
      for (sk=0; sk<NAA2; sk++) taap[sk] = 0;
      for (j1=0; j1<len1; j1++) {
        c22= seqi[j1]*NAA1 + seqi[j1+1]; 
        taap[c22]++;
      }
      for (sk=0,mm=0; sk<NAA2; sk++) { 
        aap_begin[sk] = mm; mm+=taap[sk]; taap[sk] = 0;
      }
      for (j1=0; j1<len1; j1++) {
        c22= seqi[j1]*NAA1 + seqi[j1+1]; 
        aap_list[aap_begin[c22]+taap[c22]++] =j1;
      }
      has_aa2 = 1;
    }

    band_width1 = (option_b < len+len2-2 ) ? option_b : len+len2-2;
    diag_test_aapn(NAA1, seqj, len, len2, taap, aap_begin, 
                           aap_list, best_sum,
                           band_width1, band_left, band_right, required_aa1);
    if ( best_sum < required_aa2 ) continue;

   if (check_this_info[0]) //return overlap region
      local_band_align2(seqi, seqj, len, len2, mat,
                        best_score, tiden_no, band_left, band_right,
                        talign_info[1],talign_info[2],
                        talign_info[3],talign_info[4],alnln);
    else
      local_band_align(seqi, seqj, len, len2, mat,
                             best_score, tiden_no, band_left, band_right);
    if ( tiden_no < required_aa1 ) continue;
    len_eff1 = (check_this_info[10] == 0) ? alnln : len;
    tiden_no = tiden_no * 100 / len_eff1;
    if (tiden_no < NR_clstr100) continue;
    if (tiden_no <= iden_no) continue; // existing iden_no
    if (aln_cover_flag) {
      if ( talign_info[4]-talign_info[3]+1 < min_aln_lenL) continue;
      if ( talign_info[2]-talign_info[1]+1 < min_aln_lenS) continue;
    }
    flag = 1; iden_no = tiden_no; hit_no = j;
    check_this_info[1] = talign_info[1];
    check_this_info[2] = talign_info[2];
    check_this_info[3] = talign_info[3];
    check_this_info[4] = talign_info[4];
    if (check_this_info[20]) { // option_g
      update_aax_cutoff(aa1_cutoff, aa2_cutoff, aan_cutoff,
                        tolerance, naa_stat_start_percent, naa_stat, NAA, iden_no);
      calc_required_aax(required_aa1, required_aa2, required_aan,
                        aa1_cutoff,   aa2_cutoff,   aan_cutoff, len_eff, NAA);
    }
    else {
      break;
    }
  }
  return flag;
  // END contained_in_old_lib()
} // END check_this_short


int add_in_lookup_table_short(int aan_no, int frg1,
                              int *aan_list, INTs *aan_list_no) {
  int i, j, k, i1, j1, k1, i0, j0, k0, fra;

  for (i=0; i<frg1; i++) {
    k = (i+1)*Frag_size < aan_no ? (i+1)*Frag_size-1: aan_no-1;
    quick_sort(aan_list, i*Frag_size, k);
  }
  for(j=aan_no-1; j; j--) {
    if (aan_list[j] == aan_list[j-1]) {
      aan_list_no[j-1] += aan_list_no[j];
      aan_list_no[j]=0;
    }
  }
  // END check_aan_list

  for (i=0; i<aan_no; i+=Frag_size) {
    k = Frag_size < (aan_no-i) ? Frag_size : (aan_no -i);
    fra=i/Frag_size;
    word_table.add_word_list(k, aan_list+i, aan_list_no+i, NR90f_no+fra);
  }

  return 0;
}  // END add_in_lookup_table


/////////////////////////// END ALL ////////////////////////
