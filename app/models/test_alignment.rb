class TestAlignment < ActiveRecord::Base

  belongs_to :referece_alingment

end

class TestClustalwAlignment < TestAlignment
end

class TestNeedleAlignment < TestAlignment
end

class TestNaFugueAlingment < TestAlignment
end

class TestStdFugueAlignment < TestAlignment
end
