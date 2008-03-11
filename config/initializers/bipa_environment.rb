# BIPA environment

class ActiveRecord::Base
  def self.lazy_calculate(*attrs)
    attrs.each do |attr|
      define_method(attr) do
        method_name = "calculate_#{attr}"
        if not self[attr]
          if self.respond_to? method_name
            self[attr] = self.send(method_name)
            self.save!
          else
            raise "You should create '#{method_name}' first!"
          end
        end
        return self[attr]
      end
    end
  end
end

BIPA_ENV = {
  :MAX_FORK     => ENV['MAX_FORK'].to_i > 0 ? ENV['MAX_FORK'].to_i : 2,
  :ENTRY_TYPE   => 'prot-nuc',
  :MAX_DISTANCE => 5.0,

  :INTERFACE_RESIDUE_DELTA_ASA_THRESHOLD  => 1.0,
  :SURFACE_RESIDUE_ASA_THRESHOLD          => 0.1,
  :SURFACE_RESIDUE_RELATIVE_THRESHOLD     => 0.05,
  :INTERFACE_ATOM_DELTA_ASA_THRESHOLD     => 0.1,
  :SURFACE_ATOM_ASA_THRESHOLD             => 0.1,
  :PDB_SOURCE                             => :local,

  :PDB_MIRROR_DIR       => '/BiO/Mirror/PDB',
  :PDB_STRUCTURE_DIR    => './data/structures/all/pdb',
  :PDB_ENTRY_TYPE_FILE  => './derived_data/pdb_entry_type.txt',

  :PDB_DIR      => File.join(RAILS_ROOT, '/public/data/pdb'),
  :SCOP_DIR     => File.join(RAILS_ROOT, '/public/data/scop'),
  :SCOP_URI     => 'http://scop.mrc-lmb.cam.ac.uk/scop/parse/',
  :PRESCOP_DIR  => File.join(RAILS_ROOT, '/public/data/pre-scop'),
  :PRESCOP_URI  => 'http://www.mrc-lmb.cam.ac.uk/agm/pre-scop/parseable/',
  :NCBI_FTP     => 'ftp.ncbi.nih.gov',
  :TAXONOMY_DIR => File.join(RAILS_ROOT, '/public/data/taxonomy'),
  :TAXONOMY_FTP => 'pub/taxonomy',

  :HBPLUS_DIR   => File.join(RAILS_ROOT, '/public/analysis/hbplus'),
  :HBPLUS_BIN   => File.join(RAILS_ROOT, '/bin/hbplus/hbplus'),
  :CLEAN_BIN    => File.join(RAILS_ROOT, '/bin/hbplus/clean'),

  :NACCESS_DIR  => File.join(RAILS_ROOT, '/public/analysis/naccess'),
  :NACCESS_BIN  => File.join(RAILS_ROOT, '/bin/naccess/naccess'),
  :NACCESS_VDW  => File.join(RAILS_ROOT, '/bin/naccess/vdw.radii'),
  :NACCESS_STD  => File.join(RAILS_ROOT, '/bin/naccess/standard.data'),

  :DSSP_DIR     => File.join(RAILS_ROOT, '/public/analysis/dssp'),
  :DSSP_BIN     => File.join(RAILS_ROOT, '/bin/dssp/dsspcmbi'),

  :DOMAIN_DIR   => File.join(RAILS_ROOT, '/public/analysis/domain'),

  :CDHIT_DIR    => File.join(RAILS_ROOT, '/public/analysis/cdhit'),
  :CDHIT_BIN    => File.join(RAILS_ROOT, '/bin/cdhit/cd-hit'),
  :PSICDHIT_BIN => File.join(RAILS_ROOT, '/bin/cdhit/psi-cd-hit.pl'),
  :CDHIT_CUTOFF => 0.8,
  :CDHIT_WORD   => 5,

  :STATS_DIR    => File.join(RAILS_ROOT, '/public/analysis/stats'),
  :STATS_FILE   => 'bipa_stats.tsv'
}
