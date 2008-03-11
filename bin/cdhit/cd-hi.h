// =============================================================================
// CD-HI
//
// Cluster Database at High Identity
//
// CD-HI clusters protein sequence database at high sequence identity threshold.
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

#include<iostream>
#include<fstream>
#include<iomanip>
#include<cstdlib>
#include<stdio.h>
#include<string.h>
#include<ctype.h>
#include<sys/times.h>


using namespace std;

#define MAX_AA 23
#define MAX_NA 6
#define MAX_UAA 21
#define MAX_SEQ 655360
#define MAX_DIAG 133000                   // MAX_DIAG be twice of MAX_SEQ
#define MAX_GAP 65536                    // MAX_GAP <= MAX_SEQ
#define MAX_DES 300000
#define MAX_LINE_SIZE 300000
#define MAX_FILE_NAME 1280
#define MAX_SEG 50
#define MAX_BIN_SWAP 2000000000
#define CLOCK_TICKS 100
#define FAILED_FUNC 1
#define OK_FUNC 0

#define IS_REP 1
#define IS_REDUNDANT 2
#define IS_PROCESSED 16
#define IS_MINUS_STRAND 32

#define max(a,b) (((a)>(b))?(a):(b))
#define min(a,b) (((a)<(b))?(a):(b))

typedef unsigned int UINT4;
typedef unsigned short UINT2;

//if the longset sequence is longer than 65535, I use INT4
#ifdef LONG_SEQ
#define INTs UINT4
#else
#define INTs UINT2
#endif

////////// Class definition //////////
class AA_MATRIX { //Matrix
  private:

  public:
    int gap, ext_gap;
    int *gap_array;
    int matrix[MAX_AA][MAX_AA];

    AA_MATRIX();
    void init();
    void set_gap(int gap1, int ext_gap1);
    void set_matrix(int *mat1);
    void set_to_na();
}; // END class AA_MATRIX



class IDX_TBL {
  private:
    int  NAA;                // length of word
    int  NAAN;               // rows of table
    int  mem_size;           // additional size for re-allocate;
    int  *size;              // real size of each column
    int  *capacity;          // capacitiy of each column
    int  *(*seq_idx);        // hold index of seqs
    INTs *(*word_no);        // hold number of seq idx has this word
    int  *buffer;            // buffer
    int  buffer_size;        // size of the buffer
    char is_aa;              // aa is for prot

  public:
    IDX_TBL();
    void init(int, int);
    void clean();
    void set_dna();
    int  read_tbl(char *);
    int  write_tbl(char *);
    int  add_word_list(int, int *, INTs *, int);
    int  add_word_list2(int, int *, INTs *, int);
    int  count_word_no(int, int *, INTs *, INTs *);
    int  count_word_no2(int, int *, INTs *, INTs *);
    int  pop_long_seqs(int upper_bound);
}; // END class INDEX_TBL



int read_swap (int sgj);
int write_swap (int sgj);
int check_this(int len, char *seqi, int &has_aa2,
               int NAA, int& aan_no, int *aan_list, INTs *aan_list_no,
               INTs *look_and_count,
               int &hit_no, int libb, int libe, int &iden_no,
               double aa1_cutoff, double aa2_cutoff, double aan_cutoff,
               char this_flag, char *NR_flag, int len_need_to_match, 
               int *check_this_info, double *check_this_infod);
int check_this_short(int len, char *seqi, int &has_aa2,
               int NAA, int& aan_no, int *aan_list, INTs *aan_list_no,
                                     int *aan_list_backup,
               INTs *look_and_count,
               int &hit_no, int libb, int libe,
               int frg2, int libfb, int libfe, int &iden_no,
               double aa1_cutoff, double aa2_cutoff, double aan_cutoff,
               char this_flag, char *NR_flag, int len_need_to_match,
               int *check_this_info, double *check_this_infod);

int add_in_lookup_table(int aan_no, int *aan_list, INTs *aan_list_no);
int add_in_lookup_table_short(int aan_no, int frg1,
                              int *aan_list, INTs *aan_list_no);
int print_usage (char *arg);
void bomb_error(char *message);
void bomb_error(char *message, char *message2);
void bomb_warning(char *message);
void bomb_warning(char *message, char *message2);
void format_seq(char *seq);
int diag_test_aapn(int NAA1, char iseq2[], int len1, int len2, int *taap,
        INTs *aap_begin, INTs *aap_list, int &best_sum,
        int band_width, int &band_left, int &band_right, int required_aa1);
int diag_test_aapn_est(int NAA1, char iseq2[], int len1, int len2, int *taap,
        INTs *aap_begin, INTs *aap_list, int &best_sum,
        int band_width, int &band_left, int &band_right, int required_aa1);
