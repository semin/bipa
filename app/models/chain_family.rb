class ChainFamily < ActiveRecord::Base
end


class TmalignFamily < ChainFamily

  has_many  :chains,
            :class_name   => "AaChain",
            :foreign_key  => "tmalign_family_id"

  %w[dna rna].each do |na|
    has_one   :"#{na}_binding_tmalign_family_alignment"

    has_many  :"#{na}_binding_subfamilies",
              :class_name   => "#{na.capitalize}BindingChainSubfamily",
              :foreign_key  => "tmalign_family_id"
  end

end
