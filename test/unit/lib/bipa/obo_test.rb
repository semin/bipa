require File.dirname(__FILE__) + '/../../../test_helper'

class Bipa::OboTest < Test::Unit::TestCase

  context "An Bipa::Obo instance" do
    setup do
      obo_str = <<END
[Term]
id: GO:0000001
name: mitochondrion inheritance
namespace: biological_process
def: "The distribution of mitochondria, including the mitochondrial genome, into daughter cells after mitosis or meiosis, mediated by interactions between mitochondria and the cytoskeleton." [GOC:mcc, PMID:10873824, PMID:11389764]
synonym: "mitochondrial inheritance" EXACT []
is_a: GO:0048308 ! organelle inheritance
is_a: GO:0048311 ! mitochondrion distribution

[Term]
id: GO:0000018
name: regulation of DNA recombination
namespace: biological_process
def: "Any process that modulates the frequency, rate or extent of DNA recombination, a process by which a new genotype is formed by reassortment of genes resulting in gene combinations different from those that were present in the parents." [GOC:go_curators, ISBN:0198506732 "Oxford Dictionary of Biochemistry and Molecular Biology"]
subset: gosubset_prok
is_a: GO:0051052 ! regulation of DNA metabolic process
relationship: regulates GO:0006310 ! DNA recombination

[Term]
id: GO:0000022
name: mitotic spindle elongation
namespace: biological_process
def: "Lengthening of the distance between poles of the mitotic spindle." [GOC:mah]
synonym: "spindle elongation during mitosis" EXACT []
is_a: GO:0051231 ! spindle elongation
relationship: part_of GO:0007052 ! mitotic spindle organization and biogenesis

END
      obo_obj         = Bipa::Obo.new(obo_str)
      @terms          = obo_obj.terms
      @associations   = obo_obj.associations
      @relationships  = obo_obj.relationships
    end

    should "have three GO terms" do
      assert_equal 3, @terms.size
    end

    should "have a correct ID for each term" do
      assert_equal "GO:0000001", @terms["GO:0000001"].go_id
      assert_equal "GO:0000018", @terms["GO:0000018"].go_id
      assert_equal "GO:0000022", @terms["GO:0000022"].go_id
    end

    should "have a correct name for each term" do
      assert_equal "mitochondrion inheritance",       @terms["GO:0000001"].name
      assert_equal "regulation of DNA recombination", @terms["GO:0000018"].name
      assert_equal "mitotic spindle elongation",      @terms["GO:0000022"].name
    end

    should "have a correct namespace for each term" do
      assert_equal "biological_process", @terms["GO:0000001"].namespace
      assert_equal "biological_process", @terms["GO:0000018"].namespace
      assert_equal "biological_process", @terms["GO:0000022"].namespace
    end

    should "have correct superclasses for each term" do
      assert_equal "GO:0048308", @associations[@terms["GO:0000001"].go_id][0].superclass_id
      assert_equal "GO:0048311", @associations[@terms["GO:0000001"].go_id][1].superclass_id
      assert_equal "GO:0051052", @associations[@terms["GO:0000018"].go_id][0].superclass_id
      assert_equal "GO:0051231", @associations[@terms["GO:0000022"].go_id][0].superclass_id
    end

    should "have correct relationships for each term" do
      assert_nil @relationships[@terms["GO:0000001"].go_id]
      assert_equal "GO:0006310",  @relationships[@terms["GO:0000018"].go_id][0].object_id
      assert_equal "regulates",   @relationships[@terms["GO:0000018"].go_id][0].type
      assert_equal "GO:0007052",  @relationships[@terms["GO:0000022"].go_id][0].object_id
      assert_equal "part_of",     @relationships[@terms["GO:0000022"].go_id][0].type
    end
  end
end
