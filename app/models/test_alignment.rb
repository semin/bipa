class TestAlignment < ActiveRecord::Base

  belongs_to :reference_alignment

end

class TestClustalwAlignment < TestAlignment
end

class TestNeedleAlignment < TestAlignment
end

class TestStdFugueAlignment < TestAlignment
end

class TestNaFugueAlignment < TestAlignment
end
