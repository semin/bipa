module ScopsHelper
  def subcategories(arg)
    "#{arg}_subcategories"
  end

  def dssp_description(arg)
    case arg
    when "H": "Alpha helix"
    when "G": "3<sub>10</sub>-helix"
    when "I": "phi-helix"
    when "E": "extended strand"
    when "B": "beta-bridge"
    when "T": "Hydrogen-bonded turn"
    when "S": "Bend"
    when "L": "Loop"
    else
      raise "Unknown DSSP type!"
    end
  end
end
