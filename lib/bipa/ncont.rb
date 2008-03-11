module BIPA
  class NCONT
    attr_reader :contacts

    Atom = Struct.new('Atom', :model_code, :chain_code,
                      :residue_code, :residue_name, :atom_name)

    Contact = Struct.new('Contact', :source, :target, :distance)

    def self.parse_source_target_line(line)
      contact = nil
      elements = line.split(':')
      if elements.size == 3
        source_atom = parse_atom_entry(elements[0])
        target_atom = parse_atom_entry(elements[1])
        contact = Contact.new(source_atom, target_atom, elements[2].to_f)
      elsif elements.size == 2
        target_atom = parse_atom_entry(elements[0])
        contact = Contact.new(nil, target_atom, elements[1].to_f)
      else
        raise "#{line}: Unknown line format!"
      end
      contact
    end

    def self.parse_atom_entry(str)
      #  /1/A/  44(TYR). / OH [ O]
      #  /1/C/ 402( DC). / O5'[ O]
      #  / 1/A/   3(LYS). / HA [ H]
      if (str =~ /\/(.*)\/(.*)\/(.*)\((.*)\)\.\s*\/(.*)\[/)
        return Atom.new($1.to_i, $2, $3.to_i, $4.strip, $5.strip)
      else
        raise "#{str}: Unknown atom entry format!"
      end
    end

    def initialize(ncont_str)
      @contacts = []
      source = nil
      ncont_str.each do |line|
        if (line =~ /^\s*\//)
          contact = NCONT.parse_source_target_line(line)
          if (contact.source.nil?)
            contact.source = source
          else
            source = contact.source
          end
          @contacts << contact
        end
      end
    end

  end
end

if $0 == __FILE__

  require 'test/unit'

  class TestNCONT < Test::Unit::TestCase
    include BIPA

    def test_parse_atom_entry
      atom_entry_str = " /1/A/ 228(ARG). / NH2[ N]"
      atom = NCONT.parse_atom_entry(atom_entry_str)

      assert_kind_of(NCONT::Atom, atom)
      assert_equal(1,     atom.model_code)
      assert_equal('A',   atom.chain_code)
      assert_equal(228,   atom.residue_code)
      assert_equal('ARG', atom.residue_name)
      assert_equal('NH2', atom.atom_name)
    end

    def test_parse_source_target_line
      test_line1 = " /1/A/  44(TYR). / OH [ O]:  /1/C/ 402( DC). / O5'[ O]:   3.78"
      contact1 = NCONT.parse_source_target_line(test_line1)

      assert_equal(1,     contact1.source.model_code)
      assert_equal("A",   contact1.source.chain_code)
      assert_equal(44,    contact1.source.residue_code)
      assert_equal('TYR', contact1.source.residue_name)
      assert_equal("OH",  contact1.source.atom_name)

      assert_equal(1,     contact1.target.model_code)
      assert_equal("C",   contact1.target.chain_code)
      assert_equal(402,   contact1.target.residue_code)
      assert_equal('DC',  contact1.target.residue_name)
      assert_equal("O5'", contact1.target.atom_name)

      test_line2 = "                             /1/C/ 425( DA). / C1'[ C]:   4.91"
      contact2 = NCONT.parse_source_target_line(test_line2)

      #assert_nil(contact2.source)
      assert_equal(1,     contact2.target.model_code)
      assert_equal("C",   contact2.target.chain_code)
      assert_equal(425,   contact2.target.residue_code)
      assert_equal('DA',  contact2.target.residue_name)
      assert_equal("C1'", contact2.target.atom_name)
    end

    def test_should_parse_contigous_lines
      test_str = <<NCONT
 /1/A/ 296(SER). / CB [ C]:  /1/B/ 403( DC). / C5'[ C]:   4.72
 /1/A/ 296(SER). / OG [ O]:  /1/B/ 403( DC). / C5'[ C]:   4.74
                             /1/B/ 403( DC). / C4'[ C]:   4.99
 /1/A/ 296(SER). / CB [ C]:  /1/B/ 403( DC). / C3'[ C]:   4.55
NCONT
      ncont = NCONT.new(test_str)
      assert_equal(4, ncont.contacts.size)
      assert_equal('CB', ncont.contacts[0].source.atom_name)
      assert_equal('OG', ncont.contacts[1].source.atom_name)
      assert_equal('OG', ncont.contacts[2].source.atom_name)
      assert_equal('CB', ncont.contacts[3].source.atom_name)
      assert_equal("C5'", ncont.contacts[0].target.atom_name)
      assert_equal("C5'", ncont.contacts[1].target.atom_name)
      assert_equal("C4'", ncont.contacts[2].target.atom_name)
      assert_equal("C3'", ncont.contacts[3].target.atom_name)
    end
  end
end

