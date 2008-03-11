// =============================================================================
// CD-HI-EST
// http://cd-hit.org/
// Cluster Database at High Identity (EST version)
// modified from CD-HI
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
//over-write some defs in cd-hi.h for est version
#undef MAX_UAA
#define MAX_UAA 5

#include "cd-hi-init.h"
//over-write some defs in cd-hi-init.h for est version
int *Comp_AAN_idx;
char seqi_comp[MAX_SEQ];
int aan_list_comp[MAX_SEQ];

void setaa_to_na();
void make_comp_short_word_index(int NAA);
void make_comp_iseq(int len, char *iseq_comp, char *iseq);

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

  NAA = 8;
  NAAN = NAA8;
  setaa_to_na();
  mat.set_to_na(); //mat.set_gap(-6,-1);

  times(&CPU_begin);

  // ***********************************    parse command line and open file
  if (argc < 5) print_usage_est(argv[0]);
  for (i=1; i<argc; i++) {
    if      (strcmp(argv[i], "-i" ) == 0) strncpy(db_in,  argv[++i], MAX_FILE_NAME-1);
    else if (strcmp(argv[i], "-o" ) == 0) strncpy(db_out, argv[++i], MAX_FILE_NAME-1);
    else if (strcmp(argv[i], "-M" ) == 0) option_M  = atoll(argv[++i]) * 1000000;
    else if (strcmp(argv[i], "-l" ) == 0) option_l  = atoi(argv[++i]);
    else if (strcmp(argv[i], "-c" ) == 0) NR_clstr  = atof(argv[++i]);
    else if (strcmp(argv[i], "-b" ) == 0) option_b  = atoi(argv[++i]);
    else if (strcmp(argv[i], "-n" ) == 0) NAA       = atoi(argv[++i]);
    else if (strcmp(argv[i], "-d" ) == 0) des_len   = atoi(argv[++i]);
    else if (strcmp(argv[i], "-s" ) == 0) option_s  = atof(argv[++i]);
    else if (strcmp(argv[i], "-S" ) == 0) option_S  = atoi(argv[++i]);
    else if (strcmp(argv[i], "-B" ) == 0) option_B  = atoi(argv[++i]);
    else if (strcmp(argv[i], "-r" ) == 0) option_r  = atoi(argv[++i]); 
    else if (strcmp(argv[i], "-p" ) == 0) option_p  = atoi(argv[++i]);
    else if (strcmp(argv[i], "-g" ) == 0) option_g  = atoi(argv[++i]);
    else if (strcmp(argv[i], "-G" ) == 0) option_G  = atoi(argv[++i]);
    else if (strcmp(argv[i], "-aL") == 0) option_aL = atof(argv[++i]);
    else if (strcmp(argv[i], "-AL") == 0) option_AL = atoi(argv[++i]);
    else if (strcmp(argv[i], "-aS") == 0) option_aS = atof(argv[++i]);
    else if (strcmp(argv[i], "-AS") == 0) option_AS = atoi(argv[++i]);
    else                                  print_usage_est(argv[0]);
  }
  if (1) {
      if ((NR_clstr > 1.0) || (NR_clstr < 0.8)) 
        bomb_error("invalid clstr threshold, should >=0.8");
      if (option_b < 1 ) bomb_error("invalid band width");
      if ( NAA < 2 || NAA > 10 ) bomb_error("invalid word length");
      if ( des_len < 0 ) 
        bomb_error("too short description, not enough to identify sequences");
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
  db_clstr_bak[0]=0;
  strcat(db_clstr_bak,db_out); strcat(db_clstr_bak,".bak.clstr");

  if      ( NAA == 2 ) { NAAN = NAA2; }
  else if ( NAA == 3 ) { NAAN = NAA3; }
  else if ( NAA == 4 ) { NAAN = NAA4; }
  else if ( NAA == 5 ) { NAAN = NAA5; }
  else if ( NAA == 6 ) { NAAN = NAA6; }
  else if ( NAA == 7 ) { NAAN = NAA7; }
  else if ( NAA == 8 ) { NAAN = NAA8; }
  else if ( NAA == 9 ) { NAAN = NAA9; }
  else if ( NAA ==10 ) { NAAN = NAA10;}
  else bomb_error("invalid -n parameter!");


  word_table.set_dna();
  word_table.init(NAA, NAAN);

  if (1) {
    if      ( NR_clstr > 0.9  && NAA < 8)
      cout << "Your word length is " << NAA
           << ", using 8 may be faster!" <<endl;
    else if ( NR_clstr > 0.87 && NAA < 5)
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

  if ( option_r ) {
    if ((Comp_AAN_idx = new int[NAAN]) == NULL) bomb_error("Memory");
    make_comp_short_word_index(NAA);
  }


  ifstream in1a(db_in);    if (! in1a) bomb_error("Can not open", db_in);
  ofstream out1(db_out);   if (! out1) bomb_error("Can not open", db_out);
  ofstream out2(db_clstr); if (! out2) bomb_error("Can not open", db_clstr);
  ofstream out2b(db_clstr_bak); if (! out2b)
                                  bomb_error("Can not open", db_clstr_bak);
  strcpy(db_bin_swap,db_out); strcat(db_bin_swap,".BINSWAP");

  DB_no = db_seq_no_test(in1a); in1a.close();
  ifstream in1(db_in);
  if (! in1) bomb_error("Can not open file", db_in); 

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
                        NAAN, SEG_no, SEG_b, SEG_e, db_swap,db_out);

  for (sg_i=0; sg_i<SEG_no; sg_i++) {
    for (i1=SEG_b[sg_i]; i1<=SEG_e[sg_i]; i1++) {
      i = NR_idx[i1];
      NR_seg[i] = sg_i;
    }
  }

  // *********************************************                Main loop
  char *seqi;
  double aa1_cutoff = NR_clstr;
  double aas_cutoff = 1 - (1-NR_clstr)*4;
  double aan_cutoff = 1 - (1-NR_clstr)*NAA;
  int len, hit_no, has_aas, iden_no, aan_no, segb;
  int aan_list[MAX_SEQ];
  INTs aan_list_no[MAX_SEQ];
  INTs *look_and_count;
  int len_need_to_match;
  int check_this_info[32];
  double check_this_infod[32];
  check_this_info[0]   = option_p;
  check_this_info[10]  = option_G;
  check_this_infod[11] = option_aL;
  check_this_info[12]  = option_AL;
  check_this_infod[13] = option_aS;
  check_this_info[14]  = option_AS;
  check_this_info[20]  = option_g;
  if ((look_and_count= new INTs[NR_no]) == NULL) bomb_error("Memory");

  NR90_no = 0;
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
        if (NR_flag[i] & IS_REDUNDANT  ) continue;
        len = NR_len[i]; seqi = NR_seq[i];
        len_need_to_match = lower_bound_length_rep(len,
          option_s, option_S, option_aL, option_AL);

        has_aas = 0;
        iden_no =  NR_iden[i];
        int flag = check_this(len, seqi, has_aas,
               NAA, aan_no, aan_list, aan_list_no, look_and_count, 
               hit_no, SEG90_b[sg_j], SEG90_e[sg_j], iden_no,
               aa1_cutoff, aas_cutoff, aan_cutoff,
               NR_flag[i], NR_flag, len_need_to_match, check_this_info, check_this_infod);

        if ((flag == 1) || (flag == -1)) { // if similar to old one delete it
          if (! option_g) {
            if (! option_B) delete [] NR_seq[i];
            NR_flag[i] |= IS_REDUNDANT ;
          }
          NR_clstr_no[i] = -hit_no-1;  // (-hit_no-1) for non representatives
          NR_iden[i] = iden_no;
          if (flag == -1) NR_flag[i] |= IS_MINUS_STRAND; // minus strand
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
    for (i1=SEG_b[sg_i]; i1<=SEG_e[sg_i]; i1++) {
      i = NR_idx[i1];
      
      if ( ! (NR_flag[i] & IS_REDUNDANT) ) {
        len = NR_len[i]; seqi = NR_seq[i];
        len_need_to_match = lower_bound_length_rep(len,
          option_s, option_S, option_aL, option_AL);

        has_aas = 0;
        iden_no =  NR_iden[i];
        int flag = check_this(len, seqi, has_aas,
               NAA, aan_no, aan_list, aan_list_no, look_and_count, 
               hit_no, segb, NR90_no-1, iden_no,
               aa1_cutoff, aas_cutoff, aan_cutoff,
               NR_flag[i], NR_flag, len_need_to_match, check_this_info, check_this_infod);

        if ((flag == 1) || (flag == -1)) { // if similar to old one delete it

          if (! option_B) delete [] NR_seq[i];
          NR_clstr_no[i] = -hit_no-1;  // (-hit_no-1) for non representatives
          NR_iden[i] = iden_no;
          NR_flag[i] |= IS_REDUNDANT ;
          if (flag == -1) NR_flag[i] |= IS_MINUS_STRAND; // minus strand
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
          word_table.add_word_list2(aan_no, aan_list, aan_list_no, NR90_no);
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

    // if not last segment
    if ( sg_i < SEG_no-2 ) word_table.write_tbl( db_swap[sg_i] );

    if(option_B) free_swap_iseq(sg_i, NR_no, NR_seg, NR_seq);
  } // for (sg_i=0; sg_i<SEG_no; sg_i++) {
  cout << endl;
  cout << NR_no << " finished\t" << NR90_no << " clusters" << endl;

  if (! option_B) for (i=0; i<NR90_no; i++)  delete [] NR_seq[ NR90_idx[i] ]; 

  cout << "writing new database" << endl;
  ifstream in1b(db_in);
  if ( ! in1b) bomb_error("Can not open file twice",db_in); 
  db_read_and_write(in1b, out1, option_l, des_len, NR_seq, NR_clstr_no);
  in1b.close(); out1.close(); 

  // write a backup clstr file in case next step crashes
  for (i=0; i<NR_no; i++) {
    j1 = NR_clstr_no[i];
    if ( j1 < 0 ) j1 =-j1-1;
    out2b << j1 << "\t" << NR_len[i] << "nt, "<< NR_seq[i] << "...";
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

  char c11;
  for (i=0; i<NR90_no; i++) {
    out2 << ">Cluster " << i << endl;
    for (k=0; k<Clstr_no[i]; k++) {
      j = Clstr_list[i][k];
      c11 = (NR_flag[j] & IS_MINUS_STRAND) ? '-' : '+';
      out2 << k << "\t" << NR_len[j] << "nt, "<< NR_seq[j] << "...";

      if ( NR_iden[j]>0 ) {
        out2 << " at ";
        if (option_p)
          out2 << NR_info[j][0] << ":" << NR_info[j][1] << ":"
               << NR_info[j][2] << ":" << NR_info[j][3] << "/";
        out2 << c11 << "/" << int(NR_iden[j]) << "%" << endl;
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


int check_this(int len, char *seqi, int &has_aas,
               int NAA, int& aan_no, int *aan_list, INTs *aan_list_no,
               INTs *look_and_count, 
               int &hit_no, int libb, int libe, int &iden_no,
               double aa1_cutoff, double aas_cutoff, double aan_cutoff,
               char this_flag, char *NR_flag, int len_need_to_match,
               int *check_this_info, double *check_this_infod) {

  static int  taap[MAX_UAA*MAX_UAA*MAX_UAA*MAX_UAA];
  static INTs aap_list[MAX_SEQ];
  static INTs aap_begin[MAX_UAA*MAX_UAA*MAX_UAA*MAX_UAA];

  int i, j, k, i1, j1, k1, i0, j0, k0, c22, sk, mm;
  int len_eff, aln_cover_flag, min_aln_lenS, min_aln_lenL;
  int required_aa1, required_aas, required_aan;

  len_eff = len;
  aln_cover_flag = 0;
  if (check_this_infod[13] > 0.0) { // has alignment coverage control
    aln_cover_flag = 1;
    min_aln_lenS = (int) (double(len) * check_this_infod[13]);
    if ( len-check_this_info[14] > min_aln_lenS)
      min_aln_lenS = len-check_this_info[14];
  }
  if (check_this_info[10] == 0) len_eff = min_aln_lenS; //option_G==0
  calc_required_aaxN(required_aa1, required_aas, required_aan,
                     aa1_cutoff,   aas_cutoff,   aan_cutoff, len_eff, NAA, 4);

  // check_aan_list 
  if (NAA>10) return FAILED_FUNC;
  aan_no = len - NAA + 1;
  for (j=0; j<aan_no; j++) {
    aan_list[j] = 0;
    for (k=0, k1=NAA-1; k<NAA; k++, k1--) aan_list[j] += seqi[j+k] * NAAN_array[k1]; 
  }

  // for the short word containing 'N', mask it to '-1'
  for (j=0; j<len; j++)
    if ( seqi[j] == 4 ) {                      // here N is 4
      i0 = (j-NAA+1 > 0)      ? j-NAA+1 : 0;
      i1 = (j+NAA < aan_no)   ? j+NAA   : aan_no;
      for (i=i0; i< i1; i++) aan_list[i]=-1;
    }

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
  for (j=libe; j>=libb; j--) look_and_count[j]=0;
  word_table.count_word_no2(aan_no, aan_list, aan_list_no, look_and_count);


  // contained_in_old_lib()
  int band_left, band_right, best_score, band_width1, best_sum, len2, alnln, len_eff1;
  int tiden_no;
  int talign_info[5];
  int len1 = len - 4 + 1;
  char *seqj;
  int flag = 0;      // compare to old lib
  has_aas = 0;
  for (j=libe; j>=libb; j--) {
    if ( look_and_count[j] < required_aan ) continue;
    len2 = NR_len[NR90_idx[j]];
    if (len2 > len_need_to_match ) continue;
    seqj = NR_seq[NR90_idx[j]];
    
    if (aln_cover_flag) {
      min_aln_lenL = (int) (double(len2) * check_this_infod[11]);
      if ( len2-check_this_info[12] > min_aln_lenL)
        min_aln_lenL = len2-check_this_info[12];
    }

    if ( has_aas == 0 )  { // calculate AAP array
      for (sk=0; sk<NAA4; sk++) taap[sk] = 0;
      for (j1=0; j1<len1; j1++) {
        c22 = seqi[j1]*NAA3 + seqi[j1+1]*NAA2 + seqi[j1+2]*NAA1 + seqi[j1+3];
        taap[c22]++;
      }
      for (sk=0,mm=0; sk<NAA4; sk++) {
        aap_begin[sk] = mm; mm+=taap[sk]; taap[sk] = 0;
      }
      for (j1=0; j1<len1; j1++) {
        c22 = seqi[j1]*NAA3 + seqi[j1+1]*NAA2 + seqi[j1+2]*NAA1 + seqi[j1+3];
        aap_list[aap_begin[c22]+taap[c22]++] =j1;
      }
      has_aas = 1;
    }

    band_width1 = (option_b < len+len2-2 ) ? option_b : len+len2-2;
    diag_test_aapn_est(NAA1, seqj, len, len2, taap, aap_begin, 
                   aap_list, best_sum,
                   band_width1, band_left, band_right, required_aa1);
    if ( best_sum < required_aas ) continue;

    if (check_this_info[0]) //return overlap region
      local_band_align2(seqi, seqj, len, len2, mat,
                        best_score, tiden_no, band_left, band_right,
                        talign_info[1],talign_info[2],
                        talign_info[3],talign_info[4], alnln);
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
    if (! check_this_info[20]) break; // not option_g
  }
  // END contained_in_old_lib()

  // comparison complimentary strand
  if (flag == 0 && option_r ) {
    for (j0=0; j0<aan_no; j0++) {
      j = aan_list[j0];
      if ( j<0 ) aan_list_comp[j0] = j;
      else       aan_list_comp[j0] = Comp_AAN_idx[j];
    }

    // lookup_aan
    for (j=libe; j>=libb; j--) look_and_count[j]=0;
    word_table.count_word_no2(aan_no, aan_list_comp, aan_list_no,
                              look_and_count);
    make_comp_iseq(len, seqi_comp, seqi);

    // reset has_aas, it use same array taap, aap_begin, aap_list
    // to store comp strand
    has_aas = 0;
    // compare to old lib
    for (j=libe; j>=libb; j--) {
      if ( look_and_count[j] < required_aan ) continue;
      len2 = NR_len[NR90_idx[j]];
      if (len2 > len_need_to_match ) continue;
      seqj = NR_seq[NR90_idx[j]];

      if (aln_cover_flag) {
        min_aln_lenL = (int) (double(len2) * check_this_infod[11]);
        if ( len2-check_this_info[12] > min_aln_lenL)
          min_aln_lenL = len2-check_this_info[12];
      }

      if ( has_aas == 0 )  { // calculate AAP array
        for (sk=0; sk<NAA4; sk++) taap[sk] = 0;
        for (j1=0; j1<len1; j1++) {
          c22 = seqi_comp[j1]*NAA3 + seqi_comp[j1+1]*NAA2 + seqi_comp[j1+2]*NAA1 + seqi_comp[j1+3];
          taap[c22]++;
        }
        for (sk=0,mm=0; sk<NAA4; sk++) {
          aap_begin[sk] = mm; mm+=taap[sk]; taap[sk] = 0;
        }
        for (j1=0; j1<len1; j1++) {
          c22 = seqi_comp[j1]*NAA3 + seqi_comp[j1+1]*NAA2 + seqi_comp[j1+2]*NAA1 + seqi_comp[j1+3];
          aap_list[aap_begin[c22]+taap[c22]++] =j1;
        }
        has_aas = 1;
      }

      band_width1 = (option_b < len+len2-2 ) ? option_b : len+len2-2;
      diag_test_aapn_est(NAA1, seqj, len, len2, taap, aap_begin,
                     aap_list, best_sum,
                     band_width1, band_left, band_right, required_aa1);

      if ( best_sum < required_aas ) continue;

      if (check_this_info[0]) {//return overlap region
        local_band_align2(seqi_comp, seqj, len, len2, mat,
                          best_score, tiden_no, band_left, band_right,
                          talign_info[1],talign_info[2],
                          talign_info[3],talign_info[4], alnln);
        talign_info[1] = len - talign_info[1] - 1;
        talign_info[2] = len - talign_info[2] - 1;
      }
      else
        local_band_align(seqi_comp, seqj, len, len2, mat,
                         best_score, tiden_no, band_left, band_right);
      if ( tiden_no < required_aa1 ) continue;
      len_eff1 = (check_this_info[10] == 0) ? alnln : len;
      tiden_no = tiden_no * 100 / len_eff1;
      if (tiden_no < NR_clstr100) continue;
      if (tiden_no <= iden_no) continue; // existing iden_no
      if (aln_cover_flag) {
        if ( talign_info[4]-talign_info[3]+1 < min_aln_lenL) continue;
        if ( talign_info[1]-talign_info[2]+1 < min_aln_lenS) continue; //reverse
      }
      flag = -1; iden_no = tiden_no; hit_no = j;
      check_this_info[1] = talign_info[1];
      check_this_info[2] = talign_info[2];
      check_this_info[3] = talign_info[3];
      check_this_info[4] = talign_info[4];
      if (! check_this_info[20]) break; // not option_g
    }
  }
  // END if (flag == 0 && option_r )
  return flag;
} // END check_this


//stupid function
void make_comp_short_word_index(int NAA) {
  int i1, i2, i3, i4, i5, i6, i7, i8, i9, i10, i11;
  int j, k;
  int c[4] = {3,2,1,0};

  if      ( NAA == 2)
    for (i1=0; i1<NAA1; i1++) for (i2=0; i2<NAA1; i2++)
      Comp_AAN_idx[i1*NAA1 + i2] =
                  c[i2]*NAA1 + c[i1];
  else if ( NAA == 3)
    for (i1=0; i1<NAA1; i1++) for (i2=0; i2<NAA1; i2++)
      for (i3=0; i3<NAA1; i3++)
        Comp_AAN_idx[i1*NAA2 + i2*NAA1 + i3] =
                     c[i3]*NAA2 + c[i2]*NAA1 + c[i1];
  else if ( NAA == 4)
    for (i1=0; i1<NAA1; i1++) for (i2=0; i2<NAA1; i2++)
      for (i3=0; i3<NAA1; i3++) for (i4=0; i4<NAA1; i4++)
        Comp_AAN_idx[i1*NAA3 + i2*NAA2 + i3*NAA1 + i4] =
                     c[i4]*NAA3 + c[i3]*NAA2 + c[i2]*NAA1 + c[i1];
  else if ( NAA == 5)
    for (i1=0; i1<NAA1; i1++) for (i2=0; i2<NAA1; i2++)
      for (i3=0; i3<NAA1; i3++) for (i4=0; i4<NAA1; i4++)
        for (i5=0; i5<NAA1; i5++)
            Comp_AAN_idx[i1*NAA4 + i2*NAA3 + i3*NAA2 + i4*NAA1 + i5] =
              c[i5]*NAA4 + c[i4]*NAA3 + c[i3]*NAA2 + c[i2]*NAA1 + c[i1];
  else if ( NAA == 6)
    for (i1=0; i1<NAA1; i1++) for (i2=0; i2<NAA1; i2++)
      for (i3=0; i3<NAA1; i3++) for (i4=0; i4<NAA1; i4++)
        for (i5=0; i5<NAA1; i5++) for (i6=0; i6<NAA1; i6++)
            Comp_AAN_idx[i1*NAA5 + i2*NAA4 + i3*NAA3 + i4*NAA2 + i5*NAA1 + i6] =
              c[i6]*NAA5 +
              c[i5]*NAA4 + c[i4]*NAA3 + c[i3]*NAA2 + c[i2]*NAA1 + c[i1];
  else if ( NAA == 7)
    for (i1=0; i1<NAA1; i1++) for (i2=0; i2<NAA1; i2++)
      for (i3=0; i3<NAA1; i3++) for (i4=0; i4<NAA1; i4++)
        for (i5=0; i5<NAA1; i5++) for (i6=0; i6<NAA1; i6++)
          for (i7=0; i7<NAA1; i7++)
            Comp_AAN_idx[i1*NAA6 + i2*NAA5 + i3*NAA4 + i4*NAA3 + i5*NAA2 +
                         i6*NAA1 + i7] =
              c[i7]*NAA6 + c[i6]*NAA5 +
              c[i5]*NAA4 + c[i4]*NAA3 + c[i3]*NAA2 + c[i2]*NAA1 + c[i1];
  else if ( NAA == 8)
    for (i1=0; i1<NAA1; i1++) for (i2=0; i2<NAA1; i2++)
      for (i3=0; i3<NAA1; i3++) for (i4=0; i4<NAA1; i4++)
        for (i5=0; i5<NAA1; i5++) for (i6=0; i6<NAA1; i6++)
          for (i7=0; i7<NAA1; i7++) for (i8=0; i8<NAA1; i8++)
            Comp_AAN_idx[i1*NAA7 + i2*NAA6 + i3*NAA5 + i4*NAA4 + i5*NAA3 +
                         i6*NAA2 + i7*NAA1 + i8] =
              c[i8]*NAA7 + c[i7]*NAA6 + c[i6]*NAA5 +
              c[i5]*NAA4 + c[i4]*NAA3 + c[i3]*NAA2 + c[i2]*NAA1 + c[i1];
  else if ( NAA == 9)
    for (i1=0; i1<NAA1; i1++) for (i2=0; i2<NAA1; i2++)
      for (i3=0; i3<NAA1; i3++) for (i4=0; i4<NAA1; i4++)
        for (i5=0; i5<NAA1; i5++) for (i6=0; i6<NAA1; i6++)
          for (i7=0; i7<NAA1; i7++) for (i8=0; i8<NAA1; i8++)
            for (i9=0; i9<NAA1; i9++)
              Comp_AAN_idx[i1*NAA8 + i2*NAA7 + i3*NAA6 + i4*NAA5 + i5*NAA4 +
                           i6*NAA3 + i7*NAA2 + i8*NAA1 + i9] =
                c[i9]*NAA8 + c[i8]*NAA7 + c[i7]*NAA6 + c[i6]*NAA5 +
                c[i5]*NAA4 + c[i4]*NAA3 + c[i3]*NAA2 + c[i2]*NAA1 + c[i1];
  else if ( NAA == 10)
    for (i1=0; i1<NAA1; i1++) for (i2=0; i2<NAA1; i2++)
      for (i3=0; i3<NAA1; i3++) for (i4=0; i4<NAA1; i4++)
        for (i5=0; i5<NAA1; i5++) for (i6=0; i6<NAA1; i6++)
          for (i7=0; i7<NAA1; i7++) for (i8=0; i8<NAA1; i8++)
            for (i9=0; i9<NAA1; i9++) for (i10=0; i10<NAA1; i10++)
              Comp_AAN_idx[i1*NAA9 + i2*NAA8 + i3*NAA7 + i4*NAA6 + i5*NAA5 +
                           i6*NAA4 + i7*NAA3 + i8*NAA2 + i9*NAA1 + i10] =
               c[i10]*NAA9 + c[i9]*NAA8 + c[i8]*NAA7 + c[i7]*NAA6 + c[i6]*NAA5 +
               c[i5]*NAA4 + c[i4]*NAA3 + c[i3]*NAA2 + c[i2]*NAA1 + c[i1];
  else return;
} // make_comp_short_word_index


void make_comp_iseq(int len, char *iseq_comp, char *iseq) {
  int i, j, k;
  int c[5] = {3,2,1,0,4};
  for (i=0; i<len; i++) iseq_comp[i] = c[ iseq[len-i-1] ];
} // make_comp_iseq

/////////////////////////// END ALL ////////////////////////