int local_band_align(char iseq1[], char iseq2[], int len1, int len2,
                     AA_MATRIX &mat, int &best_score, int &iden_no,
                     int band_left, int band_right);
int local_band_align2(char iseq1[], char iseq2[], int len1, int len2,
                     AA_MATRIX &mat, int &best_score, int &iden_no,
                     int band_left, int band_right,
                     int &from1, int &end1, int &from2, int &end2, int &alnln);
int outiseq(char iseq[], int len);
int setiseq(char *seq, int len);
int quick_sort (int *a, int lo0, int hi0 );
int quick_sort_idx (int *a, int *idx, int lo0, int hi0 );
int quick_sort_idx2 (int *a, int *b, int *idx, int lo0, int hi0 );
int quick_sort_a_b_idx (int *a, int *b, int *idx, int lo0, int hi0 );
int db_seq_no_test(ifstream &in1);
int old_clstr_seq_no_test(ifstream &in1);
int db_read_in_old (ifstream &in1, int length_of_throw, 
                    int & NR_no, char *NR_seq[], int *NR_len);
int db_read_in (ifstream &in1, char *db_bin_swap, int seq_swap, 
                int length_of_throw, 
                int & NR_no, char *NR_seq[], int *NR_len);
int sort_seqs_divide_segs (int seq_swap,
                           int NR_no, int *NR_len, int *NR_idx, char *NR_seq[],
                           long long mem_limit, int NAAN,
                           int &SEG_no, int *SEG_b, int *SEG_e,
                           char db_swap[MAX_SEG][MAX_FILE_NAME],
                           char db_out[]);
int cut_fasta_des(char *des1);
int db_read_and_write (ifstream &in1, ofstream &out1,
                       int length_of_throw, int des_len,
                       char *NR_seq[], int *NR_clstr_no);
int des_to_idx(int &id1, int &id2, char *str1);
int get_index_of_sorted_list (int *list, int b, int e, int element);
int get_index_of_2_sorted_list (int *list, int *list2, int b, int e,
                                int element, int element2);
int read_swap_iseq(int sgj, char *bindbname,
                   int NR_no, char *NR_seg, char *(*NR_seq));
int free_swap_iseq(int sgj, int NR_no, char *NR_seg, char *(*NR_seq));
int remove_tmp_files(int SEG_no, char db_swap[MAX_SEG][MAX_FILE_NAME],
                     int seq_swap, char db_bin_swap[]);

//for cd-hit-2d
int calc_ann_list(int len, char *seqi,
                  int NAA, int& aan_no, int *aan_list, INTs *aan_list_no);
int read_swap_db2_iseq(int sgj, char *bindbname);
int free_swap_db2_iseq(int sgj);
int db_read_des(ifstream &in1,
                int length_of_throw, int des_len, char *NR_seq[]);
int db2_seqs_divide_segs (int seq_swap,
                           int NR_no, int *NR_len, char *NR_seq[],
                           long long mem_limit, int NAAN,
                           int &SEG_no, int *SEG_b, int *SEG_e);
int remove_tmp_files_db2(int seq_swap, char db_bin_swap[]);
int check_this_2d(int len, char *seqi, int &has_aa2,
               int NAA, int& aan_no, int *aan_list, INTs *aan_list_no,
               INTs *look_and_count,
               int &hit_no, int libb, int libe, int &iden_no,
               double aa1_cutoff, double aa2_cutoff, double aan_cutoff,
               char this_flag, char *NR_flag, int len_need_to_match,
               int &lens, int len_db1_at_least, int *check_this_info,
               double *check_this_infod);
int print_usage_2d (char *arg);
int print_usage_est (char *arg);
int print_usage_div (char *arg);
int print_usage_est_2d (char *arg);

int lower_bound_length_rep(int len, double opt_s,  int opt_S, 
                                    double opt_aL, int opt_AL);
void cal_aax_cutoff (double &aa1_cutoff, double &aa2_cutoff, double &aan_cutoff,
                     double NR_clstr, int tolerance, int naa_stat_start_percent,
                     int naa_stat[5][61][4], int NAA);
void update_aax_cutoff(double &aa1_cutoff, double &aa2_cutoff, double &aan_cutoff,
                     int tolerance, int naa_stat_start_percent,
                     int naa_stat[5][61][4], int NAA, int iden);
void calc_required_aax(int &required_aa1, int &required_aa2, int &required_aan,
                       double aa1_cutoff, double aa2_cutoff, double aan_cutoff,
                       int len_eff, int NAA);
void calc_required_aaxN(int &required_aa1, int &required_aas, int &required_aan,
                       double aa1_cutoff, double aas_cutoff, double aan_cutoff,
                       int len_eff, int NAA, int ss);
void show_cpu_time(tms &CPU_begin, tms &CPU_end);
