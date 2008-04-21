namespace :bipa do
  namespace :analyze do

    desc "Stat"
    task :stats => [:environment] do
      dna_interfaces = DomainDnaInterface.find(:all, :select => "asa, polarity")

    end

  end
end
