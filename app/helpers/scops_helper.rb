module ScopsHelper
  def subcategories(arg)
    "#{arg}_subcategories"
  end

  def dssp_description(arg)
    case arg
    when "H" then "Alpha helix"
    when "G" then "3<sub>10</sub>-helix"
    when "I" then "phi-helix"
    when "E" then "extended strand"
    when "B" then "beta-bridge"
    when "T" then "Hydrogen-bonded turn"
    when "S" then "Bend"
    when "L" then "Loop"
    else
      raise "Unknown DSSP type!"
    end
  end
end
