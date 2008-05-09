module Bipa
  class Obo

    attr_reader :terms, :associations, :relationships

    require "rubygems"
    require "active_support"

    Term = Struct.new(:go_id,
                      :is_anonymous,
                      :name,
                      :namespace,
                      :definition,
                      :synonym,
                      :alt_id,
                      :comment,
                      :subset,
                      :synonym,
                      :xref,
                      :is_obsolete,
                      :replaced_by,
                      :consider)

    Association = Struct.new(:subclass_id.
                              :superclass_id)

    Relationship = Struct.new(:object_id.
                              :subject_id,
                              :type)

    def initialize(obo_str)

      @terms          = Array.new
      @associations   = Hash.new([])
      @relationships  = Hash.new([])

      parse_obo_flat_file(obo_str)
    end

    def parse_obo_flat_file(obo_str)

      obo_str.scan(/^\[Term\].*?^\n$/m).each do |term, i|

        term = Term.new

        term.split(/\n/).each do |line|
          case line
          when /^\[Term\]/ # title line
            next
          when /^\s*$/ # empty line
            next
          when /^id:\s+(\S+)/
            term[:go_id] = $1
          when /^is_anonymous:\s+(.*)$/
            term[:is_anonymous] = $1
          when /^name:\s+(.*)$/
            term[:name] = $1
          when /^namespace:\s+(.*)$/
            term[:namespace] = $1
          when /^def:\s+(.*)$/
            term[:definition] = $1
          when /^synonym:\s+(.*)$/
            next # can be many, at the moment
          when /^alt_id:\s+(\S+)/
            term[:alt_id] = $1
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
          when /^is_a:\s+(\S+)/
            association = Association.new
            association[:subclass_id]    = term[:go_id]
            association[:superclass_id]  = $1
            @associations[term[:go_id]] << association
          when /^relationship:\s+(\S+)\s+(\S+)/
            relationship = Relationship.new
            relationship[:subject_id] = term[:go_id]
            relationship[:type]       = $1
            relationship[:object_id]  = $2
            @relationships[term[:go_id]] << relationship
          else
            raise "Unknown type: #{line}"
            #next
          end
        end
      end
    end

  end
end
