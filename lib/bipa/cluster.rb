module BIPA
  module Cluster
    def hierarchical(elements, threshold, &sim_func)
      clusters = elements.collect {|d| Cluster.new([d])}
      iter = 0
      sim_fun = options[:similarity_function] || :upgma
      options[:similarity_function] = nil
      while clusters.size > k
        puts "Iteration ....#{iter}"

        pairs = []
        clusters.each_with_index {|c,i| pairs.concat(clusters.slice(i+1,clusters.size).collect{|f| [c,f] })}
        pair = pairs.max {|a,b| a[0].send(sim_fun, a[1]) <=> b[0].send(sim_fun, b[1]) }
        clusters.delete(pair[1])
        pair[0].merge!(pair[1])

        iter += 1
      end
      options[:refined] ? clusters = kmeans(elements, k, options.merge(:seeds => clusters)) : clusters
    end
  end
end

module Clusterer
  class Cluster
    attr_reader :centroid, :elements
    include ClusterSimilarity

    def initialize(docs = [])
      @elements = docs
    end

    def centroid
      @centroid ||= (@elements.empty? ? nil : @elements[0].class.centroid_class.new(elements))
    end

    def merge!(cluster)
      elements.concat(cluster.elements)
      @centroid ? centroid.merge!(cluster.centroid) : @centroid = cluster.centroid
      @intra_cluster_similarity = nil
    end

    def + (cluster)
      c = Cluster.new(self.elements.clone)
      c.merge!(cluster)
      return c
    end

    def ==(cluster)
      cluster && self.elements == cluster.elements
    end

    def intra_cluster_cosine_similarity
      @intra_cluster_similarity ||= elements.inject(0) {|n,d| n + d.cosine_similarity(centroid) }
    end
  end
end

module Clusterer
  class Clustering
    class << self
      def cluster(algorithm, objects, options = { })
        options[:no_of_clusters] ||= Math.sqrt(objects.size).to_i
        idf = InverseDocumentFrequency.new
        docs = objects.collect {|o|
          (defined? yield) == "yield" ? Document.new(o, options.merge(:idf => idf)) {|o| yield(o)} : Document.new(o, options.merge(:idf => idf))}
          Algorithms.send(algorithm, docs.collect {|d| d.normalize!(idf) }, options[:no_of_clusters])
      end
    end
  end
end
