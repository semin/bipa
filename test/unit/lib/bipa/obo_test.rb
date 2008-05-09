require File.dirname(__FILE__) + '/../../../test_helper'

class OboFlatFileTest < Test::Unit::TestCase

  context "A OboFlatFile instance" do

    setup do
      obo_str   = <<END
[Term]
id: GO:0000001
name: mitochondrion inheritance
namespace: biological_process
def: "The distribution of mitochondria, including the mitochondrial genome, into daughter cells after mitosis or meiosis, mediated by interactions between mitochondria and the cytoskeleton." [GOC:mcc, PMID:10873824, PMID:11389764]
synonym: "mitochondrial inheritance" EXACT []
is_a: GO:0048308 ! organelle inheritance
is_a: GO:0048311 ! mitochondrion distribution

[Term]
id: GO:0000002
name: mitochondrial genome maintenance
namespace: biological_process
def: "The maintenance of the structure and integrity of the mitochondrial genome; includes replication and segregation of the mitochondrial chromosome." [GOC:ai, GOC:vw]
is_a: GO:0007005 ! mitochondrion organization and biogenesis

[Term]
id: GO:0000003
name: reproduction
namespace: biological_process
alt_id: GO:0019952
alt_id: GO:0050876
def: "The production by an organism of new individuals that contain some portion of their genetic material inherited from that organism." [GOC:go_curators, GOC:isa_complete, ISBN:0198506732 "Oxford Dictionary of Biochemistry and Molecular Biology"]
subset: goslim_generic
subset: goslim_pir
subset: goslim_plant
subset: gosubset_prok
synonym: "reproductive physiological process" EXACT []
is_a: GO:0008150 ! biological_process
END
      obo_obj   = Bipa::OboFlatFile.new(obo_str)
    end

    should "have three GO terms" do
      assert_equal 3, obo_obj.terms.size
    end
  end
end
