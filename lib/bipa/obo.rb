module Bipa
  class Obo

    attr_reader :terms, :associations, :relationships

    require "rubygems"
    require "active_support"

    Term = Struct.new(:goid,
                      :is_anonymous,
                      :name,
                      :namespace,
                      :definition,
                      :comment,
                      :is_obsolete)

    Association = Struct.new(:subclass_id,
                             :superclass_id)

    Relationship = Struct.new(:subject_id,
                              :object_id,
                              :type)

    def initialize(obo_str)
      @terms          = Hash.new
      @associations   = Hash.new
      @relationships  = Hash.new

      parse_obo_flat_file(obo_str)
    end

    def parse_obo_flat_file(obo_str)
      obo_str.scan(/^\[Term\].*?^$/m).each_with_index do |t, i|

        term = Term.new

        t.split(/\n/).each do |line|
          case line
          when /^\[Term\]/ # title line
            next
          when /^\s*$/ # empty line
            next
          when /^id:\s+(\S+)/
            term[:goid] = $1
          when /^is_anonymous:\s+(.*)$/
            term[:is_anonymous] = $1
          when /^name:\s+(.*)$/
            term[:name] = $1
          when /^namespace:\s+(.*)$/
            term[:namespace] = $1
          when /^def:\s+(.*)$/
            term[:definition] = $1
          when /^synonym:\s+(.*)$/
            next # can be many
          when /^alt_id:\s+(\S+)/
            next # can be many
          when /^comment:\s+(.*)$/
            term[:comment] = $1
          when /^subset:\s+(.*)$/
            next # can be many
          when /^xref:\s+(.*)$/
            next # can be many
          when /^is_obsolete:\s+(\S+)/
            term[:is_obsolete] = ($1 =~ /true/ ? true : false)
          when /^replaced_by:\s+(\S+)/
            next # can be many
          when /^consider:\s+(\S+)/
            next # can be many
          when /^disjoint_from:\s+(\S+)/
            next # can be many
          when /^is_a:\s+(\S+)/
            association = Association.new(term.goid, $1)
            if @associations[term.goid].nil?
              @associations[term.goid] = []
              @associations[term.goid] << association
            else
              @associations[term.goid] << association
            end
          when /^relationship:\s+(\S+)\s+(\S+)/
            relationship = Relationship.new(term.goid, $2, $1)
            if @relationships[term.goid].nil?
              @relationships[term.goid] = []
              @relationships[term.goid] << relationship
            else
              @relationships[term.goid] << relationship
            end
          else
            raise "Unknown type: #{line}"
            #next
          end
        end
        @terms[term.goid] = term
      end
    end

  end
end
