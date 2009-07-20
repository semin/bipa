class Esst < ActiveRecord::Base

  has_many :substitutions

  named_scope :dna, :conditions => ["dna_rna_interface = 'D'"]
  named_scope :rna, :conditions => ["dna_rna_interface = 'R'"]
  named_scope :nnb, :conditions => ["dna_rna_interface = 'N'"]

  def nmatrix(value = :prob)
    NMatrix[*substitutions.map(&:"#{value}").in_groups_of(21)]
  end
end

class StdEsst < Esst
end

class NaEsst < Esst
end
